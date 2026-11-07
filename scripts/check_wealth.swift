import Foundation

@main struct WealthChecks {
    @MainActor static func main() throws {
        catalog()
        riskMapping()
        interestMath()
        holdingDays()
        statusAndRedeemable()
        print("Wealth checks passed")
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

    static func order(created: String, minHold: Int = 1, principal: Int64 = 100_000, bps: Int = 240,
                      redeemed: Bool = false) -> WealthOrder {
        WealthOrder(id: "o1", requestID: "r1", productID: "w.tiantianli2", productName: "测试产品", accountID: "acct_8472",
                    principalInCents: principal, rateBasisPoints: bps, minHoldDays: minHold, createdAt: created,
                    purchaseTransactionID: "wealth_buy_o1", redeemedAt: redeemed ? "2026-11-20 10:00:00" : nil,
                    redeemedAmountInCents: redeemed ? principal : nil, redeemTransactionID: redeemed ? "wealth_redeem_o1" : nil)
    }

    // MARK: - 目录

    static func catalog() {
        let products = WealthProductCatalog.products
        precondition(products.count == 8, "products")
        precondition(Set(products.map(\.id)).count == 8, "ids unique")
        precondition(products.allSatisfy { $0.minPurchaseInCents > 0 && !$0.summary.isEmpty })
        let daily = WealthProductCatalog.product(id: "w.tiantianli2")!
        precondition(daily.category == .daily && daily.risk == .r2 && daily.rateBasisPoints == 240)
        precondition(daily.minHoldDays == 1 && daily.minPurchaseInCents == 100 && daily.rateText == "2.40%")
        let growth = WealthProductCatalog.product(id: "w.chengzhang")!
        precondition(growth.category == .performance && growth.risk == .r3 && growth.rateBasisPoints == 360)
        precondition(growth.minHoldDays == 180 && growth.minPurchaseInCents == 100_000)
        precondition(WealthProductCatalog.product(id: "w.shishifu")!.risk == .r1 && WealthProductCatalog.product(id: "w.shishifu")!.rateBasisPoints == 90)
        precondition(WealthProductCatalog.product(id: "w.lingdong90")!.minPurchaseInCents == 100_000)
        precondition(WealthProductCatalog.product(id: "none") == nil)

        func ids(_ category: WealthCategory?, _ risk: ProductRiskLevel?, _ period: HoldingPeriodFilter) -> [String] {
            WealthProductCatalog.filtered(category: category, risk: risk, period: period).map(\.id)
        }
        precondition(ids(.daily, nil, .any) == ["w.shishifu", "w.tiantianli2"])
        precondition(ids(nil, .r3, .any) == ["w.chengzhang"])
        precondition(ids(nil, nil, .any).count == 8)
        precondition(Set(ids(nil, nil, .within7)) == ["w.shishifu", "w.tiantianli2", "w.piaoxi", "w.wenjian7"])
        precondition(Set(ids(nil, nil, .within30)).contains("w.wenjian30") && !Set(ids(nil, nil, .within30)).contains("w.lingdong90"))
        precondition(Set(ids(nil, nil, .over30)) == ["w.lingdong90", "w.lingdong180", "w.chengzhang"])
        precondition(ids(.daily, .r3, .any).isEmpty)
        precondition(WealthCategory.allCases.map(\.title) == ["日日悦享", "低波稳健", "业绩优选"])
        precondition(HoldingPeriodFilter.allCases.map(\.title) == ["不限", "7天内", "30天内", "30天以上"])
    }

    static func riskMapping() {
        precondition(ProductRiskLevel.r2.requiredProfile == .c2 && ProductRiskLevel.r1.requiredProfile == .c1 && ProductRiskLevel.r3.requiredProfile == .c3)
        let r3 = WealthProductCatalog.product(id: "w.chengzhang")!
        let r1 = WealthProductCatalog.product(id: "w.shishifu")!
        precondition(!WealthRules.canBuy(r3, with: .c2) && WealthRules.canBuy(r3, with: .c3))
        precondition(WealthRules.canBuy(r1, with: .c5) && WealthRules.canBuy(r1, with: .c1))
        precondition(RiskProfile.c1 < .c5 && ProductRiskLevel.r1 < .r3)
        precondition(RiskProfile.c2.title == "稳健型" && RiskProfile.c5.shortTitle == "C5")
        precondition(ProductRiskLevel.r2.title == "中低风险" && ProductRiskLevel.r2.shortTitle == "R2")
    }

    static func interestMath() {
        func interest(_ principal: Int64, _ bps: Int, _ days: Int) -> Int64 {
            WealthRules.accruedInterestInCents(principal: principal, rateBasisPoints: bps, days: days)
        }
        precondition(interest(100_000, 240, 30) == 197)
        precondition(interest(100_000, 240, 0) == 0)
        precondition(interest(1, 240, 30) == 0)
        precondition(interest(10_000_000, 240, 1) == 657)
        let maxValue = Decimal(100_000_000) * 360 * 3650 / (10_000 * 365)
        precondition(interest(100_000_000, 360, 3650) == NSDecimalNumber(decimal: maxValue).int64Value, "max value")
        precondition(WealthRules.maxPurchaseInCents == 100_000_000 && WealthRules.maxAccrualDays == 3650)
    }

    static func holdingDays() {
        func days(_ created: String, _ dates: BankingDateContext) -> Int {
            WealthRules.holdingDays(since: created, now: dates.now, dates: dates)
        }
        let created = "2026-11-06 23:59:30"
        precondition(days(created, clock("2026-11-06 23:59")) == 0)
        precondition(days(created, clock("2026-11-07 00:00")) == 1)
        precondition(days(created, clock(utc: "2026-11-06T15:59:00Z")) == 0)
        precondition(days(created, clock(utc: "2026-11-06T16:00:00Z")) == 1)
        precondition(days("2026-10-31 10:00:00", clock("2026-11-02 08:00")) == 2, "cross month")
        precondition(days("2025-12-31 10:00:00", clock("2026-01-02 08:00")) == 2, "cross year")
        precondition(days("2000-01-01 10:00:00", clock("2026-11-02 08:00")) == 3650, "capped")
        precondition(days("2026-11-06 10:00:00", clock("2026-11-01 08:00")) == 0, "never negative")
    }

    static func statusAndRedeemable() {
        let one = order(created: "2026-11-06 10:00:00", minHold: 1)
        func status(_ order: WealthOrder, _ now: String) -> WealthOrderStatus {
            let dates = clock(now)
            return WealthRules.status(of: order, now: dates.now, dates: dates)
        }
        precondition(status(one, "2026-11-06 12:00") == .holding(redeemable: false, daysUntilRedeemable: 1))
        precondition(status(one, "2026-11-07 00:00") == .holding(redeemable: true, daysUntilRedeemable: 0))
        precondition(WealthRules.redeemableDay(of: one, dates: shanghai) == "2026-11-07")
        let long = order(created: "2026-11-06 10:00:00", minHold: 180)
        precondition(WealthRules.redeemableDay(of: long, dates: shanghai) == "2027-05-05")
        precondition(status(long, "2027-05-04 23:59") == .holding(redeemable: false, daysUntilRedeemable: 1))
        precondition(status(long, "2027-05-05 00:00") == .holding(redeemable: true, daysUntilRedeemable: 0))

        let redeemed = order(created: "2026-11-06 10:00:00", redeemed: true)
        let later = clock("2026-12-06 10:00")
        precondition(WealthRules.status(of: redeemed, now: later.now, dates: later) == .redeemed)
        precondition(WealthRules.holdingValueInCents(of: redeemed, now: later.now, dates: later) == 0)
        let value = WealthRules.holdingValueInCents(of: one, now: later.now, dates: later)
        precondition(value == 100_000 + WealthRules.accruedInterestInCents(principal: 100_000, rateBasisPoints: 240, days: 30))
    }
}
