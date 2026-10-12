//
//  MineFinanceMetricView.swift
//  ABank
//

import UIKit
import SnapKit

/// 双栏金额指标（资产/负债、支出/收入）
final class MineFinanceMetricView: UIView {

    private let leftAccent = UIView()
    private let rightAccent = UIView()
    private let leftTitleLabel = UILabel()
    private let rightTitleLabel = UILabel()
    private let leftAmountLabel = UILabel()
    private let rightAmountLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        leftTitle: String,
        leftAmount: String,
        rightTitle: String,
        rightAmount: String,
        leftAccentColor: UIColor = .abankTeal,
        rightAccentColor: UIColor = UIColor(red: 1, green: 0.75, blue: 0.30, alpha: 1)
    ) {
        leftTitleLabel.text = leftTitle
        rightTitleLabel.text = rightTitle
        setAmount(leftAmount, on: leftAmountLabel)
        setAmount(rightAmount, on: rightAmountLabel)
        leftAccent.backgroundColor = leftAccentColor
        rightAccent.backgroundColor = rightAccentColor
    }

    private func setAmount(_ text: String, on label: UILabel) {
        let value = NSMutableAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 23, weight: .medium)])
        if text.hasPrefix("¥") {
            value.addAttribute(.font, value: UIFont.systemFont(ofSize: 15), range: NSRange(location: 0, length: 1))
        }
        label.attributedText = value
    }

    private func setupUI() {
        [leftTitleLabel, rightTitleLabel].forEach {
            $0.font = .systemFont(ofSize: 14)
            $0.textColor = .abankTextSecondary
        }
        [leftAmountLabel, rightAmountLabel].forEach {
            $0.font = .systemFont(ofSize: 22, weight: .regular)
            $0.textColor = .abankTextPrimary
            $0.adjustsFontSizeToFitWidth = true
            $0.minimumScaleFactor = 0.7
        }
        [leftAccent, rightAccent].forEach {
            $0.layer.cornerRadius = 0
        }

        let leftColumn = makeColumn(accent: leftAccent, title: leftTitleLabel, amount: leftAmountLabel)
        let rightColumn = makeColumn(accent: rightAccent, title: rightTitleLabel, amount: rightAmountLabel)
        let row = UIStackView(arrangedSubviews: [leftColumn, rightColumn])
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = Spacing.md

        addSubview(row)
        row.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func makeColumn(accent: UIView, title: UILabel, amount: UILabel) -> UIView {
        let column = UIView()
        column.addSubview(accent)
        column.addSubview(title)
        column.addSubview(amount)
        accent.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.width.equalTo(2)
            make.height.equalTo(14)
        }
        title.snp.makeConstraints { make in
            make.leading.equalTo(accent.snp.trailing).offset(6)
            make.centerY.equalTo(accent)
            make.trailing.equalToSuperview()
        }
        amount.snp.makeConstraints { make in
            make.leading.equalTo(accent)
            make.top.equalTo(title.snp.bottom).offset(10)
            make.trailing.bottom.equalToSuperview()
        }
        return column
    }
}
