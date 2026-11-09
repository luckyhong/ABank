//
//  LoanHistoryViewController.swift
//  ABank
//
//  历史贷款：只读的已结清贷款目录，不计入任何汇总。
//

import UIKit

final class LoanHistoryViewController: LoanStackPageViewController {
    private let store: FinanceLedgerStore

    init(store: FinanceLedgerStore = .shared) {
        self.store = store
        super.init(title: "历史贷款")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func reloadContent() {
        let loans = LoanHistoryCatalog.settledLoans
        guard !loans.isEmpty else { return addEmpty("暂无历史贷款") }
        for loan in loans {
            let amount = TransferMoney.amount(loan.amountInCents).abankPlainAmountString()
            let row = LoanListRowView(
                title: loan.name, trailing: "已结清",
                detail: "贷款金额 \(amount)元\n期限 \(loan.startDate) 至 \(loan.endDate)\n结清日 \(loan.settledDate)",
                showsChevron: true
            )
            row.accessibilityIdentifier = "loan.history." + loan.id
            row.onTap = { [weak self] in self?.open(loan) }
            stack.addArrangedSubview(row)
        }
    }

    private func open(_ loan: SettledLoan) {
        if let record = store.settlementCertificate(loanID: loan.id) {
            navigationController?.pushViewController(LoanCertificateViewController(loan: loan, record: record), animated: true)
        } else {
            showToast("请先申请结清证明")
            navigationController?.pushViewController(LoanCertificateListViewController(store: store), animated: true)
        }
    }
}
