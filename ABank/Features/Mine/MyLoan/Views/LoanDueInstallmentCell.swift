//
//  LoanDueInstallmentCell.swift
//  ABank
//

import UIKit
import SnapKit

final class LoanDueInstallmentCell: UITableViewCell {
    static let reuseId = "LoanDueInstallmentCell"

    var onRepay: (() -> Void)?
    var onToggle: (() -> Void)?

    private let headerControl = UIControl()
    private let dateLabel = UILabel()
    private let amountLabel = UILabel()
    private let chevronView = UIImageView()
    private let amountStack = UIStackView()
    private let detailStack = UIStackView()
    private let separator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .white
        contentView.backgroundColor = .white
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(item: LoanDueInstallment, expanded: Bool, isLast: Bool) {
        dateLabel.text = item.date
        amountLabel.text = "−¥\(item.amount.abankPlainAmountString())"

        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        chevronView.image = UIImage(
            systemName: expanded ? "chevron.up" : "chevron.down",
            withConfiguration: config
        )

        detailStack.arrangedSubviews.forEach {
            detailStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        detailStack.isHidden = !expanded
        if expanded {
            detailStack.addArrangedSubview(
                LoanRepaymentKVRowView(title: item.loanName, value: item.contractNumber)
            )
            detailStack.addArrangedSubview(
                LoanRepaymentKVRowView(title: "扣款金额", value: "¥\(item.amount.abankPlainAmountString())")
            )
        }

        if expanded && item.canRepay {
            let button = UIButton(type: .system)
            button.setTitle("办理本期还款", for: .normal)
            button.tintColor = .abankTeal
            button.accessibilityIdentifier = "loan.installment.repay"
            button.addAction(UIAction { [weak self] _ in self?.onRepay?() }, for: .touchUpInside)
            button.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44) }
            detailStack.addArrangedSubview(button)
        }

        headerControl.accessibilityIdentifier = "loan.installment.toggle"
        headerControl.accessibilityLabel = "\(item.date)，待还 \(item.amount.abankPlainAmountString()) 元"
        headerControl.accessibilityValue = expanded ? "已展开" : "已折叠"
        headerControl.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.greaterThanOrEqualTo(48)
            if !expanded {
                make.bottom.equalToSuperview()
            }
        }
        detailStack.snp.remakeConstraints { make in
            make.top.equalTo(headerControl.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(16)
            if expanded {
                make.bottom.equalToSuperview().offset(-8)
            }
        }
        separator.isHidden = isLast && !expanded
        updateLayout()
    }

    private func setupUI() {
        dateLabel.font = .preferredFont(forTextStyle: .callout)
        dateLabel.adjustsFontForContentSizeCategory = true
        dateLabel.textColor = .abankTextPrimary

        amountLabel.font = UIFontMetrics(forTextStyle: .callout)
            .scaledFont(for: .monospacedDigitSystemFont(ofSize: 17, weight: .medium))
        amountLabel.adjustsFontForContentSizeCategory = true
        amountLabel.textColor = .abankTextPrimary
        amountLabel.numberOfLines = 0
        amountLabel.textAlignment = .right

        chevronView.tintColor = UIColor(red: 190 / 255, green: 190 / 255, blue: 190 / 255, alpha: 1)
        chevronView.contentMode = .scaleAspectFit

        detailStack.axis = .vertical
        detailStack.alignment = .fill
        detailStack.spacing = 0
        detailStack.isHidden = true

        separator.backgroundColor = .abankSeparator
        headerControl.isAccessibilityElement = true
        headerControl.accessibilityTraits = .button
        headerControl.addTarget(self, action: #selector(headerTapped), for: .touchUpInside)

        contentView.addSubview(headerControl)
        amountStack.addArrangedSubview(dateLabel)
        amountStack.addArrangedSubview(amountLabel)
        headerControl.addSubview(amountStack)
        headerControl.addSubview(chevronView)
        contentView.addSubview(detailStack)
        contentView.addSubview(separator)

        headerControl.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.greaterThanOrEqualTo(48)
        }
        amountStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)
            make.leading.equalToSuperview().inset(Spacing.md)
            make.trailing.equalTo(chevronView.snp.leading).offset(-8)
        }
        chevronView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
        detailStack.snp.makeConstraints { make in
            make.top.equalTo(headerControl.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-8)
        }
        separator.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLayout()
    }

    private func updateLayout() {
        let large = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        amountStack.axis = large ? .vertical : .horizontal
        amountStack.alignment = large ? .fill : .firstBaseline
        amountStack.spacing = large ? 4 : 12
        amountLabel.textAlignment = large ? .left : .right
    }

    @objc private func headerTapped() { onToggle?() }
}
