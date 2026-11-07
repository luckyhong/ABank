//
//  BenefitsFlowViewController.swift
//  ABank
//
//  权益订单页面基类：持有 BenefitsStore，数据变化、回到前台或跨日时调用 `refreshBankingData()`。
//

import UIKit
import SnapKit

class BenefitsFlowViewController: TransferFlowViewController {
    let benefits: BenefitsStore
    let dates: BankingDateContext

    init(benefits: BenefitsStore = .shared, dates: BankingDateContext = .system) {
        self.benefits = benefits
        self.dates = dates
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(benefitsDidChange),
                                               name: BenefitsStore.didChangeNotification, object: benefits)
    }

    @objc private func benefitsDidChange() {
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
        showToast((error as? BenefitsError)?.errorDescription ?? BenefitsError.saveFailed.errorDescription!)
    }

    func dateText(_ date: Date, format: String = "yyyy-MM-dd HH:mm") -> String {
        dates.string(from: date, format: format)
    }
}
