//
//  IncomeExpenseTransactionCell.swift
//  ABank
//

import UIKit
import SnapKit

final class IncomeExpenseTransactionCell: UITableViewCell {
    static let reuseId = "IncomeExpenseTransactionCell"

    var onTap: (() -> Void)?

    private let iconView = UIImageView()
    private let iconBackground = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let amountLabel = UILabel()
    private let balanceLabel = UILabel()
    private let arrowView = UIImageView()
    private let separator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(transaction: LedgerTransaction, accountLabel: String, isLast: Bool) {
        titleLabel.text = transaction.title
        let displayTime = String(transaction.time.prefix(5))
        subtitleLabel.text = "\(accountLabel) \(displayTime)"

        let prefix = transaction.direction == .income ? "+ ¥ " : "- ¥ "
        amountLabel.text = prefix + transaction.amount.abankPlainAmountString()
        amountLabel.textColor = .abankTextPrimary

        balanceLabel.text = "余额: ¥ \(transaction.balanceAfter.abankPlainAmountString())"

        iconBackground.backgroundColor = .clear
        iconView.image = LedgerTransactionArtwork.image(for: transaction)

        separator.isHidden = isLast
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .white
        contentView.backgroundColor = .white

        iconBackground.layer.cornerRadius = 8
        iconBackground.clipsToBounds = true
        iconView.contentMode = .scaleAspectFit

        titleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        titleLabel.textColor = .abankTextPrimary
        titleLabel.lineBreakMode = .byTruncatingTail

        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .abankTextTertiary

        amountLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        amountLabel.textAlignment = .right

        balanceLabel.font = .systemFont(ofSize: 12)
        balanceLabel.textColor = .abankTextTertiary
        balanceLabel.textAlignment = .right

        let arrowConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        arrowView.image = UIImage(systemName: "chevron.right", withConfiguration: arrowConfig)
        arrowView.tintColor = UIColor(red: 210 / 255, green: 210 / 255, blue: 210 / 255, alpha: 1)
        arrowView.contentMode = .scaleAspectFit

        separator.backgroundColor = .abankSeparator

        contentView.addSubview(iconBackground)
        iconBackground.addSubview(iconView)
        [titleLabel, subtitleLabel, amountLabel, balanceLabel, arrowView, separator].forEach {
            contentView.addSubview($0)
        }

        iconBackground.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.centerY.equalTo(titleLabel)
            make.size.equalTo(18)
        }
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(18)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBackground.snp.trailing).offset(6)
            make.top.equalToSuperview().offset(18)
            make.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-10)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.bottom.equalToSuperview().offset(-18)
            make.trailing.lessThanOrEqualTo(balanceLabel.snp.leading).offset(-10)
        }
        arrowView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.centerY.equalToSuperview()
            make.size.equalTo(12)
        }
        amountLabel.snp.makeConstraints { make in
            make.trailing.equalTo(arrowView.snp.leading).offset(-6)
            make.centerY.equalTo(titleLabel)
        }
        balanceLabel.snp.makeConstraints { make in
            make.trailing.equalTo(amountLabel)
            make.centerY.equalTo(subtitleLabel)
        }
        separator.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
}

final class IncomeExpenseDayHeaderView: UITableViewHeaderFooterView {
    static let reuseId = "IncomeExpenseDayHeaderView"

    private let badge = UILabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .white

        badge.font = .systemFont(ofSize: 12, weight: .medium)
        badge.textColor = .abankTextSecondary
        badge.textAlignment = .center
        badge.backgroundColor = .clear
        badge.layer.borderWidth = 0.8
        badge.layer.borderColor = UIColor.abankTextTertiary.cgColor
        badge.layer.cornerRadius = 10
        badge.layer.masksToBounds = true

        contentView.addSubview(badge)
        badge.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.centerY.equalToSuperview()
            make.height.equalTo(22)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(day: Int) {
        badge.text = "  \(day)日  "
    }
}
