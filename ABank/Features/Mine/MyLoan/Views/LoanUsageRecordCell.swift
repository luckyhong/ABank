//
//  LoanUsageRecordCell.swift
//  ABank
//

import UIKit
import SnapKit

final class LoanUsageRecordCell: UITableViewCell {
    static let reuseId = "LoanUsageRecordCell"

    var onToggle: (() -> Void)?

    private let titleLabel = UILabel()
    private let timeLabel = UILabel()
    private let amountLabel = UILabel()
    private let chevronView = UIImageView()
    private let headerControl = UIControl()
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

    func configure(record: LoanUsageRecord, expanded: Bool, isLast: Bool) {
        titleLabel.text = record.title
        timeLabel.text = record.dateTime
        amountLabel.text = "+¥\(record.totalAmount.abankPlainAmountString())"

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
            let rows: [(String, String)] = [
                ("还款金额", record.totalAmount.abankYenAmount()),
                ("本金", record.principal.abankYenAmount()),
                ("利息", record.interest.abankYenAmount()),
                ("罚息", record.penalty.abankYenAmount()),
                ("罚息复利", record.compoundPenalty.abankYenAmount())
            ]
            for row in rows {
                detailStack.addArrangedSubview(LoanUsageDetailRowView(title: row.0, value: row.1))
            }
        }

        headerControl.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(64)
            if !expanded {
                make.bottom.equalToSuperview()
            }
        }
        detailStack.snp.remakeConstraints { make in
            make.top.equalTo(headerControl.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(16)
            if expanded {
                make.bottom.equalToSuperview().offset(-12)
            }
        }

        separator.isHidden = isLast
    }

    private func setupUI() {
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .abankTextPrimary

        timeLabel.font = .systemFont(ofSize: 13)
        timeLabel.textColor = .abankTextTertiary

        amountLabel.font = .systemFont(ofSize: 16)
        amountLabel.textColor = .abankTextPrimary
        amountLabel.textAlignment = .right

        chevronView.tintColor = UIColor(red: 200 / 255, green: 200 / 255, blue: 200 / 255, alpha: 1)
        chevronView.contentMode = .scaleAspectFit

        detailStack.axis = .vertical
        detailStack.alignment = .fill
        detailStack.spacing = 0
        detailStack.isHidden = true

        separator.backgroundColor = .abankSeparator
        headerControl.addTarget(self, action: #selector(headerTapped), for: .touchUpInside)

        contentView.addSubview(headerControl)
        headerControl.addSubview(titleLabel)
        headerControl.addSubview(timeLabel)
        headerControl.addSubview(amountLabel)
        headerControl.addSubview(chevronView)
        contentView.addSubview(detailStack)
        contentView.addSubview(separator)

        headerControl.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(64)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(14)
        }
        timeLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
        }
        chevronView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(titleLabel)
            make.size.equalTo(16)
        }
        amountLabel.snp.makeConstraints { make in
            make.trailing.equalTo(chevronView.snp.leading).offset(-8)
            make.centerY.equalTo(titleLabel)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(12)
        }
        detailStack.snp.makeConstraints { make in
            make.top.equalTo(headerControl.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-12)
        }
        separator.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    @objc private func headerTapped() { onToggle?() }
}

private final class LoanUsageDetailRowView: UIView {

    init(title: String, value: String) {
        super.init(frame: .zero)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .abankTextTertiary

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14)
        valueLabel.textColor = .abankTextSecondary
        valueLabel.textAlignment = .right

        addSubview(titleLabel)
        addSubview(valueLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }
        valueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(titleLabel)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(12)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

private extension Double {
    func abankYenAmount() -> String {
        "¥\(abankPlainAmountString())"
    }
}
