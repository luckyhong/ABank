//
//  MyLoanContractSectionView.swift
//  ABank
//

import UIKit
import SnapKit

final class MyLoanContractSectionView: UIView {

    var onContractTapped: ((String) -> Void)?
    var onToggleDetail: ((String) -> Void)?
    var onTaxInfoTapped: (() -> Void)?

    private let headerContainer = UIView()
    private let sectionHeader = UILabel()
    private let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(contracts: [LoanContract]) {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        contracts.forEach { contract in
            stackView.addArrangedSubview(MyLoanContractCardView(contract: contract))
        }
        stackView.arrangedSubviews.compactMap { $0 as? MyLoanContractCardView }.forEach { card in
            card.onContractTapped = { [weak self] id in self?.onContractTapped?(id) }
            card.onToggleDetail = { [weak self] id in self?.onToggleDetail?(id) }
            card.onTaxInfoTapped = { [weak self] in self?.onTaxInfoTapped?() }
        }
    }

    private func setupUI() {
        headerContainer.backgroundColor = UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1)

        sectionHeader.text = "我的贷款合同"
        sectionHeader.font = .systemFont(ofSize: 15, weight: .semibold)
        sectionHeader.textColor = .abankTextPrimary

        stackView.axis = .vertical
        stackView.spacing = 0

        headerContainer.addSubview(sectionHeader)
        addSubview(headerContainer)
        addSubview(stackView)

        sectionHeader.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.centerY.equalToSuperview()
        }
        headerContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(40)
        }
        stackView.snp.makeConstraints { make in
            make.top.equalTo(headerContainer.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}

// MARK: - Contract card

private final class MyLoanContractCardView: UIView {

    var onContractTapped: ((String) -> Void)?
    var onToggleDetail: ((String) -> Void)?
    var onTaxInfoTapped: (() -> Void)?

    private let contractId: String
    private let titleRow = UIControl()
    private let detailToggleRow = UIControl()
    private let expandedStack = UIStackView()
    private let detailChevron = UIImageView()

    init(contract: LoanContract) {
        self.contractId = contract.id
        super.init(frame: .zero)
        setupUI(contract: contract)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI(contract: LoanContract) {
        backgroundColor = .white

        let titleLabel = UILabel()
        titleLabel.text = contract.name
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .abankTextPrimary

        let titleArrow = UIImageView()
        let arrowConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        titleArrow.image = UIImage(systemName: "chevron.right", withConfiguration: arrowConfig)
        titleArrow.tintColor = UIColor(red: 200 / 255, green: 200 / 255, blue: 200 / 255, alpha: 1)

        titleRow.addSubview(titleLabel)
        titleRow.addSubview(titleArrow)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.centerY.equalToSuperview()
        }
        titleArrow.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.centerY.equalToSuperview()
            make.size.equalTo(14)
        }
        titleRow.addTarget(self, action: #selector(contractTapped), for: .touchUpInside)

        let separator = makeSeparator()
        let limitRow = makeInfoRow(title: "合同额度", value: "¥\(contract.contractLimit.abankPlainAmountString())")
        let expiryRow = makeInfoRow(title: "合同到期日", value: contract.expiryDate)
        let taxRow = makeTaxRow()

        let detailTitle = UILabel()
        detailTitle.text = "合同详情"
        detailTitle.font = .systemFont(ofSize: 14)
        detailTitle.textColor = .abankTextPrimary

        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        detailChevron.image = UIImage(
            systemName: contract.isDetailExpanded ? "chevron.up" : "chevron.down",
            withConfiguration: chevronConfig
        )
        detailChevron.tintColor = UIColor(red: 200 / 255, green: 200 / 255, blue: 200 / 255, alpha: 1)

        detailToggleRow.addSubview(detailTitle)
        detailToggleRow.addSubview(detailChevron)
        detailTitle.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.centerY.equalToSuperview()
        }
        detailChevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.centerY.equalToSuperview()
            make.size.equalTo(14)
        }
        detailToggleRow.addTarget(self, action: #selector(toggleDetailTapped), for: .touchUpInside)

        expandedStack.axis = .vertical
        expandedStack.alignment = .fill
        expandedStack.spacing = 0
        expandedStack.isHidden = !contract.isDetailExpanded
        expandedStack.addArrangedSubview(
            makeInfoRow(title: "合同合约号", value: contract.contractNumber.isEmpty ? "-" : contract.contractNumber)
        )
        expandedStack.addArrangedSubview(
            makeInfoRow(title: "合同签订日期", value: contract.signingDate.isEmpty ? "-" : contract.signingDate)
        )

        [titleRow, separator, limitRow, expiryRow, taxRow, detailToggleRow, expandedStack].forEach {
            addSubview($0)
        }

        titleRow.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(48)
        }
        separator.snp.makeConstraints { make in
            make.top.equalTo(titleRow.snp.bottom)
            make.leading.equalToSuperview().offset(Spacing.md)
            make.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
        limitRow.snp.makeConstraints { make in
            make.top.equalTo(separator.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(36)
        }
        expiryRow.snp.makeConstraints { make in
            make.top.equalTo(limitRow.snp.bottom)
            make.leading.trailing.height.equalTo(limitRow)
        }
        taxRow.snp.makeConstraints { make in
            make.top.equalTo(expiryRow.snp.bottom)
            make.leading.trailing.height.equalTo(limitRow)
        }
        detailToggleRow.snp.makeConstraints { make in
            make.top.equalTo(taxRow.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(36)
        }

        if contract.isDetailExpanded {
            expandedStack.isHidden = false
            expandedStack.snp.makeConstraints { make in
                make.top.equalTo(detailToggleRow.snp.bottom)
                make.leading.trailing.equalToSuperview()
                make.bottom.equalToSuperview().offset(-8)
            }
            expandedStack.arrangedSubviews.forEach { row in
                row.snp.makeConstraints { make in
                    make.height.equalTo(36)
                }
            }
        } else {
            expandedStack.isHidden = true
            detailToggleRow.snp.makeConstraints { make in
                make.bottom.equalToSuperview().offset(-8)
            }
            expandedStack.snp.makeConstraints { make in
                make.top.equalTo(detailToggleRow.snp.bottom)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(0)
            }
        }
    }

    private func makeInfoRow(title: String, value: String) -> UIView {
        let row = UIView()
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .abankTextPrimary

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14)
        valueLabel.textColor = .abankTextPrimary
        valueLabel.textAlignment = .right

        row.addSubview(titleLabel)
        row.addSubview(valueLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.centerY.equalToSuperview()
        }
        valueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(12)
        }
        return row
    }

    private func makeTaxRow() -> UIControl {
        let row = UIControl()
        let titleLabel = UILabel()
        titleLabel.text = "报税信息"
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .abankTextPrimary

        let infoConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        let info = UIImageView(image: UIImage(systemName: "info.circle", withConfiguration: infoConfig))
        info.tintColor = UIColor(red: 190 / 255, green: 190 / 255, blue: 190 / 255, alpha: 1)
        info.isUserInteractionEnabled = false

        row.addSubview(titleLabel)
        row.addSubview(info)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.centerY.equalToSuperview()
        }
        info.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(4)
            make.centerY.equalTo(titleLabel)
            make.size.equalTo(16)
        }
        row.addTarget(self, action: #selector(taxTapped), for: .touchUpInside)
        return row
    }

    private func makeSeparator() -> UIView {
        let view = UIView()
        view.backgroundColor = .abankSeparator
        return view
    }

    @objc private func contractTapped() { onContractTapped?(contractId) }
    @objc private func toggleDetailTapped() { onToggleDetail?(contractId) }
    @objc private func taxTapped() { onTaxInfoTapped?() }
}
