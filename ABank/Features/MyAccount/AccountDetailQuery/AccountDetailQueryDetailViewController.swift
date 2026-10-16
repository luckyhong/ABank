//
//  AccountDetailQueryDetailViewController.swift
//  ABank
//

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
    private let sectionGap = UIView()
    private let infoStack = UIStackView()

    private var infoRows: [AccountDetailQueryInfoRow] = []

    init(
        transaction: LedgerTransaction,
        maskedNumber: String = "6230 **** 8472"
    ) {
        self.transactionId = transaction.id
        self.transaction = transaction
        self.maskedNumber = maskedNumber
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "明细查询"
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.tintColor = .abankTextPrimary

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.abankTextPrimary,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func refreshBankingData() { reloadTransaction() }

    override func setupUI() {
        view.backgroundColor = .white

        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false

        amountTitleLabel.text = "交易金额"
        amountTitleLabel.font = .systemFont(ofSize: 15)
        amountTitleLabel.textColor = .abankTextSecondary

        amountValueLabel.font = .systemFont(ofSize: 28, weight: .semibold)
        amountValueLabel.textColor = .abankTextPrimary
        amountValueLabel.textAlignment = .right

        sectionGap.backgroundColor = UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1)

        infoStack.axis = .vertical
        infoStack.alignment = .fill
        infoStack.spacing = 0

        let titles = [
            "交易时间", "交易摘要", "对方户名", "对方账户",
            "交易类型", "交易渠道", "本次余额", "交易附言"
        ]
        infoRows = titles.map { AccountDetailQueryInfoRow(title: $0) }
        infoRows.forEach { infoStack.addArrangedSubview($0) }

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        [accountBar, amountTitleLabel, amountValueLabel, sectionGap, infoStack].forEach {
            contentView.addSubview($0)
        }

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        accountBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(48)
        }
        amountTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(accountBar.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(16)
        }
        amountValueLabel.snp.makeConstraints { make in
            make.centerY.equalTo(amountTitleLabel)
            make.trailing.equalToSuperview().offset(-16)
            make.leading.greaterThanOrEqualTo(amountTitleLabel.snp.trailing).offset(12)
        }
        sectionGap.snp.makeConstraints { make in
            make.top.equalTo(amountTitleLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(10)
        }
        infoStack.snp.makeConstraints { make in
            make.top.equalTo(sectionGap.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-24)
        }

        accountBar.configure(maskedNumber: maskedNumber, showsCurrency: false)
        applyTransaction()
    }

    private func reloadTransaction() {
        guard let latest = FinanceLedgerStore.shared.transaction(id: transactionId) else { return }
        transaction = latest
        applyTransaction()
    }

    private func applyTransaction() {
        amountValueLabel.text = transaction.signedAmountText

        let values = [
            transaction.datetimeText,
            transaction.summary,
            transaction.counterpartyName,
            transaction.counterpartyAccount,
            transaction.transactionType,
            transaction.channel,
            transaction.balanceAfter.abankPlainAmountString(),
            transaction.postscript
        ]
        zip(infoRows, values).forEach { $0.configure(value: $1) }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Info row

final class AccountDetailQueryInfoRow: UIView {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .abankTextSecondary
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        valueLabel.font = .systemFont(ofSize: 14)
        valueLabel.textColor = .abankTextPrimary
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 0

        addSubview(titleLabel)
        addSubview(valueLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(14)
            make.width.equalTo(72)
        }
        valueLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(16)
            make.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(14)
            make.bottom.equalToSuperview().offset(-14)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(value: String) {
        valueLabel.text = value.isEmpty ? "-" : value
    }
}
