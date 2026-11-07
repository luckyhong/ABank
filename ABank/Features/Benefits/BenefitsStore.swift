//
//  BenefitsStore.swift
//  ABank
//
//  积分/小豆流水、卡券、订单、领取与签到的本地持久化。每次变更都在快照副本上完成，
//  整体写入成功后才更新内存并发通知；数据无法解码时视为空，原字节保留到下一次成功保存。
//  状态（卡券、订单、等级、签到连续）均在读取时推算。
//

import Foundation

final class BenefitsStore {
    static let shared = BenefitsStore()
    static let storageKey = "abank.benefits.v1"
    static let didChangeNotification = Notification.Name("ABank.benefitsDidChange")

    private let defaults: UserDefaults
    private let notificationCenter: NotificationCenter
    private let dates: BankingDateContext
    private let dataWriter: ((Data) throws -> Void)?
    private var records: BenefitsRecords

    init(defaults: UserDefaults = .standard,
         notificationCenter: NotificationCenter = .default,
         dates: BankingDateContext = .system,
         dataWriter: ((Data) throws -> Void)? = nil) {
        self.defaults = defaults
        self.notificationCenter = notificationCenter
        self.dates = dates
        self.dataWriter = dataWriter
        if let data = defaults.data(forKey: Self.storageKey),
           let stored = try? JSONDecoder().decode(BenefitsRecords.self, from: data) {
            records = stored
        } else {
            records = .empty
        }
    }

    // MARK: - 读取

    private var allEntries: [RewardEntry] { BenefitsCatalog.seedEntries + records.entries }

    /// 按时间倒序；同一时刻的条目后写入的在前。
    private static func newestFirst<T>(_ items: [T], date: (T) -> Date) -> [T] {
        items.enumerated().sorted { lhs, rhs in
            let (l, r) = (date(lhs.element), date(rhs.element))
            return l != r ? l > r : lhs.offset > rhs.offset
        }.map(\.element)
    }

    func balance(_ currency: RewardCurrency) -> Int {
        BenefitsRules.balance(currency, entries: allEntries)
    }

    func ledger(currency: RewardCurrency) -> [RewardEntry] {
        Self.newestFirst(allEntries.filter { $0.currency == currency }, date: \.createdAt)
    }

    var lifetimeEarnedPoints: Int { BenefitsRules.lifetimeEarned(entries: allEntries) }
    var level: CustomerLevel { BenefitsRules.level(forEarnedPoints: lifetimeEarnedPoints) }

    var coupons: [Coupon] { Self.newestFirst(records.coupons, date: \.receivedAt) }
    var orders: [RewardOrder] { Self.newestFirst(records.orders, date: \.createdAt) }
    func coupon(id: String) -> Coupon? { records.coupons.first { $0.id == id } }
    func order(id: String) -> RewardOrder? { records.orders.first { $0.id == id } }

    func status(of coupon: Coupon) -> CouponStatus {
        BenefitsRules.status(of: coupon, at: dates.now, dates: dates)
    }

    func status(of order: RewardOrder) -> OrderStatus {
        BenefitsRules.status(of: order, coupon: coupon(id: order.couponID), at: dates.now, dates: dates)
    }

    func expiresAt(_ coupon: Coupon) -> Date { BenefitsRules.expiresAt(coupon, dates: dates) }
    func couponCode(for coupon: Coupon) -> String { BenefitsRules.couponCode(id: coupon.id) }

    func claimState(of benefit: Benefit) -> ClaimState {
        BenefitsRules.claimState(of: benefit, claims: records.claims, level: level, now: dates.now, dates: dates)
    }

    func redeemedCount(goodsID: String) -> Int {
        BenefitsRules.redeemedCount(goodsID: goodsID, orders: records.orders, now: dates.now, dates: dates)
    }

    var checkInStreak: Int {
        BenefitsRules.checkInStreak(days: records.checkInDays, now: dates.now, dates: dates)
    }

    var hasCheckedInToday: Bool { records.checkInDays.contains(dates.string(from: dates.now)) }
    var nextCheckInReward: Int { BenefitsRules.nextCheckInReward(streak: checkInStreak) }
    var unusedCouponCount: Int { records.coupons.filter { status(of: $0) == .unused }.count }

    // MARK: - 签到

    @discardableResult
    func checkIn() throws -> Int {
        guard !hasCheckedInToday else { throw BenefitsError.alreadyCheckedIn }
        let now = dates.now
        let reward = nextCheckInReward
        var updated = records
        updated.checkInDays.append(dates.string(from: now))
        updated.entries.append(entry(.beans, reward, .checkIn, "每日签到", at: now))
        try commit(updated)
        return reward
    }

    // MARK: - 权益领取

    @discardableResult
    func claim(benefitID: String) throws -> BenefitClaim {
        guard let benefit = BenefitsCatalog.benefit(id: benefitID) else { throw BenefitsError.unknownItem }
        switch claimState(of: benefit) {
        case .available: break
        case .levelTooLow: throw BenefitsError.levelTooLow
        case .claimedOnce, .claimedThisMonth: throw BenefitsError.alreadyClaimed
        }
        let now = dates.now
        var updated = records
        var couponID: String?
        switch benefit.reward {
        case .points(let amount):
            updated.entries.append(entry(.points, amount, .claim, "领取" + benefit.title, at: now))
        case .coupon(let templateID):
            let coupon = Coupon(id: UUID().uuidString, templateID: templateID, benefitID: benefit.id,
                                orderID: nil, receivedAt: now, usedAt: nil, voidedAt: nil)
            updated.coupons.append(coupon)
            couponID = coupon.id
        }
        let claim = BenefitClaim(id: UUID().uuidString, benefitID: benefit.id, createdAt: now, couponID: couponID)
        updated.claims.append(claim)
        try commit(updated)
        return claim
    }

    // MARK: - 兑换与取消

    @discardableResult
    func redeem(goodsID: String) throws -> RewardOrder {
        guard let goods = BenefitsCatalog.goods(id: goodsID),
              let template = BenefitsCatalog.template(id: goods.templateID) else { throw BenefitsError.unknownItem }
        guard balance(goods.currency) >= goods.price else { throw BenefitsError.insufficientBalance }
        guard redeemedCount(goodsID: goodsID) < goods.monthlyLimit else { throw BenefitsError.monthlyLimitReached }
        let now = dates.now
        let orderID = UUID().uuidString
        let coupon = Coupon(id: UUID().uuidString, templateID: template.id, benefitID: nil,
                            orderID: orderID, receivedAt: now, usedAt: nil, voidedAt: nil)
        let order = RewardOrder(
            id: orderID, orderNo: BenefitsRules.orderNo(id: orderID, createdAt: now, dates: dates),
            goodsID: goods.id, title: template.title, currency: goods.currency, cost: goods.price,
            quantity: 1, createdAt: now, couponID: coupon.id, cancelledAt: nil
        )
        var updated = records
        updated.orders.append(order)
        updated.coupons.append(coupon)
        updated.entries.append(entry(goods.currency, -goods.price, .redeem, "兑换" + template.title, at: now, orderID: orderID))
        try commit(updated)
        return order
    }

    func cancelOrder(id: String) throws {
        guard let orderIndex = records.orders.firstIndex(where: { $0.id == id }),
              records.orders[orderIndex].cancelledAt == nil,
              let couponIndex = records.coupons.firstIndex(where: { $0.id == records.orders[orderIndex].couponID }),
              status(of: records.coupons[couponIndex]) == .unused else { throw BenefitsError.notCancellable }
        let now = dates.now
        let order = records.orders[orderIndex]
        var updated = records
        updated.orders[orderIndex].cancelledAt = now
        updated.coupons[couponIndex].voidedAt = now
        updated.entries.append(entry(order.currency, order.cost, .refund, "退回" + order.title, at: now, orderID: order.id))
        try commit(updated)
    }

    // MARK: - 卡券

    func useCoupon(id: String) throws {
        guard let index = records.coupons.firstIndex(where: { $0.id == id }) else { throw BenefitsError.unknownItem }
        guard status(of: records.coupons[index]) == .unused else { throw BenefitsError.notUsable }
        var updated = records
        updated.coupons[index].usedAt = dates.now
        try commit(updated)
    }

    // MARK: - 持久化

    private func entry(_ currency: RewardCurrency, _ amount: Int, _ kind: RewardEntryKind,
                       _ title: String, at time: Date, orderID: String? = nil) -> RewardEntry {
        RewardEntry(id: UUID().uuidString, currency: currency, amount: amount, kind: kind,
                    title: title, createdAt: time, orderID: orderID)
    }

    private func commit(_ updated: BenefitsRecords) throws {
        do {
            let data = try JSONEncoder().encode(updated)
            if let dataWriter {
                try dataWriter(data)
            } else {
                defaults.set(data, forKey: Self.storageKey)
            }
        } catch {
            throw BenefitsError.saveFailed
        }
        records = updated
        notificationCenter.post(name: Self.didChangeNotification, object: self)
    }
}
