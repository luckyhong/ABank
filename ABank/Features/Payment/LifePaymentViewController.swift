//
//  LifePaymentViewController.swift
//  ABank
//
//  生活缴费：水费、电费、燃气费三类页签，列出模拟户号与本期账单状态。
//

import UIKit
import SnapKit

final class LifePaymentViewController: PaymentFlowViewController, RouteHosting {
    private static let kinds: [PaymentKind] = [.water, .electric, .gas]
    private var kindIndex = 0

    var hostedRoute: AppRoute? { .lifePayment }

    override func setupUI() {
        super.setupUI()
        title = "生活缴费"
    }

    override func setupNavigationBar() {
        super.setupNavigationBar()
        let records = UIBarButtonItem(title: "缴费记录", style: .plain, target: self, action: #selector(openRecords))
        records.accessibilityIdentifier = "payment.records"
        navigationItem.rightBarButtonItem = records
    }

    @objc private func openRecords() {
        router.open(.orders, from: self)
    }

    override func refreshBankingData() {
        clearContent()
        let bar = BranchChipBar(titles: Self.kinds.map(\.title), selected: kindIndex, idPrefix: "payment.kind")
        bar.onSelect = { [weak self] index in
            self?.kindIndex = index
            self?.refreshBankingData()
        }
        contentStack.addArrangedSubview(bar)

        for account in PaymentCatalog.billAccounts(of: Self.kinds[kindIndex]) {
            let bill = ledger.currentBill(for: account)
            let amount = "\(wealthMoneyText(bill.amountInCents)) 元"
            let row = BenefitsRow(
                title: account.name,
                subtitle: "户号 \(account.accountNo) · " + (bill.isPaid ? "本期 \(amount)" : "待缴 \(amount)"),
                trailing: BranchStatusTagView(text: bill.isPaid ? "已缴清" : "待缴", active: !bill.isPaid),
                id: "payment.row.\(account.id)", showsChevron: true
            )
            row.onTap = { [weak self] in
                guard let self else { return }
                self.router.open(.utilityBill(billAccountID: account.id), from: self)
            }
            contentStack.addArrangedSubview(row)
        }
        addNotice("选择缴费项目，查看本期账单")
    }
}
