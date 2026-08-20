//
//  IncomeExpenseSummaryCardView.swift
//  ABank
//

import UIKit
import SnapKit

final class IncomeExpenseSummaryCardView: UIView {

    var onAnalysisTapped: (() -> Void)?

    private let card = UIView()
    private let gradientLayer = CAGradientLayer()
    private let monthNumberLabel = UILabel()
    private let monthUnitLabel = UILabel()
    private let infoButton = UIButton(type: .system)
    private let analysisButton = UIButton(type: .system)
    private let expenseAmountLabel = UILabel()
    private let incomeAmountLabel = UILabel()
    private let expenseTitleLabel = UILabel()
    private let incomeTitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = card.bounds
    }

    func configure(monthLabelText: String, expense: Double, income: Double) {
        // "8月" → 数字 + 单位
        if monthLabelText.hasSuffix("月"), monthLabelText.count > 1 {
            monthNumberLabel.text = String(monthLabelText.dropLast())
            monthUnitLabel.text = "月"
        } else {
            monthNumberLabel.text = monthLabelText
            monthUnitLabel.text = ""
        }
        expenseAmountLabel.text = expense.abankPlainAmountString()
        incomeAmountLabel.text = income.abankPlainAmountString()
    }

    private func setupUI() {
        card.layer.cornerRadius = 10
        card.clipsToBounds = true
        gradientLayer.colors = [
            UIColor(red: 255 / 255, green: 244 / 255, blue: 214 / 255, alpha: 1).cgColor,
            UIColor(red: 255 / 255, green: 248 / 255, blue: 230 / 255, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        card.layer.insertSublayer(gradientLayer, at: 0)

        monthNumberLabel.font = .systemFont(ofSize: 32, weight: .bold)
        monthNumberLabel.textColor = .abankTextPrimary

        monthUnitLabel.font = .systemFont(ofSize: 16, weight: .medium)
        monthUnitLabel.textColor = .abankTextPrimary

        let infoConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        infoButton.setImage(UIImage(systemName: "info.circle", withConfiguration: infoConfig), for: .normal)
        infoButton.tintColor = UIColor(red: 180 / 255, green: 180 / 255, blue: 180 / 255, alpha: 1)
        infoButton.isUserInteractionEnabled = false

        analysisButton.setTitle("分析", for: .normal)
        analysisButton.setTitleColor(.abankTextSecondary, for: .normal)
        analysisButton.titleLabel?.font = .systemFont(ofSize: 13)
        analysisButton.backgroundColor = .white.withAlphaComponent(0.55)
        analysisButton.layer.cornerRadius = 14
        analysisButton.layer.borderWidth = 0.5
        analysisButton.layer.borderColor = UIColor(red: 210 / 255, green: 210 / 255, blue: 210 / 255, alpha: 1).cgColor
        analysisButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 16, bottom: 5, right: 16)
        analysisButton.addTarget(self, action: #selector(analysisTapped), for: .touchUpInside)

        [expenseAmountLabel, incomeAmountLabel].forEach {
            $0.font = .systemFont(ofSize: 24, weight: .bold)
            $0.textColor = .abankTextPrimary
            $0.adjustsFontSizeToFitWidth = true
            $0.minimumScaleFactor = 0.7
        }
        expenseTitleLabel.text = "支出(元)"
        incomeTitleLabel.text = "收入(元)"
        [expenseTitleLabel, incomeTitleLabel].forEach {
            $0.font = .systemFont(ofSize: 13)
            $0.textColor = .abankTextSecondary
        }

        addSubview(card)
        [monthNumberLabel, monthUnitLabel, infoButton, analysisButton,
         expenseAmountLabel, incomeAmountLabel, expenseTitleLabel, incomeTitleLabel]
            .forEach { card.addSubview($0) }

        card.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        monthNumberLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(Spacing.md)
        }
        monthUnitLabel.snp.makeConstraints { make in
            make.leading.equalTo(monthNumberLabel.snp.trailing).offset(2)
            make.bottom.equalTo(monthNumberLabel).offset(-4)
        }
        infoButton.snp.makeConstraints { make in
            make.leading.equalTo(monthUnitLabel.snp.trailing).offset(6)
            make.centerY.equalTo(monthUnitLabel)
            make.size.equalTo(18)
        }
        analysisButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.centerY.equalTo(monthNumberLabel)
            make.height.equalTo(28)
        }
        expenseAmountLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.top.equalTo(monthNumberLabel.snp.bottom).offset(18)
            make.trailing.lessThanOrEqualTo(card.snp.centerX).offset(-8)
        }
        expenseTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(expenseAmountLabel)
            make.top.equalTo(expenseAmountLabel.snp.bottom).offset(6)
            make.bottom.equalToSuperview().offset(-16)
        }
        incomeAmountLabel.snp.makeConstraints { make in
            make.leading.equalTo(card.snp.centerX).offset(16)
            make.centerY.equalTo(expenseAmountLabel)
            make.trailing.lessThanOrEqualToSuperview().offset(-Spacing.md)
        }
        incomeTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(incomeAmountLabel)
            make.centerY.equalTo(expenseTitleLabel)
        }
    }

    @objc private func analysisTapped() { onAnalysisTapped?() }
}
