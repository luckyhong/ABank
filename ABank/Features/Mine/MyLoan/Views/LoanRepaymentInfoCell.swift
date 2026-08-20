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
    private let bottomSpacer = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.backgroundColor = .white
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 0
        bottomSpacer.backgroundColor = UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1)

        contentView.addSubview(cardView)
        cardView.addSubview(stackView)
        contentView.addSubview(bottomSpacer)

        cardView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-4)
        }
        bottomSpacer.snp.makeConstraints { make in
            make.top.equalTo(cardView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(8)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(rows: [(String, String)], isLast: Bool) {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for row in rows {
            stackView.addArrangedSubview(LoanRepaymentKVRowView(title: row.0, value: row.1))
        }
        bottomSpacer.isHidden = isLast
        bottomSpacer.snp.updateConstraints { make in
            make.height.equalTo(isLast ? 0 : 8)
        }
    }

    func configure(plan: LoanRepaymentPlanItem, isLast: Bool) {
        configure(rows: [
            ("贷款合约号", plan.contractNumber),
            ("期次", "\(plan.period)"),
            ("还款日期", plan.date),
            ("还款金额", "\(plan.repaymentAmount.abankPlainAmountString())元"),
            ("还本金额", "\(plan.principal.abankPlainAmountString())元"),
            ("还息金额", "\(plan.interest.abankPlainAmountString())元"),
            ("贷款余额", "\(plan.balance.abankPlainAmountString())元")
        ], isLast: isLast)
    }

    func configure(detail: LoanRepaymentDetailItem, isLast: Bool) {
        configure(rows: [
            ("贷款合约号", detail.contractNumber),
            ("还款日期", detail.date),
            ("还本金额", "\(detail.principal.abankPlainAmountString())元"),
            ("还息金额", "\(detail.interest.abankPlainAmountString())元"),
            ("还罚息", "\(detail.penalty.abankPlainAmountString())元"),
            ("还复利", "\(detail.compoundInterest.abankPlainAmountString())元")
        ], isLast: isLast)
    }
}

private final class LoanRepaymentKVRowView: UIView {

    init(title: String, value: String) {
        super.init(frame: .zero)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .abankTextSecondary

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14)
        valueLabel.textColor = .abankTextPrimary
        valueLabel.textAlignment = .right
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(titleLabel)
        addSubview(valueLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
        }
        valueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(titleLabel)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(12)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
