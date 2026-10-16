import Foundation

// This is a local UI exercise. Raw card/phone input stays in the in-memory draft only.
nonisolated enum TransferMethod: String, Codable, CaseIterable, Sendable {
    case account, phone
    var title: String { self == .account ? "账号转账" : "手机号转账" }
}

nonisolated enum TransferStatus: String, Codable, Sendable {
    case succeeded, failed
    var title: String { self == .succeeded ? "模拟转账成功" : "模拟转账失败" }
}

nonisolated struct TransferRecipient: Equatable, Identifiable {
    let id: String
    let name: String
    let bankName: String
    let maskedDestination: String
    var method: TransferMethod = .account
    var linkedAccountID: String? = nil

    static let presets: [TransferRecipient] = [
        .init(id: "a1", name: "韩继宏", bankName: "中国农业银行", maskedDestination: "6230****8472", linkedAccountID: "acct_8472"),
        .init(id: "a2", name: "韩继宏", bankName: "中国工商银行", maskedDestination: "6222****9517"),
        .init(id: "a3", name: "欧梦瑶", bankName: "中国建设银行", maskedDestination: "6217****0593"),
        .init(id: "a4", name: "俞增林", bankName: "中国建设银行", maskedDestination: "6227****1081")
    ]
}

nonisolated struct TransferDraft: Equatable, Sendable {
    var payerAccountID: String
    var method: TransferMethod = .account
    var recipientName = ""
    var bankName = "中国农业银行"
    var destination = ""
    var savedRecipientID: String? = nil
    var amountInCents: Int64 = 0
    var note = ""
}

nonisolated struct TransferRecord: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let requestID: String
    let payerAccountID: String
    let payerLabel: String
    let method: TransferMethod
    let recipientName: String
    let bankName: String
    let maskedDestination: String
    let savedRecipientID: String?
    let amountInCents: Int64
    let note: String
    let createdAt: String  // Beijing yyyy-MM-dd HH:mm:ss
    let status: TransferStatus
    let transactionID: String?
    let failureReason: String?

    var reusableRecipient: TransferRecipient {
        TransferRecipient(id: "history:\(id)", name: recipientName, bankName: bankName,
                          maskedDestination: maskedDestination, method: method)
    }
}

nonisolated struct TransferLimits {
    var perTransferInCents: Int64 = 5_000_000
    var dailyInCents: Int64 = 20_000_000
}

nonisolated enum TransferError: LocalizedError, Equatable {
    case invalidAmount, invalidRecipient, invalidDestination, missingAccount, sameAccount
    case insufficientBalance, singleLimit, dailyLimit, persistence, invalidRequest, corruptLedger
    var errorDescription: String? {
        switch self {
        case .invalidAmount: return "请输入大于0的金额，最多保留两位小数"
        case .invalidRecipient: return "请检查收款人、收款银行和附言（最多60字）"
        case .invalidDestination: return "请输入16至19位演示账号或有效的11位演示手机号"
        case .missingAccount: return "付款账户不存在或暂不可用，请重新选择"
        case .sameAccount: return "付款账户与收款账户相同，请更换收款账户"
        case .insufficientBalance: return "可用余额不足，请调整金额或更换付款账户"
        case .singleLimit: return "超过本机模拟单笔转账限额"
        case .dailyLimit: return "超过本机模拟当日累计转账限额"
        case .persistence: return "本地保存失败，本次未扣款，请重试"
        case .invalidRequest: return "转账请求无效，请返回重新确认"
        case .corruptLedger: return "本地账本无法读取，请先检查账本数据"
        }
    }
}

/// One conversion boundary between new cent-based transfers and the existing Double ledger.
nonisolated enum TransferMoney {
    static func parse(_ text: String) -> Int64? {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.range(of: #"^[0-9]{1,10}(\.[0-9]{1,2})?$"#, options: .regularExpression) != nil,
              let decimal = Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")) else { return nil }
        let value = NSDecimalNumber(decimal: decimal * 100)
        guard value.compare(NSDecimalNumber(value: Int64.max)) == .orderedAscending else { return nil }
        return value.int64Value
    }

    static func cents(from value: Double) -> Int64? {
        guard value.isFinite, abs(value) < 1_000_000_000_000 else { return nil }
        var decimal = Decimal(value) * 100
        var rounded = Decimal()
        NSDecimalRound(&rounded, &decimal, 0, .plain)
        return NSDecimalNumber(decimal: rounded).int64Value
    }

    static func amount(_ cents: Int64) -> Double { Double(cents) / 100 }
    static func text(_ cents: Int64) -> String { String(format: "%.2f", amount(cents)) }
}
