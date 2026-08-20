//
//  WealthSpareMoneyZoneView.swift
//  ABank
//

import UIKit
import SnapKit

final class WealthSpareMoneyZoneView: UIView {

    var onHeaderTapped: (() -> Void)?
    var onFeaturedTapped: (() -> Void)?
    var onSideTapped: ((Int) -> Void)?

    private let header = WealthSectionHeaderView(title: "活钱专区", subtitle: "闲钱打理 随用随赎")
    private let card = UIView()
    private let featuredCard = UIView()
    private let sideStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(featured: WealthSpareMoneyFeatured, sides: [WealthSpareMoneySide]) {
        buildFeaturedCard(featured)
        sideStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        sides.enumerated().forEach { index, side in
            sideStack.addArrangedSubview(makeSideCard(side, index: index))
        }
        updateCardHeightConstraints()
    }

    private func updateCardHeightConstraints() {
        featuredCard.snp.remakeConstraints { make in
            make.top.leading.equalToSuperview().inset(12)
            make.width.equalToSuperview().multipliedBy(0.48)
        }
        sideStack.snp.remakeConstraints { make in
            make.top.trailing.equalToSuperview().inset(12)
            make.leading.equalTo(featuredCard.snp.trailing).offset(8)
        }
        card.snp.remakeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.bottom.equalTo(featuredCard.snp.bottom).offset(12)
            make.bottom.equalTo(sideStack.snp.bottom).offset(12)
        }
    }

    private func setupUI() {
        header.onTap = { [weak self] in self?.onHeaderTapped?() }

        card.backgroundColor = .abankCardBackground
        card.layer.cornerRadius = CornerRadius.lg
        card.addShadow(color: .black, opacity: 0.06, offset: CGSize(width: 0, height: 2), radius: 8)

        sideStack.axis = .vertical
        sideStack.spacing = 8
        sideStack.distribution = .fill

        addSubview(header)
        addSubview(card)
        card.addSubview(featuredCard)
        card.addSubview(sideStack)

        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
    }

    private func buildFeaturedCard(_ item: WealthSpareMoneyFeatured) {
        featuredCard.subviews.forEach { $0.removeFromSuperview() }
        styleInnerCard(featuredCard, bg: UIColor(red: 0.98, green: 0.97, blue: 0.94, alpha: 1))

        let title = UILabel()
        title.text = item.title
        title.font = .systemFont(ofSize: 15, weight: .semibold)
        title.textColor = .abankTextPrimary

        let tag = WealthProductTagView(text: item.tag)
        let descStack = UIStackView()
        descStack.axis = .vertical
        descStack.spacing = 2
        item.descriptions.forEach { text in
            let label = UILabel()
            label.text = text
            label.font = .systemFont(ofSize: 11)
            label.textColor = .abankTextTertiary
            descStack.addArrangedSubview(label)
        }

        let yield = UILabel()
        yield.text = item.yieldRate
        yield.font = .systemFont(ofSize: 28, weight: .bold)
        yield.textColor = .abankHighlight

        let yieldTitle = UILabel()
        yieldTitle.text = item.yieldLabel
        yieldTitle.font = .systemFont(ofSize: 11)
        yieldTitle.textColor = .abankTextTertiary

        let button = UIButton(type: .system)
        button.setTitle(item.actionTitle, for: .normal)
        button.setTitleColor(.abankOrange, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        button.backgroundColor = UIColor.abankOrange.withAlphaComponent(0.15)
        button.layer.cornerRadius = 14
        button.addAction(UIAction { [weak self] _ in self?.onFeaturedTapped?() }, for: .touchUpInside)

        [title, tag, descStack, yield, yieldTitle, button].forEach { featuredCard.addSubview($0) }
        title.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(10)
        }
        tag.snp.makeConstraints { make in
            make.leading.equalTo(title.snp.trailing).offset(6)
            make.centerY.equalTo(title)
            make.height.equalTo(16)
            make.width.greaterThanOrEqualTo(28)
        }
        descStack.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(10)
        }
        yield.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.top.equalTo(descStack.snp.bottom).offset(10)
        }
        yieldTitle.snp.makeConstraints { make in
            make.leading.equalTo(yield)
            make.top.equalTo(yield.snp.bottom).offset(2)
        }
        button.snp.makeConstraints { make in
            make.top.equalTo(yieldTitle.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(10)
            make.bottom.equalToSuperview().offset(-10)
            make.height.equalTo(28)
        }
    }

    private func makeSideCard(_ item: WealthSpareMoneySide, index: Int) -> UIView {
        let wrap = UIControl()
        wrap.tag = index
        wrap.addAction(UIAction { [weak self] _ in self?.onSideTapped?(index) }, for: .touchUpInside)
        styleInnerCard(wrap, bg: UIColor(red: 1.0, green: 0.98, blue: 0.94, alpha: 1))

        let title = UILabel()
        title.text = item.title
        title.font = .systemFont(ofSize: 14, weight: .semibold)
        title.textColor = .abankTextPrimary

        let tag = WealthProductTagView(text: item.tag)
        let subtitle = UILabel()
        subtitle.text = item.subtitle
        subtitle.font = .systemFont(ofSize: 11)
        subtitle.textColor = .abankTextTertiary

        let yieldText = NSMutableAttributedString()
        if let prefix = item.yieldPrefix {
            yieldText.append(NSAttributedString(
                string: prefix + " ",
                attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.abankTextSecondary]
            ))
        }
        yieldText.append(NSAttributedString(
            string: item.yieldRate,
            attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .semibold), .foregroundColor: UIColor.abankHighlight]
        ))

        let yieldLabel = UILabel()
        yieldLabel.attributedText = yieldText

        [title, tag, subtitle, yieldLabel].forEach { wrap.addSubview($0) }
        title.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(10)
        }
        tag.snp.makeConstraints { make in
            make.leading.equalTo(title.snp.trailing).offset(6)
            make.centerY.equalTo(title)
            make.height.equalTo(16)
            make.width.greaterThanOrEqualTo(28)
        }
        subtitle.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(10)
        }
        yieldLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.top.greaterThanOrEqualTo(subtitle.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-10)
        }
        wrap.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(72)
        }
        return wrap
    }

    private func styleInnerCard(_ view: UIView, bg: UIColor) {
        view.backgroundColor = bg
        view.layer.cornerRadius = CornerRadius.md
        view.clipsToBounds = true
    }
}
