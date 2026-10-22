import Foundation

/// 电子回单只从已成功并已入账的本机模拟转账派生，不单独持久化，避免与账本不一致。
struct TransferReceipt: Equatable, Identifiable {
    static let simulationMark = "模拟交易 · 非真实凭证"
    static let disclaimer = "本回单由 ABank 学习项目在本机根据模拟转账生成，仅用于界面演示，不代表真实资金交易，不具备任何凭证效力。"

    let id: String            // TransferRecord.id
    let receiptNumber: String
    let transactionID: String
    let createdAt: String     // 北京时间 yyyy-MM-dd HH:mm:ss
    let payerAccountID: String
    let payerLabel: String
    let payerMaskedCard: String
    let payeeName: String
    let payeeBank: String
    let payeeMaskedDestination: String
    let method: TransferMethod
    let amountInCents: Int64
    let note: String

    var amountText: String { "¥ " + TransferMoney.amount(amountInCents).abankPlainAmountString() }
    var amountInWords: String { RMBUppercase.text(cents: amountInCents) }
    var statusText: String { "交易成功（模拟）" }

    /// 失败、未入账或关联流水缺失的记录不生成回单。
    init?(record: TransferRecord, transaction: LedgerTransaction?, account: LedgerAccount?) {
        guard record.status == .succeeded, let transactionID = record.transactionID,
              let transaction, transaction.id == transactionID else { return nil }
        id = record.id
        receiptNumber = Self.receiptNumber(createdAt: record.createdAt, recordID: record.id)
        self.transactionID = transactionID
        createdAt = record.createdAt
        payerAccountID = record.payerAccountID
        payerLabel = record.payerLabel
        payerMaskedCard = account.map { "****" + $0.tailNumber } ?? transaction.cardNumber
        payeeName = record.recipientName
        payeeBank = record.bankName
        payeeMaskedDestination = record.maskedDestination
        method = record.method
        amountInCents = record.amountInCents
        note = record.note
    }

    /// 稳定编号：SIM + 交易时间数字 + 记录 ID 末 6 位，重复打开同一回单编号不变。
    static func receiptNumber(createdAt: String, recordID: String) -> String {
        let digits = createdAt.filter(\.isNumber)
        let suffix = String(recordID.filter { $0.isLetter || $0.isNumber }.suffix(6)).uppercased()
        return "SIM" + digits + suffix
    }

    /// 分享时附带的文字，同样带模拟标记。
    var shareText: String {
        [
            "【\(Self.simulationMark)】ABank 电子回单",
            "回单编号：\(receiptNumber)",
            "交易时间：\(createdAt)",
            "付款账户：\(payerLabel) \(payerMaskedCard)",
            "收款人：\(payeeName)",
            "收款账户：\(payeeBank) \(payeeMaskedDestination)",
            "金额：\(amountText)（\(amountInWords)）",
            "附言：\(note.isEmpty ? "无" : note)",
            Self.disclaimer
        ].joined(separator: "\n")
    }
}

/// 人民币金额大写（以分为单位），如 100010.01 → 壹拾万零壹拾元零壹分。
enum RMBUppercase {
    private static let digits = ["零", "壹", "贰", "叁", "肆", "伍", "陆", "柒", "捌", "玖"]
    private static let units = ["", "拾", "佰", "仟"]
    private static let groupUnits = ["", "万", "亿", "万亿", "亿亿"]
    private static let divisors = [1, 10, 100, 1000]

    static func text(cents: Int64) -> String {
        guard cents > 0 else { return "零元整" }
        let yuan = cents / 100
        let jiao = Int((cents / 10) % 10)
        let fen = Int(cents % 10)

        var result = yuan > 0 ? integerText(yuan) + "元" : ""
        if jiao == 0 && fen == 0 { return result + "整" }
        if jiao > 0 {
            result += digits[jiao] + "角"
        } else if yuan > 0 {
            result += "零"
        }
        result += fen > 0 ? digits[fen] + "分" : "整"
        return result
    }

    private static func integerText(_ value: Int64) -> String {
        var groups: [Int] = []
        var remaining = value
        while remaining > 0 {
            groups.append(Int(remaining % 10_000))
            remaining /= 10_000
        }
        var result = ""
        var pendingZero = false
        for index in groups.indices.reversed() {
            let group = groups[index]
            if group == 0 {
                pendingZero = !result.isEmpty
                continue
            }
            if !result.isEmpty && (pendingZero || group < 1000) { result += "零" }
            result += groupText(group) + groupUnits[index]
            pendingZero = false
        }
        return result
    }

    private static func groupText(_ group: Int) -> String {
        var result = ""
        var pendingZero = false
        for position in stride(from: 3, through: 0, by: -1) {
            let digit = group / divisors[position] % 10
            if digit == 0 {
                pendingZero = !result.isEmpty
            } else {
                if pendingZero { result += "零" }
                result += digits[digit] + units[position]
                pendingZero = false
            }
        }
        return result
    }
}
