import Foundation

@main struct WealthChecks {
    @MainActor static func main() throws {
        catalog()
        riskMapping()
        interestMath()
        holdingDays()
        statusAndRedeemable()
        try questionnaire()
        try assessmentStoreRules()
        try assessmentExpiry()
        try assessmentPersistence()
        try legacyLedgerDecodes()
        try purchaseRules()
        try purchaseAmountRules()
        try purchaseIdempotency()
        try accrualAndAssets()
        try redeemBoundary()
        try corruptLedgerKeepsBytes()
        try writeFailureIsAtomic()
        catalogLinks()
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

    // MARK: - 风险测评

    final class TestClock {
        var now: Date
        init(_ text: String) { now = WealthChecks.at(text) }
        func set(_ text: String) { now = WealthChecks.at(text) }
        func set(utc text: String) { now = WealthChecks.utc(text) }
    }

    final class Counter { var count = 0 }

    struct WriteFailure: Error {}

    @MainActor static func withSuite(_ body: @MainActor (UserDefaults) throws -> Void) rethrows {
        let suite = "ABank.WealthChecks." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        try body(defaults)
    }

    @MainActor static func makeRiskStore(_ defaults: UserDefaults, _ clock: TestClock,
                                         center: NotificationCenter = NotificationCenter(),
                                         writer: ((Data) throws -> Void)? = nil) -> RiskAssessmentStore {
        RiskAssessmentStore(defaults: defaults, notificationCenter: center,
                            dates: BankingDateContext(now: { clock.now }), dataWriter: writer)
    }

    @MainActor static func count(_ center: NotificationCenter, _ name: Notification.Name) -> Counter {
        let counter = Counter()
        center.addObserver(forName: name, object: nil, queue: nil) { _ in counter.count += 1 }
        return counter
    }

    @MainActor static func questionnaire() throws {
        let questions = RiskQuestionnaire.questions
        precondition(questions.count == 5 && questions.allSatisfy { $0.options.count == 4 && !$0.title.isEmpty })
        precondition(RiskQuestionnaire.score(answers: [0, 0, 0, 0, 0]) == 5)
        precondition(RiskQuestionnaire.score(answers: [3, 3, 3, 3, 3]) == 20)
        precondition(RiskQuestionnaire.score(answers: [1, 1, 1, 1, 1]) == 10)
        precondition(RiskQuestionnaire.score(answers: [0, 0, 0, 0]) == nil)
        precondition(RiskQuestionnaire.score(answers: [0, 0, 0, 0, 4]) == nil)
        precondition(RiskQuestionnaire.score(answers: [0, 0, 0, 0, -1]) == nil)
        let cases: [(Int, RiskProfile)] = [
            (5, .c1), (8, .c1), (9, .c2), (11, .c2), (12, .c3), (14, .c3), (15, .c4), (17, .c4), (18, .c5), (20, .c5)
        ]
        for (score, profile) in cases {
            precondition(RiskQuestionnaire.profile(forScore: score) == profile, "profile for \(score)")
        }
    }

    @MainActor static func assessmentStoreRules() throws {
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let center = NotificationCenter()
            let counter = count(center, RiskAssessmentStore.didChangeNotification)
            let store = makeRiskStore(defaults, clock, center: center)
            precondition(store.state == .none && store.record == nil)
            let record = try store.submit(answers: [1, 1, 1, 1, 1])
            precondition(record.level == .c2 && store.record == record)
            precondition(store.state == .valid(.c2, expiresOn: "2027-11-05") && counter.count == 1)
            do {
                try store.submit(answers: [1])
                preconditionFailure("expected incompleteAnswers")
            } catch let error as RiskAssessmentError {
                precondition(error == .incompleteAnswers)
            }
            precondition(counter.count == 1, "failure does not notify")
            let reloaded = makeRiskStore(defaults, clock)
            precondition(reloaded.record == record)
        }
    }

    @MainActor static func assessmentExpiry() throws {
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let store = makeRiskStore(defaults, clock)
            let record = try store.submit(answers: [1, 1, 1, 1, 1])
            precondition(RiskAssessmentRules.expiresAt(record, dates: BankingDateContext(now: { clock.now })) == at("2027-11-06 00:00"))
            clock.set("2027-11-05 23:59")
            precondition(store.state == .valid(.c2, expiresOn: "2027-11-05"))
            clock.set("2027-11-06 00:00")
            precondition(store.state == .expired(.c2))
            try store.submit(answers: [3, 3, 3, 3, 3])
            precondition(store.state == .valid(.c5, expiresOn: "2028-11-04"), "retest replaces expired record")
        }
    }

    @MainActor static func assessmentPersistence() throws {
        try withSuite { defaults in
            let original = Data(#"{"answers":"x"}"#.utf8)
            defaults.set(original, forKey: RiskAssessmentStore.storageKey)
            let clock = TestClock("2026-11-06 10:00")
            let store = makeRiskStore(defaults, clock)
            precondition(store.state == .none)
            precondition(defaults.data(forKey: RiskAssessmentStore.storageKey) == original, "bytes untouched on load")
            try store.submit(answers: [0, 0, 0, 0, 0])
            precondition(defaults.data(forKey: RiskAssessmentStore.storageKey) != original, "replaced after successful save")
        }
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let center = NotificationCenter()
            let counter = count(center, RiskAssessmentStore.didChangeNotification)
            var failing = false
            let store = makeRiskStore(defaults, clock, center: center, writer: { data in
                if failing { throw WriteFailure() }
                defaults.set(data, forKey: RiskAssessmentStore.storageKey)
            })
            let record = try store.submit(answers: [1, 1, 1, 1, 1])
            failing = true
            do {
                try store.submit(answers: [3, 3, 3, 3, 3])
                preconditionFailure("expected saveFailed")
            } catch let error as RiskAssessmentError {
                precondition(error == .saveFailed)
            }
            precondition(store.record == record && counter.count == 1, "memory unchanged, no notification")
        }
    }

    // MARK: - 账本集成

    final class RiskBox {
        var state: RiskAssessmentState
        init(_ state: RiskAssessmentState) { self.state = state }
    }

    static let validC2 = RiskAssessmentState.valid(.c2, expiresOn: "2027-11-05")
    static let ledgerKey = "abank.financeLedger.record.v8"

    static func fixture(balance: Double) -> FinanceLedgerRecord {
        let account = LedgerAccount(id: "acct_8472", tailNumber: "8472", currency: "人民币", balance: balance, openingBalance: balance)
        return FinanceLedgerRecord(accounts: [account], transactions: [], loanContracts: [],
                                   assetLiabilityAnnouncement: "演示", dataTimestamp: "2026-11-05 12:00:00")
    }

    @MainActor static func ledgerStore(_ defaults: UserDefaults, _ clock: TestClock, _ risk: RiskBox,
                                       balance: Double = 1499.66, seed: Bool = true,
                                       writer: ((Data) throws -> Void)? = nil) -> FinanceLedgerStore {
        let store = FinanceLedgerStore(defaults: defaults, dates: BankingDateContext(now: { clock.now }),
                                       riskStateProvider: { risk.state }, dataWriter: writer)
        if seed { precondition(store.save(fixture(balance: balance)), "seed") }
        return store
    }

    static func cents(_ value: Double) -> Int64 { TransferMoney.cents(from: value)! }

    @MainActor static func expect(_ expected: WealthError, _ body: () throws -> Void, _ label: String) {
        do {
            try body()
            preconditionFailure("\(label): expected \(expected), got success")
        } catch let error as WealthError {
            precondition(error == expected, "\(label): expected \(expected), got \(error)")
        } catch {
            preconditionFailure("\(label): unexpected \(error)")
        }
    }

    @MainActor static func balanceCents(_ store: FinanceLedgerStore) -> Int64 {
        cents(store.load().accounts[0].balance)
    }

    @MainActor static func legacyLedgerDecodes() throws {
        try withSuite { defaults in
            let store = ledgerStore(defaults, TestClock("2026-11-06 10:00"), RiskBox(validC2))
            var legacy = try JSONSerialization.jsonObject(with: JSONEncoder().encode(fixture(balance: 1499.66))) as! [String: Any]
            legacy.removeValue(forKey: "wealthOrders")
            defaults.set(try JSONSerialization.data(withJSONObject: legacy), forKey: ledgerKey)
            let bytes = defaults.data(forKey: ledgerKey)
            precondition(store.load().wealthOrders.isEmpty && store.wealthOrders().isEmpty)
            precondition(cents(store.totalAssets()) == 149_966)
            precondition(defaults.data(forKey: ledgerKey) == bytes, "reading does not rewrite legacy bytes")
        }
    }

    @MainActor static func purchaseRules() throws {
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let risk = RiskBox(validC2)
            let store = ledgerStore(defaults, clock, risk, balance: 5000)
            let assetsBefore = cents(store.totalAssets())
            let flowBefore = store.mineMonthlyFlow().expense
            let order = try store.submitWealthPurchase(productID: "w.tiantianli2", amountInCents: 50_000, requestID: "a")
            precondition(order.principalInCents == 50_000 && order.createdAt == "2026-11-06 10:00:00")
            precondition(order.accountID == "acct_8472" && order.rateBasisPoints == 240 && order.minHoldDays == 1)
            let transaction = store.transaction(id: order.purchaseTransactionID)!
            precondition(order.purchaseTransactionID == "wealth_buy_" + order.id)
            precondition(transaction.direction == .expense && cents(transaction.amount) == 50_000)
            precondition(!transaction.includeInFlow && transaction.categoryId == "wealth_product" && transaction.iconKey == "wealth")
            precondition(transaction.transactionType == "理财购买" && transaction.channel == "本机模拟")
            precondition(balanceCents(store) == 450_000, "cash reduced")
            precondition(cents(store.totalAssets()) == assetsBefore, "assets unchanged by purchase")
            precondition(store.mineMonthlyFlow().expense == flowBefore, "monthly flow unchanged")
            precondition(store.wealthOrders().count == 1 && store.wealthOrder(id: order.id) == order)
            precondition(store.wealthStatus(of: order) == .holding(redeemable: false, daysUntilRedeemable: 1))

            @MainActor func attempt(_ expected: WealthError, _ product: String, _ label: String) {
                let orders = store.wealthOrders().count, balance = balanceCents(store)
                expect(expected, { try store.submitWealthPurchase(productID: product, amountInCents: 100, requestID: UUID().uuidString) }, label)
                precondition(store.wealthOrders().count == orders && balanceCents(store) == balance, "\(label) changed state")
            }
            attempt(.riskLevelTooLow, "w.chengzhang", "R3 with C2")
            risk.state = .none
            attempt(.assessmentRequired, "w.tiantianli2", "none")
            risk.state = .expired(.c3)
            attempt(.assessmentExpired, "w.tiantianli2", "expired")
            risk.state = validC2
            attempt(.productNotFound, "w.none", "unknown product")
            risk.state = .valid(.c3, expiresOn: "2027-11-05")
            try store.submitWealthPurchase(productID: "w.chengzhang", amountInCents: 100_000, requestID: "b")
            precondition(store.wealthOrders().count == 2 && store.wealthOrders().first?.requestID == "b", "newest first")
        }
    }

    @MainActor static func purchaseAmountRules() throws {
        @MainActor func buy(_ store: FinanceLedgerStore, _ product: String, _ cents: Int64) throws {
            try store.submitWealthPurchase(productID: product, amountInCents: cents, requestID: UUID().uuidString)
        }
        try withSuite { defaults in
            let store = ledgerStore(defaults, TestClock("2026-11-06 10:00"), RiskBox(validC2))
            expect(.belowMinimum, { try buy(store, "w.tiantianli2", 99) }, "99 cents")
            expect(.invalidAmount, { try buy(store, "w.tiantianli2", 0) }, "zero")
            expect(.invalidAmount, { try buy(store, "w.tiantianli2", -1) }, "negative")
            try buy(store, "w.tiantianli2", 100)
            expect(.belowMinimum, { try buy(store, "w.lingdong90", 99_999) }, "below 1000 yuan")
            precondition(store.wealthOrders().count == 1)
        }
        try withSuite { defaults in
            let store = ledgerStore(defaults, TestClock("2026-11-06 10:00"), RiskBox(validC2))
            try buy(store, "w.tiantianli2", 149_966)
            precondition(balanceCents(store) == 0, "exact balance buys")
            expect(.insufficientBalance, { try buy(store, "w.tiantianli2", 100) }, "empty account")
        }
        try withSuite { defaults in
            let store = ledgerStore(defaults, TestClock("2026-11-06 10:00"), RiskBox(validC2))
            expect(.insufficientBalance, { try buy(store, "w.tiantianli2", 149_967) }, "one cent short")
            precondition(balanceCents(store) == 149_966 && store.wealthOrders().isEmpty)
        }
        try withSuite { defaults in
            let store = ledgerStore(defaults, TestClock("2026-11-06 10:00"), RiskBox(validC2), balance: 2_000_000)
            expect(.aboveMaximum, { try buy(store, "w.tiantianli2", 100_000_001) }, "above cap")
            try buy(store, "w.tiantianli2", 100_000_000)
            precondition(store.wealthOrders().count == 1 && balanceCents(store) == 100_000_000)
        }
    }

    @MainActor static func purchaseIdempotency() throws {
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let risk = RiskBox(validC2)
            let store = ledgerStore(defaults, clock, risk)
            let first = try store.submitWealthPurchase(productID: "w.tiantianli2", amountInCents: 10_000, requestID: "dup")
            let second = try store.submitWealthPurchase(productID: "w.tiantianli2", amountInCents: 10_000, requestID: "dup")
            precondition(first == second && store.wealthOrders().count == 1)
            precondition(store.load().transactions.filter { $0.id.hasPrefix("wealth_buy_") }.count == 1)
            precondition(balanceCents(store) == 139_966)
            let restarted = ledgerStore(defaults, clock, risk, seed: false)
            let third = try restarted.submitWealthPurchase(productID: "w.tiantianli2", amountInCents: 10_000, requestID: "dup")
            precondition(third == first && restarted.wealthOrders().count == 1 && balanceCents(restarted) == 139_966)
            expect(.invalidRequest, { try store.submitWealthPurchase(productID: "w.tiantianli2", amountInCents: 100, requestID: "") }, "empty id")
            expect(.invalidRequest, { try store.submitWealthPurchase(productID: "w.tiantianli2", amountInCents: 100, requestID: String(repeating: "x", count: 101)) }, "long id")
        }
    }

    @MainActor static func accrualAndAssets() throws {
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let store = ledgerStore(defaults, clock, RiskBox(validC2), balance: 5000)
            precondition(!store.assetLiabilityPageData().assetCategories.contains { $0.id == FinanceLedgerRecord.wealthCategoryId })
            let order = try store.submitWealthPurchase(productID: "w.tiantianli2", amountInCents: 100_000, requestID: "a")
            clock.set("2026-12-06 10:00")
            precondition(store.accruedInterestInCents(of: order) == 197 && store.holdingValueInCents(of: order) == 100_197)
            precondition(store.totalHoldingValueInCents() == 100_197)
            precondition(cents(store.totalAssets()) == 500_197, "cash 4000 + holding 1001.97")
            let page = store.assetLiabilityPageData()
            let wealth = page.assetCategories.first { $0.id == FinanceLedgerRecord.wealthCategoryId }!
            precondition(wealth.title == "理财" && cents(wealth.totalAmount ?? 0) == 100_197)
            precondition(wealth.items.count == 1 && wealth.items[0].id == order.id && cents(wealth.items[0].amount) == 100_197)
            precondition(wealth.items[0].subtitle == "本金 1000.00 元 · 收益 1.97 元" && !wealth.items[0].showsMenu)
            precondition(cents(page.totalAssets) == cents(store.totalAssets()))
            let sum = page.assetCategories.reduce(0) { $0 + cents($1.totalAmount ?? 0) }
            precondition(sum == cents(page.totalAssets), "categories add up to total assets")
            precondition(cents(store.mineAssetLiability().assets) == 500_197)
        }
    }

    @MainActor static func redeemBoundary() throws {
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 23:59")
            let store = ledgerStore(defaults, clock, RiskBox(validC2), balance: 5000)
            let order = try store.submitWealthPurchase(productID: "w.tiantianli2", amountInCents: 100_000, requestID: "a")
            expect(.notRedeemable, { try store.redeemWealthOrder(orderID: order.id) }, "same day")
            clock.set(utc: "2026-11-06T15:59:59Z")
            expect(.notRedeemable, { try store.redeemWealthOrder(orderID: order.id) }, "one second before Shanghai midnight")
            clock.set(utc: "2026-11-06T16:00:00Z")
            let redeemed = try store.redeemWealthOrder(orderID: order.id)
            let expected = 100_000 + WealthRules.accruedInterestInCents(principal: 100_000, rateBasisPoints: 240, days: 1)
            precondition(redeemed.redeemedAmountInCents == expected && redeemed.redeemedAt == "2026-11-07 00:00:00")
            let transaction = store.transaction(id: redeemed.redeemTransactionID!)!
            precondition(transaction.id == "wealth_redeem_" + order.id && transaction.direction == .income)
            precondition(cents(transaction.amount) == expected && !transaction.includeInFlow && transaction.categoryId == "wealth_product")
            precondition(transaction.transactionType == "理财赎回")
            precondition(store.wealthStatus(of: store.wealthOrder(id: order.id)!) == .redeemed)
            precondition(cents(store.totalAssets()) == balanceCents(store), "assets are all cash after redeeming")
            precondition(balanceCents(store) == 400_000 + expected)
            expect(.alreadyRedeemed, { try store.redeemWealthOrder(orderID: order.id) }, "twice")
            expect(.orderNotFound, { try store.redeemWealthOrder(orderID: "none") }, "unknown")
            precondition(store.totalHoldingValueInCents() == 0)
        }
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let store = ledgerStore(defaults, clock, RiskBox(validC2), balance: 5000)
            let order = try store.submitWealthPurchase(productID: "w.lingdong180", amountInCents: 100_000, requestID: "a")
            clock.set("2027-05-04 10:00")
            expect(.notRedeemable, { try store.redeemWealthOrder(orderID: order.id) }, "day 179")
            clock.set("2027-05-05 10:00")
            try store.redeemWealthOrder(orderID: order.id)
        }
    }

    @MainActor static func corruptLedgerKeepsBytes() throws {
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let store = ledgerStore(defaults, clock, RiskBox(validC2))
            let order = try store.submitWealthPurchase(productID: "w.tiantianli2", amountInCents: 100, requestID: "a")
            let garbage = Data(#"{"accounts":"x"}"#.utf8)
            defaults.set(garbage, forKey: ledgerKey)
            clock.set("2026-11-08 10:00")
            expect(.corruptLedger, { try store.submitWealthPurchase(productID: "w.tiantianli2", amountInCents: 100, requestID: "b") }, "purchase")
            expect(.corruptLedger, { try store.redeemWealthOrder(orderID: order.id) }, "redeem")
            expect(.corruptLedger, { try store.validateWealthPurchase(productID: "w.tiantianli2", amountInCents: 100) }, "validate")
            precondition(defaults.data(forKey: ledgerKey) == garbage, "bytes untouched")
        }
    }

    @MainActor static func writeFailureIsAtomic() throws {
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            var failing = false
            let store = ledgerStore(defaults, clock, RiskBox(validC2), writer: { data in
                if failing { throw WriteFailure() }
                defaults.set(data, forKey: ledgerKey)
            })
            let order = try store.submitWealthPurchase(productID: "w.tiantianli2", amountInCents: 50_000, requestID: "a")
            clock.set("2026-11-08 10:00")
            let counter = count(NotificationCenter.default, .financeLedgerDidChange)
            let before = store.load()
            failing = true
            expect(.persistence, { try store.submitWealthPurchase(productID: "w.tiantianli2", amountInCents: 100, requestID: "b") }, "purchase")
            expect(.persistence, { try store.redeemWealthOrder(orderID: order.id) }, "redeem")
            precondition(store.load() == before, "orders, transactions and balances unchanged")
            precondition(counter.count == 0, "no notification on failed writes")
            failing = false
            try store.redeemWealthOrder(orderID: order.id)
            precondition(counter.count == 1 && store.wealthOrders().first?.redeemedAt != nil)
        }
    }

    @MainActor static func catalogLinks() {
        for id in ["w.tiantianli2", "w.piaoxi", "w.lingdong180"] {
            precondition(WealthProductCatalog.product(id: id) != nil, "wealth tab product \(id)")
        }
        precondition(AppRoute.wealthProductDetail(productID: "w.piaoxi") != AppRoute.wealthProductDetail(productID: "w.tiantianli2"))
        precondition(AppRoute.wealthOrderDetail(orderID: "a", justPurchased: true) != AppRoute.wealthOrderDetail(orderID: "a", justPurchased: false))
    }
}
