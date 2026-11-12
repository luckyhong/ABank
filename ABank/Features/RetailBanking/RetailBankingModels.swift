import Foundation

struct DepositProduct: Identifiable {
    let id: String
    let title: String
    let months: Int
    let rateBasisPoints: Int
    var rateText: String { String(format: "%.2f%%", Double(rateBasisPoints) / 100) }
    static let all = [DepositProduct(id: "deposit_3m", title: "整存整取 · 三个月", months: 3, rateBasisPoints: 90),
                      DepositProduct(id: "deposit_6m", title: "整存整取 · 六个月", months: 6, rateBasisPoints: 95),
                      DepositProduct(id: "deposit_12m", title: "整存整取 · 一年", months: 12, rateBasisPoints: 105)]
}
struct TermDeposit: Codable, Equatable, Identifiable {
    let id: String
    let requestID: String
    let accountID: String
    let productID: String
    let title: String
    let principalInCents: Int64
    let rateBasisPoints: Int
    let openedAt: String
    let maturityDate: String
    var closedAt: String? = nil
    var interestPaidInCents: Int64? = nil
}
struct CreditCardAccount: Codable, Equatable, Identifiable {
    let id: String
    let tail: String
    let limitInCents: Int64
    let statementDate: String
    let dueDate: String
    let originalBillInCents: Int64
    var repaidInCents: Int64 = 0
    var remainingInCents: Int64 { max(0, originalBillInCents - repaidInCents) }
    var minimumInCents: Int64 { min(remainingInCents, max(0, (originalBillInCents + 9) / 10 - repaidInCents)) }
}
struct CreditRepaymentRecord: Codable, Equatable, Identifiable {
    let id: String
    let requestID: String
    let cardID: String
    let accountID: String
    let amountInCents: Int64
    let createdAt: String
}
