//
//  BenefitsViews.swift
//  ABank
//
//  权益订单复用视图：余额卡、快捷入口条、通用行。
//

import UIKit
import SnapKit

/// 等级 + 积分/小豆余额卡。
final class BalanceCardView: UIView {
    var onPointsTapped: (() -> Void)?
    var onBeansTapped: (() -> Void)?
    var onLevelTapped: (() -> Void)?

    init(level: CustomerLevel, points: Int, beans: Int) {
        super.init(frame: .zero)
        backgroundColor = .abankPrimary
        layer.cornerRadius = 12

        let levelButton = UIButton(type: .system)
        levelButton.setTitle(level.title + " ›", for: .normal)
        levelButton.setTitleColor(.white, for: .normal)
        levelButton.titleLabel?.font = .abankBodyMedium()
        levelButton.contentHorizontalAlignment = .leading
        levelButton.accessibilityIdentifier = "benefits.level"
        levelButton.addAction(UIAction { [weak self] _ in self?.onLevelTapped?() }, for: .touchUpInside)

        let pointsBlock = Self.block(title: "积分", value: points, id: "benefits.points") { [weak self] in self?.onPointsTapped?() }
        let beansBlock = Self.block(title: "小豆", value: beans, id: "benefits.beans") { [weak self] in self?.onBeansTapped?() }
        let balances = UIStackView(arrangedSubviews: [pointsBlock, beansBlock])
        balances.distribution = .fillEqually
        let stack = UIStackView(arrangedSubviews: [levelButton, balances])
        stack.axis = .vertical
        stack.spacing = Spacing.md
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(Spacing.md) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private static func block(title: String, value: Int, id: String, action: @escaping () -> Void) -> UIControl {
        let control = UIControl()
        control.accessibilityIdentifier = id
        control.isAccessibilityElement = true
        control.accessibilityTraits = .button
        control.accessibilityLabel = "\(title) \(formattedAmount(value))"
        let valueLabel = UILabel()
        valueLabel.text = formattedAmount(value)
        valueLabel.font = .systemFont(ofSize: 28, weight: .semibold)
        valueLabel.textColor = .white
        valueLabel.adjustsFontSizeToFitWidth = true
        let titleLabel = UILabel()
        titleLabel.text = title + " ›"
        titleLabel.font = .abankCaption()
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        let stack = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.isUserInteractionEnabled = false
        control.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        control.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return control
    }
}

/// 横排快捷入口：图标 + 文字。
final class BenefitsShortcutBar: UIView {
    var onSelect: ((Int) -> Void)?

    init(items: [(title: String, icon: String, id: String)]) {
        super.init(frame: .zero)
        backgroundColor = .abankCardBackground
        layer.cornerRadius = 10
        let stack = UIStackView()
        stack.distribution = .fillEqually
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: Spacing.md, left: Spacing.sm, bottom: Spacing.md, right: Spacing.sm)) }
        for (index, item) in items.enumerated() {
            let icon = UIImageView(image: UIImage(systemName: item.icon))
            icon.tintColor = .abankPrimary
            icon.contentMode = .scaleAspectFit
            icon.snp.makeConstraints { $0.size.equalTo(26) }
            let label = UILabel()
            label.text = item.title
            label.font = .abankCaption()
            label.textColor = .abankTextPrimary
            label.textAlignment = .center
            let column = UIStackView(arrangedSubviews: [icon, label])
            column.axis = .vertical
            column.alignment = .center
            column.spacing = Spacing.xs
            column.isUserInteractionEnabled = false
            let control = UIControl()
            control.accessibilityIdentifier = item.id
            control.isAccessibilityElement = true
            control.accessibilityTraits = .button
            control.accessibilityLabel = item.title
            control.addSubview(column)
            column.snp.makeConstraints { $0.edges.equalToSuperview() }
            control.addAction(UIAction { [weak self] _ in self?.onSelect?(index) }, for: .touchUpInside)
            stack.addArrangedSubview(control)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// 通用行：标题 + 副标题，右侧可选附件视图（标签、按钮或箭头）。整行可点（`onTap`）。
final class BenefitsRow: UIControl {
    var onTap: (() -> Void)?

    init(title: String, subtitle: String?, trailing: UIView? = nil, id: String, showsChevron: Bool = false) {
        super.init(frame: .zero)
        accessibilityIdentifier = id
        backgroundColor = .abankCardBackground
        layer.cornerRadius = 10

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .abankBodyMedium()
        titleLabel.textColor = .abankTextPrimary
        titleLabel.numberOfLines = 0
        var labels: [UIView] = [titleLabel]
        if let subtitle { labels.append(branchCaption(subtitle)) }
        let text = UIStackView(arrangedSubviews: labels)
        text.axis = .vertical
        text.spacing = Spacing.xs
        text.isUserInteractionEnabled = false

        var parts: [UIView] = [text, UIView()]
        if let trailing { parts.append(trailing) }
        if showsChevron {
            let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
            chevron.tintColor = .abankTextTertiary
            chevron.setContentHuggingPriority(.required, for: .horizontal)
            chevron.isUserInteractionEnabled = false
            parts.append(chevron)
        }
        let row = UIStackView(arrangedSubviews: parts)
        row.alignment = .center
        row.spacing = Spacing.sm
        addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview().inset(Spacing.md) }
        addAction(UIAction { [weak self] _ in self?.onTap?() }, for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// 内部普通子视图（标签、堆叠视图）不拦截触摸，整行才能响应点击；行内按钮仍可单独点击。
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hit = super.hitTest(point, with: event) else { return nil }
        return hit is UIControl ? hit : self
    }
}

/// 主色小按钮（行内领取等）。
func benefitsActionButton(_ title: String, id: String, action: @escaping () -> Void) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
    button.setTitleColor(.white, for: .normal)
    button.backgroundColor = .abankPrimary
    button.layer.cornerRadius = 14
    button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
    button.accessibilityIdentifier = id
    button.setContentHuggingPriority(.required, for: .horizontal)
    button.addAction(UIAction { _ in action() }, for: .touchUpInside)
    return button
}

/// 小豆签到卡：7 日进度 + 签到按钮。
final class CheckInCardView: UIView {
    var onCheckIn: (() -> Void)?

    init(streak: Int, todayReward: Int, checkedIn: Bool, rewards: [Int]) {
        super.init(frame: .zero)
        backgroundColor = .abankCardBackground
        layer.cornerRadius = 10

        let cycle = rewards.count
        let filled = checkedIn ? (streak % cycle == 0 ? cycle : streak % cycle) : streak % cycle
        let title = UILabel()
        title.text = streak > 0 ? "已连续签到 \(streak) 天" : "每日签到领小豆"
        title.font = .abankBodyMedium()
        title.textColor = .abankTextPrimary
        title.accessibilityIdentifier = "checkin.streak"

        let days = UIStackView()
        days.distribution = .fillEqually
        days.spacing = Spacing.xs
        for (index, reward) in rewards.enumerated() {
            let cell = UILabel()
            cell.text = "+\(reward)"
            cell.font = .systemFont(ofSize: 13, weight: .medium)
            cell.textAlignment = .center
            cell.layer.cornerRadius = 8
            cell.layer.masksToBounds = true
            cell.layer.borderWidth = 0.8
            let isFilled = index < filled
            let isNext = !checkedIn && index == filled
            cell.backgroundColor = isFilled ? RewardCurrency.beans.tint : .clear
            cell.textColor = isFilled ? .white : (isNext ? RewardCurrency.beans.tint : .abankTextTertiary)
            cell.layer.borderColor = (isFilled || isNext ? RewardCurrency.beans.tint : UIColor.abankSeparator).cgColor
            cell.snp.makeConstraints { $0.height.equalTo(40) }
            days.addArrangedSubview(cell)
        }

        let button = UIButton(type: .system)
        button.setTitle(checkedIn ? "今日已签到" : "签到领 \(todayReward) 小豆", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = checkedIn ? .abankTextTertiary : RewardCurrency.beans.tint
        button.layer.cornerRadius = 8
        button.isEnabled = !checkedIn
        button.accessibilityIdentifier = "checkin.button"
        button.snp.makeConstraints { $0.height.equalTo(44) }
        button.addAction(UIAction { [weak self] _ in self?.onCheckIn?() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, days, button])
        stack.axis = .vertical
        stack.spacing = Spacing.sm + 4
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(Spacing.md) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// 商品行：卡券名、品牌与有效期、本月余量，右侧标价。
func goodsRow(goods: RewardGoods, template: CouponTemplate, remaining: Int, onTap: @escaping () -> Void) -> BenefitsRow {
    let price = UILabel()
    price.text = formattedAmount(goods.price) + " " + goods.currency.unit
    price.font = .abankBodyMedium()
    price.textColor = goods.currency.tint
    price.setContentHuggingPriority(.required, for: .horizontal)
    let subtitle = "\(template.brand) · 本月余 \(remaining) 次"
    let row = BenefitsRow(title: template.title, subtitle: subtitle, trailing: price,
                          id: "mall.goods.\(goods.id)", showsChevron: true)
    row.onTap = onTap
    return row
}
