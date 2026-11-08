//
//  LoanTasksViewController.swift
//  ABank
//
//  贷款待办任务：每次进入或账本变化时由 `loanTasks()` 派生，不另存完成状态。
//

import UIKit

final class LoanTasksViewController: LoanStackPageViewController {
    private let store: FinanceLedgerStore

    init(store: FinanceLedgerStore = .shared) {
        self.store = store
        super.init(title: "待办任务")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func reloadContent() {
        let tasks = store.loanTasks()
        guard !tasks.isEmpty else { return addEmpty("暂无待办任务") }
        for task in tasks {
            let row = LoanListRowView(title: task.title, trailing: nil, detail: task.detail, actionTitle: "去处理")
            row.accessibilityIdentifier = "loan.task." + task.id
            row.onTap = { [weak self] in self?.handle(task.kind) }
            stack.addArrangedSubview(row)
        }
    }

    private func handle(_ kind: LoanTaskKind) {
        let controller: UIViewController
        switch kind {
        case .repaymentReminder:
            controller = LoanDueViewController(period: .nextMonth)
        case .insufficientBalance:
            controller = MyAccountViewController()
        case .certificatePending:
            controller = LoanCertificateListViewController(store: store)
        }
        navigationController?.pushViewController(controller, animated: true)
    }
}
