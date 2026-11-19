//
//  LoanRepaymentInfoCell.swift
//  ABank
//

import UIKit
import SnapKit

final class LoanRepaymentInfoCell: UITableViewCell {
    static let reuseId = "LoanRepaymentInfoCell"

    private let cardView = UIView()
    private let stackView = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.backgroundColor = .white
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 0

        contentView.addSubview(cardView)
        cardView.addSubview(stackView)

        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-Spacing.sm)
        }
        stackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(Spacing.md)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(rows: [(String, String)]) {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for row in rows {
            stackView.addArrangedSubview(LoanRepaymentKVRowView(title: row.0, value: row.1))
        }
    }

    func configure(plan: LoanRepaymentPlanItem) {
        configure(rows: [
            ("贷款合约号", plan.contractNumber),
            ("期次", "\(plan.period)"),
            ("还款日期", plan.date),
            ("还款金额", "\(plan.repaymentAmount.abankPlainAmountString())元"),
            ("还本金额", "\(plan.principal.abankPlainAmountString())元"),
            ("还息金额", "\(plan.interest.abankPlainAmountString())元"),
            ("贷款余额", "\(plan.balance.abankPlainAmountString())元")
        ])
    }

    func configure(detail: LoanRepaymentDetailItem) {
        configure(rows: [
            ("贷款合约号", detail.contractNumber),
            ("还款日期", detail.date),
            ("还本金额", "\(detail.principal.abankPlainAmountString())元"),
            ("还息金额", "\(detail.interest.abankPlainAmountString())元"),
            ("还罚息", "\(detail.penalty.abankPlainAmountString())元"),
            ("还复利", "\(detail.compoundInterest.abankPlainAmountString())元")
        ])
    }
}

final class LoanRepaymentKVRowView: UIView {
    private let stack = UIStackView()
    private let valueLabel = UILabel()

    init(title: String, value: String) {
        super.init(frame: .zero)
        let titleLabel = BankingPageStyle.text(title, style: .callout, color: .abankTextSecondary)
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        valueLabel.text = value
        valueLabel.textColor = .abankTextPrimary
        valueLabel.font = UIFontMetrics(forTextStyle: .callout)
            .scaledFont(for: .monospacedDigitSystemFont(ofSize: 16, weight: .regular))
        valueLabel.adjustsFontForContentSizeCategory = true
        valueLabel.numberOfLines = 0
        valueLabel.lineBreakMode = .byCharWrapping
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(valueLabel)
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)) }
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityValue = value
        updateLayout()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLayout()
    }

    private func updateLayout() {
        let large = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        stack.axis = large ? .vertical : .horizontal
        stack.alignment = large ? .fill : .firstBaseline
        stack.spacing = large ? 4 : 12
        valueLabel.textAlignment = large ? .left : .right
    }
}
