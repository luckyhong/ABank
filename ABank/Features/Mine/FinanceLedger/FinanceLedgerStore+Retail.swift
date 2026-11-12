import Foundation

extension FinanceLedgerStore {
    func activeDeposits() -> [TermDeposit] { load().termDeposits.filter { $0.closedAt == nil } }
    func depositInterest(_ deposit: TermDeposit) -> Int64 {
        guard let start = dates.date(from: String(deposit.openedAt.prefix(10))), let maturity = dates.date(from: deposit.maturityDate) else { return 0 }
        let end = min(dates.calendar.startOfDay(for: dates.now), maturity)
        let days = max(0, dates.calendar.dateComponents([.day], from: start, to: end).day ?? 0)
        let rate = dates.string(from: dates.now) < deposit.maturityDate ? 5 : deposit.rateBasisPoints
        return WealthRules.accruedInterestInCents(principal: deposit.principalInCents, rateBasisPoints: rate, days: days)
    }
    @discardableResult func openDeposit(productID: String, amount: Int64, accountID: String, requestID: String) throws -> TermDeposit {
        guard !requestID.isEmpty else { throw TransferError.invalidRequest }
        var root = try loadForTransfer()
        if let existing = root.termDeposits.first(where: { $0.requestID == requestID }) { return existing }
        guard let product = DepositProduct.all.first(where: { $0.id == productID }), (5_000...50_000_000).contains(amount) else { throw TransferError.invalidAmount }
        let account = try retailPayer(root, accountID: accountID, amount: amount)
        let now = dates.now
        let maturity = dates.calendar.date(byAdding: .month, value: product.months, to: now)!
        let row = TermDeposit(id: UUID().uuidString, requestID: requestID, accountID: accountID, productID: productID,
            title: product.title, principalInCents: amount, rateBasisPoints: product.rateBasisPoints,
            openedAt: dates.string(from: now, format: "yyyy-MM-dd HH:mm:ss"), maturityDate: dates.string(from: maturity))
        root.termDeposits.append(row)
        root.transactions.append(retailTransaction(id: "deposit_" + row.id, account: account, title: "存入定期-" + product.title, direction: .expense, cents: amount, category: "term_deposit", inFlow: false))
        try persistRetail(&root)
        return row
    }
    @discardableResult func withdrawDeposit(id: String) throws -> TermDeposit {
        var root = try loadForTransfer()
        guard let index = root.termDeposits.firstIndex(where: { $0.id == id }), root.termDeposits[index].closedAt == nil,
              let account = root.accounts.first(where: { $0.id == root.termDeposits[index].accountID }) else { throw TransferError.invalidRequest }
        var row = root.termDeposits[index]
        let interest = depositInterest(row)
        row.closedAt = dates.string(from: dates.now, format: "yyyy-MM-dd HH:mm:ss"); row.interestPaidInCents = interest
        root.termDeposits[index] = row
        root.transactions.append(retailTransaction(id: "deposit_return_" + row.id, account: account, title: "定期存款支取", direction: .income, cents: row.principalInCents, category: "term_deposit", inFlow: false))
        if interest > 0 { root.transactions.append(retailTransaction(id: "deposit_interest_" + row.id, account: account, title: "定期存款利息", direction: .income, cents: interest, category: "interest_income", inFlow: true)) }
        try persistRetail(&root)
        return row
    }
    /// Binding the separate local credit-card scenario is explicit and never alters the confirmed debit-card history.
    @discardableResult func addCreditCard() throws -> CreditCardAccount {
        var root = try loadForTransfer()
        if let existing = root.creditCards.first { return existing }
        let monthStart = dates.calendar.dateInterval(of: .month, for: dates.now)!.start
        let day = dates.calendar.component(.day, from: dates.now)
        let cycle = day >= 10 ? monthStart : dates.calendar.date(byAdding: .month, value: -1, to: monthStart)!
        let statement = dates.calendar.date(byAdding: .day, value: 9, to: cycle)!
        let due = dates.calendar.date(byAdding: .day, value: 27, to: cycle)!
        let card = CreditCardAccount(id: "credit_" + UUID().uuidString, tail: "1968", limitInCents: 2_000_000,
            statementDate: dates.string(from: statement), dueDate: dates.string(from: due), originalBillInCents: 128_050)
        root.creditCards.append(card)
        let purchases: [(String, Int64, Int)] = [("商超消费", 36_850, 2), ("餐饮消费", 12_800, 4), ("交通出行", 8_400, 6), ("线上购物", 70_000, 8)]
        for (offset, item) in purchases.enumerated() {
            let date = dates.calendar.date(byAdding: .day, value: item.2, to: cycle)!
            root.transactions.append(LedgerTransaction(id: card.id + "_purchase_" + String(offset), accountId: card.id, date: dates.string(from: date), time: "",
                title: item.0, direction: .expense, amount: TransferMoney.amount(item.1), balanceAfter: 0,
                iconKey: "creditcard", categoryId: "third_party_out", summary: "信用卡消费", cardNumber: "****" + card.tail, transactionType: "消费", channel: "信用卡"))
        }
        try persistRetail(&root)
        return card
    }
    @discardableResult func repayCreditCard(id: String, amount: Int64, accountID: String, requestID: String) throws -> CreditRepaymentRecord {
        guard !requestID.isEmpty else { throw TransferError.invalidRequest }
        var root = try loadForTransfer()
        if let old = root.creditRepayments.first(where: { $0.requestID == requestID }) { return old }
        guard let index = root.creditCards.firstIndex(where: { $0.id == id }), amount > 0, amount <= root.creditCards[index].remainingInCents else { throw TransferError.invalidAmount }
        let account = try retailPayer(root, accountID: accountID, amount: amount)
        let row = CreditRepaymentRecord(id: UUID().uuidString, requestID: requestID, cardID: id, accountID: accountID, amountInCents: amount,
            createdAt: dates.string(from: dates.now, format: "yyyy-MM-dd HH:mm:ss"))
        root.creditRepayments.append(row); root.creditCards[index].repaidInCents += amount
        root.transactions.append(retailTransaction(id: "credit_repay_" + row.id, account: account, title: "信用卡还款-" + root.creditCards[index].tail, direction: .expense, cents: amount, category: "abc_credit_repay", inFlow: false))
        try persistRetail(&root)
        return row
    }
    private func retailPayer(_ root: FinanceLedgerRecord, accountID: String, amount: Int64) throws -> LedgerAccount {
        guard let account = root.accounts.first(where: { $0.id == accountID && $0.currency == "人民币" }) else { throw TransferError.missingAccount }
        guard !account.isReportedLost else { throw AccountSettingsError.cardReportedLost }
        guard account.permissions.onlinePayment else { throw PaymentError.onlinePaymentDisabled }
        guard let balance = TransferMoney.cents(from: account.balance), amount <= balance else { throw TransferError.insufficientBalance }
        return account
    }
    private func persistRetail(_ root: inout FinanceLedgerRecord) throws {
        recalculate(&root); root.dataTimestamp = dates.string(from: dates.now, format: "yyyy-MM-dd HH:mm:ss")
        do { try persist(root) } catch { throw TransferError.persistence }
    }
    private func retailTransaction(id: String, account: LedgerAccount, title: String, direction: LedgerTransactionDirection, cents: Int64, category: String, inFlow: Bool) -> LedgerTransaction {
        LedgerTransaction(id: id, accountId: account.id, date: dates.string(from: dates.now), time: dates.string(from: dates.now, format: "HH:mm:ss"),
            title: title, direction: direction, amount: TransferMoney.amount(cents), balanceAfter: 0, iconKey: "banknote", categoryId: category,
            includeInFlow: inFlow, summary: title, cardNumber: account.maskedCardNumber, transactionType: title, channel: "手机银行")
    }
}
