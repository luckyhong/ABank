import Foundation

@main @MainActor struct LedgerFixtureChecks {
    static let key = "abank.financeLedger.record.v8"
    static let dates = BankingDateContext(now: { ISO8601DateFormatter().date(from: "2026-11-16T12:00:00Z")! })
    static func cents(_ amount: Double) -> Int64 { TransferMoney.cents(from: amount)! }

    static func withDefaults(_ body: (UserDefaults) throws -> Void) rethrows {
        let suite = "ABank.FixtureChecks." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        try body(defaults)
    }

    static func main() throws {
        try exactFixtureAndProjections()
        try incrementalMigration()
        try metadataCorrectionMigration()
        try weChatSupplementMigration()
        try migrationAndPreservation()
        contractDetailsMigration()
        try failedMigrationAndCorruption()
        try customLoanAndUnrecognizedRecord()
        print("Ledger fixture checks passed: canonical cents, ordering, projections, loan schedule, migration and failure preservation")
    }

    static func exactFixtureAndProjections() throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: "docs/analysis/ledger-data-20261116.json"))
        let expected = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let rows = expected["transactions"] as! [[String: Any]]
        let seed = FinanceLedgerStore.makeSeedRecord()
        precondition(seed.demoDataVersion == BankingDemoFixture.version && seed.transactions.count == rows.count + 1)
        let originalData = try Data(contentsOf: URL(fileURLWithPath: "docs/analysis/ledger-data-20261110.json"))
        let originalRows = (try JSONSerialization.jsonObject(with: originalData) as! [String: Any])["transactions"] as! [[String: Any]]
        let financialKeys = ["id", "sequence", "account_id", "date", "time", "time_precision", "direction", "amount_cents", "balance_before_cents", "balance_after_cents", "category_id", "include_in_account_flow", "is_manual"]
        for (old, current) in zip(originalRows, rows.prefix(37)) {
            for key in financialKeys { precondition((old[key] as? NSObject) == (current[key] as? NSObject), "Financial field changed: \(key)") }
        }
        let added = seed.transactions[rows.count - 1]
        precondition(added.id == "fixture-2026-11-16-transfer-to-ou" && added.date == "2026-11-16" && added.time == "10:45")
        precondition(added.datetimeText == "2026-11-16 10:45" && added.counterpartyName == "欧梦瑶" && added.title == "转支")
        precondition(added.direction == .expense && cents(added.amount) == 300_000 && added.categoryId == "transfer_out" && added.includeInFlow && !added.isManual)
        precondition(added.counterpartyAccount == "6217****0593" && added.counterpartyBank == "建设银行" && added.channel == "掌上银行")
        let supplementData = try Data(contentsOf: URL(fileURLWithPath: "docs/analysis/ledger-supplement-20261118.json"))
        let supplement = try JSONSerialization.jsonObject(with: supplementData) as! [String: Any]
        let referenceRow = supplement["transaction"] as! [String: Any]
        let weChat = seed.transactions.last!
        precondition(weChat.id == referenceRow["id"] as! String)
        precondition(weChat.date == referenceRow["date"] as! String && weChat.time == referenceRow["time"] as! String)
        precondition(weChat.title == "微信支付" && weChat.summary == "微信支付" && weChat.transactionType == "转账")
        precondition(weChat.direction == .expense && cents(weChat.amount) == 120_000 && cents(weChat.balanceAfter) == 406_923)
        precondition(weChat.categoryId == "third_party_out" && weChat.includeInFlow && !weChat.isManual)
        precondition(seed.transferRecords.isEmpty, "No bank instruction generated from a historical bill")
        for row in seed.transactions where BankingDemoFixture.correctedTransactionIDs.contains(row.id) {
            precondition(row.title == "转支" && row.summary == "转支" && row.counterpartyName == "欧梦瑶" && row.counterpartyBank == "建设银行")
        }
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
            precondition(first == seed && cents(store.totalAssets()) == 406_923 && cents(store.totalLiabilities()) == 1_412_674)
            var recent = AccountDetailQueryFilter.default(referenceDate: dates.now)
            recent.applyCustom(start: weChat.date, end: weChat.date)
            precondition(store.accountDetailQueryPageData(filter: recent).transactions.map(\.id) == [weChat.id])
            var recalculated = first
            store.recalculate(&recalculated)
            precondition(recalculated == first, "Integer-cent recomputation must preserve every reference balance")
            let saved = defaults.data(forKey: key)!
            precondition(FinanceLedgerStore(defaults: defaults, dates: dates).load() == first)
            precondition(defaults.data(forKey: key) == saved && defaults.data(forKey: FinanceLedgerStore.demoBackupKey) == nil)

            let monthly: [(String, Int64, Int64)] = [("2026-09",1_575_206,1_606_466), ("2026-10",1_450_670,1_470_817), ("2026-11",2_117_706,1_721_342)]
            for (month, income, expense) in monthly {
                let summary = store.incomeExpensePageData(month: month).summary
                precondition(cents(summary.income) == income && cents(summary.expense) == expense)
            }
            let snap = store.widgetSnapshot()!
            precondition(snap.balanceInCents == 406_923 && snap.monthIncomeInCents == 2_117_706 && snap.monthExpenseInCents == 1_721_342)

            var filter = AccountDetailQueryFilter.default(referenceDate: dates.now)
            precondition(store.accountDetailQueryPageData(filter: filter).transactions.count == 6)
            filter.applyQuickRange(.month, referenceDate: dates.now)
            precondition(store.accountDetailQueryPageData(filter: filter).transactions.count == 15)
            filter.applyQuickRange(.threeMonths, referenceDate: dates.now)
            precondition(store.accountDetailQueryPageData(filter: filter).transactions.count == 36)
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
            precondition(page.planItems.count == 131 && page.detailItems.count == 3 && planned.count == 131)
            for (plan, reference) in zip(planned, reference) {
                precondition(plan.date == reference["due_date"] as! String)
                precondition(cents(plan.repaymentAmount) == 12_791)
                precondition(cents(plan.principal) == (reference["principal_repaid_cents"] as! NSNumber).int64Value)
                precondition(cents(plan.interest) == (reference["interest_cents"] as! NSNumber).int64Value)
                precondition(cents(plan.balance) == (reference["closing_principal_cents"] as! NSNumber).int64Value)
            }
            precondition(planned.last?.date == "2037-10-08" && planned.last?.balance == 0)
            let upcoming = store.loanRepaymentPageData(contractId: loan.id, filter: .default(tab: .plan, dates: dates))
            let paid = store.loanRepaymentPageData(contractId: loan.id, filter: .default(tab: .detail, dates: dates))
            precondition(upcoming.planItems.prefix(3).map(\.date) == ["2026-12-09", "2027-01-09", "2027-02-09"])
            precondition(upcoming.planItems.first?.repaymentAmount == store.loanDuePageData(period: .nextMonth).totalAmount)
            precondition(paid.detailItems.map(\.date) == ["2026-09-09", "2026-10-09", "2026-11-09"])
            precondition(paid.detailItems.allSatisfy { cents($0.principal) + cents($0.interest) == 12_791 })
            let missing = store.loanRepaymentPageData(contractId: "missing", filter: loanFilter)
            precondition(missing.planItems.isEmpty && missing.detailItems.isEmpty)
            let history = store.loanUsageRecordsPageData(contractId: loan.id, page: 0).records
            precondition(history.count == 3 && history.allSatisfy { cents($0.totalAmount) == 12_791 })
            precondition(cents(store.loanDuePageData(period: .nextMonth).totalAmount) == 12_791)
            precondition(store.loanPrepaymentInfo(contractId: loan.id)?.contractNumber == FinanceLedgerStore.legacyHousingContract.contractNumber)
            let preview = try store.previewPrepayment(contractID: loan.id, amountInCents: 10_000, method: .shortenTerm)
            precondition(preview.maturityBefore == "2037-10-08")
            _ = try store.submitPrepayment(contractID: loan.id, amountInCents: 10_000, method: .shortenTerm, requestID: "new-loan-test", expected: preview)
            let changed = store.loanContract(id: loan.id)!
            precondition(changed.finalDueDate == preview.maturityAfter && cents(changed.unpaidPrincipal) == 1_402_674)
            precondition(cents(store.load().accounts[0].balance) == 396_923)
        }
    }

    static func previousFixture() -> FinanceLedgerRecord {
        var record = FinanceLedgerStore.makeSeedRecord()
        record.transactions.removeAll { BankingDemoFixture.addedTransactionIDs.contains($0.id) || $0.id == BankingDemoFixture.latestTransactionID }
        let raw = try! Data(contentsOf: URL(fileURLWithPath: "docs/analysis/ledger-data-20261110.json"))
        let oldRows = (try! JSONSerialization.jsonObject(with: raw) as! [String: Any])["transactions"] as! [[String: Any]]
        for index in record.transactions.indices {
            let old = oldRows[index]
            record.transactions[index].title = old["title"] as! String
            record.transactions[index].summary = old["title"] as! String
            record.transactions[index].counterpartyName = old["counterparty_name"] as? String ?? ""
            record.transactions[index].counterpartyAccount = old["counterparty_account_masked"] as? String ?? ""
            record.transactions[index].counterpartyBank = ""
            record.transactions[index].channel = old["channel"] as? String ?? "—"
        }
        record.accounts[0].balance = 8269.23
        record.demoDataVersion = BankingDemoFixture.previousVersion
        record.dataTimestamp = "2026-11-10 19:22:30"
        return record
    }

    static func incrementalMigration() throws {
        try withDefaults { defaults in
            let old = previousFixture()
            let bytes = try JSONEncoder().encode(old)
            defaults.set(bytes, forKey: key)
            let oldBackup = Data("previous-backup".utf8)
            defaults.set(oldBackup, forKey: FinanceLedgerStore.demoBackupKey)
            let store = FinanceLedgerStore(defaults: defaults, dates: dates)
            let migrated = try store.loadForTransfer()
            precondition(migrated == FinanceLedgerStore.makeSeedRecord())
            precondition(defaults.data(forKey: FinanceLedgerStore.demoSupplementBackupKey) == bytes)
            precondition(defaults.data(forKey: FinanceLedgerStore.demoBackupKey) == oldBackup)
            let committed = defaults.data(forKey: key)
            _ = store.load(); _ = try store.loadForTransfer()
            precondition(defaults.data(forKey: key) == committed && store.load().transactions.count == 39)
        }
        try withDefaults { defaults in
            var old = previousFixture()
            old.accounts[0].alias = "生活卡"; old.accounts[0].openingBalance += 100
            old.accounts[0].permissions.onlinePayment = false; old.accounts[0].isReportedLost = true
            old.accounts.append(LedgerAccount(id: "extra-account", tailNumber: "7890", currency: "人民币", balance: 50, openingBalance: 50))
            old.transactions[0].note = "保留用户备注"; old.transactions[0].purposeCategoryID = "food"
            old.transactions[0].includeInFlow = false
            old.loanContracts[0].unpaidPrincipal -= 90
            old.transactions.append(LedgerTransaction(id: "user_extra", accountId: old.accounts[0].id, date: "2026-11-12", time: "12:01:03", title: "附加入账", direction: .income, amount: 12.34, balanceAfter: 0, iconKey: "", categoryId: "transfer_in"))
            let store = FinanceLedgerStore(defaults: defaults, dates: dates)
            store.recalculate(&old)
            let bytes = try JSONEncoder().encode(old); defaults.set(bytes, forKey: key)
            var expected = old
            let baseline = FinanceLedgerStore.makeSeedRecord()
            let existingIDs = Set(old.transactions.map(\.id))
            expected.transactions += baseline.transactions.filter { !existingIDs.contains($0.id) }
            for index in expected.transactions.indices where BankingDemoFixture.correctedTransactionIDs.contains(expected.transactions[index].id) {
                let correct = baseline.transactions.first { $0.id == expected.transactions[index].id }!
                expected.transactions[index].title = correct.title; expected.transactions[index].summary = correct.summary
                expected.transactions[index].counterpartyName = correct.counterpartyName
                expected.transactions[index].counterpartyAccount = correct.counterpartyAccount
                expected.transactions[index].counterpartyBank = correct.counterpartyBank
                expected.transactions[index].channel = correct.channel
            }
            expected.demoDataVersion = BankingDemoFixture.version; expected.dataTimestamp = baseline.dataTimestamp
            store.recalculate(&expected)
            let migrated = try store.loadForTransfer()
            precondition(migrated == expected, "Every custom field and earlier balance remains intact")
            precondition(cents(store.load().accounts[0].balance) == 418_157 && store.load().accounts[1].balance == 50)
            precondition(defaults.data(forKey: FinanceLedgerStore.demoSupplementBackupKey) == bytes)
        }
        try withDefaults { defaults in
            let old = previousFixture(), bytes = try JSONEncoder().encode(old)
            defaults.set(bytes, forKey: key)
            let broken = FinanceLedgerStore(defaults: defaults, dates: dates, dataWriter: { _ in throw TransferError.persistence })
            do { _ = try broken.loadForTransfer(); preconditionFailure() } catch { precondition(error as? TransferError == .persistence) }
            precondition(defaults.data(forKey: key) == bytes && broken.load() == old)
            precondition(defaults.data(forKey: FinanceLedgerStore.demoSupplementBackupKey) == bytes)
            precondition(FinanceLedgerStore(defaults: defaults, dates: dates).load().transactions.count == 39)
        }
        for scenario in 0..<3 {
            try withDefaults { defaults in
                var old = previousFixture()
                if scenario == 0 { old.transactions.append(FinanceLedgerStore.makeSeedRecord().transactions.last!) }
                if scenario == 1 { old.transactions.removeFirst() }
                if scenario == 2 { old.demoDataVersion = "unrecognized-version" }
                let bytes = try JSONEncoder().encode(old); defaults.set(bytes, forKey: key)
                precondition(FinanceLedgerStore(defaults: defaults, dates: dates).load() == old)
                precondition(defaults.data(forKey: key) == bytes && defaults.data(forKey: FinanceLedgerStore.demoSupplementBackupKey) == nil)
            }
        }
    }

    static func previousSupplementFixture() -> FinanceLedgerRecord {
        var record = previousFixture()
        var added = FinanceLedgerStore.makeSeedRecord().transactions.first { BankingDemoFixture.addedTransactionIDs.contains($0.id) }!
        added.title = "转出（欧）"; added.summary = added.title; added.counterpartyName = "欧"
        added.counterpartyAccount = ""; added.counterpartyBank = ""; added.channel = "—"
        record.transactions.append(added); record.accounts[0].balance = 5269.23
        record.demoDataVersion = BankingDemoFixture.previousSupplementVersion; record.dataTimestamp = "2026-11-16 10:45"
        return record
    }

    static func metadataCorrectionMigration() throws {
        try withDefaults { defaults in
            let old = previousSupplementFixture()
            let encoded = try JSONEncoder().encode(old)
            var object = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
            var rows = object["transactions"] as! [[String: Any]]
            for index in rows.indices { rows[index].removeValue(forKey: "counterpartyBank") }
            object["transactions"] = rows
            let bytes = try JSONSerialization.data(withJSONObject: object)
            precondition(try! JSONDecoder().decode(FinanceLedgerRecord.self, from: bytes).transactions.allSatisfy { $0.counterpartyBank.isEmpty })
            defaults.set(bytes, forKey: key)
            let earlierBackup = Data("append-backup-preserved".utf8)
            defaults.set(earlierBackup, forKey: FinanceLedgerStore.demoSupplementBackupKey)
            let store = FinanceLedgerStore(defaults: defaults, dates: dates)
            precondition(store.load() == FinanceLedgerStore.makeSeedRecord())
            precondition(store.load().transactions.count == 39 && cents(store.load().accounts[0].balance) == 406_923)
            precondition(defaults.data(forKey: FinanceLedgerStore.demoDetailCorrectionBackupKey) == bytes)
            precondition(defaults.data(forKey: FinanceLedgerStore.demoSupplementBackupKey) == earlierBackup)
            let committed = defaults.data(forKey: key); _ = store.load()
            precondition(defaults.data(forKey: key) == committed, "Metadata correction and WeChat supplement must run only once")
        }
        try withDefaults { defaults in
            var old = previousSupplementFixture()
            let index = old.transactions.count - 1
            old.transactions[index].note = "用户备注"; old.transactions[index].purposeCategoryID = "housing"
            old.transactions[index].counterpartyName = "自定义姓名"; old.transactions[index].counterpartyBank = "用户填写银行"
            let bytes = try JSONEncoder().encode(old); defaults.set(bytes, forKey: key)
            let updated = FinanceLedgerStore(defaults: defaults, dates: dates).load().transactions[index]
            precondition(updated.title == "转支" && updated.summary == "转支" && updated.counterpartyName == "自定义姓名" && updated.counterpartyBank == "用户填写银行")
            precondition(updated.note == "用户备注" && updated.purposeCategoryID == "housing" && cents(updated.balanceAfter) == 526_923)
        }
        try withDefaults { defaults in
            let old = previousSupplementFixture(), bytes = try JSONEncoder().encode(old)
            defaults.set(bytes, forKey: key)
            let store = FinanceLedgerStore(defaults: defaults, dates: dates, dataWriter: { _ in throw TransferError.persistence })
            do { _ = try store.loadForTransfer(); preconditionFailure() } catch { precondition(error as? TransferError == .persistence) }
            precondition(defaults.data(forKey: key) == bytes && store.load() == old)
            precondition(defaults.data(forKey: FinanceLedgerStore.demoDetailCorrectionBackupKey) == bytes)
        }
    }

    static func weChatSupplementMigration() throws {
        try withDefaults { defaults in
            let seed = FinanceLedgerStore.makeSeedRecord()
            var old = seed
            old.transactions.removeLast()
            old.demoDataVersion = BankingDemoFixture.previousCorrectedVersion
            old.dataTimestamp = "2026-11-16 10:45"
            old.accounts[0].alias = "生活卡"
            old.transactions[0].note = "保留备注"
            let store = FinanceLedgerStore(defaults: defaults, dates: dates)
            store.recalculate(&old)
            let bytes = try JSONEncoder().encode(old)
            defaults.set(bytes, forKey: key)

            let failingStore = FinanceLedgerStore(defaults: defaults, dates: dates, dataWriter: { _ in throw TransferError.persistence })
            precondition(failingStore.load() == old && defaults.data(forKey: key) == bytes)
            precondition(defaults.data(forKey: FinanceLedgerStore.demoWeChatBackupKey) == bytes)

            let migrated = try store.loadForTransfer()
            precondition(Array(migrated.transactions.dropLast()) == old.transactions)
            precondition(migrated.transactions.last == seed.transactions.last)
            precondition(migrated.loanContracts == old.loanContracts && migrated.transferRecords == old.transferRecords)
            precondition(migrated.accounts[0].alias == old.accounts[0].alias)
            precondition(cents(old.accounts[0].balance) - cents(migrated.accounts[0].balance) == 120_000)
            precondition(migrated.demoDataVersion == seed.demoDataVersion && migrated.dataTimestamp == seed.dataTimestamp)
            let saved = defaults.data(forKey: key)
            precondition(FinanceLedgerStore(defaults: defaults, dates: dates).load() == migrated)
            precondition(defaults.data(forKey: key) == saved && defaults.data(forKey: FinanceLedgerStore.demoWeChatBackupKey) == bytes)
        }
    }

    static func contractDetailsMigration() {
        withDefaults { defaults in
            let store = FinanceLedgerStore(defaults: defaults, dates: dates)
            var baseline = FinanceLedgerStore.makeSeedRecord()
            baseline.loanContracts[0].contractNumber = ""
            baseline.loanContracts[0].contractLimit = 0
            baseline.loanContracts[0].loanAmount = 0
            baseline.loanContracts[0].disbursementDateText = ""
            baseline.loanContracts[0].expiryDate = baseline.loanContracts[0].finalDueDate!
            baseline.loanContracts[0].pricingMethod = "固定利率"
            baseline.loanContracts[0].pricingBenchmark = ""
            baseline.loanContracts[0].floatingRange = ""
            baseline.loanContracts[0].repricingCycle = ""
            baseline.loanContracts[0].repricingDatesText = ""
            baseline.loanContracts[0].isDetailExpanded = false
            baseline.loanContracts[0].unpaidPrincipal = 13_000
            baseline.loanContracts[0].installmentAmount = 120
            precondition(store.save(baseline))
            let migrated = store.load()
            let loan = migrated.loanContracts[0]
            precondition(loan.contractLimit == 670_000 && loan.loanAmount == 670_000)
            precondition(loan.expiryDate == "2047-09-14" && loan.finalDueDate == baseline.loanContracts[0].finalDueDate)
            precondition(loan.pricingMethod == "浮动利率" && loan.pricingBenchmark == "LPR" && loan.floatingRange == "-30bp")
            precondition(loan.disbursementDateText == "2017年10月9日" && loan.repricingCycle == "3个月")
            precondition(loan.unpaidPrincipal == 13_000 && loan.installmentAmount == 120 && !loan.isDetailExpanded)
            precondition(loan.recordedRepayments == baseline.loanContracts[0].recordedRepayments && loan.contractNumber == FinanceLedgerStore.legacyHousingContract.contractNumber)
            precondition(migrated.transactions == baseline.transactions && migrated.accounts == baseline.accounts)
            precondition(defaults.data(forKey: FinanceLedgerStore.demoContractDetailsBackupKey) != nil)
            precondition(store.load() == migrated)
        }
        withDefaults { defaults in
            let store = FinanceLedgerStore(defaults: defaults, dates: dates)
            var baseline = FinanceLedgerStore.makeSeedRecord()
            baseline.demoDataVersion = nil
            baseline.loanContracts[0].contractNumber = ""
            baseline.loanContracts[0].pricingMethod = "浮动利率"
            baseline.loanContracts[0].pricingBenchmark = ""
            baseline.loanContracts[0].floatingRange = ""
            baseline.loanContracts[0].repricingCycle = ""
            baseline.loanContracts[0].repricingDatesText = ""
            baseline.loanContracts[0].finalDueDate = "2035-05-09"
            baseline.loanContracts[0].maturityDateText = ""
            baseline.loanContracts[0].statusText = ""
            precondition(store.save(baseline))
            let migrated = store.load()
            let loan = migrated.loanContracts[0]
            precondition(loan.pricingBenchmark == "LPR" && loan.floatingRange == "-30bp")
            precondition(migrated.demoDataVersion == nil && loan.contractNumber == FinanceLedgerStore.legacyHousingContract.contractNumber)
            let page = store.loanRepaymentPageData(contractId: loan.id, filter: .init(quickRange: .custom, startDate: "2026-09-01", endDate: "2027-01-01", sortOrder: .farToNear))
            precondition(page.planItems.first?.contractNumber == loan.contractNumber && page.detailItems.first?.contractNumber == loan.contractNumber)
            precondition(loan.repricingCycle == "3个月" && loan.repricingDatesText == "1月9日,4月9日,7月9日,10月9日")
            precondition(loan.maturityDateText == "2035年5月9日" && loan.statusText == "正常")
            precondition(migrated.accounts == baseline.accounts && migrated.transactions == baseline.transactions)
            precondition(store.load() == migrated)
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
            precondition(changed.transactions.count == 40 && changed.accounts[0].alias == "生活卡")
            precondition(cents(changed.accounts[0].balance) == 418_157, "Preserve additional opening adjustment and new transaction")
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
            precondition(cents(recovered.accounts[0].balance) == 406_923)
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
