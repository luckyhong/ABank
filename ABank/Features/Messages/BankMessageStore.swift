import Foundation

struct BankMessage: Identifiable {
    let id: String
    let title: String
    let body: String
    let date: String
    let route: AppRoute
    let category: String
}

@MainActor final class BankMessageStore {
    static let shared = BankMessageStore()
    static let didChange = Notification.Name("ABank.messageReadDidChange")
    private let defaults: UserDefaults
    private let key = "abank.messages.read.v1"
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    func isRead(_ message: BankMessage) -> Bool { Set(defaults.stringArray(forKey: key) ?? []).contains(message.id) }
    func markRead(_ messages: [BankMessage]) {
        var ids = Set(defaults.stringArray(forKey: key) ?? [])
        ids.formUnion(messages.map(\.id))
        defaults.set(ids.sorted(), forKey: key)
        NotificationCenter.default.post(name: Self.didChange, object: self)
    }
    func unreadCount(ledger: FinanceLedgerStore? = nil) -> Int { messages(ledger: ledger).filter { !isRead($0) }.count }
    func messages(ledger: FinanceLedgerStore? = nil) -> [BankMessage] {
        let ledger = ledger ?? .shared
        let root = ledger.load()
        var rows: [BankMessage] = []
        if root.transactions.contains(where: { $0.date.hasPrefix(ledger.dates.previousMonth) && $0.includeInFlow }) {
            rows.append(BankMessage(id: "bill_" + ledger.dates.previousMonth, title: "月度账单已出",
                body: "您的\(ledger.dates.previousMonthTitle)账单已生成，可查看分类收支和月度趋势。",
                date: ledger.dates.currentMonth + "-01", route: .ledgerAnalysis, category: "账户通知"))
        }
        for transfer in root.transferRecords {
            rows.append(BankMessage(id: "transfer_" + transfer.id, title: transfer.status.title,
                body: "向\(transfer.recipientName)转账\(TransferMoney.text(transfer.amountInCents))元。\(transfer.failureReason ?? "可查看交易详情。")",
                date: transfer.createdAt, route: .transferRecords, category: "交易通知"))
        }
        for order in root.paymentOrders {
            rows.append(BankMessage(id: "payment_" + order.id, title: order.kind.isUtility ? "生活缴费完成" : "手机充值完成",
                body: "\(order.targetTitle)，实付\(TransferMoney.text(order.paidInCents))元。",
                date: order.createdAt, route: .paymentOrderDetail(orderID: order.id, justPaid: false), category: "交易通知"))
        }
        for order in root.wealthOrders {
            rows.append(BankMessage(id: "wealth_buy_" + order.id, title: "理财购买完成", body: "\(order.productName)，本金\(TransferMoney.text(order.principalInCents))元。",
                date: order.createdAt, route: .wealthOrderDetail(orderID: order.id, justPurchased: false), category: "财富通知"))
            if let date = order.redeemedAt { rows.append(BankMessage(id: "wealth_redeem_" + order.id, title: "理财赎回到账", body: "\(order.productName)，到账\(TransferMoney.text(order.redeemedAmountInCents ?? order.principalInCents))元。",
                date: date, route: .wealthOrderDetail(orderID: order.id, justPurchased: false), category: "财富通知")) }
        }
        for deposit in root.termDeposits {
            rows.append(BankMessage(id: "deposit_open_" + deposit.id, title: "定期存入成功", body: "\(deposit.title)，本金\(TransferMoney.text(deposit.principalInCents))元。", date: deposit.openedAt,
                route: .depositDetail(id: deposit.id), category: "财富通知"))
            if let date = deposit.closedAt { rows.append(BankMessage(id: "deposit_closed_" + deposit.id, title: "定期支取到账", body: "本金与利息已回到原账户。", date: date,
                route: .depositDetail(id: deposit.id), category: "财富通知")) }
        }
        for card in root.creditCards {
            rows.append(BankMessage(id: "credit_bill_" + card.id, title: "信用卡账单", body: "尾号\(card.tail)，账单\(TransferMoney.text(card.originalBillInCents))元，还款日\(card.dueDate)。", date: card.statementDate, route: .creditCards, category: "账户通知"))
        }
        for row in root.creditRepayments {
            rows.append(BankMessage(id: "credit_repaid_" + row.id, title: "信用卡还款成功", body: "本次还款\(TransferMoney.text(row.amountInCents))元。", date: row.createdAt, route: .creditCards, category: "交易通知"))
        }
        if let pending = ledger.pendingLoanPlans().first {
            let past = pending.plan.date < ledger.dates.string(from: ledger.dates.now)
            rows.append(BankMessage(id: "loan_plan_" + pending.contract.id + "_" + pending.plan.date,
                title: past ? "还款计划待处理" : "还款计划提醒", body: "\(pending.contract.name)，计划日期\(pending.plan.date)，金额\(TransferMoney.text(TransferMoney.cents(from: pending.plan.repaymentAmount) ?? 0))元。",
                date: ledger.dates.string(from: ledger.dates.now), route: .myLoan, category: "账户通知"))
        }
        return rows.sorted { $0.date == $1.date ? $0.id < $1.id : $0.date > $1.date }
    }
}
