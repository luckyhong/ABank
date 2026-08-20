//
//  LoanPrepaymentViewController.swift
//  ABank
//

import UIKit
import SnapKit

/// 提前还款（贷款详情入口）
final class LoanPrepaymentViewController: BaseViewController {

    private let contractId: String
    private var info: LoanPrepaymentInfo?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let infoStack = UIStackView()
    private let sectionSpacer = UIView()
    private let actionButton = UIButton(type: .system)

    init(contractId: String) {
        self.contractId = contractId
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "提前还款"
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.tintColor = .abankTextPrimary
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
    }

    override func setupUI() {
        view.backgroundColor = .white

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true

        infoStack.axis = .vertical
        infoStack.alignment = .fill
        infoStack.spacing = 0

        sectionSpacer.backgroundColor = UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1)

        actionButton.setTitle("提前还款", for: .normal)
        actionButton.setTitleColor(.abankOrange, for: .normal)
        actionButton.titleLabel?.font = .systemFont(ofSize: 16)
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(infoStack)
        contentView.addSubview(sectionSpacer)
        contentView.addSubview(actionButton)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        infoStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        sectionSpacer.snp.makeConstraints { make in
            make.top.equalTo(infoStack.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(8)
        }
        actionButton.snp.makeConstraints { make in
            make.top.equalTo(sectionSpacer.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(52)
            make.bottom.equalToSuperview().offset(-40)
        }

        reload()
    }

    private func reload() {
        info = FinanceLedgerStore.shared.loanPrepaymentInfo(contractId: contractId)
        infoStack.arrangedSubviews.forEach {
            infoStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        guard let info else { return }

        let rows: [(String, String, Bool)] = [
            ("贷款凭证号", info.voucherNumber, false),
            ("贷款合约号", info.contractNumber, false),
            ("贷款到期日", info.maturityDate, false),
            ("用款时间", info.usageDate, false),
            ("贷款年化利率", String(format: "%.1f%%", info.annualRatePercent), true),
            ("未还本金", "\(info.unpaidPrincipal.abankPlainAmountString())元", false)
        ]
        for (index, item) in rows.enumerated() {
            let row = LoanPrepaymentInfoRowView(
                title: item.0,
                value: item.1,
                showsInfo: item.2,
                showsSeparator: index < rows.count - 1
            )
            if item.2 {
                row.onInfoTapped = { [weak self] in self?.showToast("贷款年化利率说明") }
            }
            infoStack.addArrangedSubview(row)
        }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func actionTapped() {
        showToast("提交提前还款")
    }
}

private final class LoanPrepaymentInfoRowView: UIView {

    var onInfoTapped: (() -> Void)?

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let infoButton = UIButton(type: .system)
    private let separator = UIView()

    init(title: String, value: String, showsInfo: Bool, showsSeparator: Bool) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.textColor = .abankTextPrimary

        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 15)
        valueLabel.textColor = .abankTextSecondary
        valueLabel.textAlignment = .right

        let infoConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        infoButton.setImage(UIImage(systemName: "info.circle", withConfiguration: infoConfig), for: .normal)
        infoButton.tintColor = UIColor(red: 190 / 255, green: 190 / 255, blue: 190 / 255, alpha: 1)
        infoButton.isHidden = !showsInfo
        infoButton.addTarget(self, action: #selector(infoTapped), for: .touchUpInside)

        separator.backgroundColor = .abankSeparator
        separator.isHidden = !showsSeparator

        addSubview(titleLabel)
        addSubview(infoButton)
        addSubview(valueLabel)
        addSubview(separator)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
        infoButton.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(4)
            make.centerY.equalTo(titleLabel)
            make.size.equalTo(18)
        }
        valueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(titleLabel)
            make.leading.greaterThanOrEqualTo(infoButton.snp.trailing).offset(12)
        }
        separator.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(52)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func infoTapped() { onInfoTapped?() }
}
