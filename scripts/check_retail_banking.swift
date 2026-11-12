import Foundation

@main struct RetailChecks {
    @MainActor static func main() throws {
        let suite = "ABank.Retail." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var now = BankingDateContext.system.date(from: "2026-11-12")!
        let dates = BankingDateContext(now: { now })
        let store = FinanceLedgerStore(defaults: defaults, dates: dates)
        let initial = store.load()
        let account = FinanceLedgerRecord.defaultAccountId
        let assets = store.totalAssets()
        let flow = store.monthlyFlow(for: dates.currentMonth)
        let opened = try store.openDeposit(productID: "deposit_3m", amount: 100_000, accountID: account, requestID: "deposit1")
        let duplicate = try store.openDeposit(productID: "deposit_3m", amount: 100_000, accountID: account, requestID: "deposit1")
        precondition(opened == duplicate && store.activeDeposits().count == 1)
        precondition(store.totalAssets() == assets && store.monthlyFlow(for: dates.currentMonth).expense == flow.expense)
        precondition(store.account(id: account)?.balance == assets - 1000)
        let withdrawn = try store.withdrawDeposit(id: opened.id)
        precondition(withdrawn.interestPaidInCents == 0 && store.totalAssets() == assets)
        let key = "abank.financeLedger.record.v8"
        var bytes = defaults.data(forKey: key)
        do { _ = try store.withdrawDeposit(id: opened.id); preconditionFailure() } catch {}
        precondition(defaults.data(forKey: key) == bytes)
        let mature = try store.openDeposit(productID: "deposit_3m", amount: 100_000, accountID: account, requestID: "deposit2")
        now = dates.calendar.date(byAdding: .day, value: 150, to: now)!
        let interest = store.depositInterest(mature)
        precondition(interest > 0)
        let closed = try store.withdrawDeposit(id: mature.id)
        precondition(closed.interestPaidInCents == interest && TransferMoney.cents(from: store.totalAssets()) == TransferMoney.cents(from: assets)! + interest)
        let beforeCardAssets = store.totalAssets(), liabilities = store.totalLiabilities()
        let card = try store.addCreditCard()
        let again = try store.addCreditCard()
        precondition(card == again && store.load().creditCards.count == 1)
        let purchases = store.load().transactions.filter { $0.accountId == card.id }
        precondition(purchases.count == 4 && purchases.reduce(Int64(0)) { $0 + TransferMoney.cents(from: $1.amount)! } == card.originalBillInCents)
        precondition(purchases.allSatisfy { $0.date <= dates.string(from: now) })
        precondition(store.totalAssets() == beforeCardAssets && store.totalLiabilities() == liabilities + 1280.5)
        let expense = store.monthlyFlow(for: String(card.statementDate.prefix(7))).expense
        let repayment = try store.repayCreditCard(id: card.id, amount: card.minimumInCents, accountID: account, requestID: "repay1")
        let repeated = try store.repayCreditCard(id: card.id, amount: card.minimumInCents, accountID: account, requestID: "repay1")
        precondition(repayment == repeated && store.load().creditRepayments.count == 1)
        precondition(store.load().creditCards[0].minimumInCents == 0, "Minimum satisfied once without requesting another minimum")
        precondition(store.load().creditCards[0].remainingInCents == card.originalBillInCents - card.minimumInCents)
        precondition(store.monthlyFlow(for: String(card.statementDate.prefix(7))).expense == expense, "Repayment must not duplicate card spending")
        let netBefore = beforeCardAssets - (liabilities + 1280.5)
        precondition(abs(store.totalAssets() - store.totalLiabilities() - netBefore) < 0.001)
        let confirmed = Set(initial.transactions.map(\.id))
        precondition(store.load().transactions.filter { confirmed.contains($0.id) } == initial.transactions, "Debit fixture unchanged")
        bytes = defaults.data(forKey: key)
        let failing = FinanceLedgerStore(defaults: defaults, dates: dates, dataWriter: { _ in throw TransferError.persistence })
        do { _ = try failing.openDeposit(productID: "deposit_3m", amount: 10_000, accountID: account, requestID: "fail"); preconditionFailure() } catch {}
        precondition(defaults.data(forKey: key) == bytes)
        try store.setReportedLost(true, accountID: account)
        bytes = defaults.data(forKey: key)
        do { _ = try store.repayCreditCard(id: card.id, amount: 1, accountID: account, requestID: "lost"); preconditionFailure() } catch { precondition(error as? AccountSettingsError == .cardReportedLost) }
        precondition(defaults.data(forKey: key) == bytes)
        print("Retail checks passed: deposit purchase/withdrawal/interest, exact assets, explicit credit scenario, statements, idempotent repayment, net worth, fixture and failure preservation")
    }
}
