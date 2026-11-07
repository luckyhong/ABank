import Foundation

@main struct BenefitsChecks {
    @MainActor static func main() throws {
        catalog()
        levels()
        lifetimeEarned()
        checkInStreak()
        shanghaiBoundaries()
        claimStates()
        couponStatus()
        redeemedCount()
        codes()
        try seedAndFreshStore()
        try checkInRules()
        try claimRules()
        try monthlyClaimRollover()
        try redeemRules()
        try useCoupon()
        try cancelRules()
        try cancelKeepsLevel()
        try persistence()
        try corruptRecordsKeepOriginal()
        try writeFailureIsAtomic()
        try mineStats()
        print("Benefits checks passed")
    }

    // MARK: - 工具

    static let shanghai = BankingDateContext(now: { Date() })

    static func at(_ text: String) -> Date {
        guard let date = shanghai.date(from: text, format: "yyyy-MM-dd HH:mm") else {
            preconditionFailure("bad date \(text)")
        }
        return date
    }

    static func clock(_ text: String) -> BankingDateContext {
        let date = at(text)
        return BankingDateContext(now: { date })
    }

    static func utc(_ text: String) -> Date {
        guard let date = ISO8601DateFormatter().date(from: text) else { preconditionFailure("bad utc \(text)") }
        return date
    }

    static func clock(utc text: String) -> BankingDateContext {
        let date = utc(text)
        return BankingDateContext(now: { date })
    }

    static var seed: [RewardEntry] { BenefitsCatalog.seedEntries }

    static func entry(_ currency: RewardCurrency, _ amount: Int, _ kind: RewardEntryKind) -> RewardEntry {
        RewardEntry(id: UUID().uuidString, currency: currency, amount: amount, kind: kind,
                    title: "测试", createdAt: at("2026-11-01 10:00"), orderID: nil)
    }

    static func coupon(received: String, used: String? = nil, voided: String? = nil) -> Coupon {
        Coupon(id: "c1", templateID: "coffee10", benefitID: nil, orderID: "o1",
               receivedAt: at(received), usedAt: used.map(at), voidedAt: voided.map(at))
    }

    static func order(_ id: String, created: String, cancelled: String? = nil, goods: String = "g.coffee30") -> RewardOrder {
        RewardOrder(id: id, orderNo: "M6", goodsID: goods, title: "咖啡", currency: .points, cost: 3000,
                    quantity: 1, createdAt: at(created), couponID: "c-\(id)", cancelledAt: cancelled.map(at))
    }

    // MARK: - 目录

    static func catalog() {
        precondition(BenefitsCatalog.benefits.count == 8, "benefits")
        let benefitIDs = BenefitsCatalog.benefits.map(\.id)
        precondition(Set(benefitIDs).count == 8 && benefitIDs.contains("welcomeGift") && benefitIDs.contains("star3Points"))
        precondition(BenefitsCatalog.goods.count == 12, "goods")
        precondition(BenefitsCatalog.goods(in: .points).count == 6 && BenefitsCatalog.goods(in: .beans).count == 6)
        for goods in BenefitsCatalog.goods {
            precondition(BenefitsCatalog.template(id: goods.templateID) != nil, "template of \(goods.id)")
            precondition(goods.price > 0 && (2...3).contains(goods.monthlyLimit), "goods values \(goods.id)")
        }
        for benefit in BenefitsCatalog.benefits {
            if case .coupon(let templateID) = benefit.reward {
                precondition(BenefitsCatalog.template(id: templateID) != nil, "template of \(benefit.id)")
            }
        }
        let templateIDs = BenefitsCatalog.templates.map(\.id)
        precondition(Set(templateIDs).count == templateIDs.count, "template ids unique")
        precondition(BenefitsCatalog.goods(id: "g.coffee30")?.price == 3000 && BenefitsCatalog.goods(id: "g.bus5")?.price == 50)
        precondition(BenefitsCatalog.goods(id: "none") == nil && BenefitsCatalog.benefit(id: "none") == nil)

        precondition(seed.allSatisfy { $0.kind == .seed }, "seed kinds")
        precondition(BenefitsRules.balance(.points, entries: seed) == 12_860, "seed points")
        precondition(BenefitsRules.balance(.beans, entries: seed) == 260, "seed beans")
        precondition(BenefitsRules.lifetimeEarned(entries: seed) == 14_360, "seed earned")
        precondition(BenefitsRules.level(forEarnedPoints: 14_360) == .two && CustomerLevel.two.title == "二星客户")
        precondition(Set(seed.map(\.id)).count == seed.count, "seed ids unique")
    }

    static func levels() {
        let cases: [(Int, CustomerLevel)] = [
            (0, .none), (1_999, .none), (2_000, .one), (9_999, .one), (10_000, .two), (29_999, .two),
            (30_000, .three), (80_000, .four), (200_000, .five), (1_000_000, .five)
        ]
        for (points, level) in cases {
            precondition(BenefitsRules.level(forEarnedPoints: points) == level, "level for \(points)")
        }
        precondition(CustomerLevel.five.next == nil && CustomerLevel.none.next == .one)
        precondition(CustomerLevel.allCases.map(\.threshold) == [0, 2_000, 10_000, 30_000, 80_000, 200_000])
        precondition(CustomerLevel.none.title == "普通客户" && CustomerLevel.five.title == "五星客户")
        precondition(CustomerLevel.three.shortTitle == "三星" && CustomerLevel.none.shortTitle == "普通")
        precondition(CustomerLevel.one < CustomerLevel.two)
    }

    static func lifetimeEarned() {
        let entries = seed + [
            entry(.points, -500, .redeem), entry(.points, 500, .refund),
            entry(.points, 200, .claim), entry(.beans, 5, .checkIn)
        ]
        precondition(BenefitsRules.lifetimeEarned(entries: entries) == 14_360 + 200, "refund/redeem/beans excluded")
        precondition(BenefitsRules.balance(.points, entries: entries) == 12_860 - 500 + 500 + 200)
        precondition(BenefitsRules.balance(.beans, entries: entries) == 265)
    }

    static func checkInStreak() {
        let dates = clock("2026-11-06 10:00")
        func streak(_ days: [String]) -> Int { BenefitsRules.checkInStreak(days: days, now: dates.now, dates: dates) }
        precondition(streak([]) == 0)
        precondition(streak(["2026-11-06"]) == 1)
        precondition(streak(["2026-11-05", "2026-11-04"]) == 2, "yesterday counts")
        precondition(streak(["2026-11-06", "2026-11-05", "2026-11-03"]) == 2, "gap breaks")
        precondition(streak(["2026-11-04"]) == 0)
        precondition(streak(["2026-10-31", "2026-11-01", "2026-11-02", "2026-11-03", "2026-11-04", "2026-11-05"]) == 6, "cross month")
        let expected = [5, 5, 8, 8, 10, 10, 20, 5]
        for (streak, reward) in expected.enumerated() {
            precondition(BenefitsRules.nextCheckInReward(streak: streak) == reward, "reward for streak \(streak)")
        }
    }

    static func shanghaiBoundaries() {
        let early = clock(utc: "2026-11-05T23:30:00Z") // 上海 11-06 07:30
        precondition(BenefitsRules.checkInStreak(days: ["2026-11-06"], now: early.now, dates: early) == 1)
        precondition(BenefitsRules.checkInStreak(days: ["2026-11-05"], now: early.now, dates: early) == 1)
        precondition(BenefitsRules.checkInStreak(days: ["2026-11-04"], now: early.now, dates: early) == 0)

        let monthly = BenefitsCatalog.benefit(id: "monthlyPoints")!
        let claim = BenefitClaim(id: "k", benefitID: "monthlyPoints", createdAt: utc("2026-10-31T15:59:00Z"), couponID: nil)
        let before = clock(utc: "2026-10-31T15:59:30Z")
        let after = clock(utc: "2026-10-31T16:00:00Z")
        precondition(BenefitsRules.claimState(of: monthly, claims: [claim], level: .two, now: before.now, dates: before) == .claimedThisMonth)
        precondition(BenefitsRules.claimState(of: monthly, claims: [claim], level: .two, now: after.now, dates: after) == .available)
    }

    static func claimStates() {
        let dates = clock("2026-11-06 10:00")
        func state(_ id: String, claims: [BenefitClaim] = [], level: CustomerLevel = .two) -> ClaimState {
            BenefitsRules.claimState(of: BenefitsCatalog.benefit(id: id)!, claims: claims, level: level, now: dates.now, dates: dates)
        }
        func claim(_ id: String, _ created: String) -> BenefitClaim {
            BenefitClaim(id: UUID().uuidString, benefitID: id, createdAt: at(created), couponID: nil)
        }
        precondition(state("welcomeGift") == .available)
        precondition(state("welcomeGift", claims: [claim("welcomeGift", "2025-01-01 10:00")]) == .claimedOnce)
        precondition(state("monthlyPoints", claims: [claim("monthlyPoints", "2026-11-02 10:00")]) == .claimedThisMonth)
        precondition(state("monthlyPoints", claims: [claim("monthlyPoints", "2026-10-30 10:00")]) == .available)
        precondition(state("star3Points") == .levelTooLow(.three))
        precondition(state("star3Points", level: .three) == .available)
        precondition(ClaimState.levelTooLow(.three).title == "需三星")
        precondition(ClaimState.available.title == "领取" && ClaimState.claimedOnce.title == "已领取" && ClaimState.claimedThisMonth.title == "本月已领")
        precondition(state("monthlyPoints", level: .none) == .levelTooLow(.one))
    }

    static func couponStatus() {
        let received = coupon(received: "2026-11-01 15:00")
        precondition(BenefitsRules.expiresAt(received, dates: shanghai) == at("2026-12-01 00:00"))
        func status(_ coupon: Coupon, _ now: String) -> CouponStatus {
            let dates = clock(now)
            return BenefitsRules.status(of: coupon, at: dates.now, dates: dates)
        }
        precondition(status(received, "2026-11-30 23:59") == .unused)
        precondition(status(received, "2026-12-01 00:00") == .expired, "now == expiresAt is expired")
        precondition(status(coupon(received: "2026-11-01 15:00", used: "2026-11-02 10:00"), "2026-12-05 10:00") == .used)
        precondition(status(coupon(received: "2026-11-01 15:00", used: "2026-11-02 10:00", voided: "2026-11-03 10:00"), "2026-11-04 10:00") == .voided)
        precondition(CouponStatus.unused.isActive && !CouponStatus.used.isActive && !CouponStatus.expired.isActive && !CouponStatus.voided.isActive)
        precondition([CouponStatus.unused, .used, .expired, .voided].map(\.title) == ["待使用", "已使用", "已过期", "已作废"])

        let dates = clock("2026-11-10 10:00")
        func orderStatus(_ order: RewardOrder, _ coupon: Coupon?) -> OrderStatus {
            BenefitsRules.status(of: order, coupon: coupon, at: dates.now, dates: dates)
        }
        let plain = order("o1", created: "2026-11-01 15:00")
        precondition(orderStatus(plain, received) == .pendingUse)
        precondition(orderStatus(plain, coupon(received: "2026-11-01 15:00", used: "2026-11-02 10:00")) == .used)
        precondition(orderStatus(plain, coupon(received: "2026-09-01 15:00")) == .expired)
        precondition(orderStatus(order("o2", created: "2026-11-01 15:00", cancelled: "2026-11-02 10:00"), received) == .cancelled)
        precondition(orderStatus(plain, nil) == .cancelled)
        precondition([OrderStatus.pendingUse, .used, .expired, .cancelled].map(\.title) == ["待使用", "已使用", "已过期", "已取消"])
    }

    static func redeemedCount() {
        let dates = clock("2026-11-10 10:00")
        let orders = [
            order("a", created: "2026-11-02 10:00"),
            order("b", created: "2026-11-03 10:00", cancelled: "2026-11-04 10:00"),
            order("c", created: "2026-10-31 23:59"),
            order("d", created: "2026-11-05 10:00", goods: "g.phone10")
        ]
        precondition(BenefitsRules.redeemedCount(goodsID: "g.coffee30", orders: orders, now: dates.now, dates: dates) == 1)
        precondition(BenefitsRules.redeemedCount(goodsID: "g.phone10", orders: orders, now: dates.now, dates: dates) == 1)
        precondition(BenefitsRules.redeemedCount(goodsID: "g.bus5", orders: orders, now: dates.now, dates: dates) == 0)
    }

    static func codes() {
        let created = at("2026-11-06 10:00")
        let no = BenefitsRules.orderNo(id: "order-1", createdAt: created, dates: shanghai)
        precondition(no.range(of: "^M620261106\\d{8}$", options: .regularExpression) != nil, "order no \(no)")
        precondition(no == BenefitsRules.orderNo(id: "order-1", createdAt: created, dates: shanghai))
        precondition(no != BenefitsRules.orderNo(id: "order-2", createdAt: created, dates: shanghai))
        let code = BenefitsRules.couponCode(id: "coupon-1")
        precondition(code.range(of: "^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$", options: .regularExpression) != nil, "code \(code)")
        precondition(code == BenefitsRules.couponCode(id: "coupon-1") && code != BenefitsRules.couponCode(id: "coupon-2"))
    }

    // MARK: - Store 工具

    final class TestClock {
        var now: Date
        init(_ text: String) { now = BenefitsChecks.at(text) }
        func set(_ text: String) { now = BenefitsChecks.at(text) }
    }

    final class Counter { var count = 0 }

    struct WriteFailure: Error {}

    @MainActor static func withSuite(_ body: (UserDefaults) throws -> Void) rethrows {
        let suite = "ABank.BenefitsChecks." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        try body(defaults)
    }

    static func expect(_ expected: BenefitsError, _ body: () throws -> Void, _ label: String) {
        do {
            try body()
            preconditionFailure("\(label): expected \(expected), got success")
        } catch let error as BenefitsError {
            precondition(error == expected, "\(label): expected \(expected), got \(error)")
        } catch {
            preconditionFailure("\(label): unexpected \(error)")
        }
    }

    @MainActor static func makeStore(_ defaults: UserDefaults, _ clock: TestClock,
                                     center: NotificationCenter = NotificationCenter(),
                                     writer: ((Data) throws -> Void)? = nil) -> BenefitsStore {
        BenefitsStore(defaults: defaults, notificationCenter: center,
                      dates: BankingDateContext(now: { clock.now }), dataWriter: writer)
    }

    @MainActor static func count(_ center: NotificationCenter) -> Counter {
        let counter = Counter()
        center.addObserver(forName: BenefitsStore.didChangeNotification, object: nil, queue: nil) { _ in counter.count += 1 }
        return counter
    }

    /// 预置一条积分支出流水，使积分余额为 `balance`。
    static func preset(_ defaults: UserDefaults, pointsBalance balance: Int) throws {
        let spend = RewardEntry(id: "preset", currency: .points, amount: balance - 12_860, kind: .redeem,
                                title: "预置", createdAt: at("2026-10-20 10:00"), orderID: nil)
        var records = BenefitsRecords.empty
        records.entries = [spend]
        defaults.set(try JSONEncoder().encode(records), forKey: BenefitsStore.storageKey)
    }

    // MARK: - Store

    @MainActor static func seedAndFreshStore() throws {
        try withSuite { defaults in
            let store = makeStore(defaults, TestClock("2026-11-06 10:00"))
            precondition(store.balance(.points) == 12_860 && store.balance(.beans) == 260)
            precondition(store.level == .two && store.lifetimeEarnedPoints == 14_360)
            precondition(store.coupons.isEmpty && store.orders.isEmpty && store.unusedCouponCount == 0)
            let points = store.ledger(currency: .points)
            precondition(points.count == 6 && points.allSatisfy { $0.currency == .points })
            precondition(points.map(\.createdAt) == points.map(\.createdAt).sorted(by: >), "descending")
            precondition(store.ledger(currency: .beans).count == 4)
            precondition(!store.hasCheckedInToday && store.checkInStreak == 0 && store.nextCheckInReward == 5)
        }
    }

    @MainActor static func checkInRules() throws {
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let center = NotificationCenter()
            let counter = count(center)
            let store = makeStore(defaults, clock, center: center)
            let first = try store.checkIn()
            precondition(first == 5)
            precondition(store.balance(.beans) == 265 && store.hasCheckedInToday && store.checkInStreak == 1)
            let entry = store.ledger(currency: .beans).first!
            precondition(entry.kind == .checkIn && entry.currency == .beans && entry.amount == 5)
            expect(.alreadyCheckedIn, { try store.checkIn() }, "same day")
            precondition(counter.count == 1, "failure does not notify")
            precondition(store.balance(.points) == 12_860, "points untouched")
            var rewards = [5]
            for day in 7...13 {
                clock.set("2026-11-\(String(format: "%02d", day)) 09:00")
                rewards.append(try store.checkIn())
            }
            precondition(rewards == [5, 5, 8, 8, 10, 10, 20, 5], "streak cycle \(rewards)")
        }
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let store = makeStore(defaults, clock)
            try store.checkIn()
            clock.set("2026-11-07 10:00")
            try store.checkIn()
            precondition(store.checkInStreak == 2)
            clock.set("2026-11-09 10:00") // 漏签 11-08
            precondition(store.checkInStreak == 0 && store.nextCheckInReward == 5)
            let rewarded = try store.checkIn()
            precondition(rewarded == 5 && store.checkInStreak == 1)
        }
    }

    @MainActor static func claimRules() throws {
        try withSuite { defaults in
            let store = makeStore(defaults, TestClock("2026-11-06 10:00"))
            let claim = try store.claim(benefitID: "welcomeGift")
            precondition(claim.couponID == nil && store.balance(.points) == 13_360)
            precondition(store.ledger(currency: .points).first!.kind == .claim)
            expect(.alreadyClaimed, { try store.claim(benefitID: "welcomeGift") }, "once twice")
            precondition(store.claimState(of: BenefitsCatalog.benefit(id: "welcomeGift")!) == .claimedOnce)

            let coupon = try store.claim(benefitID: "takeoutPack")
            let issued = store.coupon(id: coupon.couponID!)!
            precondition(issued.benefitID == "takeoutPack" && issued.orderID == nil)
            precondition(store.status(of: issued) == .unused && store.unusedCouponCount == 1)
            precondition(store.balance(.points) == 13_360, "coupon claim leaves balance")

            expect(.levelTooLow, { try store.claim(benefitID: "star3Points") }, "level")
            expect(.unknownItem, { try store.claim(benefitID: "none") }, "unknown")
            try store.claim(benefitID: "monthlyPoints")
            expect(.alreadyClaimed, { try store.claim(benefitID: "monthlyPoints") }, "monthly twice")
        }
    }

    @MainActor static func monthlyClaimRollover() throws {
        try withSuite { defaults in
            let clock = TestClock("2026-10-31 23:59")
            let store = makeStore(defaults, clock)
            try store.claim(benefitID: "monthlyPoints")
            expect(.alreadyClaimed, { try store.claim(benefitID: "monthlyPoints") }, "same month")
            clock.set("2026-11-01 00:00")
            try store.claim(benefitID: "monthlyPoints")
            precondition(store.balance(.points) == 12_860 + 400)
        }
    }

    @MainActor static func redeemRules() throws {
        try withSuite { defaults in
            let store = makeStore(defaults, TestClock("2026-11-06 10:00"))
            let order = try store.redeem(goodsID: "g.coffee30")
            precondition(store.balance(.points) == 9_860 && store.balance(.beans) == 260, "currencies are separate")
            precondition(order.cost == 3_000 && order.currency == .points && order.quantity == 1)
            precondition(order.orderNo.range(of: "^M620261106\\d{8}$", options: .regularExpression) != nil)
            let coupon = store.coupon(id: order.couponID)!
            precondition(coupon.orderID == order.id && store.status(of: coupon) == .unused)
            let entry = store.ledger(currency: .points).first!
            precondition(entry.kind == .redeem && entry.amount == -3_000 && entry.orderID == order.id)
            precondition(store.unusedCouponCount == 1 && store.redeemedCount(goodsID: "g.coffee30") == 1)
            precondition(store.status(of: order) == .pendingUse && store.orders.first == order)

            try store.redeem(goodsID: "g.bus5")
            precondition(store.balance(.beans) == 210 && store.balance(.points) == 9_860, "beans only")
            expect(.unknownItem, { try store.redeem(goodsID: "none") }, "unknown goods")
        }
        try withSuite { defaults in
            try preset(defaults, pointsBalance: 1_000)
            let store = makeStore(defaults, TestClock("2026-11-06 10:00"))
            precondition(store.balance(.points) == 1_000)
            try store.redeem(goodsID: "g.phone10")
            precondition(store.balance(.points) == 0, "exact balance redeemable")
            expect(.insufficientBalance, { try store.redeem(goodsID: "g.phone10") }, "empty")
        }
        try withSuite { defaults in
            try preset(defaults, pointsBalance: 999)
            let store = makeStore(defaults, TestClock("2026-11-06 10:00"))
            expect(.insufficientBalance, { try store.redeem(goodsID: "g.phone10") }, "short by one")
            precondition(store.balance(.points) == 999 && store.orders.isEmpty)
        }
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let store = makeStore(defaults, clock)
            var firstID = ""
            for index in 0..<3 {
                let order = try store.redeem(goodsID: "g.phone10")
                if index == 0 { firstID = order.id }
            }
            expect(.monthlyLimitReached, { try store.redeem(goodsID: "g.phone10") }, "limit 3")
            try store.cancelOrder(id: firstID)
            try store.redeem(goodsID: "g.phone10")
            expect(.monthlyLimitReached, { try store.redeem(goodsID: "g.phone10") }, "limit again")
            clock.set("2026-12-01 00:00")
            try store.redeem(goodsID: "g.phone10")
            precondition(store.redeemedCount(goodsID: "g.phone10") == 1, "new month resets")
        }
    }

    @MainActor static func useCoupon() throws {
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let store = makeStore(defaults, clock)
            let order = try store.redeem(goodsID: "g.coffee30")
            try store.useCoupon(id: order.couponID)
            precondition(store.status(of: store.coupon(id: order.couponID)!) == .used)
            precondition(store.status(of: store.order(id: order.id)!) == .used)
            expect(.notUsable, { try store.useCoupon(id: order.couponID) }, "used twice")
            expect(.unknownItem, { try store.useCoupon(id: "none") }, "unknown coupon")

            let expiring = try store.redeem(goodsID: "g.ride20")
            clock.set("2026-12-06 00:00")
            expect(.notUsable, { try store.useCoupon(id: expiring.couponID) }, "expired")

            clock.set("2026-12-07 10:00")
            let voided = try store.redeem(goodsID: "g.book30")
            try store.cancelOrder(id: voided.id)
            expect(.notUsable, { try store.useCoupon(id: voided.couponID) }, "voided")
        }
    }

    @MainActor static func cancelRules() throws {
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let center = NotificationCenter()
            let store = makeStore(defaults, clock, center: center)
            let order = try store.redeem(goodsID: "g.coffee30")
            let counter = count(center)
            try store.cancelOrder(id: order.id)
            precondition(counter.count == 1)
            precondition(store.status(of: store.order(id: order.id)!) == .cancelled)
            precondition(store.status(of: store.coupon(id: order.couponID)!) == .voided)
            let refund = store.ledger(currency: .points).first!
            precondition(refund.kind == .refund && refund.amount == 3_000 && refund.orderID == order.id)
            precondition(store.balance(.points) == 12_860 && store.unusedCouponCount == 0)
            precondition(store.orders.count == 1, "order kept")
            expect(.notCancellable, { try store.cancelOrder(id: order.id) }, "cancel twice")
            expect(.notCancellable, { try store.cancelOrder(id: "none") }, "unknown order")

            let used = try store.redeem(goodsID: "g.ride20")
            try store.useCoupon(id: used.couponID)
            expect(.notCancellable, { try store.cancelOrder(id: used.id) }, "used order")
            precondition(counter.count == 3, "redeem + use notify; failed cancels do not")

            let beans = try store.redeem(goodsID: "g.bus5")
            try store.cancelOrder(id: beans.id)
            precondition(store.balance(.beans) == 260 && store.ledger(currency: .beans).first!.kind == .refund)
        }
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let store = makeStore(defaults, clock)
            let order = try store.redeem(goodsID: "g.coffee30")
            clock.set("2026-12-05 23:59")
            let early = makeStore(defaults, clock)
            try early.cancelOrder(id: order.id)
            clock.set("2026-12-30 23:59")
            let late = makeStore(defaults, clock)
            let expiring = try late.redeem(goodsID: "g.book30")
            clock.set("2027-01-29 00:00") // 12-30 + 30 天 = 2027-01-29 00:00 即过期
            expect(.notCancellable, { try late.cancelOrder(id: expiring.id) }, "now == expiresAt")
        }
    }

    @MainActor static func cancelKeepsLevel() throws {
        try withSuite { defaults in
            let store = makeStore(defaults, TestClock("2026-11-06 10:00"))
            for goods in ["g.market50", "g.coffee30"] {
                let order = try store.redeem(goodsID: goods)
                precondition(store.lifetimeEarnedPoints == 14_360 && store.level == .two)
                try store.cancelOrder(id: order.id)
                precondition(store.lifetimeEarnedPoints == 14_360 && store.level == .two, "refund is not earned")
            }
            try store.claim(benefitID: "welcomeGift")
            precondition(store.lifetimeEarnedPoints == 14_860)
        }
    }

    @MainActor static func persistence() throws {
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let store = makeStore(defaults, clock)
            try store.checkIn()
            try store.claim(benefitID: "welcomeGift")
            try store.claim(benefitID: "takeoutPack")
            let order = try store.redeem(goodsID: "g.coffee30")
            let reloaded = makeStore(defaults, clock)
            precondition(reloaded.balance(.points) == store.balance(.points) && reloaded.balance(.beans) == store.balance(.beans))
            precondition(reloaded.coupons == store.coupons && reloaded.orders == store.orders)
            precondition(reloaded.order(id: order.id) == order && reloaded.hasCheckedInToday)
            precondition(reloaded.claimState(of: BenefitsCatalog.benefit(id: "welcomeGift")!) == .claimedOnce)
            precondition(reloaded.ledger(currency: .points) == store.ledger(currency: .points))
        }
    }

    @MainActor static func corruptRecordsKeepOriginal() throws {
        try withSuite { defaults in
            let original = Data(#"{"entries":[{"id":1}]}"#.utf8)
            defaults.set(original, forKey: BenefitsStore.storageKey)
            let store = makeStore(defaults, TestClock("2026-11-06 10:00"))
            precondition(store.balance(.points) == 12_860 && store.orders.isEmpty && store.coupons.isEmpty)
            precondition(defaults.data(forKey: BenefitsStore.storageKey) == original, "bytes untouched on load")
            try store.checkIn()
            precondition(defaults.data(forKey: BenefitsStore.storageKey) != original, "replaced after successful save")
        }
    }

    @MainActor static func writeFailureIsAtomic() throws {
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let center = NotificationCenter()
            var failing = false
            let store = makeStore(defaults, clock, center: center, writer: { data in
                if failing { throw WriteFailure() }
                defaults.set(data, forKey: BenefitsStore.storageKey)
            })
            let order = try store.redeem(goodsID: "g.coffee30")
            let counter = count(center)
            failing = true
            let points = store.balance(.points), beans = store.balance(.beans)
            let coupons = store.coupons, orders = store.orders, ledger = store.ledger(currency: .points)
            expect(.saveFailed, { try store.redeem(goodsID: "g.phone10") }, "redeem")
            expect(.saveFailed, { try store.cancelOrder(id: order.id) }, "cancel")
            expect(.saveFailed, { try store.checkIn() }, "check in")
            expect(.saveFailed, { try store.claim(benefitID: "welcomeGift") }, "claim")
            expect(.saveFailed, { try store.useCoupon(id: order.couponID) }, "use")
            precondition(store.balance(.points) == points && store.balance(.beans) == beans)
            precondition(store.coupons == coupons && store.orders == orders && store.ledger(currency: .points) == ledger)
            precondition(!store.hasCheckedInToday && counter.count == 0, "no notification on failure")
            failing = false
            try store.cancelOrder(id: order.id)
            precondition(store.balance(.points) == 12_860 && counter.count == 1)
        }
    }

    @MainActor static func mineStats() throws {
        try withSuite { defaults in
            let store = makeStore(defaults, TestClock("2026-11-06 10:00"))
            func stats() -> [MineAssetStat] { MineAssetStats.make(benefits: store) }
            precondition(stats().map(\.label) == ["银行卡", "小豆", "积分", "礼券"])
            precondition(stats().map(\.value) == [1, 260, 12_860, 0])
            precondition(stats().map(\.route) == [.myAccount, .rewardLedger(currency: .beans), .rewardLedger(currency: .points), .coupons])
            let order = try store.redeem(goodsID: "g.coffee30")
            precondition(stats().map(\.value) == [1, 260, 9_860, 1])
            try store.cancelOrder(id: order.id)
            precondition(stats().map(\.value) == [1, 260, 12_860, 0])
        }
    }
}
