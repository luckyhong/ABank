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
            stackView.addArrangedSubview(makeContractView(contract))
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

    private func makeContractView(_ contract: LoanContract) -> UIView {
        let container = UIView()
        container.backgroundColor = .white

        let titleRow = UIControl()
        let titleLabel = UILabel()
        titleLabel.text = contract.name
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .abankTextPrimary

        let arrow = UIImageView()
        let arrowConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        arrow.image = UIImage(systemName: "chevron.right", withConfiguration: arrowConfig)
        arrow.tintColor = UIColor(red: 200 / 255, green: 200 / 255, blue: 200 / 255, alpha: 1)

        titleRow.addSubview(titleLabel)
        titleRow.addSubview(arrow)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.centerY.equalToSuperview()
        }
        arrow.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.centerY.equalToSuperview()
            make.size.equalTo(14)
        }
        titleRow.addTarget(self, action: #selector(contractTapped(_:)), for: .touchUpInside)

        let separator1 = makeSeparator()
        let limitRow = makeInfoRow(title: "合同额度", value: "¥\(contract.contractLimit.abankPlainAmountString())")
        let expiryRow = makeInfoRow(title: "合同到期日", value: contract.expiryDate)
        let taxRow = makeTaxRow()
        let detailRow = makeDetailRow(contract: contract)

        [titleRow, separator1, limitRow, expiryRow, taxRow, detailRow].forEach { container.addSubview($0) }

        titleRow.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        separator1.snp.makeConstraints { make in
            make.top.equalTo(titleRow.snp.bottom)
            make.leading.equalToSuperview().offset(Spacing.md)
            make.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
        limitRow.snp.makeConstraints { make in
            make.top.equalTo(separator1.snp.bottom)
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
        detailRow.snp.makeConstraints { make in
            make.top.equalTo(taxRow.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(36)
            make.bottom.equalToSuperview().offset(-4)
        }

        objc_setAssociatedObject(titleRow, &AssociatedKeys.contractId, contract.id, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        objc_setAssociatedObject(detailRow, &AssociatedKeys.contractId, contract.id, .OBJC_ASSOCIATION_COPY_NONATOMIC)

        return container
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

    private func makeDetailRow(contract: LoanContract) -> UIControl {
        let row = UIControl()
        let titleLabel = UILabel()
        titleLabel.text = "合同详情"
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .abankTextPrimary
        let arrow = UIImageView()
        let iconName = contract.isDetailExpanded ? "chevron.up" : "chevron.down"
        let arrowConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        arrow.image = UIImage(systemName: iconName, withConfiguration: arrowConfig)
        arrow.tintColor = UIColor(red: 200 / 255, green: 200 / 255, blue: 200 / 255, alpha: 1)
        row.addSubview(titleLabel)
        row.addSubview(arrow)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.centerY.equalToSuperview()
        }
        arrow.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.centerY.equalToSuperview()
            make.size.equalTo(14)
        }
        row.addTarget(self, action: #selector(toggleDetailTapped(_:)), for: .touchUpInside)
        return row
    }

    private func makeSeparator() -> UIView {
        let view = UIView()
        view.backgroundColor = .abankSeparator
        return view
    }

    @objc private func contractTapped(_ sender: UIControl) {
        guard let id = objc_getAssociatedObject(sender, &AssociatedKeys.contractId) as? String else { return }
        onContractTapped?(id)
    }

    @objc private func toggleDetailTapped(_ sender: UIControl) {
        guard let id = objc_getAssociatedObject(sender, &AssociatedKeys.contractId) as? String else { return }
        onToggleDetail?(id)
    }

    @objc private func taxTapped() {
        onTaxInfoTapped?()
    }
}

private enum AssociatedKeys {
    static var contractId = "contractId"
}
