//
//  WealthSelectionView.swift
//  ABank
//

import UIKit
import SnapKit

final class WealthSelectionView: UIView {

    private let header = SectionHeaderView(title: "财富优选")
    private let featuredCard = UIView()
    private let sideStack = UIStackView()
    private let quoteBar = UIView()
    private let featuredTitle = UILabel()
    private let featuredTag = UILabel()
    private let featuredSubtitle = UILabel()
    private let featuredValue = UILabel()
    private let featuredLabel = UILabel()
    private let featuredButton = UIButton(type: .system)
    private let quoteLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        featured: HomeWealthFeaturedItem,
        sides: [HomeWealthSideItem],
        quotes: [HomeMarketQuote]
    ) {
        featuredTitle.text = featured.title
        featuredTag.text = featured.tag
        featuredSubtitle.text = featured.subtitle
        featuredValue.text = featured.highlightValue
        featuredLabel.text = featured.highlightLabel
        featuredButton.setTitle(featured.actionTitle, for: .normal)

        sideStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        sides.forEach { sideStack.addArrangedSubview(makeSideCard(item: $0)) }

        quoteLabel.text = quotes.map { "\($0.name) \($0.value)" }.joined(separator: "    ")
    }

    private func setupUI() {
        sideStack.axis = .vertical
        sideStack.spacing = 8
        sideStack.distribution = .fillEqually

        styleCard(featuredCard)
        featuredCard.backgroundColor = UIColor(red: 0.96, green: 0.98, blue: 1.0, alpha: 1)

        featuredTitle.font = .systemFont(ofSize: 15, weight: .semibold)
        featuredTitle.textColor = .abankTextPrimary
        featuredTag.font = .systemFont(ofSize: 10, weight: .medium)
        featuredTag.textColor = .abankOrange
        featuredTag.layer.borderColor = UIColor.abankOrange.cgColor
        featuredTag.layer.borderWidth = 0.5
        featuredTag.layer.cornerRadius = 3
        featuredTag.textAlignment = .center
        featuredSubtitle.font = .systemFont(ofSize: 11)
        featuredSubtitle.textColor = .abankTextTertiary
        featuredValue.font = .systemFont(ofSize: 28, weight: .bold)
        featuredValue.textColor = .abankHighlight
        featuredLabel.font = .systemFont(ofSize: 11)
        featuredLabel.textColor = .abankTextTertiary
        featuredButton.backgroundColor = .abankOrange
        featuredButton.setTitleColor(.white, for: .normal)
        featuredButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        featuredButton.layer.cornerRadius = 16

        quoteBar.backgroundColor = UIColor(red: 0.98, green: 0.97, blue: 0.94, alpha: 1)
        quoteBar.layer.cornerRadius = CornerRadius.sm
        quoteLabel.font = .systemFont(ofSize: 12, weight: .medium)
        quoteLabel.textColor = .abankGold
        quoteLabel.textAlignment = .center

        addSubview(header)
        addSubview(featuredCard)
        addSubview(sideStack)
        addSubview(quoteBar)
        quoteBar.addSubview(quoteLabel)

        [featuredTitle, featuredTag, featuredSubtitle, featuredValue, featuredLabel, featuredButton].forEach {
            featuredCard.addSubview($0)
        }

        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(24)
        }
        featuredCard.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(12)
            make.leading.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.48)
            make.height.equalTo(168)
        }
        sideStack.snp.makeConstraints { make in
            make.top.equalTo(featuredCard)
            make.trailing.equalToSuperview()
            make.leading.equalTo(featuredCard.snp.trailing).offset(8)
            make.height.equalTo(featuredCard)
        }
        quoteBar.snp.makeConstraints { make in
            make.top.equalTo(featuredCard.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(36)
        }
        quoteLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        featuredTitle.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(12)
        }
        featuredTag.snp.makeConstraints { make in
            make.leading.equalTo(featuredTitle.snp.trailing).offset(6)
            make.centerY.equalTo(featuredTitle)
            make.height.equalTo(16)
            make.width.equalTo(28)
        }
        featuredSubtitle.snp.makeConstraints { make in
            make.top.equalTo(featuredTitle.snp.bottom).offset(4)
            make.leading.equalTo(featuredTitle)
        }
        featuredValue.snp.makeConstraints { make in
            make.top.equalTo(featuredSubtitle.snp.bottom).offset(14)
            make.leading.equalTo(featuredTitle)
        }
        featuredLabel.snp.makeConstraints { make in
            make.top.equalTo(featuredValue.snp.bottom).offset(2)
            make.leading.equalTo(featuredTitle)
        }
        featuredButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-12)
            make.height.equalTo(32)
        }
    }

    private func makeSideCard(item: HomeWealthSideItem) -> UIView {
        let card = UIView()
        styleCard(card)
        card.backgroundColor = UIColor(red: 1.0, green: 0.98, blue: 0.94, alpha: 1)

        let title = UILabel()
        title.text = item.title
        title.font = .systemFont(ofSize: 14, weight: .semibold)
        title.textColor = .abankTextPrimary

        let tag = UILabel()
        tag.text = item.tag
        tag.font = .systemFont(ofSize: 10)
        tag.textColor = .abankOrange
        tag.layer.borderWidth = 0.5
        tag.layer.borderColor = UIColor.abankOrange.cgColor
        tag.layer.cornerRadius = 3
        tag.textAlignment = .center

        let subtitle = UILabel()
        subtitle.text = item.subtitle
        subtitle.font = .systemFont(ofSize: 11)
        subtitle.textColor = .abankTextTertiary
        subtitle.numberOfLines = 1

        let action = UILabel()
        action.text = item.actionTitle
        action.font = .systemFont(ofSize: 12, weight: .medium)
        action.textColor = .abankOrange

        [title, tag, subtitle, action].forEach { card.addSubview($0) }
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
        action.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
        }
        return card
    }

    private func styleCard(_ view: UIView) {
        view.layer.cornerRadius = CornerRadius.md
        view.clipsToBounds = true
    }
}
