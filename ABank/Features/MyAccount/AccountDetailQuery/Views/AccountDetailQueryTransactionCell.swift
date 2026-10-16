//
//  AccountDetailQueryTransactionCell.swift
//  ABank
//

import UIKit
import SnapKit

final class AccountDetailQueryTransactionCell: UITableViewCell {
    static let reuseId = "AccountDetailQueryTransactionCell"

    private let titleLabel = UILabel()
    private let timeLabel = UILabel()
    private let amountLabel = UILabel()
    private let balanceLabel = UILabel()
    private let arrowView = UIImageView()
    private let separator = UIView()

    private let incomeColor = UIColor(red: 245 / 255, green: 166 / 255, blue: 35 / 255, alpha: 1)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(transaction: LedgerTransaction, isLast: Bool) {
        titleLabel.text = transaction.title
        timeLabel.text = transaction.datetimeText

        amountLabel.text = transaction.signedAmountText
        amountLabel.textColor = transaction.direction == .income ? incomeColor : .abankTextPrimary

        balanceLabel.text = "余额： \(transaction.balanceAfter.abankPlainAmountString())"
        separator.isHidden = isLast
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .white
        contentView.backgroundColor = .white

        titleLabel.font = .systemFont(ofSize: 17, weight: .regular)
        titleLabel.textColor = .abankTextPrimary
        titleLabel.lineBreakMode = .byTruncatingTail

        timeLabel.font = .systemFont(ofSize: 14)
        timeLabel.textColor = .abankTextSecondary

        amountLabel.font = .systemFont(ofSize: 17, weight: .regular)
        amountLabel.textAlignment = .right
        amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        balanceLabel.font = .systemFont(ofSize: 14)
        balanceLabel.textColor = .abankTextSecondary
        balanceLabel.textAlignment = .right
        balanceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let arrowConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        arrowView.image = UIImage(systemName: "chevron.right", withConfiguration: arrowConfig)
        arrowView.tintColor = UIColor(red: 210 / 255, green: 210 / 255, blue: 210 / 255, alpha: 1)
        arrowView.contentMode = .scaleAspectFit

        separator.backgroundColor = .abankSeparator

        [titleLabel, timeLabel, amountLabel, balanceLabel, arrowView, separator].forEach {
            contentView.addSubview($0)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(12)
            make.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-12)
            make.trailing.lessThanOrEqualTo(contentView.snp.centerX).offset(-28)
        }
        timeLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.bottom.equalToSuperview().offset(-12)
            make.trailing.lessThanOrEqualTo(balanceLabel.snp.leading).offset(-12)
        }
        arrowView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.equalTo(10)
            make.height.equalTo(20)
        }
        amountLabel.snp.makeConstraints { make in
            make.trailing.equalTo(arrowView.snp.leading).offset(-14)
            make.centerY.equalTo(titleLabel)
        }
        balanceLabel.snp.makeConstraints { make in
            make.trailing.equalTo(amountLabel)
            make.centerY.equalTo(timeLabel)
        }
        separator.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
}
