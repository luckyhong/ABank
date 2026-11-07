import Foundation

@main struct PaymentChecks {
    @MainActor static func main() throws {
        catalog()
        phoneRules()
        couponRules()
        billAmounts()
        billPeriods()
        try legacyLedgerDecodes()
        categories()
        try releaseCoupon()
        try rechargeRules()
        try rechargeCoupons()
        try rechargeAmountRules()
        try rechargeIdempotency()
        try couponCompensation()
        try utilityRules()
        try corruptLedgerKeepsBytes()
        try writeFailureIsAtomic()
        orderListMerge()
        try expectedAmountGuards()
        print("Payment checks passed")
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

    static func account(_ id: String) -> BillAccount {
        guard let account = PaymentCatalog.billAccount(id: id) else { preconditionFailure("missing \(id)") }
        return account
    }

    static func order(target: String, period: String?, kind: PaymentKind = .water,
                      created: String = "2026-11-06 10:00:00") -> PaymentOrder {
        PaymentOrder(id: "p1", orderNo: "M820261106", requestID: "r1", kind: kind, targetID: target,
                     targetTitle: "测试", period: period, faceInCents: 5_000, couponID: nil,
                     couponDiscountInCents: 0, paidInCents: 5_000, accountID: "acct_8472",
                     createdAt: created, transactionID: "payment_p1")
    }

    // MARK: - 目录

    static func catalog() {
        let accounts = PaymentCatalog.billAccounts
        precondition(accounts.count == 6, "bill accounts")
        precondition(Set(accounts.map(\.id)).count == 6, "bill ids unique")
        precondition(PaymentCatalog.billAccounts(of: .water).count == 2)
        precondition(PaymentCatalog.billAccounts(of: .electric).count == 2)
        precondition(PaymentCatalog.billAccounts(of: .gas).count == 2)
        precondition(PaymentCatalog.billAccounts(of: .mobile).isEmpty)
        precondition(accounts.allSatisfy { !$0.accountNo.isEmpty && !$0.address.isEmpty && !$0.provider.isEmpty })
        precondition(PaymentCatalog.denominationsInCents == [1000, 2000, 3000, 5000, 10000, 20000])
        precondition(PaymentKind.mobile.categoryId == "mobile_recharge")
        precondition(PaymentKind.gas.categoryId == "life_payment")
        precondition(PaymentKind.water.title == "水费" && PaymentKind.mobile.title == "手机充值")
        precondition(PaymentKind.electric.title == "电费" && PaymentKind.gas.title == "燃气费")
        precondition(!PaymentKind.mobile.isUtility && PaymentKind.water.isUtility)
        precondition(PaymentKind.mobile.transactionType == "手机充值" && PaymentKind.electric.transactionType == "生活缴费")
        precondition(PaymentCatalog.billAccount(id: "nope") == nil)
    }

    // MARK: - 手机号

    static func phoneRules() {
        precondition(PaymentRules.normalizedPhone("152 8888-8684") == "15288888684")
        for valid in ["15288888684", "13012345678", "19912345678"] {
            precondition(PaymentRules.isValidPhone(valid), "valid \(valid)")
        }
        for invalid in ["1528888868", "152888886845", "25288888684", "12288888684", "1528888868a", "", "10288888684"] {
            precondition(!PaymentRules.isValidPhone(invalid), "invalid \(invalid)")
        }
        precondition(PaymentRules.maskedPhone("15288888684") == "152****8684")
        precondition(PaymentRules.phoneOperator(of: "15288888684") == .mobile)
        precondition(PaymentRules.phoneOperator(of: "18688888684") == .unicom)
        precondition(PaymentRules.phoneOperator(of: "18988888684") == .telecom)
        precondition(PaymentRules.phoneOperator(of: "17088888684") == .other)
        precondition(PaymentRules.phoneOperator(of: "19988888684") == .telecom)
        precondition(PhoneOperator.mobile.title == "中国移动" && PhoneOperator.other.title == "其他运营商")
        precondition(PaymentRules.targetTitle(phone: "15288888684") == "手机号 152****8684")
        precondition(PaymentRules.targetTitle(for: account("bill.water.home")) == "水费 · 家庭住宅")
    }

    // MARK: - 话费券

    static func couponRules() {
        precondition(PaymentRules.phoneCouponFaceInCents(templateID: "phone10") == 1000)
        precondition(PaymentRules.phoneCouponFaceInCents(templateID: "phone5") == 500)
        precondition(PaymentRules.phoneCouponFaceInCents(templateID: "coffee10") == nil)
        precondition(PaymentRules.usableCouponFaceInCents(templateID: "phone10", faceInCents: 1000) == nil, "equal")
        precondition(PaymentRules.usableCouponFaceInCents(templateID: "phone10", faceInCents: 2000) == 1000)
        precondition(PaymentRules.usableCouponFaceInCents(templateID: "phone5", faceInCents: 1000) == 500)
        precondition(PaymentRules.usableCouponFaceInCents(templateID: "phone5", faceInCents: 500) == nil)
        precondition(PaymentRules.usableCouponFaceInCents(templateID: "coffee10", faceInCents: 5000) == nil)
    }

    // MARK: - 账单金额

    static func billAmounts() {
        let ranges: [PaymentKind: Range<Int64>] = [.water: 3_500..<9_500, .electric: 8_000..<26_000, .gas: 4_000..<18_000]
        var periods: [String] = []
        for year in [2026, 2027] {
            for month in 1...12 { periods.append(String(format: "%04d-%02d", year, month)) }
        }
        var largest: Int64 = 0
        for account in PaymentCatalog.billAccounts {
            for period in periods {
                let amount = PaymentRules.billAmountInCents(for: account, period: period)
                precondition(ranges[account.kind]!.contains(amount), "\(account.id) \(period) \(amount)")
                precondition(amount == PaymentRules.billAmountInCents(for: account, period: period), "stable")
                largest = max(largest, amount)
            }
        }
        precondition(largest < 26_000)
        let electric = account("bill.electric.home")
        let distinct = Set(periods.map { PaymentRules.billAmountInCents(for: electric, period: $0) })
        precondition(distinct.count >= 2, "periods differ")
    }

    // MARK: - 账期

    static func billPeriods() {
        precondition(PaymentRules.currentPeriod(now: utc("2026-11-30T15:59:00Z"), dates: shanghai) == "2026-11")
        precondition(PaymentRules.currentPeriod(now: utc("2026-11-30T16:00:00Z"), dates: shanghai) == "2026-12")
        precondition(PaymentRules.dueDate(period: "2026-11", dates: shanghai) == "2026-11-30")
        precondition(PaymentRules.dueDate(period: "2028-02", dates: shanghai) == "2028-02-29")
        precondition(PaymentRules.dueDate(period: "2026-02", dates: shanghai) == "2026-02-28")

        let water = account("bill.water.home")
        let dates = clock("2026-11-06 10:00")
        let paid = [order(target: water.id, period: "2026-11")]
        let november = PaymentRules.bill(for: water, orders: paid, now: dates.now, dates: dates)
        precondition(november.isPaid && november.period == "2026-11" && november.dueDate == "2026-11-30")
        precondition(november.amountInCents == PaymentRules.billAmountInCents(for: water, period: "2026-11"))
        let december = PaymentRules.bill(for: water, orders: paid, now: at("2026-12-01 00:00"), dates: dates)
        precondition(!december.isPaid && december.period == "2026-12", "next period unpaid")
        let other = PaymentRules.bill(for: account("bill.water.parents"), orders: paid, now: dates.now, dates: dates)
        precondition(!other.isPaid, "other account unaffected")
        let otherPeriod = [order(target: water.id, period: "2026-10")]
        precondition(!PaymentRules.bill(for: water, orders: otherPeriod, now: dates.now, dates: dates).isPaid)

        let created = at("2026-11-06 10:00")
        let number = PaymentRules.orderNo(id: "abc", createdAt: created, dates: shanghai)
        precondition(number.hasPrefix("M820261106") && number.count == 18, number)
        precondition(number == PaymentRules.orderNo(id: "abc", createdAt: created, dates: shanghai), "stable")
        precondition(number != PaymentRules.orderNo(id: "abd", createdAt: created, dates: shanghai))
        precondition(PaymentRules.createdDate(of: order(target: "x", period: nil), dates: shanghai) == created)
        precondition(PaymentRules.createdDate(of: order(target: "x", period: nil, created: "bad"), dates: shanghai) == nil)
    }

    // MARK: - 夹具

    final class TestClock {
        var now: Date
        init(_ text: String) { now = PaymentChecks.at(text) }
        func set(_ text: String) { now = PaymentChecks.at(text) }
        func set(utc text: String) { now = PaymentChecks.utc(text) }
    }

    final class Counter { var count = 0 }

    struct WriteFailure: Error {}

    static let ledgerKey = "abank.financeLedger.record.v8"

    @MainActor static func withSuite(_ body: @MainActor (UserDefaults) throws -> Void) rethrows {
        let suite = "ABank.PaymentChecks." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        try body(defaults)
    }

    @MainActor static func count(_ center: NotificationCenter, _ name: Notification.Name) -> Counter {
        let counter = Counter()
        center.addObserver(forName: name, object: nil, queue: nil) { _ in counter.count += 1 }
        return counter
    }

    static func fixture(balance: Double) -> FinanceLedgerRecord {
        let account = LedgerAccount(id: "acct_8472", tailNumber: "8472", currency: "人民币", balance: balance, openingBalance: balance)
        return FinanceLedgerRecord(accounts: [account], transactions: [], loanContracts: [],
                                   assetLiabilityAnnouncement: "演示", dataTimestamp: "2026-11-05 12:00:00")
    }

    @MainActor static func makeBenefits(_ defaults: UserDefaults, _ clock: TestClock,
                                        center: NotificationCenter = NotificationCenter(),
                                        writer: ((Data) throws -> Void)? = nil) -> BenefitsStore {
        BenefitsStore(defaults: defaults, notificationCenter: center,
                      dates: BankingDateContext(now: { clock.now }), dataWriter: writer)
    }

    // MARK: - 账本数据层

    @MainActor static func legacyLedgerDecodes() throws {
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let store = FinanceLedgerStore(defaults: defaults, dates: BankingDateContext(now: { clock.now }))
            precondition(store.save(fixture(balance: 1499.66)), "seed")
            var legacy = try JSONSerialization.jsonObject(with: JSONEncoder().encode(fixture(balance: 1499.66))) as! [String: Any]
            legacy.removeValue(forKey: "paymentOrders")
            defaults.set(try JSONSerialization.data(withJSONObject: legacy), forKey: ledgerKey)
            let bytes = defaults.data(forKey: ledgerKey)
            precondition(store.load().paymentOrders.isEmpty, "legacy decodes to empty")
            precondition(defaults.data(forKey: ledgerKey) == bytes, "reading does not rewrite legacy bytes")
        }
        var record = fixture(balance: 100)
        record.paymentOrders = [order(target: "bill.water.home", period: "2026-11")]
        let decoded = try JSONDecoder().decode(FinanceLedgerRecord.self, from: JSONEncoder().encode(record))
        precondition(decoded == record && decoded.paymentOrders.count == 1, "round trip")
    }

    static func categories() {
        precondition(IncomeExpenseFilterCatalog.title(for: "mobile_recharge") == "手机充值")
        precondition(IncomeExpenseFilterCatalog.title(for: "life_payment") == "生活缴费")
        for id in ["mobile_recharge", "life_payment"] {
            precondition(IncomeExpenseFilterCatalog.expenseCategoryIds.contains(id), "expense \(id)")
            precondition(IncomeExpenseFilterCatalog.allCategoryIds.contains(id), "all \(id)")
            precondition(IncomeExpenseFilterCatalog.selectableOptions(for: .expense).contains { $0.id == id })
            precondition(!IncomeExpenseFilterCatalog.selectableOptions(for: .income).contains { $0.id == id })
        }
    }

    @MainActor static func releaseCoupon() throws {
        try withSuite { defaults in
            let center = NotificationCenter()
            let changes = count(center, BenefitsStore.didChangeNotification)
            let store = makeBenefits(defaults, TestClock("2026-11-06 10:00"), center: center)
            let couponID = try store.redeem(goodsID: "g.phone5").couponID
            precondition(store.coupon(id: couponID).map(store.status) == .unused)
            try store.useCoupon(id: couponID)
            precondition(store.coupon(id: couponID).map(store.status) == .used)
            let before = changes.count
            try store.releaseCoupon(id: couponID)
            precondition(store.coupon(id: couponID).map(store.status) == .unused, "released")
            precondition(changes.count == before + 1, "one notification")
            do { try store.releaseCoupon(id: couponID); preconditionFailure("unused coupon released") }
            catch let error as BenefitsError { precondition(error == .notUsable) }
            do { try store.releaseCoupon(id: "nope"); preconditionFailure("unknown coupon released") }
            catch let error as BenefitsError { precondition(error == .unknownItem) }
        }
        try withSuite { defaults in
            let store = makeBenefits(defaults, TestClock("2026-11-06 10:00"))
            let order = try store.redeem(goodsID: "g.phone5")
            try store.cancelOrder(id: order.id)
            do { try store.releaseCoupon(id: order.couponID); preconditionFailure("voided coupon released") }
            catch let error as BenefitsError { precondition(error == .notUsable) }
        }
        try withSuite { defaults in
            let failing = Counter()
            let store = makeBenefits(defaults, TestClock("2026-11-06 10:00"), writer: { data in
                if failing.count > 0 { throw WriteFailure() }
                defaults.set(data, forKey: BenefitsStore.storageKey)
            })
            let couponID = try store.redeem(goodsID: "g.phone5").couponID
            try store.useCoupon(id: couponID)
            failing.count = 1
            do { try store.releaseCoupon(id: couponID); preconditionFailure("write failure ignored") }
            catch let error as BenefitsError { precondition(error == .saveFailed) }
            precondition(store.coupon(id: couponID).map(store.status) == .used, "state unchanged on failure")
        }
    }

    // MARK: - 提交

    @MainActor static func ledgerStore(_ defaults: UserDefaults, _ clock: TestClock, _ benefits: BenefitsStore,
                                       balance: Double = 1499.66,
                                       writer: ((Data) throws -> Void)? = nil) -> FinanceLedgerStore {
        let store = FinanceLedgerStore(defaults: defaults, dates: BankingDateContext(now: { clock.now }),
                                       benefitsProvider: { benefits }, dataWriter: writer)
        precondition(store.save(fixture(balance: balance)), "seed")
        return store
    }

    static func cents(_ value: Double) -> Int64 { TransferMoney.cents(from: value)! }

    @MainActor static func balanceCents(_ store: FinanceLedgerStore) -> Int64 {
        cents(store.load().accounts[0].balance)
    }

    @MainActor static func expect(_ expected: PaymentError, _ body: () throws -> Void, _ label: String) {
        do {
            try body()
            preconditionFailure("\(label): expected \(expected), got success")
        } catch let error as PaymentError {
            precondition(error == expected, "\(label): expected \(expected), got \(error)")
        } catch {
            preconditionFailure("\(label): unexpected \(error)")
        }
    }

    @MainActor static func status(_ benefits: BenefitsStore, _ couponID: String) -> CouponStatus {
        benefits.status(of: benefits.coupon(id: couponID)!)
    }

    static let phone = "15288888684"

    @MainActor static func rechargeRules() throws {
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let benefits = makeBenefits(defaults, clock)
            let store = ledgerStore(defaults, clock, benefits)
            let assetsBefore = cents(store.totalAssets())
            let flowBefore = store.mineMonthlyFlow().expense
            let order = try store.submitMobileRecharge(phone: "152 8888 8684", faceInCents: 2000, couponID: nil, requestID: "a")
            precondition(order.kind == .mobile && order.paidInCents == 2000 && order.faceInCents == 2000)
            precondition(order.couponID == nil && order.couponDiscountInCents == 0 && order.period == nil)
            precondition(order.targetID == phone && order.targetTitle == "手机号 152****8684")
            precondition(order.createdAt == "2026-11-06 10:00:00" && order.accountID == "acct_8472")
            precondition(order.orderNo.hasPrefix("M820261106") && order.requestID == "a")
            let transaction = store.transaction(id: order.transactionID)!
            precondition(order.transactionID == "payment_" + order.id)
            precondition(transaction.direction == .expense && cents(transaction.amount) == 2000)
            precondition(transaction.includeInFlow && transaction.categoryId == "mobile_recharge")
            precondition(transaction.title == "手机充值-152****8684" && transaction.transactionType == "手机充值")
            precondition(transaction.channel == "本机模拟" && transaction.counterpartyName == "模拟通信服务商")
            precondition(balanceCents(store) == 147_966, "cash reduced")
            precondition(cents(store.totalAssets()) == assetsBefore - 2000, "assets reduced by payment")
            precondition(cents(store.mineMonthlyFlow().expense) == cents(flowBefore) + 2000, "monthly flow includes payment")
            precondition(store.paymentOrders() == [order] && store.paymentOrder(id: order.id) == order)
            precondition(store.paymentOrder(id: "none") == nil)

            @MainActor func attempt(_ expected: PaymentError, _ number: String, _ face: Int64, _ label: String) {
                let orders = store.paymentOrders().count, balance = balanceCents(store)
                expect(expected, { _ = try store.submitMobileRecharge(phone: number, faceInCents: face, couponID: nil, requestID: UUID().uuidString) }, label)
                precondition(store.paymentOrders().count == orders && balanceCents(store) == balance, "\(label) changed state")
            }
            attempt(.invalidPhone, "12345", 2000, "short phone")
            attempt(.invalidPhone, "25288888684", 2000, "bad prefix")
            attempt(.invalidDenomination, phone, 1500, "off-menu face")
            attempt(.invalidDenomination, phone, 0, "zero face")
            attempt(.invalidDenomination, phone, -1000, "negative face")
            try store.submitMobileRecharge(phone: phone, faceInCents: 1000, couponID: nil, requestID: "b")
            precondition(store.paymentOrders().count == 2 && store.paymentOrders().first?.requestID == "b", "newest first")
        }
    }

    @MainActor static func rechargeCoupons() throws {
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let benefits = makeBenefits(defaults, clock)
            let store = ledgerStore(defaults, clock, benefits)
            let c5 = try benefits.redeem(goodsID: "g.phone5").couponID
            let c10 = try benefits.redeem(goodsID: "g.phone10").couponID
            let coffee = try benefits.claim(benefitID: "coffeeMonthly").couponID!
            precondition(Set(store.usableCoupons(forFaceInCents: 1000).map(\.id)) == [c5], "only phone5 under 10 yuan")
            precondition(Set(store.usableCoupons(forFaceInCents: 2000).map(\.id)) == [c5, c10])
            precondition(store.usableCoupons(forFaceInCents: 500).isEmpty)

            expect(.couponUnavailable, { _ = try store.submitMobileRecharge(phone: phone, faceInCents: 1000, couponID: c10, requestID: "a") }, "equal face")
            precondition(status(benefits, c10) == .unused && store.paymentOrders().isEmpty, "rejected coupon stays unused")
            expect(.couponUnavailable, { _ = try store.submitMobileRecharge(phone: phone, faceInCents: 5000, couponID: coffee, requestID: "b") }, "non-phone coupon")
            expect(.couponUnavailable, { _ = try store.submitMobileRecharge(phone: phone, faceInCents: 5000, couponID: "nope", requestID: "c") }, "unknown coupon")
            precondition(status(benefits, coffee) == .unused)

            let order = try store.submitMobileRecharge(phone: phone, faceInCents: 1000, couponID: c5, requestID: "d")
            precondition(order.paidInCents == 500 && order.couponDiscountInCents == 500 && order.couponID == c5 && order.faceInCents == 1000)
            precondition(status(benefits, c5) == .used && balanceCents(store) == 149_466)
            precondition(cents(store.transaction(id: order.transactionID)!.amount) == 500, "transaction is paid amount")
            expect(.couponUnavailable, { _ = try store.submitMobileRecharge(phone: phone, faceInCents: 2000, couponID: c5, requestID: "e") }, "used coupon")

            let paid10 = try store.submitMobileRecharge(phone: phone, faceInCents: 2000, couponID: c10, requestID: "f")
            precondition(paid10.paidInCents == 1000 && paid10.couponDiscountInCents == 1000 && status(benefits, c10) == .used)

            let voided = try benefits.redeem(goodsID: "g.phone5")
            try benefits.cancelOrder(id: voided.id)
            expect(.couponUnavailable, { _ = try store.submitMobileRecharge(phone: phone, faceInCents: 1000, couponID: voided.couponID, requestID: "g") }, "voided coupon")
            precondition(store.usableCoupons(forFaceInCents: 20000).isEmpty, "no phone coupon left")
        }
    }

    @MainActor static func rechargeAmountRules() throws {
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let store = ledgerStore(defaults, clock, makeBenefits(defaults, clock), balance: 10.00)
            try store.submitMobileRecharge(phone: phone, faceInCents: 1000, couponID: nil, requestID: "a")
            precondition(balanceCents(store) == 0, "exact balance payable")
            expect(.insufficientBalance, { _ = try store.submitMobileRecharge(phone: phone, faceInCents: 1000, couponID: nil, requestID: "b") }, "empty")
        }
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let store = ledgerStore(defaults, clock, makeBenefits(defaults, clock), balance: 9.99)
            expect(.insufficientBalance, { _ = try store.submitMobileRecharge(phone: phone, faceInCents: 1000, couponID: nil, requestID: "a") }, "short by one cent")
            precondition(balanceCents(store) == 999 && store.paymentOrders().isEmpty)
        }
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let benefits = makeBenefits(defaults, clock)
            let store = ledgerStore(defaults, clock, benefits, balance: 5.00)
            let c5 = try benefits.redeem(goodsID: "g.phone5").couponID
            let order = try store.submitMobileRecharge(phone: phone, faceInCents: 1000, couponID: c5, requestID: "a")
            precondition(order.paidInCents == 500 && balanceCents(store) == 0 && status(benefits, c5) == .used, "coupon makes it affordable")
        }
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let store = ledgerStore(defaults, clock, makeBenefits(defaults, clock))
            for index in 0..<7 {
                try store.submitMobileRecharge(phone: phone, faceInCents: 20_000, couponID: nil, requestID: "r\(index)")
            }
            precondition(balanceCents(store) == 9_966)
            expect(.insufficientBalance, { _ = try store.submitMobileRecharge(phone: phone, faceInCents: 20_000, couponID: nil, requestID: "last") }, "eighth")
        }
    }

    @MainActor static func rechargeIdempotency() throws {
        try withSuite { defaults in
            let center = NotificationCenter()
            let changes = count(center, BenefitsStore.didChangeNotification)
            let clock = TestClock("2026-11-06 10:00")
            let benefits = makeBenefits(defaults, clock, center: center)
            let store = ledgerStore(defaults, clock, benefits)
            let first = try store.submitMobileRecharge(phone: phone, faceInCents: 2000, couponID: nil, requestID: "a")
            let second = try store.submitMobileRecharge(phone: "13012345678", faceInCents: 5000, couponID: nil, requestID: "a")
            precondition(first == second, "same request returns original")
            precondition(store.paymentOrders().count == 1 && store.load().transactions.count == 1)
            precondition(balanceCents(store) == 147_966, "charged once")

            let c5 = try benefits.redeem(goodsID: "g.phone5").couponID
            let withCoupon = try store.submitMobileRecharge(phone: phone, faceInCents: 1000, couponID: c5, requestID: "b")
            let afterFirst = (changes.count, balanceCents(store))
            let again = try store.submitMobileRecharge(phone: phone, faceInCents: 1000, couponID: c5, requestID: "b")
            precondition(again == withCoupon && status(benefits, c5) == .used)
            precondition(changes.count == afterFirst.0 && balanceCents(store) == afterFirst.1, "no second charge or coupon write")

            let restarted = FinanceLedgerStore(defaults: defaults, dates: BankingDateContext(now: { clock.now }),
                                               benefitsProvider: { benefits })
            let replay = try restarted.submitMobileRecharge(phone: phone, faceInCents: 2000, couponID: nil, requestID: "a")
            precondition(replay == first, "restart keeps idempotency")
            precondition(restarted.paymentOrders().count == 2)

            expect(.invalidRequest, { _ = try store.submitMobileRecharge(phone: phone, faceInCents: 2000, couponID: nil, requestID: "") }, "empty id")
            expect(.invalidRequest, { _ = try store.submitMobileRecharge(phone: phone, faceInCents: 2000, couponID: nil, requestID: String(repeating: "x", count: 101)) }, "long id")
        }
    }

    @MainActor static func couponCompensation() throws {
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let benefitCenter = NotificationCenter()
            let benefitChanges = count(benefitCenter, BenefitsStore.didChangeNotification)
            let benefits = makeBenefits(defaults, clock, center: benefitCenter)
            var failing = false
            let store = ledgerStore(defaults, clock, benefits, writer: { data in
                if failing { throw WriteFailure() }
                defaults.set(data, forKey: ledgerKey)
            })
            try store.submitMobileRecharge(phone: phone, faceInCents: 2000, couponID: nil, requestID: "plain")
            let c5 = try benefits.redeem(goodsID: "g.phone5").couponID
            let ledgerChanges = count(NotificationCenter.default, .financeLedgerDidChange)
            let before = store.load()
            failing = true
            expect(.persistence, { _ = try store.submitMobileRecharge(phone: phone, faceInCents: 1000, couponID: c5, requestID: "x") }, "write failure")
            precondition(store.load() == before, "orders, transactions and balance unchanged")
            precondition(status(benefits, c5) == .unused, "coupon released")
            precondition(ledgerChanges.count == 0, "no ledger notification")
            failing = false
            let order = try store.submitMobileRecharge(phone: phone, faceInCents: 1000, couponID: c5, requestID: "x")
            precondition(order.couponID == c5 && status(benefits, c5) == .used && ledgerChanges.count == 1, "retry succeeds")

            let c5b = try benefits.redeem(goodsID: "g.phone5").couponID
            let writes = benefitChanges.count
            expect(.invalidPhone, { _ = try store.submitMobileRecharge(phone: "123", faceInCents: 1000, couponID: c5b, requestID: "y1") }, "bad phone")
            expect(.invalidDenomination, { _ = try store.submitMobileRecharge(phone: phone, faceInCents: 1500, couponID: c5b, requestID: "y2") }, "bad face")
            precondition(status(benefits, c5b) == .unused && benefitChanges.count == writes, "validation never touches the coupon")
        }
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let center = NotificationCenter()
            let benefitChanges = count(center, BenefitsStore.didChangeNotification)
            let benefits = makeBenefits(defaults, clock, center: center)
            let c5 = try benefits.redeem(goodsID: "g.phone5").couponID
            let store = ledgerStore(defaults, clock, benefits, balance: 4.99)
            let writes = benefitChanges.count
            expect(.insufficientBalance, { _ = try store.submitMobileRecharge(phone: phone, faceInCents: 1000, couponID: c5, requestID: "z") }, "short even with coupon")
            precondition(status(benefits, c5) == .unused && benefitChanges.count == writes, "balance check precedes coupon use")
        }
    }

    @MainActor static func utilityRules() throws {
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let store = ledgerStore(defaults, clock, makeBenefits(defaults, clock))
            let water = account("bill.water.home")
            let amount = PaymentRules.billAmountInCents(for: water, period: "2026-11")
            let bill = store.currentBill(for: water)
            precondition(bill.amountInCents == amount && !bill.isPaid && bill.period == "2026-11")
            let order = try store.submitUtilityPayment(billAccountID: water.id, requestID: "a")
            precondition(order.kind == .water && order.period == "2026-11" && order.targetID == water.id)
            precondition(order.paidInCents == amount && order.faceInCents == amount && order.couponID == nil && order.couponDiscountInCents == 0)
            precondition(order.targetTitle == "水费 · 家庭住宅" && order.createdAt == "2026-11-06 10:00:00")
            let transaction = store.transaction(id: order.transactionID)!
            precondition(transaction.direction == .expense && cents(transaction.amount) == amount && transaction.includeInFlow)
            precondition(transaction.categoryId == "life_payment" && transaction.title == "水费缴费-家庭住宅")
            precondition(transaction.transactionType == "生活缴费" && transaction.counterpartyName == water.provider)
            precondition(balanceCents(store) == 149_966 - amount && store.currentBill(for: water).isPaid)
            expect(.alreadyPaid, { _ = try store.submitUtilityPayment(billAccountID: water.id, requestID: "b") }, "second payment same period")
            let replayed = try store.submitUtilityPayment(billAccountID: water.id, requestID: "a")
            precondition(replayed == order, "same request idempotent")
            precondition(store.paymentOrders().count == 1)
            let parents = try store.submitUtilityPayment(billAccountID: "bill.water.parents", requestID: "c")
            precondition(parents.targetTitle == "水费 · 父母住宅", "other account unaffected")
            expect(.billNotFound, { _ = try store.submitUtilityPayment(billAccountID: "nope", requestID: "d") }, "unknown account")

            clock.set("2026-11-30 23:59")
            precondition(store.currentBill(for: water).isPaid, "still November")
            expect(.alreadyPaid, { _ = try store.submitUtilityPayment(billAccountID: water.id, requestID: "e") }, "month end")
            clock.set(utc: "2026-11-30T16:00:00Z")
            precondition(!store.currentBill(for: water).isPaid && store.currentBill(for: water).period == "2026-12", "new period")
            let december = try store.submitUtilityPayment(billAccountID: water.id, requestID: "f")
            precondition(december.period == "2026-12" && store.paymentOrders().count == 3)
        }
        let electric = account("bill.electric.home")
        let due = PaymentRules.billAmountInCents(for: electric, period: "2026-11")
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let store = ledgerStore(defaults, clock, makeBenefits(defaults, clock), balance: Double(due) / 100)
            try store.submitUtilityPayment(billAccountID: electric.id, requestID: "a")
            precondition(balanceCents(store) == 0, "exact balance payable")
        }
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let store = ledgerStore(defaults, clock, makeBenefits(defaults, clock), balance: Double(due - 1) / 100)
            expect(.insufficientBalance, { _ = try store.submitUtilityPayment(billAccountID: electric.id, requestID: "a") }, "short by one cent")
            precondition(store.paymentOrders().isEmpty && balanceCents(store) == due - 1)
        }
    }

    @MainActor static func corruptLedgerKeepsBytes() throws {
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let benefits = makeBenefits(defaults, clock)
            let store = ledgerStore(defaults, clock, benefits)
            let c5 = try benefits.redeem(goodsID: "g.phone5").couponID
            let garbage = Data(#"{"accounts":"x"}"#.utf8)
            defaults.set(garbage, forKey: ledgerKey)
            expect(.corruptLedger, { _ = try store.submitMobileRecharge(phone: phone, faceInCents: 1000, couponID: c5, requestID: "a") }, "recharge")
            expect(.corruptLedger, { _ = try store.submitUtilityPayment(billAccountID: "bill.water.home", requestID: "b") }, "utility")
            precondition(defaults.data(forKey: ledgerKey) == garbage, "bytes untouched")
            precondition(status(benefits, c5) == .unused, "coupon untouched")
        }
    }

    @MainActor static func writeFailureIsAtomic() throws {
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            var failing = false
            let store = ledgerStore(defaults, clock, makeBenefits(defaults, clock), writer: { data in
                if failing { throw WriteFailure() }
                defaults.set(data, forKey: ledgerKey)
            })
            let counter = count(NotificationCenter.default, .financeLedgerDidChange)
            let before = store.load()
            failing = true
            expect(.persistence, { _ = try store.submitUtilityPayment(billAccountID: "bill.gas.home", requestID: "a") }, "utility")
            precondition(store.load() == before, "unchanged")
            precondition(counter.count == 0, "no notification on failed write")
            failing = false
            try store.submitUtilityPayment(billAccountID: "bill.gas.home", requestID: "a")
            precondition(counter.count == 1 && store.paymentOrders().count == 1)
        }
    }

    // MARK: - 订单列表

    static func reward(_ id: String, _ created: String) -> RewardOrder {
        RewardOrder(id: id, orderNo: "M6" + id, goodsID: "g.phone5", title: "测试兑换", currency: .beans, cost: 100,
                    quantity: 1, createdAt: at(created), couponID: "c" + id, cancelledAt: nil)
    }

    static func orderListMerge() {
        let rewards = [reward("r1", "2026-11-05 10:00"), reward("r2", "2026-11-06 09:00")]
        let payments = [
            order(target: "x", period: nil, created: "2026-11-06 09:00:00").withID("p1"),
            order(target: "y", period: nil, created: "2026-11-04 12:00:00").withID("p2")
        ]
        let status: (RewardOrder) -> OrderStatus = { $0.id == "r1" ? .pendingUse : .used }
        func ids(_ filter: OrderListFilter, reward: [RewardOrder] = rewards, payment: [PaymentOrder] = payments) -> [String] {
            OrderListBuilder.items(filter: filter, reward: reward, payment: payment, status: status, dates: shanghai).map(\.id)
        }
        precondition(ids(.all) == ["p1", "r2", "r1", "p2"], "mixed newest first, payment first on ties")
        precondition(ids(.payments) == ["p1", "p2"])
        precondition(ids(.pendingUse) == ["r1"] && ids(.used) == ["r2"])
        precondition(ids(.expired).isEmpty && ids(.cancelled).isEmpty)
        precondition(ids(.all, reward: [], payment: []).isEmpty)
        let broken = [order(target: "z", period: nil, created: "bad").withID("p3")] + payments
        precondition(ids(.all, payment: broken) == ["p1", "r2", "r1", "p2", "p3"], "unparsable date sorts last")
        precondition(OrderListFilter.allCases.map(\.title) == ["全部", "待使用", "已使用", "已失效", "已取消", "充值缴费"])
    }

    // MARK: - 确认金额与实际扣款一致（审查修复）

    @MainActor static func expectedAmountGuards() throws {
        try withSuite { defaults in
            let clock = TestClock("2026-11-06 10:00")
            let benefits = makeBenefits(defaults, clock)
            let store = ledgerStore(defaults, clock, benefits)
            let c5 = try benefits.redeem(goodsID: "g.phone5").couponID
            let before = store.load()
            expect(.amountChanged, { _ = try store.submitMobileRecharge(phone: phone, faceInCents: 1000, couponID: nil, requestID: "a", expectedPaidInCents: 500) }, "coupon dropped after confirm")
            expect(.amountChanged, { _ = try store.submitMobileRecharge(phone: phone, faceInCents: 1000, couponID: c5, requestID: "b", expectedPaidInCents: 1000) }, "coupon applied after confirm")
            precondition(store.load() == before && status(benefits, c5) == .unused, "mismatch changes nothing and never consumes the coupon")
            let order = try store.submitMobileRecharge(phone: phone, faceInCents: 1000, couponID: c5, requestID: "c", expectedPaidInCents: 500)
            precondition(order.paidInCents == 500 && status(benefits, c5) == .used, "matching expectation succeeds")
        }
        try withSuite { defaults in
            let clock = TestClock("2026-11-30 23:59")
            let store = ledgerStore(defaults, clock, makeBenefits(defaults, clock))
            let water = account("bill.water.home")
            let november = PaymentRules.billAmountInCents(for: water, period: "2026-11")
            clock.set(utc: "2026-11-30T16:00:00Z")
            let before = store.load()
            expect(.amountChanged, { _ = try store.submitUtilityPayment(billAccountID: water.id, requestID: "a", expectedPeriod: "2026-11", expectedAmountInCents: november) }, "period rolled over while confirming")
            precondition(store.load() == before, "rollover mismatch charges nothing")
            let december = try store.submitUtilityPayment(billAccountID: water.id, requestID: "b", expectedPeriod: "2026-12",
                                                         expectedAmountInCents: PaymentRules.billAmountInCents(for: water, period: "2026-12"))
            precondition(december.period == "2026-12")
            expect(.alreadyPaid, { _ = try store.submitUtilityPayment(billAccountID: water.id, requestID: "c", expectedPeriod: "2026-12", expectedAmountInCents: december.paidInCents) }, "same period still reports paid")
        }
    }
}

extension PaymentOrder {
    func withID(_ newID: String) -> PaymentOrder {
        PaymentOrder(id: newID, orderNo: orderNo, requestID: requestID, kind: kind, targetID: targetID,
                     targetTitle: targetTitle, period: period, faceInCents: faceInCents, couponID: couponID,
                     couponDiscountInCents: couponDiscountInCents, paidInCents: paidInCents, accountID: accountID,
                     createdAt: createdAt, transactionID: transactionID)
    }
}
