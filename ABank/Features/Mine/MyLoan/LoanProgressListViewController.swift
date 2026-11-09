//
//  LoanProgressListViewController.swift
//  ABank
//
//  贷款业务办理进度：本机办理记录 + 种子历史申请，按时间倒序。
//

import UIKit

final class LoanProgressListViewController: LoanStackPageViewController {
    private let store: FinanceLedgerStore

    init(store: FinanceLedgerStore = .shared) {
        self.store = store
        super.init(title: "进度查询")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func reloadContent() {
        let items = store.loanProgressItems()
        guard !items.isEmpty else { return addEmpty("暂无办理记录") }
        for item in items {
            let row = LoanListRowView(title: item.title, trailing: item.status,
                                      detail: "\(item.loanName) · \(item.time)", showsChevron: true)
            row.accessibilityIdentifier = "loan.progress." + item.id
            row.onTap = { [weak self] in
                guard let self else { return }
                self.navigationController?.pushViewController(
                    LoanProgressDetailViewController(item: item, store: self.store), animated: true)
            }
            stack.addArrangedSubview(row)
        }
    }
}
