import Foundation

@main struct InsightsChecks {
    @MainActor static func main() throws {
        let suite = "ABank.InsightsChecks." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FinanceLedgerStore(defaults: defaults)
        let account = LedgerAccount(id: "a", tailNumber: "1234", currency: "人民币", balance: 1000, openingBalance: 1000)
        func tx(_ id: String, _ date: String, _ amount: Double, _ direction: LedgerTransactionDirection = .expense, _ included: Bool = true) -> LedgerTransaction {
            LedgerTransaction(id: id, accountId: "a", date: date, time: "12:00:00", title: "演示交易", direction: direction, amount: amount, balanceAfter: 0, iconKey: "", categoryId: direction == .expense ? "transfer_out" : "transfer_in", includeInFlow: included, note: "午餐退款")
        }
        precondition(store.save(FinanceLedgerRecord(accounts: [account], transactions: [tx("old", "2025-12-16", 10), tx("new", "2026-01-16", 20), tx("refund", "2026-01-17", 5, .income), tx("excluded", "2026-01-18", 50, .expense, false)], loanContracts: [], assetLiabilityAnnouncement: "", dataTimestamp: "")))
        let query = IncomeExpenseQuery(dateMode: .custom(start: "2025-12-01", end: "2026-01-31"))
        let page = store.incomeExpensePageData(query: query)
        precondition(page.dayGroups.map(\.date) == ["2026-01-18", "2026-01-17", "2026-01-16", "2025-12-16"])
        precondition(page.summary.expense == 30 && page.summary.income == 5)
        let january = IncomeExpenseQuery(dateMode: .month("2026-01"))
        let summary = store.analysis(query: january)
        precondition(summary.summary.expense == 20 && summary.summary.income == 5)
        precondition(summary.majorTransactions.count == 2 && summary.categories.allSatisfy { $0.share == 1 })
        precondition(store.searchTransactions(query: january, keyword: "退款 2026-01-18").map(\.id) == ["excluded"])
        precondition(store.searchTransactions(query: january, keyword: "不存在").isEmpty)
        precondition(store.analysis(query: .init(dateMode: .month("2027-01"))).categories.isEmpty)
        var filtered = january
        filtered.accountFilter = .debitCard(id: "missing")
        precondition(store.searchTransactions(query: filtered, keyword: "").isEmpty)
        store.updateTransactionDetail(id: "new", includeInFlow: false, categoryId: "other_expense", note: "修改备注")
        precondition(store.analysis(query: january).summary.expense == 0)
        precondition(store.searchTransactions(query: january, keyword: "修改备注").count == 1)
        let draft = TransferDraft(payerAccountID: "a", method: .account, recipientName: "模拟客户", bankName: "演示银行", destination: "6217000000000593", amountInCents: 100, note: "测试回单")
        let transfer = try store.submitTransfer(draft: draft, requestID: "receipt")
        let key = "abank.financeLedger.record.v8"
        let before = defaults.data(forKey: key)
        for _ in 0..<5 {
            let receipt = store.receiptRecords().first!
            precondition(receipt.id == transfer.id && receipt.transactionID == transfer.transactionID)
            precondition(receipt.receiptText.contains("转账电子回单") && !receipt.receiptText.contains("模拟交易"))
            precondition(!receipt.receiptText.contains(draft.destination))
            _ = store.analysis(query: query)
            _ = store.searchTransactions(query: query, keyword: "")
        }
        precondition(defaults.data(forKey: key) == before, "Read-only receipt and analysis must not write or deduct")
        precondition(store.receiptRecords(accountID: "missing").isEmpty)
        store.update { $0.transactions.removeAll { $0.id == transfer.transactionID } }
        precondition(store.receiptRecords().isEmpty, "Orphaned receipt must be unavailable")
        print("M2 insights checks passed")
    }
}
