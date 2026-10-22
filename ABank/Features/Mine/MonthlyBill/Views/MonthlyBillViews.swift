//
//  MonthlyBillViews.swift
//  ABank
//

import UIKit
import SnapKit

enum MonthlyBillFormat {
    static let expenseColor = UIColor.abankOrange
    static let incomeColor = UIColor.abankTeal

    static func amount(_ cents: Int64, hidden: Bool, symbol: Bool = false) -> String {
        if hidden { return "****" }
        let text = TransferMoney.amount(cents).abankPlainAmountString()
        return symbol ? "¥ " + text : text
    }

    static func shortMonth(_ month: String) -> String {
        guard let number = Int(month.split(separator: "-").last ?? "") else { return month }
        return "\(number)月"
    }
}

// MARK: - 卡片容器

final class MonthlyBillSectionCard: UIView {
    let titleLabel = UILabel()
    let accessoryLabel = UILabel()
    let stack = UIStackView()

    init(title: String) {
        super.init(frame: .zero)
        backgroundColor = .white
        layer.cornerRadius = CornerRadius.md
        clipsToBounds = true

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .abankTextPrimary
        accessoryLabel.font = .systemFont(ofSize: 12)
        accessoryLabel.textColor = .abankTextTertiary
        accessoryLabel.textAlignment = .right
        stack.axis = .vertical
        stack.spacing = 0

        [titleLabel, accessoryLabel, stack].forEach { addSubview($0) }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(Spacing.md)
        }
        accessoryLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-Spacing.md)
        }
        stack.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-8)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setRows(_ rows: [UIView]) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        rows.forEach { stack.addArrangedSubview($0) }
    }

    static func placeholder(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14)
        label.textColor = .abankTextTertiary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.snp.makeConstraints { $0.height.greaterThanOrEqualTo(72) }
        return label
    }
}

// MARK: - 月份切换

final class MonthlyBillMonthSwitcher: UIView {
    var onPrevious: (() -> Void)?
    var onNext: (() -> Void)?

    private let previousButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        previousButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        nextButton.setImage(UIImage(systemName: "chevron.right", withConfiguration: config), for: .normal)
        [previousButton, nextButton].forEach { $0.tintColor = .abankTextPrimary }
        previousButton.accessibilityLabel = "上个月"
        nextButton.accessibilityLabel = "下个月"
        previousButton.accessibilityIdentifier = "bill.month.previous"
        nextButton.accessibilityIdentifier = "bill.month.next"
        previousButton.addAction(UIAction { [weak self] _ in self?.onPrevious?() }, for: .touchUpInside)
        nextButton.addAction(UIAction { [weak self] _ in self?.onNext?() }, for: .touchUpInside)

        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .abankTextPrimary
        titleLabel.textAlignment = .center
        titleLabel.accessibilityIdentifier = "bill.month.title"
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .abankTextTertiary
        subtitleLabel.textAlignment = .center

        [previousButton, titleLabel, subtitleLabel, nextButton].forEach { addSubview($0) }
        previousButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalTo(titleLabel)
            make.size.equalTo(44)
        }
        nextButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalTo(titleLabel)
            make.size.equalTo(44)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalTo(previousButton.snp.trailing)
            make.trailing.equalTo(nextButton.snp.leading)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-8)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, subtitle: String, canGoPrevious: Bool, canGoNext: Bool) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        previousButton.isEnabled = canGoPrevious
        nextButton.isEnabled = canGoNext
        previousButton.alpha = canGoPrevious ? 1 : 0.3
        nextButton.alpha = canGoNext ? 1 : 0.3
    }
}

// MARK: - 汇总

final class MonthlyBillSummaryView: UIView {
    private let expenseCaption = UILabel()
    private let expenseLabel = UILabel()
    private let incomeLabel = UILabel()
    private let balanceLabel = UILabel()
    private let footnoteLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .abankTeal
        layer.cornerRadius = CornerRadius.md
        clipsToBounds = true

        expenseCaption.text = "本月支出(元)"
        expenseCaption.font = .systemFont(ofSize: 13)
        expenseCaption.textColor = UIColor.white.withAlphaComponent(0.85)
        expenseLabel.font = .systemFont(ofSize: 30, weight: .semibold)
        expenseLabel.textColor = .white
        expenseLabel.adjustsFontSizeToFitWidth = true
        expenseLabel.minimumScaleFactor = 0.5
        expenseLabel.accessibilityIdentifier = "bill.summary.expense"
        [incomeLabel, balanceLabel].forEach {
            $0.font = .systemFont(ofSize: 14)
            $0.textColor = .white
            $0.adjustsFontSizeToFitWidth = true
            $0.minimumScaleFactor = 0.6
        }
        incomeLabel.accessibilityIdentifier = "bill.summary.income"
        balanceLabel.accessibilityIdentifier = "bill.summary.balance"
        balanceLabel.textAlignment = .right
        footnoteLabel.font = .systemFont(ofSize: 12)
        footnoteLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        footnoteLabel.numberOfLines = 0

        let bottomRow = UIStackView(arrangedSubviews: [incomeLabel, balanceLabel])
        bottomRow.distribution = .fillEqually
        bottomRow.spacing = 12
        let stack = UIStackView(arrangedSubviews: [expenseCaption, expenseLabel, bottomRow, footnoteLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.setCustomSpacing(16, after: expenseLabel)
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 18, left: 18, bottom: 16, right: 18)) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with data: MonthlyBillData, hidden: Bool) {
        expenseLabel.text = MonthlyBillFormat.amount(data.expenseInCents, hidden: hidden)
        incomeLabel.text = "收入 " + MonthlyBillFormat.amount(data.incomeInCents, hidden: hidden)
        let balance = hidden ? "****" : (data.balanceInCents < 0 ? "-" : "") + MonthlyBillFormat.amount(abs(data.balanceInCents), hidden: false)
        balanceLabel.text = "结余 " + balance
        var note = "共 \(data.flowCount) 笔计入收支"
        if data.excludedCount > 0 { note += "，\(data.excludedCount) 笔不计入收支未参与统计" }
        footnoteLabel.text = note
    }
}

// MARK: - 趋势

/// 近 6 个月收支柱状图；点击某月切换账单月份。
final class MonthlyBillTrendView: UIView {
    var onSelectMonth: ((String) -> Void)?

    private var points: [LedgerMonthTrendPoint] = []
    private var selectedMonth = ""
    private var hidesAmounts = false
    private let chartHeight: CGFloat = 120
    private let labelHeight: CGFloat = 36

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        isOpaque = false
        contentMode = .redraw
        isAccessibilityElement = true
        accessibilityIdentifier = "bill.trend"
        snp.makeConstraints { $0.height.equalTo(chartHeight + labelHeight + 16) }
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(_:))))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(points: [LedgerMonthTrendPoint], selectedMonth: String, hidesAmounts: Bool) {
        self.points = points
        self.selectedMonth = selectedMonth
        self.hidesAmounts = hidesAmounts
        accessibilityLabel = hidesAmounts ? "近6个月收支趋势，金额已隐藏" : points.map {
            "\(MonthlyBillFormat.shortMonth($0.month))支出\(TransferMoney.text($0.expenseInCents))元，收入\(TransferMoney.text($0.incomeInCents))元"
        }.joined(separator: "；")
        setNeedsDisplay()
    }

    private var columnWidth: CGFloat {
        points.isEmpty ? 0 : (bounds.width - Spacing.md * 2) / CGFloat(points.count)
    }

    override func draw(_ rect: CGRect) {
        guard !points.isEmpty else { return }
        let maxValue = max(1, points.map { max($0.incomeInCents, $0.expenseInCents) }.max() ?? 1)
        let top: CGFloat = 16
        let baseline = top + chartHeight
        let barWidth = min(12, columnWidth / 4)

        let axis = UIBezierPath()
        axis.move(to: CGPoint(x: Spacing.md, y: baseline))
        axis.addLine(to: CGPoint(x: bounds.width - Spacing.md, y: baseline))
        UIColor.abankSeparator.setStroke()
        axis.lineWidth = 0.5
        axis.stroke()

        for (index, point) in points.enumerated() {
            let centerX = Spacing.md + columnWidth * (CGFloat(index) + 0.5)
            let isSelected = point.month == selectedMonth
            let alpha: CGFloat = isSelected ? 1 : 0.45
            for (offset, value, color) in [(-barWidth / 2 - 1, point.expenseInCents, MonthlyBillFormat.expenseColor),
                                           (barWidth / 2 + 1, point.incomeInCents, MonthlyBillFormat.incomeColor)] {
                // 金额隐藏时只保留月份，不暴露相对大小
                let height = hidesAmounts ? 0 : max(value > 0 ? 2 : 0, chartHeight * CGFloat(Double(value) / Double(maxValue)))
                let bar = UIBezierPath(roundedRect: CGRect(x: centerX + offset - barWidth / 2, y: baseline - height,
                                                           width: barWidth, height: height),
                                       byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 3, height: 3))
                color.withAlphaComponent(alpha).setFill()
                bar.fill()
            }
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: isSelected ? .semibold : .regular),
                .foregroundColor: isSelected ? UIColor.abankTextPrimary : UIColor.abankTextTertiary
            ]
            let text = MonthlyBillFormat.shortMonth(point.month) as NSString
            let size = text.size(withAttributes: attributes)
            text.draw(at: CGPoint(x: centerX - size.width / 2, y: baseline + 8), withAttributes: attributes)
        }
    }

    @objc private func tapped(_ gesture: UITapGestureRecognizer) {
        let x = gesture.location(in: self).x - Spacing.md
        guard columnWidth > 0, x >= 0 else { return }
        let index = Int(x / columnWidth)
        guard points.indices.contains(index) else { return }
        onSelectMonth?(points[index].month)
    }
}

final class MonthlyBillLegendView: UIStackView {
    init() {
        super.init(frame: .zero)
        spacing = 16
        for (title, color) in [("支出", MonthlyBillFormat.expenseColor), ("收入", MonthlyBillFormat.incomeColor)] {
            let dot = UIView()
            dot.backgroundColor = color
            dot.layer.cornerRadius = 4
            dot.snp.makeConstraints { $0.size.equalTo(8) }
            let label = UILabel()
            label.text = title
            label.font = .systemFont(ofSize: 12)
            label.textColor = .abankTextSecondary
            let item = UIStackView(arrangedSubviews: [dot, label])
            item.spacing = 4
            item.alignment = .center
            addArrangedSubview(item)
        }
    }

    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - 分类 / 主要收支行

final class MonthlyBillCategoryRow: UIControl {
    init(stat: LedgerCategoryStat, color: UIColor, hidden: Bool) {
        super.init(frame: .zero)
        let titleLabel = UILabel()
        titleLabel.text = "\(stat.title) · \(stat.count)笔"
        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.textColor = .abankTextPrimary
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let amountLabel = UILabel()
        amountLabel.text = MonthlyBillFormat.amount(stat.amountInCents, hidden: hidden)
        amountLabel.font = .systemFont(ofSize: 15, weight: .medium)
        amountLabel.textColor = .abankTextPrimary
        amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let percentLabel = UILabel()
        percentLabel.text = hidden ? "--" : String(format: "%.1f%%", stat.ratio * 100)
        percentLabel.font = .systemFont(ofSize: 12)
        percentLabel.textColor = .abankTextTertiary
        percentLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let track = UIView()
        track.backgroundColor = .abankSectionBackground
        track.layer.cornerRadius = 3
        let fill = UIView()
        fill.backgroundColor = color
        fill.layer.cornerRadius = 3
        track.addSubview(fill)

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right",
                                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)))
        arrow.tintColor = .abankTextTertiary

        [titleLabel, amountLabel, percentLabel, track, arrow].forEach {
            $0.isUserInteractionEnabled = false
            addSubview($0)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(Spacing.md)
            make.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-8)
        }
        arrow.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.centerY.equalTo(titleLabel)
        }
        amountLabel.snp.makeConstraints { make in
            make.trailing.equalTo(arrow.snp.leading).offset(-6)
            make.centerY.equalTo(titleLabel)
        }
        track.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(percentLabel.snp.leading).offset(-8)
            make.height.equalTo(6)
            make.bottom.equalToSuperview().offset(-12)
        }
        percentLabel.snp.makeConstraints { make in
            make.trailing.equalTo(amountLabel)
            make.centerY.equalTo(track)
            make.width.greaterThanOrEqualTo(44)
        }
        percentLabel.textAlignment = .right
        fill.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(hidden ? 0.0001 : max(0.0001, min(1, stat.ratio)))
        }

        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = hidden ? "\(stat.title)，\(stat.count)笔，金额已隐藏"
            : "\(stat.title)，\(stat.count)笔，\(TransferMoney.text(stat.amountInCents))元，占比\(percentLabel.text ?? "")"
        accessibilityIdentifier = "bill.category.\(stat.categoryId)"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isHighlighted: Bool {
        didSet { backgroundColor = isHighlighted ? .abankSectionBackground : .clear }
    }
}

final class MonthlyBillTopRow: UIControl {
    init(rank: Int, transaction: LedgerTransaction, accountLabel: String, hidden: Bool) {
        super.init(frame: .zero)
        let rankLabel = UILabel()
        rankLabel.text = "\(rank)"
        rankLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        rankLabel.textColor = rank == 1 ? .white : .abankTextSecondary
        rankLabel.backgroundColor = rank == 1 ? .abankTeal : .abankSectionBackground
        rankLabel.textAlignment = .center
        rankLabel.layer.cornerRadius = 10
        rankLabel.clipsToBounds = true

        let titleLabel = UILabel()
        titleLabel.text = transaction.title
        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.textColor = .abankTextPrimary
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "\(transaction.date) \(accountLabel)"
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .abankTextTertiary

        let amountLabel = UILabel()
        let sign = transaction.direction == .income ? "+" : "-"
        amountLabel.text = hidden ? "****" : sign + transaction.amount.abankPlainAmountString()
        amountLabel.font = .systemFont(ofSize: 15, weight: .medium)
        amountLabel.textColor = .abankTextPrimary
        amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        [rankLabel, titleLabel, subtitleLabel, amountLabel].forEach {
            $0.isUserInteractionEnabled = false
            addSubview($0)
        }
        rankLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalTo(rankLabel.snp.trailing).offset(10)
            make.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-8)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel)
            make.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-8)
            make.bottom.equalToSuperview().offset(-12)
        }
        amountLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.centerY.equalToSuperview()
        }

        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = "第\(rank)名，\(transaction.title)，\(transaction.date)，" + (hidden ? "金额已隐藏" : "\(sign)\(transaction.amount.abankPlainAmountString())元")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isHighlighted: Bool {
        didSet { backgroundColor = isHighlighted ? .abankSectionBackground : .clear }
    }
}
