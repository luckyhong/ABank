import Foundation

@main @MainActor struct LedgerFixtureChecks {
    static let key = "abank.financeLedger.record.v8"
    static let dates = BankingDateContext(now: { ISO8601DateFormatter().date(from: "2026-11-10T12:00:00Z")! })
    static func cents(_ amount: Double) -> Int64 { TransferMoney.cents(from: amount)! }

    static func withDefaults(_ body: (UserDefaults) throws -> Void) rethrows {
        let suite = "ABank.FixtureChecks." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        try body(defaults)
    }

    static func main() throws {
        try exactFixtureAndProjections()
        try migrationAndPreservation()
        try failedMigrationAndCorruption()
        try customLoanAndUnrecognizedRecord()
        print("Ledger fixture checks passed: canonical cents, ordering, projections, loan schedule, migration and failure preservation")
    }

    static func exactFixtureAndProjections() throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: "docs/analysis/ledger-data-20261110.json"))
        let expected = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let rows = expected["transactions"] as! [[String: Any]]
        let seed = FinanceLedgerStore.makeSeedRecord()
        precondition(seed.demoDataVersion == BankingDemoFixture.version && seed.transactions.count == 37)
        for (tx, row) in zip(seed.transactions, rows) {
            precondition(tx.id == row["id"] as! String && tx.date == row["date"] as! String)
            precondition(tx.time == (row["time"] as? String ?? ""))
            precondition(cents(tx.amount) == (row["amount_cents"] as! NSNumber).int64Value)
            precondition(cents(tx.balanceAfter) == (row["balance_after_cents"] as! NSNumber).int64Value)
            precondition(IncomeExpenseFilterCatalog.allCategoryIds.contains(tx.categoryId))
            if tx.time.isEmpty { precondition(tx.datetimeText == tx.date) }
        }
        try withDefaults { defaults in
            let store = FinanceLedgerStore(defaults: defaults, dates: dates)
            let first = store.load()
            precondition(first == seed && cents(store.totalAssets()) == 826_923 && cents(store.totalLiabilities()) == 1_412_674)
            var recalculated = first
            store.recalculate(&recalculated)
            precondition(recalculated == first, "Integer-cent recomputation must preserve every reference balance")
            let saved = defaults.data(forKey: key)!
            precondition(FinanceLedgerStore(defaults: defaults, dates: dates).load() == first)
            precondition(defaults.data(forKey: key) == saved && defaults.data(forKey: FinanceLedgerStore.demoBackupKey) == nil)

            let monthly: [(String, Int64, Int64)] = [("2026-09",1_575_206,1_606_466), ("2026-10",1_450_670,1_470_817), ("2026-11",2_117_706,1_301_342)]
            for (month, income, expense) in monthly {
                let summary = store.incomeExpensePageData(month: month).summary
                precondition(cents(summary.income) == income && cents(summary.expense) == expense)
            }
            let snap = store.widgetSnapshot()!
            precondition(snap.balanceInCents == 826_923 && snap.monthIncomeInCents == 2_117_706 && snap.monthExpenseInCents == 1_301_342)

            var filter = AccountDetailQueryFilter.default(referenceDate: dates.now)
            precondition(store.accountDetailQueryPageData(filter: filter).transactions.count == 8)
            filter.applyQuickRange(.month, referenceDate: dates.now)
            precondition(store.accountDetailQueryPageData(filter: filter).transactions.count == 21)
            filter.applyQuickRange(.threeMonths, referenceDate: dates.now)
            precondition(store.accountDetailQueryPageData(filter: filter).transactions.count == 37)
            filter.applyCustom(start: "2026-09-01", end: "2026-11-10")
            let visible = store.accountDetailQueryPageData(filter: filter).transactions
            precondition(visible.count == 31 && visible.first?.id == "fixture-2026-11-10-transfer-out")
            let october = visible.filter { $0.date == "2026-10-10" }.map(\.id)
            let ordered = first.transactions.filter { $0.date == "2026-10-10" }.map(\.id).reversed()
            precondition(october == Array(ordered), "Unknown display times must not invert salary/transfer ordering")
            precondition(!first.transactions.contains { $0.date == "2026-11-09" && $0.title == "微信支付" })

            let loan = first.loanContracts[0]
            precondition(loan.recordedRepayments?.count == 3 && !loan.hasOriginalContractDetails)
            let loanFilter = LoanRepaymentFilter(quickRange: .custom, startDate: "2026-09-01", endDate: "2037-10-31", sortOrder: .farToNear)
            let page = store.loanRepaymentPageData(contractId: loan.id, filter: loanFilter)
            let planned = page.planItems.filter { $0.date >= "2026-12-01" }
            let reference = (expected["loan"] as! [String: Any])["remaining_schedule"] as! [[String: Any]]
            precondition(page.planItems.count == 134 && page.detailItems.count == 3 && planned.count == 131)
            for (plan, reference) in zip(planned, reference) {
                precondition(plan.date == reference["due_date"] as! String)
                precondition(cents(plan.repaymentAmount) == 12_791)
                precondition(cents(plan.principal) == (reference["principal_repaid_cents"] as! NSNumber).int64Value)
                precondition(cents(plan.interest) == (reference["interest_cents"] as! NSNumber).int64Value)
                precondition(cents(plan.balance) == (reference["closing_principal_cents"] as! NSNumber).int64Value)
            }
            precondition(planned.last?.date == "2037-10-08" && planned.last?.balance == 0)
            let history = store.loanUsageRecordsPageData(contractId: loan.id, page: 0).records
            precondition(history.count == 3 && history.allSatisfy { cents($0.totalAmount) == 12_791 })
            precondition(cents(store.loanDuePageData(period: .nextMonth).totalAmount) == 12_791)
            precondition(store.loanPrepaymentInfo(contractId: loan.id)?.contractNumber == "—")
            let preview = try store.previewPrepayment(contractID: loan.id, amountInCents: 10_000, method: .shortenTerm)
            precondition(preview.maturityBefore == "2037-10-08")
            _ = try store.submitPrepayment(contractID: loan.id, amountInCents: 10_000, method: .shortenTerm, requestID: "new-loan-test", expected: preview)
            let changed = store.loanContract(id: loan.id)!
            precondition(changed.finalDueDate == preview.maturityAfter && cents(changed.unpaidPrincipal) == 1_402_674)
            precondition(cents(store.load().accounts[0].balance) == 816_923)
        }
    }

    static func migrationAndPreservation() throws {
        try withDefaults { defaults in
            let old = FinanceLedgerStore.makeLegacySeedRecord()
            let bytes = try JSONEncoder().encode(old)
            defaults.set(bytes, forKey: key)
            let store = FinanceLedgerStore(defaults: defaults, dates: dates)
            let updated = try store.loadForTransfer()
            precondition(updated == FinanceLedgerStore.makeSeedRecord())
            precondition(defaults.data(forKey: FinanceLedgerStore.demoBackupKey) == bytes)
            let committed = defaults.data(forKey: key)
            _ = store.load(); _ = try store.loadForTransfer()
            precondition(defaults.data(forKey: key) == committed, "Migration only runs once")
        }
        try withDefaults { defaults in
            var old = FinanceLedgerStore.makeLegacySeedRecord()
            old.accounts[0].alias = "生活卡"
            old.accounts[0].openingBalance += 100
            old.transactions[11].note = "保留备注"
            old.transactions[11].ledgerId = "family"
            old.transactions[11].includeInFlow = false
            old.transactions.append(LedgerTransaction(id: "user_extra", accountId: old.accounts[0].id, date: "2026-11-10", time: "20:00:00", title: "新增模拟收入", direction: .income, amount: 12.34, balanceAfter: 0, iconKey: "", categoryId: "transfer_in"))
            defaults.set(try JSONEncoder().encode(old), forKey: key)
            let store = FinanceLedgerStore(defaults: defaults, dates: dates)
            let changed = store.load()
            precondition(changed.transactions.count == 38 && changed.accounts[0].alias == "生活卡")
            precondition(cents(changed.accounts[0].balance) == 838_157, "Preserve additional opening adjustment and new transaction")
            let edited = store.transaction(id: "fixture-2026-08-22-alipay")!
            precondition(edited.note == "保留备注" && edited.ledgerId == "family" && !edited.includeInFlow)
            precondition(store.transaction(id: "user_extra") != nil)
        }
    }

    static func failedMigrationAndCorruption() throws {
        try withDefaults { defaults in
            let old = FinanceLedgerStore.makeLegacySeedRecord()
            let original = try JSONEncoder().encode(old)
            defaults.set(original, forKey: key)
            let broken = FinanceLedgerStore(defaults: defaults, dates: dates, dataWriter: { _ in throw TransferError.persistence })
            do { _ = try broken.loadForTransfer(); preconditionFailure("Migration should fail") }
            catch let error as TransferError { precondition(error == .persistence) }
            precondition(defaults.data(forKey: key) == original && broken.load() == old)
            precondition(defaults.data(forKey: FinanceLedgerStore.demoBackupKey) == original)
            let recovered = FinanceLedgerStore(defaults: defaults, dates: dates).load()
            precondition(cents(recovered.accounts[0].balance) == 826_923)
            let beforeEdit = defaults.data(forKey: key)
            precondition(!broken.updateTransactionDetail(id: "fixture-2026-08-15-alipay", note: "保存失败的备注"))
            precondition(defaults.data(forKey: key) == beforeEdit)

            let corrupt = Data("{broken-ledger".utf8)
            defaults.set(corrupt, forKey: key)
            let store = FinanceLedgerStore(defaults: defaults, dates: dates)
            _ = store.load() // 只读展示降级不能覆盖原字节。
            let changed = store.update { $0.transactions[0].note = "不得写回" }
            store.updateTransactionDetail(id: "fixture-2026-08-15-alipay", note: "不得写回")
            store.toggleLoanDetailExpanded(id: FinanceLedgerRecord.defaultLoanId)
            precondition(!changed && defaults.data(forKey: key) == corrupt)
        }
    }

    static func customLoanAndUnrecognizedRecord() throws {
        try withDefaults { defaults in
            var old = FinanceLedgerStore.makeLegacySeedRecord()
            old.loanContracts[0].unpaidPrincipal -= 100
            let customLoan = old.loanContracts[0]
            defaults.set(try JSONEncoder().encode(old), forKey: key)
            let changed = FinanceLedgerStore(defaults: defaults, dates: dates).load()
            precondition(changed.demoDataVersion == BankingDemoFixture.version && changed.loanContracts[0] == customLoan)
        }
        try withDefaults { defaults in
            var custom = FinanceLedgerStore.makeLegacySeedRecord()
            custom.transactions = []
            let bytes = try JSONEncoder().encode(custom)
            defaults.set(bytes, forKey: key)
            precondition(FinanceLedgerStore(defaults: defaults, dates: dates).load() == custom)
            precondition(defaults.data(forKey: key) == bytes && defaults.data(forKey: FinanceLedgerStore.demoBackupKey) == nil)
        }
        try withDefaults { defaults in
            var collision = FinanceLedgerStore.makeLegacySeedRecord()
            collision.transactions.append(FinanceLedgerStore.makeSeedRecord().transactions[0])
            let bytes = try JSONEncoder().encode(collision)
            defaults.set(bytes, forKey: key)
            precondition(FinanceLedgerStore(defaults: defaults, dates: dates).load() == collision)
            precondition(defaults.data(forKey: key) == bytes && defaults.data(forKey: FinanceLedgerStore.demoBackupKey) == nil)
        }
    }
}
