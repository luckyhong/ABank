import UIKit
import SnapKit

/// 我的账户 · 明细查询 · 单笔交易详情
final class AccountDetailQueryDetailViewController: BankingDataViewController {
    private let transactionId: String
    private var transaction: LedgerTransaction
    private let maskedNumber: String
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let accountBar = AccountDetailQueryHeaderView()
    private let amountTitleLabel = UILabel()
    private let amountValueLabel = UILabel()
    private let infoStack = UIStackView()
    private let amount = UIStackView()
    private var infoRows: [AccountDetailQueryInfoRow] = []

    init(transaction: LedgerTransaction, maskedNumber: String = "6230 **** 8472") {
        transactionId = transaction.id
        self.transaction = transaction; self.maskedNumber = maskedNumber
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "明细查询"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage.abankBackIndicator, style: .plain, target: self, action: #selector(backTapped))
    }
    override func refreshBankingData() {
        guard isViewLoaded else { return }
        if let latest = FinanceLedgerStore.shared.transaction(id: transactionId) { transaction = latest }
        applyTransaction()
    }
    override func setupUI() {
        let footer = UIColor(white: 0.945, alpha: 1)
        view.backgroundColor = footer; scrollView.backgroundColor = footer
        contentView.backgroundColor = .white
        scrollView.alwaysBounceVertical = true; scrollView.showsVerticalScrollIndicator = false
        amountTitleLabel.text = "交易金额"
        amountTitleLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15))
        amountTitleLabel.adjustsFontForContentSizeCategory = true
        amountTitleLabel.textColor = .abankTextSecondary
        amountTitleLabel.setContentHuggingPriority(.required, for: .horizontal)
        amountTitleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        amountValueLabel.font = UIFontMetrics(forTextStyle: .title1).scaledFont(for: .systemFont(ofSize: 26, weight: .regular))
        amountValueLabel.adjustsFontForContentSizeCategory = true
        amountValueLabel.textAlignment = .right; amountValueLabel.numberOfLines = 1
        amountValueLabel.adjustsFontSizeToFitWidth = true; amountValueLabel.minimumScaleFactor = 0.7
        amountValueLabel.accessibilityIdentifier = "accountDetail.amount"
        amount.addArrangedSubview(amountTitleLabel); amount.addArrangedSubview(amountValueLabel)
        amount.spacing = 16; amount.alignment = .center
        let amountContainer = UIView(); amountContainer.addSubview(amount)
        amount.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(16); $0.top.bottom.equalToSuperview().inset(4) }
        amountContainer.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44) }
        let gap = UIView(); gap.backgroundColor = UIColor(white: 0.96, alpha: 1)
        infoStack.axis = .vertical; infoStack.spacing = 0
        let titles = ["交易时间", "交易摘要", "对方户名", "对方账户", "收款银行", "交易类型", "交易渠道", "本次余额", "交易附言"]
        infoRows = titles.map { AccountDetailQueryInfoRow(title: $0) }
        infoRows.forEach(infoStack.addArrangedSubview)
        view.addSubview(scrollView); scrollView.addSubview(contentView)
        [accountBar, amountContainer, gap, infoStack].forEach(contentView.addSubview)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentView.snp.makeConstraints { $0.edges.equalTo(scrollView.contentLayoutGuide); $0.width.equalTo(scrollView.frameLayoutGuide) }
        accountBar.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview(); $0.height.greaterThanOrEqualTo(36) }
        amountContainer.snp.makeConstraints { $0.top.equalTo(accountBar.snp.bottom); $0.leading.trailing.equalToSuperview() }
        gap.snp.makeConstraints { $0.top.equalTo(amountContainer.snp.bottom).offset(8); $0.leading.trailing.equalToSuperview(); $0.height.equalTo(10) }
        infoStack.snp.makeConstraints { $0.top.equalTo(gap.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview().inset(16); $0.bottom.equalToSuperview().inset(8) }
        accountBar.configure(maskedNumber: maskedNumber, showsCurrency: false)
        applyTransaction(); updateAmountLayout()
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection); updateAmountLayout()
    }
    private func updateAmountLayout() {
        let large = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        amount.axis = large ? .vertical : .horizontal
        amount.alignment = large ? .fill : .center
    }
    private func applyTransaction() {
        amountValueLabel.text = transaction.signedAmountText
        amountValueLabel.textColor = transaction.direction == .income ? .abankIncomeAmount : .abankExpenseAmount
        // Keep source precision, masked payee details and the ledger's actual running balance.
        let values = [transaction.datetimeText, transaction.displaySummary, transaction.displayCounterparty,
                      transaction.counterpartyAccount, transaction.counterpartyBank, transaction.transactionType,
                      transaction.displayChannel, TransferMoney.text(TransferMoney.cents(from: transaction.balanceAfter) ?? 0), transaction.postscript]
        zip(infoRows, values).forEach { $0.configure(value: $1) }
    }
    @objc private func backTapped() { navigationController?.popViewController(animated: true) }
}

final class AccountDetailQueryInfoRow: UIView {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let line = UIStackView()
    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title; titleLabel.textColor = .abankTextPrimary
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        valueLabel.textColor = .abankTextSecondary; valueLabel.textAlignment = .right
        for label in [titleLabel, valueLabel] {
            label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15))
            label.adjustsFontForContentSizeCategory = true; label.numberOfLines = 0
        }
        valueLabel.accessibilityIdentifier = "accountDetail.value." + title
        line.addArrangedSubview(titleLabel); line.addArrangedSubview(valueLabel)
        line.spacing = 12; line.alignment = .center
        addSubview(line); line.snp.makeConstraints { $0.leading.trailing.equalToSuperview(); $0.top.bottom.equalToSuperview().inset(8) }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(36) }
        isAccessibilityElement = true
        updateLayout()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(value: String) {
        valueLabel.text = value.isEmpty ? "---" : value
        accessibilityLabel = (titleLabel.text ?? "") + "，" + (valueLabel.text ?? "")
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection); updateLayout()
    }
    private func updateLayout() {
        let large = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        line.axis = large ? .vertical : .horizontal
        line.alignment = large ? .leading : .center
        valueLabel.textAlignment = large ? .left : .right
    }
}
