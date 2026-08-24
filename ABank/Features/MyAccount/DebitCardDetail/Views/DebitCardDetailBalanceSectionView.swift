//
//  DebitCardDetailBalanceSectionView.swift
//  ABank
//

import UIKit
import SnapKit

final class DebitCardDetailBalanceSectionView: UIView {

    private let flagView = ChinaFlagIconView()
    private let currencyTitleLabel = UILabel()
    private let availableRow = DebitCardDetailKeyValueRow(style: .balance)
    private let accountBalanceRow = DebitCardDetailKeyValueRow(style: .balance)
    private let separator = UIView()
    private let markRow = DebitCardDetailKeyValueRow(style: .secondary)
    private let rateRow = DebitCardDetailKeyValueRow(style: .secondary)
    private let dateRow = DebitCardDetailKeyValueRow(style: .secondary)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with data: DebitCardDetailPageData) {
        currencyTitleLabel.text = data.currencyTitle
        availableRow.configure(
            title: "可用余额",
            value: "¥ \(data.availableBalance.abankPlainAmountString())"
        )
        accountBalanceRow.configure(
            title: "账户余额",
            value: "¥ \(data.accountBalance.abankPlainAmountString())"
        )
        markRow.configure(title: "钞汇标志", value: data.cashRemittanceMark)
        rateRow.configure(title: "执行利率", value: data.interestRateText)
        dateRow.configure(title: "开户日期", value: data.openDateText)
    }

    private func setupUI() {
        backgroundColor = .white

        currencyTitleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        currencyTitleLabel.textColor = .abankTextPrimary

        separator.backgroundColor = .abankSeparator

        let titleRow = UIStackView(arrangedSubviews: [flagView, currencyTitleLabel, UIView()])
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 8

        let balanceStack = UIStackView(arrangedSubviews: [availableRow, accountBalanceRow])
        balanceStack.axis = .vertical
        balanceStack.spacing = 0

        let secondaryStack = UIStackView(arrangedSubviews: [markRow, rateRow, dateRow])
        secondaryStack.axis = .vertical
        secondaryStack.spacing = 0

        [titleRow, balanceStack, separator, secondaryStack].forEach { addSubview($0) }

        flagView.snp.makeConstraints { make in
            make.size.equalTo(18)
        }
        titleRow.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        balanceStack.snp.makeConstraints { make in
            make.top.equalTo(titleRow.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        separator.snp.makeConstraints { make in
            make.top.equalTo(balanceStack.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(0.5)
        }
        secondaryStack.snp.makeConstraints { make in
            make.top.equalTo(separator.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-12)
        }
    }
}

// MARK: - Key value row

enum DebitCardDetailRowStyle {
    case card
    case balance
    case secondary
}

final class DebitCardDetailKeyValueRow: UIView {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let style: DebitCardDetailRowStyle

    init(style: DebitCardDetailRowStyle) {
        self.style = style
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
    }

    private func setupUI() {
        switch style {
        case .card:
            titleLabel.font = .systemFont(ofSize: 14)
            titleLabel.textColor = .abankTextSecondary
            valueLabel.font = .systemFont(ofSize: 14)
            valueLabel.textColor = .abankTextPrimary
            valueLabel.textAlignment = .left
        case .balance:
            titleLabel.font = .systemFont(ofSize: 14)
            titleLabel.textColor = .abankTextPrimary
            valueLabel.font = .systemFont(ofSize: 15, weight: .medium)
            valueLabel.textColor = UIColor(red: 196 / 255, green: 148 / 255, blue: 74 / 255, alpha: 1)
            valueLabel.textAlignment = .right
        case .secondary:
            titleLabel.font = .systemFont(ofSize: 14)
            titleLabel.textColor = .abankTextSecondary
            valueLabel.font = .systemFont(ofSize: 14)
            valueLabel.textColor = .abankTextPrimary
            valueLabel.textAlignment = .right
        }

        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        valueLabel.numberOfLines = 0

        addSubview(titleLabel)
        addSubview(valueLabel)

        let vertical: CGFloat = style == .card ? 8 : 12
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(vertical)
            if style == .card {
                make.width.equalTo(72)
            }
            make.bottom.lessThanOrEqualToSuperview().offset(-vertical)
        }
        valueLabel.snp.makeConstraints { make in
            if style == .card {
                make.leading.equalTo(titleLabel.snp.trailing).offset(12)
            } else {
                make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(12)
            }
            make.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(vertical)
            make.bottom.equalToSuperview().offset(-vertical)
            if style != .card {
                make.centerY.equalTo(titleLabel)
            }
        }
    }
}

// MARK: - China flag icon

final class ChinaFlagIconView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 222 / 255, green: 40 / 255, blue: 40 / 255, alpha: 1)
        layer.cornerRadius = 9
        layer.masksToBounds = true
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setFillColor(UIColor(red: 1, green: 0.85, blue: 0.1, alpha: 1).cgColor)
        let cx = rect.width * 0.28
        let cy = rect.height * 0.32
        let r = min(rect.width, rect.height) * 0.13
        drawStar(context: context, center: CGPoint(x: cx, y: cy), radius: r)

        let smallR = r * 0.38
        let offsets: [(CGFloat, CGFloat)] = [
            (0.58, 0.18), (0.70, 0.32), (0.70, 0.50), (0.58, 0.64)
        ]
        for (ox, oy) in offsets {
            drawStar(
                context: context,
                center: CGPoint(x: rect.width * ox, y: rect.height * oy),
                radius: smallR
            )
        }
    }

    private func drawStar(context: CGContext, center: CGPoint, radius: CGFloat) {
        let path = CGMutablePath()
        for i in 0..<5 {
            let angle = CGFloat(i) * .pi * 2 / 5 - .pi / 2
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
            let innerAngle = angle + .pi / 5
            let inner = CGPoint(
                x: center.x + cos(innerAngle) * radius * 0.4,
                y: center.y + sin(innerAngle) * radius * 0.4
            )
            path.addLine(to: inner)
        }
        path.closeSubpath()
        context.addPath(path)
        context.fillPath()
    }
}
