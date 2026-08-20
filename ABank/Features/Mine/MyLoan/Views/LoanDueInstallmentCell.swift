//
//  LoanDueInstallmentCell.swift
//  ABank
//

import UIKit
import SnapKit

final class LoanDueInstallmentCell: UITableViewCell {
    static let reuseId = "LoanDueInstallmentCell"

    var onToggle: (() -> Void)?

    private let headerControl = UIControl()
    private let dateLabel = UILabel()
    private let amountLabel = UILabel()
    private let chevronView = UIImageView()
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
        amountLabel.text = "-¥\(item.amount.abankPlainAmountString())"

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
                LoanDueDetailRowView(title: item.loanName, value: item.contractNumber)
            )
            detailStack.addArrangedSubview(
                LoanDueDetailRowView(title: "扣款金额", value: "¥\(item.amount.abankPlainAmountString())")
            )
        }

        headerControl.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(52)
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
    }

    private func setupUI() {
        dateLabel.font = .systemFont(ofSize: 15)
        dateLabel.textColor = .abankTextPrimary

        amountLabel.font = .systemFont(ofSize: 15)
        amountLabel.textColor = .abankTextPrimary
        amountLabel.textAlignment = .right

        chevronView.tintColor = UIColor(red: 190 / 255, green: 190 / 255, blue: 190 / 255, alpha: 1)
        chevronView.contentMode = .scaleAspectFit

        detailStack.axis = .vertical
        detailStack.alignment = .fill
        detailStack.spacing = 0
        detailStack.isHidden = true

        separator.backgroundColor = .abankSeparator
        headerControl.addTarget(self, action: #selector(headerTapped), for: .touchUpInside)

        contentView.addSubview(headerControl)
        headerControl.addSubview(dateLabel)
        headerControl.addSubview(amountLabel)
        headerControl.addSubview(chevronView)
        contentView.addSubview(detailStack)
        contentView.addSubview(separator)

        headerControl.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(52)
        }
        dateLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        chevronView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
        amountLabel.snp.makeConstraints { make in
            make.trailing.equalTo(chevronView.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(dateLabel.snp.trailing).offset(12)
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

    @objc private func headerTapped() { onToggle?() }
}

private final class LoanDueDetailRowView: UIView {

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

        let line = UIView()
        line.backgroundColor = .abankSeparator

        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(line)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
        valueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(titleLabel)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(12)
        }
        line.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
