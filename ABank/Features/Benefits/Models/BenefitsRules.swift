//
//  BenefitsRules.swift
//  ABank
//
//  等级、余额、签到、卡券/订单状态、领取与限兑规则。全部为纯函数，时间来自注入的
//  BankingDateContext（Asia/Shanghai）；编码使用 FNV-1a，避免 hashValue 的启动随机化。
//

import Foundation

nonisolated enum BenefitsRules {
    static let checkInRewards = [5, 5, 8, 8, 10, 10, 20]
    static let defaultValidDays = 30

    // MARK: - 余额与等级

    static func balance(_ currency: RewardCurrency, entries: [RewardEntry]) -> Int {
        entries.filter { $0.currency == currency }.reduce(0) { $0 + $1.amount }
    }

    /// 累计获得积分：不含兑换支出与取消退回，因此取消订单不会抬高等级。
    static func lifetimeEarned(entries: [RewardEntry]) -> Int {
        entries.filter { $0.currency == .points && $0.kind != .refund && $0.kind != .redeem && $0.amount > 0 }
            .reduce(0) { $0 + $1.amount }
    }

    static func level(forEarnedPoints points: Int) -> CustomerLevel {
        CustomerLevel.allCases.last { points >= $0.threshold } ?? .none
    }

    // MARK: - 签到

    /// 从今天（已签）或昨天起向前连续的天数；昨天也未签则为 0。
    static func checkInStreak(days: [String], now: Date, dates: BankingDateContext) -> Int {
        let signed = Set(days)
        let today = dates.calendar.startOfDay(for: now)
        var cursor = signed.contains(dates.string(from: today)) ? today : dates.calendar.date(byAdding: .day, value: -1, to: today)!
        var streak = 0
        while signed.contains(dates.string(from: cursor)) {
            streak += 1
            cursor = dates.calendar.date(byAdding: .day, value: -1, to: cursor)!
        }
        return streak
    }

    static func nextCheckInReward(streak: Int) -> Int {
        checkInRewards[streak % checkInRewards.count]
    }

    // MARK: - 卡券与订单

    static func expiresAt(_ coupon: Coupon, dates: BankingDateContext) -> Date {
        let days = BenefitsCatalog.template(id: coupon.templateID)?.validDays ?? defaultValidDays
        let start = dates.calendar.startOfDay(for: coupon.receivedAt)
        return dates.calendar.date(byAdding: .day, value: days, to: start)!
    }

    static func status(of coupon: Coupon, at time: Date, dates: BankingDateContext) -> CouponStatus {
        if coupon.voidedAt != nil { return .voided }
        if coupon.usedAt != nil { return .used }
        if time >= expiresAt(coupon, dates: dates) { return .expired }
        return .unused
    }

    static func status(of order: RewardOrder, coupon: Coupon?, at time: Date, dates: BankingDateContext) -> OrderStatus {
        guard order.cancelledAt == nil, let coupon else { return .cancelled }
        switch status(of: coupon, at: time, dates: dates) {
        case .unused: return .pendingUse
        case .used: return .used
        case .expired: return .expired
        case .voided: return .cancelled
        }
    }

    // MARK: - 领取与限兑

    static func claimState(of benefit: Benefit, claims: [BenefitClaim], level: CustomerLevel,
                           now: Date, dates: BankingDateContext) -> ClaimState {
        let mine = claims.filter { $0.benefitID == benefit.id }
        switch benefit.period {
        case .once:
            if !mine.isEmpty { return .claimedOnce }
        case .monthly:
            let month = dates.string(from: now, format: "yyyy-MM")
            if mine.contains(where: { dates.string(from: $0.createdAt, format: "yyyy-MM") == month }) {
                return .claimedThisMonth
            }
        }
        return level >= benefit.minLevel ? .available : .levelTooLow(benefit.minLevel)
    }

    /// 本上海自然月内该商品未取消的订单数。
    static func redeemedCount(goodsID: String, orders: [RewardOrder], now: Date, dates: BankingDateContext) -> Int {
        let month = dates.string(from: now, format: "yyyy-MM")
        return orders.filter {
            $0.goodsID == goodsID && $0.cancelledAt == nil
                && dates.string(from: $0.createdAt, format: "yyyy-MM") == month
        }.count
    }

    // MARK: - 稳定编码

    static func orderNo(id: String, createdAt: Date, dates: BankingDateContext) -> String {
        let digits = String(BranchSchedule.stableHash("order", id) % 100_000_000)
        return "M6" + dates.string(from: createdAt, format: "yyyyMMdd")
            + String(repeating: "0", count: 8 - digits.count) + digits
    }

    static func couponCode(id: String) -> String {
        let alphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        var value = BranchSchedule.stableHash("coupon", id)
        var chars: [Character] = []
        for _ in 0..<12 {
            chars.append(alphabet[Int(value % 36)])
            value /= 36
        }
        let text = String(chars)
        return [text.prefix(4), text.dropFirst(4).prefix(4), text.suffix(4)].map(String.init).joined(separator: "-")
    }
}
