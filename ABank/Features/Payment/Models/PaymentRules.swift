//
//  PaymentRules.swift
//  ABank
//
//  充值缴费纯规则：手机号、账期、账单金额、话费券抵扣、订单号。时间来自注入的 `BankingDateContext`。
//

import Foundation

nonisolated enum PaymentRules {
    // MARK: - 手机号

    /// 仅去掉空格与连字符。
    static func normalizedPhone(_ text: String) -> String {
        text.filter { $0 != " " && $0 != "-" }
    }

    /// 11 位纯数字，首位 1，第二位 3–9。
    static func isValidPhone(_ normalized: String) -> Bool {
        let digits = Array(normalized.utf8)
        guard digits.count == 11, digits.allSatisfy({ $0 >= 48 && $0 <= 57 }) else { return false }
        return digits[0] == 49 && digits[1] >= 51 && digits[1] <= 57
    }

    static func maskedPhone(_ normalized: String) -> String {
        guard normalized.count == 11 else { return normalized }
        return normalized.prefix(3) + "****" + normalized.suffix(4)
    }

    static func phoneOperator(of normalized: String) -> PhoneOperator {
        PaymentCatalog.phoneOperator(prefix: String(normalized.prefix(3)))
    }

    static func targetTitle(phone normalized: String) -> String {
        "手机号 " + maskedPhone(normalized)
    }

    static func targetTitle(for account: BillAccount) -> String {
        account.kind.title + " · " + account.name
    }

    // MARK: - 账期与账单

    static func currentPeriod(now: Date, dates: BankingDateContext) -> String {
        dates.string(from: now, format: "yyyy-MM")
    }

    /// 账期最后一天，`yyyy-MM-dd`。
    static func dueDate(period: String, dates: BankingDateContext) -> String {
        guard let first = dates.date(from: period + "-01"),
              let days = dates.calendar.range(of: .day, in: .month, for: first)?.count else { return period + "-01" }
        return period + "-" + String(format: "%02d", days)
    }

    /// `base + stableHash(账户 ID, 账期) % span`，同户号同账期金额固定。
    static func billAmountInCents(for account: BillAccount, period: String) -> Int64 {
        let (base, span): (Int64, UInt64)
        switch account.kind {
        case .water: (base, span) = (3_500, 6_000)
        case .electric: (base, span) = (8_000, 18_000)
        case .gas: (base, span) = (4_000, 14_000)
        case .mobile: (base, span) = (0, 1)
        }
        return base + Int64(BranchSchedule.stableHash(account.id, period) % span)
    }

    static func bill(for account: BillAccount, orders: [PaymentOrder], now: Date, dates: BankingDateContext) -> UtilityBill {
        bill(for: account, orders: orders, period: currentPeriod(now: now, dates: dates), dates: dates)
    }

    static func bill(for account: BillAccount, orders: [PaymentOrder], period: String, dates: BankingDateContext) -> UtilityBill {
        let paid = orders.contains { $0.targetID == account.id && $0.period == period }
        return UtilityBill(account: account, period: period, dueDate: dueDate(period: period, dates: dates),
                           amountInCents: billAmountInCents(for: account, period: period), isPaid: paid)
    }

    // MARK: - 话费券

    static func phoneCouponFaceInCents(templateID: String) -> Int64? {
        switch templateID {
        case "phone5": return 500
        case "phone10": return 1_000
        default: return nil
        }
    }

    /// 面值小于面额才可用，返回面值。
    static func usableCouponFaceInCents(templateID: String, faceInCents amount: Int64) -> Int64? {
        guard let face = phoneCouponFaceInCents(templateID: templateID), face < amount else { return nil }
        return face
    }

    // MARK: - 订单

    static func orderNo(id: String, createdAt: Date, dates: BankingDateContext) -> String {
        let digits = String(BranchSchedule.stableHash("payment", id) % 100_000_000)
        return "JF" + dates.string(from: createdAt, format: "yyyyMMdd")
            + String(repeating: "0", count: 8 - digits.count) + digits
    }

    static func createdDate(of order: PaymentOrder, dates: BankingDateContext) -> Date? {
        dates.date(from: order.createdAt, format: "yyyy-MM-dd HH:mm:ss")
    }
}
