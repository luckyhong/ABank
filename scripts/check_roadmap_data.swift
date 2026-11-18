import Foundation

@main struct RoadmapChecks {
    private static let payer = FinanceLedgerRecord.defaultAccountId
    private static let key = "abank.financeLedger.record.v8"

    @MainActor static func main() throws {
        let suite = "ABank.Roadmap." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var now = ISO8601DateFormatter().date(from: "2026-12-10T07:00:00Z")!
        let dates = BankingDateContext(now: { now })
        var risk = RiskAssessmentState.none
        var limit = TransferLimits()
        var writeFails = false
        var transferSucceeds = true
        let ledger = FinanceLedgerStore(defaults: defaults, dates: dates, transferLimitsProvider: { limit },
            riskStateProvider: { risk }, dataWriter: { data in
                if writeFails { throw CheckFailure.write }
                defaults.set(data, forKey: key)
            }, simulationSucceeds: { _ in transferSucceeds })

        let initial = ledger.load()
        precondition(initial.transactions.count == 39)
        let budgetMonth = dates.currentMonth
        try ledger.setBudget(month: budgetMonth, categoryID: nil, limit: 12_791)
        try ledger.setBudget(month: budgetMonth, categoryID: "loan_repay", limit: 10_000)
        let contract = initial.loanContracts[0]
        let plan = try ledger.previewInstallment(contractID: contract.id, period: contract.nextPeriod)
        let payment = try ledger.repayInstallment(contractID: contract.id, expected: plan, accountID: payer)
        precondition(payment.amount == 12_791 && payment.principal < payment.amount)
        let budgetsAfterLoan = ledger.budgetProgress(month: budgetMonth)
        precondition(budgetsAfterLoan.first?.balance == 0 && budgetsAfterLoan.last?.balance == -2_791)
        precondition(ledger.updateTransactionDetail(id: payment.transactionID, includeInFlow: false))
        precondition(ledger.budgetProgress(month: budgetMonth).allSatisfy { $0.used == 0 })
        precondition(ledger.updateTransactionDetail(id: payment.transactionID, includeInFlow: true, categoryId: "life_payment"))
        precondition(ledger.budgetProgress(month: budgetMonth).last?.used == 0)
        precondition(ledger.updateTransactionDetail(id: payment.transactionID, categoryId: "loan_repay"))
        precondition(ledger.budgetProgress(month: "2027-01").isEmpty)
        try ledger.setBudget(month: budgetMonth, categoryID: "loan_repay", limit: nil)

        let assetsBeforeFund = cents(ledger.totalAssets())
        let monthlyExpenseBeforeFund = ledger.monthlyFlow(for: budgetMonth).expense
        try expect(WealthError.assessmentRequired) { _ = try ledger.subscribeFund(amount: 10_000, accountID: payer, requestID: "fund") }
        risk = .valid(.c1, expiresOn: "2027-01-01")
        try expect(WealthError.riskLevelTooLow) { _ = try ledger.subscribeFund(amount: 10_000, accountID: payer, requestID: "fund") }
        risk = .valid(.c2, expiresOn: "2027-01-01")
        try expect(WealthError.insufficientBalance) { _ = try ledger.subscribeFund(amount: 9_000_000, accountID: payer, requestID: "fund") }
        let fund = try ledger.subscribeFund(amount: 10_000, accountID: payer, requestID: "fund")
        let repeatedFund = try ledger.subscribeFund(amount: 10_000, accountID: payer, requestID: "fund")
        precondition(repeatedFund == fund)
        precondition(fund.confirmationDay == "2026-12-11" && cents(ledger.totalAssets()) == assetsBeforeFund)
        try ledger.settleDueFundOrders()
        precondition(ledger.fundOrders().first?.units == nil)
        now.addTimeInterval(2 * 86_400)
        let pending = defaults.data(forKey: key)
        writeFails = true
        try expect(WealthError.persistence) { try ledger.settleDueFundOrders() }
        precondition(defaults.data(forKey: key) == pending)
        writeFails = false
        let reopened = FinanceLedgerStore(defaults: defaults, dates: dates)
        try reopened.settleDueFundOrders()
        let confirmed = ledger.fundOrders()[0]
        precondition(confirmed.purchaseNAV == SimulatedFund.nav(on: "2026-12-11", dates: dates))
        precondition(confirmed.canRedeem && confirmed.units != nil)
        let requestedCash = cents(ledger.account(id: payer)!.balance)
        try ledger.requestFundRedemption(orderID: fund.id)
        try ledger.requestFundRedemption(orderID: fund.id)
        precondition(cents(ledger.account(id: payer)!.balance) == requestedCash)
        now.addTimeInterval(86_400)
        try reopened.settleDueFundOrders()
        try ledger.settleDueFundOrders()
        let redeemed = ledger.fundOrders()[0]
        let finalCash = cents(ledger.account(id: payer)!.balance)
        precondition(finalCash == requestedCash + redeemed.redemptionAmount! && ledger.fundValue(of: redeemed) == 0)
        precondition(ledger.monthlyFlow(for: budgetMonth).expense == monthlyExpenseBeforeFund)
        precondition(ledger.load().transactions.filter { $0.id.hasPrefix("fund_") }.count == 2)

        let utilityID = PaymentCatalog.extraBillAccounts.first { $0.kind == .water }!.id
        precondition(ledger.utilityAccount(id: utilityID) == nil)
        try ledger.editUtilityAccount(id: utilityID, edit: .add)
        try ledger.editUtilityAccount(id: utilityID, edit: .add)
        try ledger.editUtilityAccount(id: utilityID, edit: .rename("新家"))
        try ledger.editUtilityAccount(id: utilityID, edit: .makeDefault)
        precondition(ledger.utilityAccounts(kind: .water).active.first?.id == utilityID)
        let bill = try ledger.submitUtilityPayment(billAccountID: utilityID, requestID: "utility", accountID: payer)
        precondition(bill.targetTitle.contains("新家"))
        try ledger.editUtilityAccount(id: utilityID, edit: .remove)
        precondition(ledger.utilityAccount(id: utilityID) == nil && ledger.paymentOrder(id: bill.id) == bill)
        precondition(ledger.utilityAccounts(kind: .water).defaultID != utilityID)
        try ledger.editUtilityAccount(id: utilityID, edit: .add)
        try expect(PaymentError.alreadyPaid) {
            _ = try ledger.submitUtilityPayment(billAccountID: utilityID, requestID: "duplicate-utility", accountID: payer)
        }
        precondition(ledger.utilityAccount(id: utilityID)?.name == "新家")

        let transfersBefore = ledger.load().transferRecords.count
        let beforeSchedule = cents(ledger.account(id: payer)!.balance)
        let due = dates.string(from: now.addingTimeInterval(86_400))
        try expect(ScheduledTransferError.invalidDate) {
            _ = try ledger.createScheduledTransfer(payerID: payer, recipientID: "a3", method: .account, amount: 1_000,
                                                   dueDate: dates.string(from: now), requestID: "today")
        }
        let order = try ledger.createScheduledTransfer(payerID: payer, recipientID: "a3", method: .account,
                                                      amount: 1_000, dueDate: due, requestID: "execute")
        let cancelled = try ledger.createScheduledTransfer(payerID: payer, recipientID: "a3", method: .account,
                                                          amount: 1_000, dueDate: due, requestID: "cancel")
        try expect(ScheduledTransferError.notDue) { _ = try ledger.executeScheduledTransfer(id: order.id) }
        try ledger.cancelScheduledTransfer(id: cancelled.id)
        try expect(ScheduledTransferError.unavailable) { _ = try ledger.executeScheduledTransfer(id: cancelled.id) }
        precondition(cents(ledger.account(id: payer)!.balance) == beforeSchedule)
        now.addTimeInterval(86_400)
        var permissions = AccountPermissions.allEnabled
        permissions.mobileTransfer = false
        try ledger.setPermissions(permissions, accountID: payer)
        try expect(TransferError.transferPermissionDisabled) { _ = try ledger.executeScheduledTransfer(id: order.id) }
        try ledger.setPermissions(.allEnabled, accountID: payer)
        limit.dailyInCents = 500
        try expect(TransferError.dailyLimit) { _ = try ledger.executeScheduledTransfer(id: order.id) }
        limit.dailyInCents = 20_000_000
        transferSucceeds = false
        try expect(ScheduledTransferError.processingFailed) { _ = try ledger.executeScheduledTransfer(id: order.id) }
        transferSucceeds = true
        writeFails = true
        try expect(TransferError.persistence) { _ = try ledger.executeScheduledTransfer(id: order.id) }
        writeFails = false
        precondition(ledger.load().scheduledTransfers.first?.isPending == true)
        precondition(ledger.load().transferRecords.count == transfersBefore)
        let result = try ledger.executeScheduledTransfer(id: order.id)
        let repeatedTransfer = try reopened.executeScheduledTransfer(id: order.id)
        precondition(repeatedTransfer == result)
        precondition(ledger.load().transferRecords.count == transfersBefore + 1 && ledger.receiptRecords().contains(result))
        precondition(cents(ledger.account(id: payer)!.balance) == beforeSchedule - 1_000)
        precondition(ledger.transferredTodayInCents() == 1_000)
        let final = ledger.load()
        let ids = Set(initial.transactions.map(\.id))
        precondition(final.transactions.filter { ids.contains($0.id) } == initial.transactions)
        precondition(final == reopened.load())
        print("Roadmap checks passed: installment, budgets, fund settlement, utility accounts, scheduling, durable state and 39-row history")
    }

    private enum CheckFailure: Error { case write }
    private static func cents(_ amount: Double) -> Int64 { TransferMoney.cents(from: amount)! }

    private static func expect<E: Error & Equatable>(_ error: E, action: () throws -> Void) throws {
        do {
            try action()
            preconditionFailure("Expected \(error)")
        } catch let actual as E {
            precondition(actual == error, "Expected \(error), got \(actual)")
        }
    }
}
