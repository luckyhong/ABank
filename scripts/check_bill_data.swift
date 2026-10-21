import Foundation

@main struct BillDataChecks {
    @MainActor static func main() throws {
        let iso = ISO8601DateFormatter()
        let now = iso.date(from: "2026-10-16T04:00:00Z")!
        let dates = BankingDateContext(now: { now })
        precondition(dates.month("2026-01", offsetBy: -1) == "2025-12")
        precondition(dates.month("2024-03", offsetBy: -1) == "2024-02")
        precondition(dates.month("2026-12", offsetBy: 1) == "2027-01")
        precondition(dates.month("2026-13", offsetBy: 1) == nil && dates.month("2026-9", offsetBy: 0) == nil)
        precondition(dates.monthTitle("2026-09") == "2026年9月")

        for (cents, words) in [(Int64(0), "零元整"), (1, "壹分"), (50, "伍角整"), (1000, "壹拾元整"), (10001, "壹佰元零壹分"),
                               (12345, "壹佰贰拾叁元肆角伍分"), (1_010_000, "壹万零壹佰元整"), (5_000_000, "伍万元整"),
                               (10_001_001, "壹拾万零壹拾元零壹分"), (100_000_000, "壹佰万元整"), (10_000_000_100, "壹亿零壹元整")] {
            precondition(RMBUppercase.text(cents: cents) == words, "\(cents): \(RMBUppercase.text(cents: cents))")
        }
        print("PASS month arithmetic and RMB uppercase amounts")

        let suite = "ABank.BillChecks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let key = "abank.financeLedger.record.v8"
        let store = FinanceLedgerStore(defaults: defaults, dates: dates)
        let a = FinanceLedgerRecord.defaultAccountId
        let b = "acct_second"
        func tx(_ id: String, _ account: String, _ date: String, _ direction: LedgerTransactionDirection, _ amount: Double,
                _ category: String, counterparty: String = "", manual: Bool = false, include: Bool = true, note: String = "") -> LedgerTransaction {
            LedgerTransaction(id: id, accountId: account, date: date, time: "10:00:00", title: "交易-" + id, direction: direction,
                              amount: amount, balanceAfter: 0, iconKey: "pay", categoryId: category, isManual: manual,
                              includeInFlow: include, counterpartyName: counterparty, note: note)
        }
        let fixture = FinanceLedgerRecord(
            accounts: [LedgerAccount(id: a, tailNumber: "8472", currency: "人民币", balance: 0, openingBalance: 10_000),
                       LedgerAccount(id: b, tailNumber: "0999", currency: "人民币", balance: 0, openingBalance: 1_000)],
            transactions: [
                tx("old", a, "2025-10-05", .expense, 9, "other_expense"),
                tx("aug", a, "2026-08-12", .expense, 20, "other_expense"),
                tx("salary", a, "2026-09-01", .income, 5_000, "salary"),
                tx("friend", a, "2026-09-05", .expense, 100.10, "transfer_out", counterparty: "欧梦瑶"),
                tx("tiny", a, "2026-09-05", .expense, 0.2, "third_party_out"),
                tx("excluded", a, "2026-09-06", .expense, 30, "other_expense", include: false),
                tx("other", b, "2026-09-07", .expense, 0.1, "third_party_out"),
                tx("manual", a, "2026-09-08", .expense, 15, "other_expense", manual: true),
                tx("refund", a, "2026-10-01", .income, 66, "transfer_in", note: "报销")
            ],
            loanContracts: [], assetLiabilityAnnouncement: "演示", dataTimestamp: "2026-10-01 10:00:00")
        var seeded = fixture
        store.recalculate(&seeded)
        precondition(store.save(seeded))
        let persisted = defaults.data(forKey: key)

        // Month bill totals are integer cents and match the existing Mine/IncomeExpense projections.
        let september = store.monthlyBill(month: "2026-09")
        precondition(september.expenseInCents == 11_540 && september.incomeInCents == 500_000)
        precondition(september.balanceInCents == 488_460)
        precondition(september.flowCount == 5 && september.excludedCount == 1 && !september.isEmpty)
        precondition(TransferMoney.cents(from: store.mineMonthlyFlow(for: "2026-09").expense) == september.expenseInCents)
        precondition(TransferMoney.cents(from: store.incomeExpensePageData(month: "2026-09").summary.income) == september.incomeInCents)
        precondition(september.expenseCategories.map(\.categoryId) == ["transfer_out", "other_expense", "third_party_out"])
        precondition(september.expenseCategories.map(\.amountInCents) == [10_010, 1_500, 30])
        precondition(september.expenseCategories.last?.count == 2)
        precondition(abs(september.expenseCategories.reduce(0) { $0 + $1.ratio } - 1) < 0.000_001)
        precondition(september.expenseCategories.first?.title == "转账给他人")
        precondition(september.incomeCategories.map(\.categoryId) == ["salary"])
        precondition(september.topExpenses.map(\.id) == ["friend", "manual", "tiny"])
        precondition(september.topIncomes.map(\.id) == ["salary"])
        precondition(september.trend.map(\.month) == ["2026-04", "2026-05", "2026-06", "2026-07", "2026-08", "2026-09"])
        precondition(september.trend.last?.expenseInCents == september.expenseInCents)
        precondition(september.trend[4].expenseInCents == 2_000 && september.trend[3].expenseInCents == 0)
        print("PASS month totals in cents, excluded transactions, categories, ratios, top transactions and 6-month trend")

        let cardA = store.monthlyBill(month: "2026-09", accountFilter: .debitCard(id: a))
        precondition(cardA.expenseInCents == 10_030 && cardA.excludedCount == 1 && cardA.accountTitle == "借记卡8472")
        precondition(store.monthlyBill(month: "2026-09", accountFilter: .excludeManual).expenseInCents == 10_040)
        precondition(store.monthlyBill(month: "2026-09", accountFilter: .manual).expenseInCents == 1_500)
        let empty = store.monthlyBill(month: "2026-07")
        precondition(empty.isEmpty && empty.expenseCategories.isEmpty && empty.topExpenses.isEmpty && empty.trend.count == 6)
        let range = store.billMonthRange()
        precondition(range.earliest == "2025-10" && range.latest == "2026-10")
        precondition(store.defaultBillMonth == "2026-09")
        print("PASS account scopes, empty month and month range")

        // Search spans all months, ignores whitespace and case, and keeps newest first.
        precondition(store.searchTransactions(keyword: "欧 梦").map(\.id) == ["friend"])
        precondition(store.searchTransactions(keyword: "100.1").map(\.id) == ["friend"])
        precondition(store.searchTransactions(keyword: "报销").map(\.id) == ["refund"])
        precondition(store.searchTransactions(keyword: "工资").map(\.id) == ["salary"])
        precondition(store.searchTransactions(keyword: "交易-").first?.id == "refund")
        precondition(store.searchTransactions(keyword: "交易-").last?.id == "old")
        precondition(store.searchTransactions(keyword: "   ").isEmpty)
        precondition(store.searchTransactions(keyword: "0.10", accountFilter: .debitCard(id: b)).map(\.id) == ["other"])
        precondition(store.searchTransactions(keyword: "三方转出").count == 2)

        // Cross-month custom ranges group by full date (both 2025-10-05 and 2026-09-05 are day 5).
        var query = IncomeExpenseQuery(dateMode: .custom(start: "2025-10-01", end: "2026-09-30"))
        let groups = store.incomeExpensePageData(query: query).dayGroups
        precondition(Set(groups.map(\.date)).count == groups.count)
        precondition(groups.first?.date == "2026-09-08" && groups.last?.date == "2025-10-05")
        precondition(groups.first(where: { $0.date == "2026-09-05" })?.transactions.count == 2)
        precondition(IncomeExpenseDayGroup.spansMultipleMonths(groups))
        precondition(groups.last?.headerTitle(showsMonth: true) == "10月5日")
        query.dateMode = .month("2026-09")
        let monthGroups = store.incomeExpensePageData(query: query).dayGroups
        precondition(!IncomeExpenseDayGroup.spansMultipleMonths(monthGroups) && monthGroups.first?.headerTitle(showsMonth: false) == "8日")
        precondition(defaults.data(forKey: key) == persisted, "Bills and search are read-only")
        print("PASS transaction search and full-date grouping across months")

        // Detail edits feed straight back into the bill.
        store.updateTransactionDetail(id: "excluded", includeInFlow: true)
        store.updateTransactionDetail(id: "tiny", categoryId: "cash_withdraw")
        let edited = store.monthlyBill(month: "2026-09")
        precondition(edited.expenseInCents == 14_540 && edited.excludedCount == 0)
        precondition(edited.expenseCategories.first(where: { $0.categoryId == "cash_withdraw" })?.amountInCents == 20)
        precondition(edited.expenseCategories.first(where: { $0.categoryId == "third_party_out" })?.amountInCents == 10)
        print("PASS include-in-flow and category edits update the bill")

        // Receipts derive from successful simulated transfers only.
        precondition(store.transferReceipts().isEmpty && store.transferReceipt(transactionID: "friend") == nil)
        let draft = TransferDraft(payerAccountID: a, method: .account, recipientName: "演示客户", bankName: "中国建设银行",
                                  destination: "6217000000000593", amountInCents: 12_345, note: "房租")
        let transfer = try store.submitTransfer(draft: draft, requestID: "receipt")
        let receipt = store.transferReceipt(recordID: transfer.id)!
        precondition(store.transferReceipts().map(\.id) == [transfer.id])
        precondition(store.transferReceipt(transactionID: transfer.transactionID!) == receipt)
        precondition(receipt.transactionID == transfer.transactionID && receipt.amountInCents == 12_345)
        precondition(receipt.amountInWords == "壹佰贰拾叁元肆角伍分" && receipt.payerMaskedCard == "****8472")
        precondition(receipt.payeeMaskedDestination == "6217****0593" && receipt.createdAt == "2026-10-16 12:00:00")
        precondition(receipt.receiptNumber.hasPrefix("SIM20261016120000") && receipt.receiptNumber.count == 23)
        precondition(receipt.shareText.contains(TransferReceipt.simulationMark) && !receipt.shareText.contains(draft.destination))
        precondition(store.transferReceipts(accountID: b).isEmpty && store.transferReceipts(accountID: a).count == 1)
        precondition(store.monthlyBill(month: "2026-10").expenseCategories.first?.amountInCents == 12_345)
        precondition(store.searchTransactions(keyword: "演示客户").map(\.id) == [transfer.transactionID!])
        let restored = FinanceLedgerStore(defaults: defaults, dates: dates)
        precondition(restored.transferReceipt(recordID: transfer.id) == receipt, "Receipt number is stable after restart")
        _ = try restored.submitTransfer(draft: draft, requestID: "receipt")
        precondition(restored.transferReceipts().count == 1, "Idempotent retry must not duplicate receipts")

        let failing = FinanceLedgerStore(defaults: defaults, dates: dates, simulationSucceeds: { _ in false })
        let failed = try failing.submitTransfer(draft: draft, requestID: "failed")
        precondition(failed.status == .failed && failing.transferReceipt(recordID: failed.id) == nil)
        precondition(failing.transferReceipts().count == 1)
        let beforeRead = defaults.data(forKey: key)
        _ = store.transferReceipts()
        precondition(defaults.data(forKey: key) == beforeRead, "Receipts are read-only")
        print("PASS receipts for successful transfers only, masking, stable numbers, idempotency and bill/search linkage")
    }
}
