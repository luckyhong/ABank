//
//  WealthFlowViewController.swift
//  ABank
//
//  理财页面基类：持有账本与风险测评 Store；账本变更、测评变更、回到前台或跨日时调用 `refreshBankingData()`。
//

import UIKit
import SnapKit

class WealthFlowViewController: TransferFlowViewController {
    let ledger: FinanceLedgerStore
    let risk: RiskAssessmentStore
    let dates: BankingDateContext

    init(ledger: FinanceLedgerStore = .shared, risk: RiskAssessmentStore = .shared, dates: BankingDateContext = .system) {
        self.ledger = ledger
        self.risk = risk
        self.dates = dates
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(riskDidChange),
                                               name: RiskAssessmentStore.didChangeNotification, object: risk)
    }

    @objc private func riskDidChange() {
        guard isViewLoaded else { return }
        refreshBankingData()
    }

    func clearContent() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    @discardableResult
    func addCard(_ views: [UIView], spacing: CGFloat = Spacing.sm, insets: CGFloat = Spacing.md) -> UIView {
        let card = BranchCardView(views, spacing: spacing, insets: insets)
        contentStack.addArrangedSubview(card)
        return card
    }

    func addSectionTitle(_ text: String) {
        let label = UILabel()
        label.text = text
        label.font = .abankBodyMedium()
        label.textColor = .abankTextPrimary
        contentStack.addArrangedSubview(label)
    }

    func addEmptyState(_ text: String, id: String) {
        let label = UILabel()
        label.text = text
        label.font = .abankBody()
        label.textColor = .abankTextSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.accessibilityIdentifier = id
        contentStack.addArrangedSubview(BranchCardView([label], spacing: 0, insets: Spacing.xl))
    }

    func confirm(_ message: String, confirmTitle: String = "确定", action: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: confirmTitle, style: .default) { _ in action() })
        present(alert, animated: true)
    }

    func showError(_ error: Error) {
        showToast(error.localizedDescription)
    }

    func dateText(_ date: Date, format: String = "yyyy-MM-dd HH:mm") -> String {
        dates.string(from: date, format: format)
    }
}
