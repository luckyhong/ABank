import Foundation

@main struct PaymentChecks {
    @MainActor static func main() throws {
        catalog()
        phoneRules()
        couponRules()
        billAmounts()
        billPeriods()
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
}
