//
//  LoanCertificateListViewController.swift
//  ABank
//
//  结清证明：列出已结清贷款，未申请的可“申请开具”（按贷款幂等），已有记录直接查看。
//

import UIKit

final class LoanCertificateListViewController: LoanStackPageViewController {
    private let store: FinanceLedgerStore

    init(store: FinanceLedgerStore = .shared) {
        self.store = store
        super.init(title: "结清证明")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func reloadContent() {
        let loans = LoanHistoryCatalog.settledLoans
        guard !loans.isEmpty else { return addEmpty("暂无已结清贷款") }
        for loan in loans {
            let record = store.settlementCertificate(loanID: loan.id)
            let row = LoanListRowView(
                title: loan.name, trailing: nil,
                detail: "合同号 \(loan.contractNumber)\n结清日 \(loan.settledDate)",
                actionTitle: record == nil ? "申请开具" : "查看证明"
            )
            row.accessibilityIdentifier = "loan.certificate." + loan.id
            row.onTap = { [weak self] in self?.open(loan) }
            stack.addArrangedSubview(row)
        }
    }

    private func open(_ loan: SettledLoan) {
        do {
            let record = try store.settlementCertificate(loanID: loan.id)
                ?? store.requestSettlementCertificate(loanID: loan.id, requestID: UUID().uuidString)
            navigationController?.pushViewController(LoanCertificateViewController(loan: loan, record: record), animated: true)
        } catch {
            showToast(error.localizedDescription)
        }
    }
}
