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
        #if DEBUG
        try checkDebugLedger(dates: dates, defaults: defaults)
        #endif
    }

    #if DEBUG
    @MainActor private final class ChangeCount { var value = 0 }

    @MainActor private static func checkDebugLedger(dates: BankingDateContext, defaults: UserDefaults) throws {
        let store = FinanceLedgerStore(defaults: defaults, dates: dates)
        let accountID = FinanceLedgerRecord.defaultAccountId
        let otherID = "electronic_debug_test"
        let key = "abank.financeLedger.record.v8"
        var original = store.load()
        original.accounts.append(LedgerAccount(id: otherID, tailNumber: "0022", currency: "人民币", balance: 0, openingBalance: 0))
        try store.persist(original)
        let initialBytes = defaults.data(forKey: key)
        let changes = ChangeCount()
        let observer = NotificationCenter.default.addObserver(forName: .financeLedgerDidChange, object: nil, queue: nil) { _ in
            MainActor.assumeIsolated { changes.value += 1 }
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        func draft(_ operation: DebugLedgerDraft.Operation, _ cents: Int64, account: String = accountID,
                   date: Date? = nil, include: Bool = true) -> DebugLedgerDraft {
            DebugLedgerDraft(accountID: account, operation: operation, amountInCents: cents, date: date,
                             summary: "", counterparty: "模拟对方", note: "调试备注", includeInFlow: include)
        }
        func post(_ draft: DebugLedgerDraft) throws -> String {
            let preview = try store.previewDebugEntry(draft)
            try store.saveDebugEntry(draft, requestID: UUID(), expected: preview)
            return store.load().transactions.last!.id
        }
        func expectError<T, E: Error & Equatable>(_ expected: E, _ action: () throws -> T) {
            do {
                _ = try action()
                preconditionFailure("Expected \(expected)")
            } catch { precondition(error as? E == expected, "Unexpected error: \(error)") }
        }

        let backdated = draft(.transfer(.income), 1234, date: dates.date(from: "2026-08-15"))
        let preview = try store.previewDebugEntry(backdated)
        precondition(preview == DebugLedgerPreview(currentBalance: 107_000, newBalance: 108_234))
        precondition(changes.value == 0 && defaults.data(forKey: key) == initialBytes)
        let requestID = UUID()
        try store.saveDebugEntry(backdated, requestID: requestID, expected: preview)
        try store.saveDebugEntry(backdated, requestID: requestID, expected: preview)
        precondition(changes.value == 1)
        let historicalEntry = store.load().transactions.last!
        precondition(FinanceLedgerStore.isDebugEntry(historicalEntry) && historicalEntry.counterpartyName == "模拟对方")
        precondition(historicalEntry.note == "调试备注" && historicalEntry.balanceAfter == 982.34)
        precondition(store.transaction(id: "previous")?.balanceAfter == 1082.34)
        precondition(store.incomeExpensePageData(month: "2026-08").summary.income == 12.34)
        precondition(store.widgetSnapshot()?.balanceInCents == 108_234 && store.widgetSnapshot()?.monthIncomeInCents == 0)
        var filter = AccountDetailQueryFilter.default(referenceDate: dates.now)
        filter.applyCustom(start: "2026-08-01", end: "2026-08-31")
        let statement = store.accountDetailQueryPageData(accountId: accountID, filter: filter)
        precondition(statement.transactions.map(\.id) == [historicalEntry.id, "history"])
        precondition(FinanceLedgerStore(defaults: defaults, dates: dates).load() == store.load())
        expectError(DebugLedgerError.missingEntry) { try store.removeDebugEntry(id: "history") }

        let credit = try post(draft(.transfer(.income), 501, account: otherID))
        let debit = try post(draft(.transfer(.expense), 1, account: otherID))
        precondition(store.account(id: otherID)?.balance == 5 && store.account(id: accountID)?.balance == 1082.34)
        let zero = draft(.targetBalance, 0, account: otherID, include: false)
        let zeroID = try post(zero)
        precondition(store.account(id: otherID)?.balance == 0)
        precondition(store.monthlyFlow(for: dates.currentMonth).income == 5.01)
        precondition(store.monthlyFlow(for: dates.currentMonth).expense == 0.01)
        precondition(store.widgetSnapshot()?.monthExpenseInCents == 1)
        let emptyPreview = try store.previewDebugEntry(zero)
        precondition(emptyPreview.change == 0)
        let beforeNoChange = changes.value
        try store.saveDebugEntry(zero, requestID: UUID(), expected: emptyPreview)
        precondition(changes.value == beforeNoChange)
        expectError(DebugLedgerError.insufficientBalance) { try store.removeDebugEntry(id: credit) }
        expectError(DebugLedgerError.insufficientBalance) { try store.previewDebugEntry(draft(.transfer(.expense), 1, account: otherID)) }
        try store.removeDebugEntry(id: zeroID)
        try store.removeDebugEntry(id: debit)
        try store.removeDebugEntry(id: credit)
        try store.removeDebugEntry(id: historicalEntry.id)
        precondition(store.load().accounts == original.accounts && store.load().transactions == original.transactions)
        precondition(store.totalAssets() == 1070 && store.assetLiabilityPageData().totalAssets == 1070)
        precondition(store.load().transferRecords == original.transferRecords)

        let oldPreview = try store.previewDebugEntry(zero)
        _ = try post(draft(.transfer(.income), 1, account: otherID))
        expectError(DebugLedgerError.balanceChanged) { try store.saveDebugEntry(zero, requestID: UUID(), expected: oldPreview) }
        expectError(DebugLedgerError.invalidAmount) { try store.previewDebugEntry(draft(.transfer(.income), 0)) }
        expectError(DebugLedgerError.invalidDate) { try store.previewDebugEntry(draft(.transfer(.income), 1, date: dates.now.addingTimeInterval(3600))) }
        expectError(DebugLedgerError.missingAccount) { try store.previewDebugEntry(draft(.targetBalance, 0, account: "missing")) }
        expectError(DebugLedgerError.insufficientBalance) {
            try store.previewDebugEntry(draft(.transfer(.expense), 100_000, date: dates.date(from: "2026-08-15")))
        }
        let beforeFailure = defaults.data(forKey: key)
        let failureCount = changes.value
        let failingStore = FinanceLedgerStore(defaults: defaults, dates: dates, dataWriter: { _ in throw DebugLedgerError.persistence })
        let latestPreview = try failingStore.previewDebugEntry(backdated)
        expectError(DebugLedgerError.persistence) { try failingStore.saveDebugEntry(backdated, requestID: UUID(), expected: latestPreview) }
        precondition(defaults.data(forKey: key) == beforeFailure && changes.value == failureCount)
        let corrupt = Data([0x00, 0xff])
        defaults.set(corrupt, forKey: key)
        expectError(TransferError.corruptLedger) { try store.previewDebugEntry(backdated) }
        expectError(TransferError.corruptLedger) { try store.saveDebugEntry(backdated, requestID: UUID(), expected: latestPreview) }
        precondition(defaults.data(forKey: key) == corrupt && changes.value == failureCount)
        print("PASS debug ledger previews, idempotency, historical balances, multiple accounts, projections, undo, stale balance and persistence failures")
    }
    #endif
}
