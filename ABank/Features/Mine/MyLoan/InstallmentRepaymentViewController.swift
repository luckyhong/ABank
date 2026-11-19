import UIKit

final class InstallmentRepaymentViewController: TransferFlowViewController {
    override var maximumContentWidth: CGFloat? { 560 }

    private let item: LoanDueInstallment
    private let ledger = FinanceLedgerStore.shared
    private var accountID = FinanceLedgerRecord.defaultAccountId
    private var result: InstallmentRepayment?

    init(item: LoanDueInstallment) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func refreshBankingData() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if let result {
            title = "还款成功"
            contentStack.addArrangedSubview(BankingPageStyle.amountSummary(
                "¥ " + TransferMoney.text(result.amount), label: "实付金额", status: "本期还款已完成"))
            addGroup([
                TransferInfoRow("剩余本金", value: TransferMoney.text(result.remainingPrincipal) + " 元"),
                TransferInfoRow("还款时间", value: result.paidAt)
            ])
            _ = addButton("查看还款记录", id: "loan.installment.records") { [weak self] in
                guard let self else { return }
                self.navigationController?.pushViewController(
                    LoanRepaymentDetailViewController(contractId: self.item.contractID, initialTab: .detail), animated: true)
            }
            _ = addButton("查看账户明细", id: "loan.installment.transaction", primary: false) { [weak self] in
                guard let self, let transaction = self.ledger.load().transactions.first(where: { $0.id == result.transactionID }) else { return }
                let maskedNumber = self.ledger.account(id: result.accountID)?.maskedCardNumber ?? "—"
                self.navigationController?.pushViewController(
                    AccountDetailQueryDetailViewController(transaction: transaction, maskedNumber: maskedNumber), animated: true)
            }
            return
        }

        title = "按期还款"
        do {
            let plan = try ledger.previewInstallment(contractID: item.contractID, period: item.period)
            contentStack.addArrangedSubview(BankingPageStyle.amountSummary(
                "¥ " + plan.repaymentAmount.abankPlainAmountString(), label: "本期应还", detail: item.loanName))
            addGroup([
                TransferInfoRow("应还期次", value: "第\(plan.period)期 · \(plan.date)"),
                TransferInfoRow("应还本金", value: plan.principal.abankPlainAmountString() + " 元"),
                TransferInfoRow("应还利息", value: plan.interest.abankPlainAmountString() + " 元")
            ])
            addGroup([BankingAccountPickerRow(account: ledger.account(id: accountID), id: "loan.installment.account") { [weak self] in
                guard let self else { return }
                BankingAccountPickerRow.choose(from: self, ledger: self.ledger, selected: self.accountID) { [weak self] id in
                    self?.accountID = id
                    self?.refreshBankingData()
                }
            }])
            addNotice("此操作使用模拟余额。")
            _ = addButton("确认还款", id: "loan.installment.confirm") { [weak self] in
                guard let self else { return }
                do {
                    self.result = try self.ledger.repayInstallment(contractID: self.item.contractID, expected: plan, accountID: self.accountID)
                    self.refreshBankingData()
                } catch {
                    self.showToast(error.localizedDescription)
                }
            }
        } catch {
            addNotice(error.localizedDescription)
        }
    }
}
