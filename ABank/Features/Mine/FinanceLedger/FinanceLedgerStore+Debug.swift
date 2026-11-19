#if DEBUG
import Foundation

struct DebugLedgerDraft {
    enum Operation {
        case transfer(LedgerTransactionDirection)
        case targetBalance

        var title: String {
            switch self {
            case .transfer(.income): return "模拟转入"
            case .transfer(.expense): return "模拟转出"
            case .targetBalance: return "设置目标余额"
            }
        }
    }

    let accountID: String
    let operation: Operation
    let amountInCents: Int64
    let date: Date? // nil uses the bank clock at commit time
    let summary: String
    let counterparty: String
    let note: String
    let includeInFlow: Bool
}

struct DebugLedgerPreview: Equatable {
    let currentBalance: Int64
    let newBalance: Int64
    var change: Int64 { newBalance - currentBalance }
}

enum DebugLedgerError: LocalizedError, Equatable {
    case invalidAmount, invalidDate, invalidText, missingAccount, missingEntry, insufficientBalance
    case balanceChanged, persistence

    var errorDescription: String? {
        switch self {
        case .invalidAmount: return "请输入有效金额，最多两位小数"
        case .invalidDate: return "请选择当前或更早的交易时间"
        case .invalidText: return "摘要和对方户名最多 40 字，备注最多 200 字"
        case .missingAccount: return "该人民币账户不可用，请重新选择"
        case .missingEntry: return "该调试流水已不存在"
        case .insufficientBalance: return "该操作会导致余额透支或扩大已有透支。请先处理相关支出，或调整金额或时间。"
        case .balanceChanged: return "账户余额已变化，请重新预览并确认"
        case .persistence: return "账本保存失败，请重试"
        }
    }
}

extension FinanceLedgerStore {
    private static let debugEntryPrefix = "debug-ledger:"
    private static let debugTimestampFormat = "yyyy-MM-dd HH:mm:ss"

    static func isDebugEntry(_ transaction: LedgerTransaction) -> Bool {
        !transaction.isManual && transaction.id.hasPrefix(debugEntryPrefix)
    }

    func previewDebugEntry(_ draft: DebugLedgerDraft) throws -> DebugLedgerPreview {
        let original = try loadForTransfer()
        return try makeDebugEntry(draft, id: Self.debugEntryPrefix + UUID().uuidString, original: original).preview
    }

    func saveDebugEntry(_ draft: DebugLedgerDraft, requestID: UUID, expected: DebugLedgerPreview) throws {
        let id = Self.debugEntryPrefix + requestID.uuidString
        let original = try loadForTransfer()
        guard !original.transactions.contains(where: { $0.id == id }) else { return }
        let account = try debugAccount(draft.accountID, in: original)
        guard TransferMoney.cents(from: account.balance) == expected.currentBalance else {
            throw DebugLedgerError.balanceChanged
        }
        let result = try makeDebugEntry(draft, id: id, original: original)
        guard result.preview == expected else { throw DebugLedgerError.balanceChanged }
        guard result.preview.change != 0 else { return }
        try persistDebugRecord(result.record)
    }

    func removeDebugEntry(id: String) throws {
        let original = try loadForTransfer()
        guard let entry = original.transactions.first(where: { $0.id == id && Self.isDebugEntry($0) }) else {
            throw DebugLedgerError.missingEntry
        }
        var record = original
        record.transactions.removeAll { $0.id == id }
        recalculate(&record)
        _ = try validateDebugBalances(in: record, comparedTo: original, accountID: entry.accountId, changedID: id)
        try persistDebugRecord(record)
    }

    private func makeDebugEntry(_ draft: DebugLedgerDraft, id: String, original: FinanceLedgerRecord) throws
        -> (preview: DebugLedgerPreview, record: FinanceLedgerRecord) {
        let account = try debugAccount(draft.accountID, in: original)
        let current = try debugCents(account.balance)
        guard (0...999_999_999_999).contains(draft.amountInCents) else { throw DebugLedgerError.invalidAmount }
        let direction: LedgerTransactionDirection
        let amount: Int64
        let defaultSummary: String
        switch draft.operation {
        case .transfer(let selectedDirection):
            direction = selectedDirection
            amount = draft.amountInCents
            defaultSummary = draft.operation.title
            guard amount > 0 else { throw DebugLedgerError.invalidAmount }
        case .targetBalance:
            let change = draft.amountInCents - current
            direction = change < 0 ? .expense : .income
            amount = abs(change)
            defaultSummary = "调试余额调整"
            if amount == 0 { return (DebugLedgerPreview(currentBalance: current, newBalance: current), original) }
        }
        let now = dates.now
        let date = draft.date ?? now
        guard date <= now else { throw DebugLedgerError.invalidDate }
        let summary = draft.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let counterparty = draft.counterparty.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = draft.note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard summary.count <= 40, counterparty.count <= 40, note.count <= 200 else { throw DebugLedgerError.invalidText }

        var record = original
        record.transactions.append(LedgerTransaction(
            id: id, accountId: account.id, date: dates.string(from: date), time: dates.string(from: date, format: "HH:mm:ss"),
            title: summary.isEmpty ? defaultSummary : summary, direction: direction, amount: TransferMoney.amount(amount),
            balanceAfter: 0, iconKey: "transfer", categoryId: direction == .income ? "transfer_in" : "transfer_out",
            includeInFlow: draft.includeInFlow, counterpartyName: counterparty, cardNumber: account.maskedCardNumber,
            transactionType: "转账", channel: "本地调试", note: note
        ))
        recalculate(&record)
        let updated = try validateDebugBalances(in: record, comparedTo: original, accountID: account.id, changedID: id)
        let signedAmount = direction == .income ? amount : -amount
        guard updated - current == signedAmount else { throw DebugLedgerError.balanceChanged }
        return (DebugLedgerPreview(currentBalance: current, newBalance: updated), record)
    }

    private func validateDebugBalances(in record: FinanceLedgerRecord, comparedTo original: FinanceLedgerRecord,
                                       accountID: String, changedID: String) throws -> Int64 {
        let current = try debugCents(debugAccount(accountID, in: original).balance)
        let updated = try debugCents(debugAccount(accountID, in: record).balance)
        guard updated >= min(0, current) else { throw DebugLedgerError.insufficientBalance }
        let before = original.transactions.filter { $0.accountId == accountID && $0.id != changedID }
        let after = record.transactions.filter { $0.accountId == accountID && $0.id != changedID }
        for (old, new) in zip(before, after) {
            let oldBalance = try debugCents(old.balanceAfter)
            let newBalance = try debugCents(new.balanceAfter)
            guard newBalance >= min(0, oldBalance) else { throw DebugLedgerError.insufficientBalance }
        }
        if let added = record.transactions.first(where: { $0.id == changedID }), added.direction == .expense,
           try debugCents(added.balanceAfter) < 0 {
            throw DebugLedgerError.insufficientBalance
        }
        return updated
    }

    private func debugAccount(_ id: String, in record: FinanceLedgerRecord) throws -> LedgerAccount {
        guard let account = record.accounts.first(where: { $0.id == id && $0.currency == "人民币" }) else {
            throw DebugLedgerError.missingAccount
        }
        return account
    }

    private func debugCents(_ balance: Double) throws -> Int64 {
        guard let cents = TransferMoney.cents(from: balance) else { throw DebugLedgerError.invalidAmount }
        return cents
    }

    private func persistDebugRecord(_ record: FinanceLedgerRecord) throws {
        var updated = record
        updated.dataTimestamp = dates.string(from: dates.now, format: Self.debugTimestampFormat)
        do { try persist(updated) } catch { throw DebugLedgerError.persistence }
    }
}
#endif
