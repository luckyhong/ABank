import Foundation

struct ManualEntryDraft {
    var title = ""
    var amountInCents: Int64 = 0
    var direction: LedgerTransactionDirection = .expense
    var date = ""
    var categoryID = "other_expense"
    var ledgerID: String? = nil
    var note = ""
    var purposeID: String? = nil
}

enum LedgerEditError: LocalizedError {
    case invalidTitle, invalidAmount, invalidDate, invalidCategory, invalidNote, missingEntry, persistence
    var errorDescription: String? {
        switch self {
        case .invalidTitle: return "请填写账单名称，最多40字"
        case .invalidAmount: return "请输入0.01至999,999,999.99元之间的金额"
        case .invalidDate: return "请选择今天或之前的有效日期"
        case .invalidCategory: return "请选择与收支方向对应的分类和有效账本"
        case .invalidNote: return "备注最多200字"
        case .missingEntry: return "该记录不存在或不属于手工记账"
        case .persistence: return "账单保存失败，请稍后重试"
        }
    }
}

extension FinanceLedgerStore {
    /// 手工账单独立于银行卡流水，只参与收支统计；重复保存同一ID不会追加第二笔。
    @discardableResult
    func saveManualEntry(_ draft: ManualEntryDraft, id: String) throws -> LedgerTransaction {
        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty, !title.isEmpty, title.count <= 40 else { throw LedgerEditError.invalidTitle }
        guard (1...99_999_999_999).contains(draft.amountInCents) else { throw LedgerEditError.invalidAmount }
        guard dates.date(from: draft.date) != nil, draft.date <= dates.string(from: dates.now) else { throw LedgerEditError.invalidDate }
        guard IncomeExpenseFilterCatalog.selectableOptions(for: draft.direction).contains(where: { $0.id == draft.categoryID }),
              draft.ledgerID == nil || LedgerBookCatalog.title(for: draft.ledgerID) != nil else { throw LedgerEditError.invalidCategory }
        guard draft.purposeID == nil || LedgerPurpose.title(draft.purposeID) != nil else { throw LedgerEditError.invalidCategory }
        guard draft.note.count <= 200 else { throw LedgerEditError.invalidNote }
        var root = try loadForTransfer()
        let existing = root.transactions.first(where: { $0.id == id })
        guard existing == nil || existing?.isManual == true else { throw LedgerEditError.missingEntry }
        preserveLegacyManualBalance(existing, in: &root)
        let transaction = LedgerTransaction(
            id: id, accountId: "manual", date: draft.date, time: existing?.time ?? dates.string(from: dates.now, format: "HH:mm:ss"),
            title: title, direction: draft.direction, amount: TransferMoney.amount(draft.amountInCents), balanceAfter: 0,
            iconKey: "pencil", categoryId: draft.categoryID, isManual: true, includeInFlow: existing?.includeInFlow ?? true,
            summary: title, transactionType: "手工记账", channel: "手工记账", ledgerId: draft.ledgerID,
            note: draft.note.trimmingCharacters(in: .whitespacesAndNewlines), purposeCategoryID: draft.purposeID)
        if let index = root.transactions.firstIndex(where: { $0.id == id }) { root.transactions[index] = transaction }
        else { root.transactions.append(transaction) }
        recalculate(&root)
        root.dataTimestamp = dates.string(from: dates.now, format: "yyyy-MM-dd HH:mm:ss")
        do { try persist(root) } catch { throw LedgerEditError.persistence }
        return transaction
    }

    func deleteManualEntry(id: String) throws {
        var root = try loadForTransfer()
        guard root.transactions.contains(where: { $0.id == id && $0.isManual }) else { throw LedgerEditError.missingEntry }
        preserveLegacyManualBalance(root.transactions.first(where: { $0.id == id }), in: &root)
        root.transactions.removeAll { $0.id == id }
        recalculate(&root)
        root.dataTimestamp = dates.string(from: dates.now, format: "yyyy-MM-dd HH:mm:ss")
        do { try persist(root) } catch { throw LedgerEditError.persistence }
    }

    /// Early versions attached manual rows to bank accounts. Preserve their prior balance contribution
    /// as opening funds when moving/deleting the row, so editing bookkeeping cannot debit a bank card.
    private func preserveLegacyManualBalance(_ entry: LedgerTransaction?, in root: inout FinanceLedgerRecord) {
        guard let entry, entry.isManual,
              let index = root.accounts.firstIndex(where: { $0.id == entry.accountId }),
              let opening = TransferMoney.cents(from: root.accounts[index].openingBalance),
              let amount = TransferMoney.cents(from: entry.amount) else { return }
        let delta = entry.direction == .income ? amount : -amount
        let sum = opening.addingReportingOverflow(delta)
        if !sum.overflow { root.accounts[index].openingBalance = TransferMoney.amount(sum.partialValue) }
    }

    /// 同一查询用于列表、统计与导出；按分求和避免浮点累计误差。
    static func sumAmounts(_ transactions: [LedgerTransaction], direction: LedgerTransactionDirection) -> Double {
        let total = transactions.filter { $0.direction == direction }.reduce(Decimal.zero) {
            $0 + Decimal(TransferMoney.cents(from: $1.amount) ?? 0)
        }
        return NSDecimalNumber(decimal: total / 100).doubleValue
    }

    func statementCSV(query: IncomeExpenseQuery) -> String {
        let items = incomeExpensePageData(query: query).dayGroups.flatMap(\.transactions)
        // Quoting protects delimiters; a leading apostrophe also prevents spreadsheet formula evaluation.
        func cell(_ value: String) -> String {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            let safe = ["=", "+", "-", "@"].contains(String(trimmed.prefix(1))) ? "'" + value : value
            return "\"" + safe.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        let header = ["日期", "时间", "名称", "方向", "金额(元)", "账户", "分类", "计入收支", "账本", "备注", "用途", "交易后余额(元)"]
        let rows = items.map { tx in
            [tx.date, tx.time, tx.title, tx.direction == .income ? "收入" : "支出",
             TransferMoney.text(TransferMoney.cents(from: tx.amount) ?? 0),
             tx.isManual ? "手工记账" : accountCardLabel(for: tx.accountId), tx.categoryTitle,
             tx.includeInFlow ? "是" : "否", LedgerBookCatalog.title(for: tx.ledgerId) ?? "未归属", tx.note, LedgerPurpose.title(tx.purposeCategoryID) ?? "未设置",
             (tx.isManual || tx.channel == "信用卡") ? "" : TransferMoney.text(TransferMoney.cents(from: tx.balanceAfter) ?? 0)]
        }
        return "\u{FEFF}" + ([header] + rows).map { $0.map(cell).joined(separator: ",") }.joined(separator: "\r\n")
    }
}

extension LedgerTransaction {
    // Normalize system-generated legacy captions only; keep user-entered titles and notes untouched.
    var displayChannel: String { channel == "本机模拟" ? "手机银行" : channel }
    var displaySummary: String {
        let legacy = ["模拟转账": "转账", "模拟理财购买": "理财购买", "模拟理财赎回": "理财赎回",
                      "模拟提前还款": "提前还款", "模拟手机充值": "手机充值", "模拟生活缴费": "生活缴费"]
        return legacy[summary] ?? summary
    }
    var displayCounterparty: String {
        ["模拟通信服务商": "通信服务商", "农银理财（模拟）": "农银理财"][counterpartyName] ?? counterpartyName
    }
}


enum LedgerPurpose {
    static let options: [(String, String)] = [("food", "餐饮美食"), ("transport", "交通出行"), ("shopping", "购物消费"), ("housing", "居家生活"), ("health", "医疗健康"), ("education", "教育学习"), ("entertainment", "休闲娱乐"), ("travel", "旅行住宿"), ("other", "其他用途")]
    static func title(_ id: String?) -> String? { options.first { $0.0 == id }?.1 }
}

extension FinanceLedgerStore {
    @discardableResult func setPurpose(id: String, purpose: String?) -> Bool {
        guard transaction(id: id) != nil, purpose == nil || LedgerPurpose.title(purpose) != nil else { return false }
        return update { root in
            guard let index = root.transactions.firstIndex(where: { $0.id == id }) else { return }
            root.transactions[index].purposeCategoryID = purpose
        }
    }
}
