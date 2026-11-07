//
//  WealthViews.swift
//  ABank
//
//  理财复用视图与格式化：金额、年化、产品行。
//

import UIKit
import SnapKit

/// 分为单位的金额，千分位、两位小数，如 1,499.66。
func wealthMoneyText(_ cents: Int64) -> String {
    let magnitude = cents.magnitude
    let yuan = formattedAmount(Int(magnitude / 100))
    return (cents < 0 ? "-" : "") + yuan + String(format: ".%02d", Int(magnitude % 100))
}

func wealthRateText(_ basisPoints: Int) -> String {
    String(format: "%.2f%%", Double(basisPoints) / 100)
}

func wealthPurchaseMinimumText(_ cents: Int64) -> String {
    cents % 100 == 0 ? "\(formattedAmount(Int(cents / 100)))元起购" : "\(wealthMoneyText(cents))元起购"
}

/// 产品行：名称，副标题“风险 · 最低持有 · 起购”，右侧年化。
func wealthProductRow(_ product: WealthProduct, onTap: @escaping () -> Void) -> BenefitsRow {
    let rate = UILabel()
    rate.text = product.rateText
    rate.font = .systemFont(ofSize: 20, weight: .semibold)
    rate.textColor = .abankHighlight
    rate.setContentHuggingPriority(.required, for: .horizontal)
    rate.setContentCompressionResistancePriority(.required, for: .horizontal)
    let subtitle = "\(product.risk.shortTitle) \(product.risk.title) · 最低持有 \(product.minHoldDays) 天 · \(wealthPurchaseMinimumText(product.minPurchaseInCents))"
    let row = BenefitsRow(title: product.name, subtitle: subtitle, trailing: rate,
                          id: "wealth.row.\(product.id)", showsChevron: true)
    row.onTap = onTap
    return row
}

/// 单选项行：圆形选中标记 + 文案，整行可点。
final class RiskOptionRow: UIControl {
    var onTap: (() -> Void)?

    init(title: String, selected: Bool, id: String) {
        super.init(frame: .zero)
        accessibilityIdentifier = id
        isAccessibilityElement = true
        accessibilityTraits = selected ? [.button, .selected] : .button
        accessibilityLabel = title
        let mark = UIImageView(image: UIImage(systemName: selected ? "largecircle.fill.circle" : "circle"))
        mark.tintColor = selected ? .abankPrimary : .abankTextTertiary
        mark.setContentHuggingPriority(.required, for: .horizontal)
        mark.isUserInteractionEnabled = false
        let label = UILabel()
        label.text = title
        label.font = .abankBody()
        label.textColor = .abankTextPrimary
        label.numberOfLines = 0
        label.isUserInteractionEnabled = false
        let row = UIStackView(arrangedSubviews: [mark, label])
        row.spacing = Spacing.sm
        row.alignment = .center
        row.isUserInteractionEnabled = false
        addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)) }
        addAction(UIAction { [weak self] _ in self?.onTap?() }, for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
