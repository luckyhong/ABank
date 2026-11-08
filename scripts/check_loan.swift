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

    static var seedContract: LoanContract { FinanceLedgerStore.makeSeedRecord().loanContracts[0] }

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
        precondition(p.lastInstallmentAfter == 7_832, "\(p)")
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
        var record = FinanceLedgerStore.makeSeedRecord()
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
}
