import Foundation

@main struct LoanChecks {
    @MainActor static func main() throws {
        seedSchedule()
        termsRule()
        installmentRule()
        maturity()
        try shortenSmallAmount()
        try previewShorten()
        try previewReduce()
        try amountRules()
        try legacyDecode()
        errorCopy()
        history()
        try submitShorten()
        try submitReduce()
        try linkedPages()
        try idempotentReplay()
        try changedWhileConfirming()
        try failuresUnchanged()
        try permissionsIgnored()
        try certificate()
        try tasks()
        try progress()
        totalsExcludeHistory()
        print("Loan checks passed")
    }

    static let dates = BankingDateContext(now: { ISO8601DateFormatter().date(from: "2026-11-08T02:00:00Z")! })
    static let rate = 3.2

    static func expect<E: Error & Equatable>(_ expected: E, _ body: () throws -> Void, _ label: String) {
        do {
            try body()
            preconditionFailure("\(label): expected \(expected), got success")
        } catch let error as E {
            precondition(error == expected, "\(label): expected \(expected), got \(error)")
        } catch {
            preconditionFailure("\(label): unexpected \(error)")
        }
    }

    static func cents(_ value: Double) -> Int64 { TransferMoney.cents(from: value)! }

    // 旧贷款数值保留为算法兼容性向量，新默认数据另由check_ledger_fixture覆盖。
    static var seedContract: LoanContract { FinanceLedgerStore.makeLegacySeedRecord().loanContracts[0] }

    // MARK: - 等额本息

    static func seedSchedule() {
        let items = LoanAmortization.schedule(principalInCents: 33_031_893, installmentInCents: 293_491, terms: 134,
                                              annualPercent: rate, firstPeriod: 107, firstDueDate: "2026-09-09",
                                              contractNumber: "26135157700004774", dates: dates)
        precondition(items.count == 134, "count \(items.count)")
        let first = items[0], second = items[1], last = items[items.count - 1]
        precondition(first.period == 107 && first.date == "2026-09-09", "first \(first)")
        precondition(cents(first.principal) == 205_406 && cents(first.interest) == 88_085 && cents(first.balance) == 32_826_487, "first \(first)")
        precondition(cents(first.repaymentAmount) == 293_491)
        precondition(second.period == 108 && second.date == "2026-10-09", "second \(second)")
        precondition(cents(second.principal) == 205_954 && cents(second.interest) == 87_537 && cents(second.balance) == 32_620_533, "second \(second)")
        precondition(last.period == 240 && last.date == "2037-10-09", "last \(last)")
        precondition(cents(last.repaymentAmount) == 293_587 && cents(last.principal) == 292_806
                     && cents(last.interest) == 781 && cents(last.balance) == 0, "last \(last)")
    }

    static func termsRule() {
        precondition(LoanAmortization.terms(principalInCents: 33_031_893, installmentInCents: 293_491, annualPercent: rate) == 134)
        precondition(LoanAmortization.terms(principalInCents: 32_781_893, installmentInCents: 293_491, annualPercent: rate) == 133)
    }

    static func installmentRule() {
        precondition(LoanAmortization.installment(principalInCents: 32_831_893, terms: 134, annualPercent: rate) == 291_715)
    }

    static func maturity() {
        precondition(LoanAmortization.maturityDate(firstDueDate: "2026-09-09", terms: 134, dates: dates) == "2037-10-08")
        precondition(LoanAmortization.maturityDate(firstDueDate: "2026-09-09", terms: 133, dates: dates) == "2037-09-08")
        precondition(LoanAmortization.maturityText("2037-10-08") == "2037年10月8日")
    }

    static func preview(_ amount: Int64, _ method: LoanRepaymentMethod, balance: Int64 = 251_966) throws -> LoanPrepaymentPreview {
        try LoanAmortization.preview(contract: seedContract, balanceInCents: balance, amountInCents: amount,
                                     method: method, dates: dates)
    }

    static func shortenSmallAmount() throws {
        let p = try preview(200_000, .shortenTerm)
        precondition(p.principalBefore == 33_031_893 && p.principalAfter == 32_831_893, "\(p)")
        precondition(p.termsBefore == 134 && p.termsAfter == 134, "\(p)")
        precondition(p.installmentBefore == 293_491 && p.installmentAfter == 293_491, "\(p)")
        precondition(p.lastInstallmentBefore == 293_587 && p.lastInstallmentAfter == 7_832, "\(p)")
        precondition(p.maturityBefore == "2037-10-08" && p.maturityAfter == "2037-10-08", "\(p)")
        precondition(p.amountInCents == 200_000 && p.balanceInCents == 251_966)
    }

    static func previewShorten() throws {
        let p = try preview(250_000, .shortenTerm)
        precondition(p.termsAfter == 133 && p.maturityAfter == "2037-09-08" && p.lastInstallmentAfter == 230_047, "\(p)")
    }

    static func previewReduce() throws {
        let p = try preview(200_000, .reduceInstallment)
        precondition(p.installmentAfter == 291_715 && p.termsAfter == 134 && p.maturityAfter == "2037-10-08", "\(p)")
    }

    static func amountRules() throws {
        let hundred = try LoanRules.amount("100"), hundredHalf = try LoanRules.amount("100.5")
        precondition(hundred == 10_000 && hundredHalf == 10_050)
        for bad in ["99.99", "100.001", "", "abc"] {
            expect(LoanError.amountInvalid, { _ = try LoanRules.amount(bad) }, "amount \(bad)")
        }
        expect(LoanError.amountNotLessThanPrincipal, { _ = try preview(33_031_893, .shortenTerm, balance: 40_000_000) }, "equal principal")
        expect(LoanError.insufficientBalance, { _ = try preview(251_967, .shortenTerm) }, "over balance")
        expect(LoanError.amountInvalid, { _ = try preview(9_999, .shortenTerm, balance: 0) }, "order")
    }

    static func legacyDecode() throws {
        let json = #"""
        {"id":"loan_housing","name":"个人住房贷款","unpaidPrincipal":330318.93,"contractLimit":670000,
         "expiryDate":"2047-09-14","monthlyDue":0,"availableLimit":0,"isDetailExpanded":true}
        """#
        let contract = try JSONDecoder().decode(LoanContract.self, from: Data(json.utf8))
        precondition(contract.installmentAmount == 2934.91 && contract.remainingTerms == 134)
        precondition(contract.nextDueDate == "2026-09-09" && contract.nextPeriod == 107)
        var record = FinanceLedgerStore.makeLegacySeedRecord()
        record.loanServiceRecords = []
        var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(record)) as! [String: Any]
        object.removeValue(forKey: "loanServiceRecords")
        let data = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(FinanceLedgerRecord.self, from: data)
        precondition(decoded.loanServiceRecords.isEmpty)
        precondition(decoded.loanContracts[0].remainingTerms == 134)
    }

    static func errorCopy() {
        let copy: [(LoanError, String)] = [
            (.amountInvalid, "提前还款金额最低 100 元，最多两位小数"),
            (.amountNotLessThanPrincipal, "提前还款金额须小于未还本金"),
            (.insufficientBalance, "账户余额不足"),
            (.contractUnavailable, "贷款不存在或已结清"),
            (.changed, "信息已变化，请重新确认"),
            (.corruptLedger, "账本数据异常，暂不能办理"),
            (.persistence, "本地保存失败，请重试"),
            (.invalidRequest, "请求无效，请重试")
        ]
        for (error, text) in copy { precondition(error.localizedDescription == text, "\(error)") }
    }

    static func history() {
        let loan = LoanHistoryCatalog.loan(id: "loan_consumer_2019")
        precondition(loan?.settledDate == "2021-12-20" && loan?.amountInCents == 5_000_000)
        precondition(LoanHistoryCatalog.settledLoans.count == 1)
    }

    // MARK: - 账本读写

    struct WriteFailure: Error {}
    static let loanID = FinanceLedgerRecord.defaultLoanId
    static let ledgerKey = "abank.financeLedger.record.v8"

    @MainActor static func withStore(_ body: (FinanceLedgerStore, UserDefaults) throws -> Void) rethrows {
        let suite = "ABank.LoanChecks." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FinanceLedgerStore(defaults: defaults, dates: dates)
        var legacy = FinanceLedgerStore.makeLegacySeedRecord()
        legacy.demoDataVersion = "legacy-loan-regression-vector"
        precondition(store.save(legacy))
        try body(store, defaults)
    }

    @MainActor static func topUp(_ store: FinanceLedgerStore, by amount: Double) {
        var record = store.load()
        record.accounts[0].openingBalance += amount
        store.recalculate(&record)
        precondition(store.save(record))
    }

    struct Snapshot: Equatable {
        let balance: Double, principal: Double, installment: Double, terms: Int, transactions: Int, records: Int
        @MainActor init(_ store: FinanceLedgerStore) {
            let record = store.load()
            balance = record.accounts[0].balance
            principal = record.loanContracts[0].unpaidPrincipal
            installment = record.loanContracts[0].installmentAmount
            terms = record.loanContracts[0].remainingTerms
            transactions = record.transactions.count
            records = record.loanServiceRecords.count
        }
    }

    @MainActor static func submitShorten() throws {
        try withStore { store, _ in
            topUp(store, by: 1_000)   // 种子余额 1519.66 → 2519.66
            let before = Snapshot(store)
            let record = try store.submitPrepayment(contractID: loanID, amountInCents: 250_000, method: .shortenTerm,
                                                    requestID: "p1", expected: nil)
            let ledger = store.load()
            precondition(cents(ledger.accounts[0].balance) == 1_966, "balance \(ledger.accounts[0].balance)")
            let contract = ledger.loanContracts[0]
            precondition(cents(contract.unpaidPrincipal) == 32_781_893 && contract.remainingTerms == 133)
            precondition(contract.maturityDateText == "2037年9月8日" && cents(contract.installmentAmount) == 293_491)
            precondition(ledger.transactions.count == before.transactions + 1)
            let tx = ledger.transactions.first { $0.id == record.transactionID }!
            precondition(tx.categoryId == "loan_repay" && tx.includeInFlow && tx.amount == 2500 && tx.date == "2026-11-08")
            precondition(tx.direction == .expense && tx.title == "提前还款-个人住房贷款")
            precondition(ledger.loanServiceRecords.count == 1 && record.kind == .prepayment)
            precondition(record.principalBefore == 33_031_893 && record.principalAfter == 32_781_893)
            precondition(record.termsBefore == 134 && record.termsAfter == 133 && record.method == .shortenTerm)
            precondition(record.businessNo.hasPrefix("DK20261108"), record.businessNo)
            // 缩短期限：末期还款额前后也随记录保存，结果页/进度页可展示。
            precondition(record.lastInstallmentBefore == 293_587 && record.lastInstallmentAfter == 230_047, "\(record)")
        }
    }

    @MainActor static func submitReduce() throws {
        try withStore { store, _ in
            topUp(store, by: 1_000)
            _ = try store.submitPrepayment(contractID: loanID, amountInCents: 200_000, method: .reduceInstallment,
                                           requestID: "p1", expected: nil)
            let contract = store.load().loanContracts[0]
            precondition(cents(contract.installmentAmount) == 291_715 && contract.remainingTerms == 134)
        }
    }

    @MainActor static func linkedPages() throws {
        try withStore { store, _ in
            topUp(store, by: 1_000)
            _ = try store.submitPrepayment(contractID: loanID, amountInCents: 200_000, method: .reduceInstallment,
                                           requestID: "p1", expected: nil)
            precondition(cents(store.loanDuePageData(period: .nextMonth).totalAmount) == 291_715)
            var filter = LoanRepaymentFilter.default()
            filter.applyCustom(start: "2026-09-01", end: "2026-12-31", sortOrder: .farToNear)
            let page = store.loanRepaymentPageData(contractId: loanID, filter: filter)
            precondition(page.planItems.first?.period == 107 && cents(page.planItems.first!.repaymentAmount) == 291_715,
                         "\(String(describing: page.planItems.first))")
            precondition(page.detailItems.contains { $0.date == "2026-11-08" && cents($0.principal) == 200_000 })
            let usage = store.loanUsageRecordsPageData(contractId: loanID, page: 0).records.first!
            precondition(usage.title == "提前还款" && cents(usage.totalAmount) == 200_000 && usage.interest == 0)
            precondition(store.loanPrepaymentInfo(contractId: loanID)?.maturityDate == "2037-10-08")
        }
    }

    @MainActor static func idempotentReplay() throws {
        try withStore { store, _ in
            let first = try store.submitPrepayment(contractID: loanID, amountInCents: 10_000, method: .shortenTerm,
                                                   requestID: "same", expected: nil)
            let after = Snapshot(store)
            let again = try store.submitPrepayment(contractID: loanID, amountInCents: 10_000, method: .shortenTerm,
                                                   requestID: "same", expected: nil)
            precondition(again == first && Snapshot(store) == after)
        }
    }

    @MainActor static func changedWhileConfirming() throws {
        try withStore { store, _ in
            let preview = try store.previewPrepayment(contractID: loanID, amountInCents: 10_000, method: .shortenTerm)
            topUp(store, by: 480.34)
            let before = Snapshot(store)
            expect(LoanError.changed, {
                _ = try store.submitPrepayment(contractID: loanID, amountInCents: 10_000, method: .shortenTerm,
                                               requestID: "c", expected: preview)
            }, "changed")
            precondition(Snapshot(store) == before)
        }
    }

    @MainActor static func failuresUnchanged() throws {
        try withStore { store, defaults in
            let before = Snapshot(store)
            expect(LoanError.insufficientBalance, {
                _ = try store.submitPrepayment(contractID: loanID, amountInCents: 300_000, method: .shortenTerm, requestID: "a", expected: nil)
            }, "balance")
            expect(LoanError.contractUnavailable, {
                _ = try store.submitPrepayment(contractID: "missing", amountInCents: 10_000, method: .shortenTerm, requestID: "b", expected: nil)
            }, "contract")
            expect(LoanError.invalidRequest, {
                _ = try store.submitPrepayment(contractID: loanID, amountInCents: 10_000, method: .shortenTerm, requestID: "", expected: nil)
            }, "request")
            let failing = FinanceLedgerStore(defaults: defaults, dates: dates, dataWriter: { _ in throw WriteFailure() })
            expect(LoanError.persistence, {
                _ = try failing.submitPrepayment(contractID: loanID, amountInCents: 10_000, method: .shortenTerm, requestID: "d", expected: nil)
            }, "write")
            precondition(Snapshot(store) == before)
            let garbage = Data("not json".utf8)
            defaults.set(garbage, forKey: ledgerKey)
            expect(LoanError.corruptLedger, {
                _ = try store.submitPrepayment(contractID: loanID, amountInCents: 10_000, method: .shortenTerm, requestID: "e", expected: nil)
            }, "corrupt")
            expect(LoanError.corruptLedger, { _ = try store.requestSettlementCertificate(loanID: "loan_consumer_2019", requestID: "f") }, "corrupt cert")
            precondition(defaults.data(forKey: ledgerKey) == garbage)
        }
    }

    @MainActor static func permissionsIgnored() throws {
        try withStore { store, _ in
            try store.setPermissions(AccountPermissions(mobileTransfer: false, onlinePayment: false),
                                     accountID: FinanceLedgerRecord.defaultAccountId)
            _ = try store.submitPrepayment(contractID: loanID, amountInCents: 10_000, method: .shortenTerm, requestID: "x", expected: nil)
        }
    }

    @MainActor static func certificate() throws {
        try withStore { store, _ in
            let first = try store.requestSettlementCertificate(loanID: "loan_consumer_2019", requestID: "c1")
            let again = try store.requestSettlementCertificate(loanID: "loan_consumer_2019", requestID: "c2")
            precondition(first == again && store.load().loanServiceRecords.count == 1)
            precondition(first.kind == .settlementCertificate && first.certificateNo?.hasPrefix("JQ20261108") == true)
            precondition(store.settlementCertificate(loanID: "loan_consumer_2019") == first)
            expect(LoanError.contractUnavailable, { _ = try store.requestSettlementCertificate(loanID: "nope", requestID: "c3") }, "unknown")
        }
    }

    @MainActor static func tasks() throws {
        try withStore { store, _ in
            let initial = store.loanTasks()
            precondition(initial.map(\.kind) == [.repaymentReminder, .insufficientBalance, .certificatePending(loanID: "loan_consumer_2019")],
                         "\(initial)")
            precondition(initial[0].detail == "09-09 应还 2934.91 元", initial[0].detail)
            precondition(initial[1].detail == "账户余额不足以支付下期还款，还差 1415.25 元", initial[1].detail)
            _ = try store.requestSettlementCertificate(loanID: "loan_consumer_2019", requestID: "c1")
            precondition(!store.loanTasks().contains { if case .certificatePending = $0.kind { return true }; return false })
            topUp(store, by: 2_000)
            precondition(!store.loanTasks().contains { $0.kind == .insufficientBalance })
        }
    }

    @MainActor static func progress() throws {
        try withStore { store, _ in
            let record = try store.submitPrepayment(contractID: loanID, amountInCents: 10_000, method: .shortenTerm, requestID: "g", expected: nil)
            let items = store.loanProgressItems()
            precondition(items.first?.record == record && items.first?.status == "已办结" && items.first?.steps.count == 3)
            precondition(items.last?.title == "住房贷款申请" && items.last?.status == "已放款", "\(String(describing: items.last))")
            precondition(items.count == 3)
        }
    }

    @MainActor static func totalsExcludeHistory() {
        withStore { store, _ in
            precondition(store.myLoanPageData().totalUnpaidPrincipal == store.load().loanContracts[0].unpaidPrincipal)
        }
    }
}
