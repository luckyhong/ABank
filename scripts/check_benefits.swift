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
}
