//
//  FeatureCategoryIndexView.swift
//  ABank
//
//  全部功能页左侧分类索引。
//

import UIKit
import SnapKit

final class FeatureCategoryIndexView: UIView {
    var onSelect: ((FeatureCategory) -> Void)?

    private var buttons: [FeatureCategory: UIButton] = [:]
    private var indicators: [FeatureCategory: UIView] = [:]

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .abankSectionBackground

        let stack = UIStackView()
        stack.axis = .vertical
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        for category in FeatureCategory.allCases {
            let button = UIButton(type: .custom)
            button.setTitle(category.title, for: .normal)
            button.titleLabel?.font = .abankCaption()
            button.titleLabel?.numberOfLines = 2
            button.titleLabel?.textAlignment = .center
            button.accessibilityIdentifier = "featureIndex.\(category.rawValue)"
            button.addAction(UIAction { [weak self] _ in
                self?.setHighlighted(category)
                self?.onSelect?(category)
            }, for: .touchUpInside)

            let indicator = UIView()
            indicator.backgroundColor = .abankPrimary
            button.addSubview(indicator)
            indicator.snp.makeConstraints { make in
                make.leading.centerY.equalToSuperview()
                make.width.equalTo(3)
                make.height.equalTo(16)
            }
            button.snp.makeConstraints { make in make.height.equalTo(52) }
            stack.addArrangedSubview(button)
            buttons[category] = button
            indicators[category] = indicator
        }
        setHighlighted(.account)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setHighlighted(_ category: FeatureCategory) {
        for (item, button) in buttons {
            let selected = item == category
            button.backgroundColor = selected ? .abankCardBackground : .clear
            button.setTitleColor(selected ? .abankPrimary : .abankTextSecondary, for: .normal)
            button.titleLabel?.font = selected ? .abankCaptionMedium() : .abankCaption()
            button.isSelected = selected
            indicators[item]?.isHidden = !selected
        }
    }
}
