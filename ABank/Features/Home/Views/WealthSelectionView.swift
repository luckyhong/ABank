import UIKit
import SnapKit

final class WealthSelectionView: UIView {
    var onMore: (() -> Void)?
    var onFeatured: (() -> Void)?
    var onSide: ((Int) -> Void)?
    var onRetry: (() -> Void)?

    private static let amberInk = UIColor(red: 0.51, green: 0.29, blue: 0.08, alpha: 1)
    private static let amberOutline = UIColor(red: 0.89, green: 0.71, blue: 0.43, alpha: 1)
    private let header = SectionHeaderView(title: "财富优选", titleFont: .abankTitle2())
    private let productStack = UIStackView()
    private let sideStack = UIStackView()
    private let quoteBar = UIView()
    private let retry = UIButton(type: .system)
    private let usd = HomeQuoteColumn(title: "美元 (USD)", unit: "元/百美元")
    private let gold = HomeQuoteColumn(title: "黄金 (AU)", unit: "元/克")

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        header.onTap = { [weak self] in self?.onMore?() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(featured: HomeWealthFeaturedItem, sides: [HomeWealthSideItem]) {
        productStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        sideStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let hero = makeFeaturedCard(featured)
        hero.addAction(UIAction { [weak self] _ in self?.onFeatured?() }, for: .touchUpInside)
        productStack.addArrangedSubview(hero)
        productStack.addArrangedSubview(sideStack)

        for (index, item) in sides.enumerated() {
            let card = makeSideCard(item)
            card.addAction(UIAction { [weak self] _ in self?.onSide?(index) }, for: .touchUpInside)
            sideStack.addArrangedSubview(card)
        }
    }

    func configureQuotes(_ quotes: HomeMarketQuotes, updating: Bool = false) {
        usd.configure(quotes.usd, cached: quotes.usdIsCached, updating: updating)
        gold.configure(quotes.gold, cached: quotes.goldIsCached, updating: updating)
        retry.isHidden = !quotes.needsRetry || (updating && retry.isHidden)
        retry.isEnabled = !updating
        retry.setTitle(updating ? "更新中" : "重试", for: .normal)
    }

    private func setupUI() {
        productStack.axis = .horizontal
        productStack.distribution = .fillEqually
        productStack.spacing = 12
        sideStack.axis = .vertical
        sideStack.spacing = 12
        sideStack.distribution = .fillEqually

        quoteBar.backgroundColor = .abankCardBackground
        quoteBar.layer.cornerRadius = 14
        quoteBar.addShadow(color: .black, opacity: 0.045, offset: CGSize(width: 0, height: 3), radius: 7)
        let quoteColumns = UIStackView(arrangedSubviews: [usd, gold])
        quoteColumns.distribution = .fillEqually
        quoteColumns.spacing = 20
        let divider = UIView()
        divider.backgroundColor = .abankSeparator

        retry.setTitle("重试", for: .normal)
        retry.setTitleColor(Self.amberInk, for: .normal)
        retry.titleLabel?.font = .abankCaptionMedium()
        retry.contentHorizontalAlignment = .trailing
        retry.isHidden = true
        retry.accessibilityLabel = "重新获取行情"
        retry.addAction(UIAction { [weak self] _ in self?.onRetry?() }, for: .touchUpInside)
        retry.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44).priority(999) }

        let quoteContent = UIStackView(arrangedSubviews: [quoteColumns, retry])
        quoteContent.axis = .vertical
        quoteContent.spacing = 4

        addSubview(header)
        addSubview(productStack)
        addSubview(quoteBar)
        [quoteContent, divider].forEach { quoteBar.addSubview($0) }

        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(36)
        }
        productStack.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview()
        }
        quoteBar.snp.makeConstraints { make in
            make.top.equalTo(productStack.snp.bottom).offset(14)
            make.leading.trailing.bottom.equalToSuperview()
        }
        quoteContent.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
        divider.snp.makeConstraints { make in
            make.centerX.equalTo(quoteColumns)
            make.top.bottom.equalTo(quoteColumns)
            make.width.equalTo(0.5)
        }
    }

    private func makeFeaturedCard(_ item: HomeWealthFeaturedItem) -> WealthProductCard {
        let card = WealthProductCard()
        let heading = makeTitle(title: item.title, tag: item.tag)
        let subtitle = Self.label(item.subtitle, size: 13, color: .abankTextPrimary)
        let value = Self.label(item.highlightValue, size: 27, color: .abankHighlight, weight: .semibold)
        let explanation = Self.label(item.highlightLabel, size: 12, color: .abankTextSecondary)
        let spacer = UIView()
        spacer.snp.makeConstraints { $0.height.greaterThanOrEqualTo(16) }

        let pill = UIView()
        pill.backgroundColor = UIColor(red: 1, green: 0.78, blue: 0.39, alpha: 1)
        pill.layer.cornerRadius = 14
        let action = Self.label(item.actionTitle, size: 13, color: Self.amberInk, weight: .medium)
        pill.addSubview(action)
        action.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 11, bottom: 6, right: 11))
        }
        let actionRow = UIStackView(arrangedSubviews: [pill, UIView()])
        actionRow.alignment = .center
        pill.setContentHuggingPriority(.required, for: .horizontal)
        action.setContentHuggingPriority(.required, for: .horizontal)

        let copy = UIStackView(arrangedSubviews: [heading, subtitle, spacer, value, explanation, actionRow])
        copy.axis = .vertical
        copy.spacing = 5
        copy.setCustomSpacing(10, after: explanation)
        card.install(copy, inset: 14)
        card.snp.makeConstraints { $0.height.greaterThanOrEqualTo(196) }
        card.accessibilityLabel = "\(item.title)，\(item.tag)，\(item.subtitle)，\(item.highlightValue)，\(item.highlightLabel)"
        card.accessibilityHint = item.actionTitle
        return card
    }

    private func makeSideCard(_ item: HomeWealthSideItem) -> WealthProductCard {
        let card = WealthProductCard()
        let heading = makeTitle(title: item.title, tag: item.tag)
        let subtitle = Self.label(item.subtitle, size: 12, color: .abankTextPrimary)
        let action = Self.label(item.actionTitle, size: 13, color: Self.amberInk, weight: .medium)
        let arrow = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 8, weight: .semibold)))
        arrow.tintColor = Self.amberInk
        arrow.contentMode = .scaleAspectFit
        arrow.snp.makeConstraints { $0.size.equalTo(9) }
        let actionRow = UIStackView(arrangedSubviews: [action, arrow, UIView()])
        actionRow.spacing = 4
        actionRow.alignment = .center
        action.setContentHuggingPriority(.required, for: .horizontal)

        let copy = UIStackView(arrangedSubviews: [heading, subtitle, actionRow])
        copy.axis = .vertical
        copy.spacing = 5
        copy.setCustomSpacing(8, after: subtitle)
        card.install(copy, inset: 12)
        card.accessibilityLabel = "\(item.title)，\(item.tag)，\(item.subtitle)"
        card.accessibilityHint = item.actionTitle
        return card
    }

    private func makeTitle(title: String, tag: String) -> UIStackView {
        let name = Self.label(title, size: 16, color: .abankTextPrimary, weight: .semibold)
        name.numberOfLines = 1
        name.adjustsFontSizeToFitWidth = true
        name.minimumScaleFactor = 0.78
        name.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let category = UIView()
        category.layer.cornerRadius = 3
        category.layer.borderColor = Self.amberOutline.cgColor
        category.layer.borderWidth = 0.75
        let badge = Self.label(tag, size: 10, color: Self.amberInk, weight: .medium)
        badge.numberOfLines = 1
        badge.setContentCompressionResistancePriority(.required, for: .horizontal)
        badge.setContentHuggingPriority(.required, for: .horizontal)
        category.addSubview(badge)
        badge.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4))
        }
        let heading = UIStackView(arrangedSubviews: [name, category, UIView()])
        heading.spacing = 5
        heading.alignment = .center
        return heading
    }

    private static func label(_ text: String, size: CGFloat, color: UIColor, weight: UIFont.Weight = .regular) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textColor = color
        label.numberOfLines = 0
        return label
    }
}

private final class WealthProductCard: UIControl {
    private let wash = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .abankCardBackground
        layer.cornerRadius = 14
        addShadow(color: .black, opacity: 0.05, offset: CGSize(width: 0, height: 3), radius: 8)
        wash.colors = [UIColor(red: 1, green: 0.96, blue: 0.88, alpha: 1).cgColor, UIColor.white.cgColor]
        wash.locations = [0, 0.78]
        wash.startPoint = CGPoint(x: 1, y: 0)
        wash.endPoint = CGPoint(x: 0.35, y: 0.85)
        wash.cornerRadius = layer.cornerRadius
        layer.insertSublayer(wash, at: 0)
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        wash.frame = bounds
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.82 : 1 }
    }

    func install(_ copy: UIView, inset: CGFloat) {
        copy.isUserInteractionEnabled = false
        addSubview(copy)
        copy.snp.makeConstraints { $0.edges.equalToSuperview().inset(inset) }
    }
}

private final class HomeQuoteColumn: UIView {
    private let name = UILabel()
    private let value = UILabel()
    private let caption = UILabel()
    private let unit: String

    init(title: String, unit: String) {
        self.unit = unit
        super.init(frame: .zero)

        name.text = title
        name.textColor = UIColor(red: 0.49, green: 0.37, blue: 0.20, alpha: 1)
        name.font = .systemFont(ofSize: 13, weight: .semibold)
        value.textColor = .abankAmount
        value.font = .monospacedDigitSystemFont(ofSize: 16, weight: .medium)
        value.adjustsFontSizeToFitWidth = true
        value.minimumScaleFactor = 0.8
        value.textAlignment = .left
        name.setContentCompressionResistancePriority(.required, for: .horizontal)
        name.setContentHuggingPriority(.required, for: .horizontal)

        let numbers = UIStackView(arrangedSubviews: [name, value])
        numbers.spacing = 8
        numbers.alignment = .firstBaseline
        caption.font = .systemFont(ofSize: 11)
        caption.textColor = .abankTextSecondary
        caption.numberOfLines = 0

        let content = UIStackView(arrangedSubviews: [numbers, caption])
        content.axis = .vertical
        content.spacing = 4
        addSubview(content)
        content.snp.makeConstraints { $0.edges.equalToSuperview() }

        isAccessibilityElement = true
        accessibilityLabel = title
        value.text = "—"
        caption.text = "\(unit) · 更新中"
        accessibilityValue = "更新中"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ quote: HomeMarketQuote?, cached: Bool, updating: Bool) {
        guard let quote else {
            let status = updating ? "更新中" : "暂无报价"
            value.text = "—"
            caption.text = "\(unit) · \(status)"
            accessibilityValue = status
            return
        }
        value.text = quote.amount.formatted(.number.grouping(.never).precision(.fractionLength(2)))
        let status = cached ? "缓存 · \(quote.day)" : quote.day
        caption.text = "\(unit) · \(status)"
        accessibilityValue = [value.text, caption.text].compactMap { $0 }.joined(separator: "，")
    }
}
