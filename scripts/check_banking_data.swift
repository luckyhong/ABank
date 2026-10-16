import Foundation

@main struct BankingDataChecks {
    @MainActor static func main() throws {
        let iso = ISO8601DateFormatter()
        var now = iso.date(from: "2026-12-31T16:05:00Z")!
        let dates = BankingDateContext(now: { now })
        precondition(dates.currentMonth == "2027-01")
        precondition(dates.previousMonth == "2026-12")
        precondition(dates.previousMonthTitle == "2026年12月份")
        precondition(dates.string(from: dates.now) == "2027-01-01")
        precondition(dates.date(from: "2027-02-30") == nil)
        precondition(dates.date(from: "2027-2-01") == nil)
        now = iso.date(from: "2024-03-30T16:01:00Z")!
        precondition(dates.previousMonth == "2024-02", "Month arithmetic must anchor to the start of the month")
        precondition(dates.previousMonthTitle == "2月份")
        precondition(dates.date(from: "2024-02-29") != nil)

        var filter = AccountDetailQueryFilter.default(referenceDate: now)
        precondition(filter.startDate == "2024-03-24" && filter.endDate == "2024-03-31")
        filter.applyQuickRange(.month, referenceDate: now)
        precondition(filter.startDate == "2024-02-29")
        filter.applyCustom(start: "2026-08-01", end: "2026-08-31")
        precondition(filter.quickRange == .custom && filter.startDate == "2026-08-01")
        print("PASS Beijing midnight/year boundary, month end, leap year, strict date parsing and account ranges")

        let suite = "ABank.BankingChecks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        now = iso.date(from: "2026-10-16T04:00:00Z")!
        let store = FinanceLedgerStore(defaults: defaults, dates: dates)
        let accountID = FinanceLedgerRecord.defaultAccountId
        let transactions = [
            LedgerTransaction(id: "history", accountId: accountID, date: "2026-08-12", time: "12:00:00",
                              title: "历史交易", direction: .expense, amount: 20, balanceAfter: 980, iconKey: "pay", categoryId: "food", note: "保留的编辑"),
            LedgerTransaction(id: "previous", accountId: accountID, date: "2026-09-20", time: "12:00:00",
                              title: "上月交易", direction: .income, amount: 100, balanceAfter: 1080, iconKey: "salary", categoryId: "salary")
        ]
        let original = FinanceLedgerRecord(
            accounts: [LedgerAccount(id: accountID, tailNumber: "8472", currency: "人民币", balance: 1080, openingBalance: 1000)],
            transactions: transactions, loanContracts: [], assetLiabilityAnnouncement: "演示", dataTimestamp: "2026-09-20 12:00:00")
        // Use the existing persisted root key to verify compatibility and absence of an implicit reset.
        let persisted = try JSONEncoder().encode(original)
        defaults.set(persisted, forKey: "abank.financeLedger.record.v8")
        precondition(store.load() == original)
        precondition(store.incomeExpensePageData().dayGroups.isEmpty)
        precondition(store.mineMonthlyFlow().income == 0 && store.mineMonthlyFlow().expense == 0)
        precondition(store.monthlyBillNotice == "您的9月份账单已出")
        precondition(!store.mineMonthlyFlow().hasBillBadge, "No invented unread bill badge")
        precondition(store.incomeExpensePageData(month: "2026-08").summary.expense == 20)
        precondition(defaults.data(forKey: "abank.financeLedger.record.v8") == persisted, "Reading must not rewrite the saved record")

        now = iso.date(from: "2026-11-01T00:00:00Z")!
        precondition(store.monthlyBillNotice == "10月份暂无收支记录")
        precondition(store.mineAssetLiability().billNotice == store.monthlyBillNotice)
        precondition(store.load() == original, "Advancing the clock must not regenerate transactions")
        precondition(store.incomeExpensePageData(month: "2026-08").summary.expense == 20)

        // A real local edit changes balances and timestamp; all projections read the same saved state.
        store.updateTransaction(id: "history", amount: 30)
        precondition(abs(store.totalAssets() - 1070) < 0.001)
        precondition(store.mineAssetLiability().assets == store.totalAssets())
        precondition(store.assetLiabilityPageData().totalAssets == store.totalAssets())
        precondition(store.incomeExpensePageData(month: "2026-08").summary.expense == 30)
        precondition(store.transaction(id: "history")?.date == "2026-08-12")
        precondition(store.transaction(id: "history")?.note == "保留的编辑")
        precondition(store.transaction(id: "previous")?.balanceAfter == 1070)
        precondition(store.load().dataTimestamp == "2026-11-01 08:00:00")
        let restored = FinanceLedgerStore(defaults: defaults, dates: dates)
        precondition(restored.load() == store.load())
        precondition(restored.load().transactions.count == original.transactions.count)
        print("PASS persisted v8 compatibility, current/empty/historical months, bill text, no generated transactions, edits and balance/timestamp projections")
    }
}
