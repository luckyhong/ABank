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
        subtitleLabel.text = "\(accountLabel) \(transaction.time)"

        let prefix = transaction.direction == .income ? "+ ¥ " : "- ¥ "
        amountLabel.text = prefix + transaction.amount.abankPlainAmountString()
        amountLabel.textColor = transaction.direction == .income
            ? UIColor(red: 220 / 255, green: 130 / 255, blue: 30 / 255, alpha: 1)
            : .abankTextPrimary

        balanceLabel.text = "余额：¥ \(transaction.balanceAfter.abankPlainAmountString())"

        let style = iconStyle(for: transaction)
        iconBackground.backgroundColor = style.background
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        iconView.image = UIImage(systemName: style.symbol, withConfiguration: config)
        iconView.tintColor = style.tint

        separator.isHidden = isLast
    }

    private struct IconStyle {
        let symbol: String
        let tint: UIColor
        let background: UIColor
    }

    private func iconStyle(for tx: LedgerTransaction) -> IconStyle {
        switch tx.iconKey {
        case "music.note": // 抖音
            return IconStyle(
                symbol: "play.rectangle.fill",
                tint: .white,
                background: UIColor(red: 20 / 255, green: 180 / 255, blue: 140 / 255, alpha: 1)
            )
        case "a.circle": // 支付宝
            return IconStyle(
                symbol: "a.circle.fill",
                tint: .white,
                background: UIColor(red: 20 / 255, green: 150 / 255, blue: 230 / 255, alpha: 1)
            )
        case "creditcard": // 财付通
            return IconStyle(
                symbol: "creditcard.fill",
                tint: .white,
                background: UIColor(red: 30 / 255, green: 190 / 255, blue: 100 / 255, alpha: 1)
            )
        case "person.crop.circle": // 转账
            return IconStyle(
                symbol: "person.fill",
                tint: .white,
                background: UIColor(red: 70 / 255, green: 150 / 255, blue: 230 / 255, alpha: 1)
            )
        case "message": // 微信
            return IconStyle(
                symbol: "message.fill",
                tint: .white,
                background: UIColor(red: 40 / 255, green: 190 / 255, blue: 90 / 255, alpha: 1)
            )
        case "yensign.circle": // 工资
            return IconStyle(
                symbol: "yensign.circle.fill",
                tint: .white,
                background: UIColor(red: 240 / 255, green: 180 / 255, blue: 50 / 255, alpha: 1)
            )
        default:
            return IconStyle(
                symbol: tx.iconKey,
                tint: .white,
                background: .abankTeal
            )
        }
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .white
        contentView.backgroundColor = .white

        iconBackground.layer.cornerRadius = 8
        iconBackground.clipsToBounds = true
        iconView.contentMode = .scaleAspectFit

        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = .abankTextPrimary
        titleLabel.lineBreakMode = .byTruncatingTail

        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .abankTextTertiary

        amountLabel.font = .systemFont(ofSize: 15, weight: .semibold)
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
            make.centerY.equalToSuperview()
            make.size.equalTo(36)
        }
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(18)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBackground.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(14)
            make.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-10)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().offset(-14)
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
        badge.backgroundColor = UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1)
        badge.layer.cornerRadius = 4
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
