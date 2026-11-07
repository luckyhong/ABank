//
//  ReservationPickerViews.swift
//  ABank
//
//  预约表单复用视图：时段宫格、数量步进器、可点击选择行。
//

import UIKit
import SnapKit

/// 时段宫格：每行 3 个，已过或约满置灰并标注。
final class ReservationSlotGridView: UIView {
    var onSelect: ((Int) -> Void)?

    init(slots: [ReservationSlot], selected: Int?) {
        super.init(frame: .zero)
        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = Spacing.sm
        let columns = 3
        for start in stride(from: 0, to: slots.count, by: columns) {
            let row = UIStackView()
            row.spacing = Spacing.sm
            row.distribution = .fillEqually
            for index in start..<(start + columns) {
                guard index < slots.count else {
                    row.addArrangedSubview(UIView())
                    continue
                }
                row.addArrangedSubview(button(for: slots[index], selected: slots[index].startMinute == selected))
            }
            grid.addArrangedSubview(row)
        }
        addSubview(grid)
        grid.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func button(for slot: ReservationSlot, selected: Bool) -> UIButton {
        let button = UIButton(type: .system)
        let title = slot.label + (slot.isAvailable ? "" : "\n不可约")
        button.setTitle(title, for: .normal)
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: selected ? .medium : .regular)
        button.setTitleColor(selected ? .white : (slot.isAvailable ? .abankTextPrimary : .abankTextTertiary), for: .normal)
        button.backgroundColor = selected ? .abankPrimary : (slot.isAvailable ? .abankCardBackground : .abankSectionBackground)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = selected ? 0 : 0.8
        button.layer.borderColor = UIColor.abankSeparator.cgColor
        button.isEnabled = slot.isAvailable
        button.accessibilityIdentifier = "reservation.slot.\(slot.startMinute)"
        if selected { button.accessibilityTraits.insert(.selected) }
        button.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44) }
        button.addAction(UIAction { [weak self] _ in self?.onSelect?(slot.startMinute) }, for: .touchUpInside)
        return button
    }
}

/// 数量步进器行。
final class QuantityStepperRow: UIView {
    var onChange: ((Int) -> Void)?
    private let stepper = UIStepper()
    private let valueLabel = UILabel()

    init(title: String, value: Int, range: ClosedRange<Int>) {
        super.init(frame: .zero)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .abankBody()
        titleLabel.textColor = .abankTextPrimary
        valueLabel.font = .abankBodyMedium()
        valueLabel.textColor = .abankTextPrimary
        valueLabel.accessibilityIdentifier = "reservation.quantity.value"
        stepper.minimumValue = Double(range.lowerBound)
        stepper.maximumValue = Double(range.upperBound)
        stepper.value = Double(value)
        stepper.accessibilityIdentifier = "reservation.quantity"
        stepper.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let value = Int(self.stepper.value)
            self.valueLabel.text = "\(value) 枚"
            self.onChange?(value)
        }, for: .valueChanged)
        valueLabel.text = "\(value) 枚"
        let stack = UIStackView(arrangedSubviews: [titleLabel, UIView(), valueLabel, stepper])
        stack.spacing = Spacing.sm
        stack.alignment = .center
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// 标题 + 值 + 箭头的可点击行。
final class BranchSelectRow: UIControl {
    var onTap: (() -> Void)?

    init(title: String, value: String, id: String) {
        super.init(frame: .zero)
        accessibilityIdentifier = id
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = title + "，" + value
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .abankBody()
        titleLabel.textColor = .abankTextSecondary
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .abankBody()
        valueLabel.textColor = .abankTextPrimary
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 0
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right",
                                                 withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)))
        chevron.tintColor = .abankTextTertiary
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel, chevron])
        stack.spacing = Spacing.sm
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)) }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(36) }
        addAction(UIAction { [weak self] _ in self?.onTap?() }, for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
