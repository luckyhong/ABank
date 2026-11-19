//
//  HotActivitiesView.swift
//  ABank
//

import UIKit
import SnapKit

final class HotActivitiesView: UIView {

    var onAction: ((AppRoute) -> Void)?

    private let header = SectionHeaderView(title: "日常权益", showsChevron: false)
    private let featuredCard = UIControl()
    private let sideStack = UIStackView()
    private let featuredTitle = UILabel()
    private let featuredSubtitle = UILabel()
    private let featuredArt = UIImageView()
    private var featuredRoute: AppRoute?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(featured: HomeActivityFeaturedItem, sides: [HomeActivitySideItem]) {
        featuredTitle.text = featured.title
        featuredSubtitle.text = featured.subtitle
        featuredRoute = featured.route
        featuredCard.accessibilityLabel = "\(featured.title)，\(featured.subtitle)"

        sideStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        sides.forEach { sideStack.addArrangedSubview(makeSideCard(item: $0)) }
    }

    private func setupUI() {
        sideStack.axis = .vertical
        sideStack.spacing = 8
        sideStack.distribution = .fillEqually

        featuredCard.backgroundColor = UIColor(red: 1.0, green: 0.96, blue: 0.92, alpha: 1)
        featuredCard.layer.cornerRadius = CornerRadius.md
        featuredCard.clipsToBounds = true
        featuredCard.isAccessibilityElement = true
        featuredCard.accessibilityTraits = .button
        featuredCard.addAction(UIAction { [weak self] _ in
            guard let self, let route = self.featuredRoute else { return }
            self.onAction?(route)
        }, for: .touchUpInside)

        featuredTitle.font = .systemFont(ofSize: 15, weight: .semibold)
        featuredTitle.textColor = .abankTextPrimary
        featuredSubtitle.font = .systemFont(ofSize: 12)
        featuredSubtitle.textColor = .abankTextSecondary
        featuredArt.image = UIImage(systemName: "gift.fill")
        featuredArt.tintColor = .abankOrange
        featuredArt.contentMode = .scaleAspectFit

        addSubview(header)
        addSubview(featuredCard)
        addSubview(sideStack)
        [featuredTitle, featuredSubtitle, featuredArt].forEach { featuredCard.addSubview($0) }

        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(24)
        }
        featuredCard.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(12)
            make.leading.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.48)
            make.height.equalTo(148)
        }
        sideStack.snp.makeConstraints { make in
            make.top.bottom.equalTo(featuredCard)
            make.trailing.equalToSuperview()
            make.leading.equalTo(featuredCard.snp.trailing).offset(8)
        }
        featuredTitle.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }
        featuredSubtitle.snp.makeConstraints { make in
            make.top.equalTo(featuredTitle.snp.bottom).offset(6)
            make.leading.trailing.equalTo(featuredTitle)
        }
        featuredArt.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-16)
            make.size.equalTo(48)
        }
    }

    private func makeSideCard(item: HomeActivitySideItem) -> UIView {
        let card = UIControl()
        card.backgroundColor = .abankCardBackground
        card.layer.cornerRadius = CornerRadius.md
        card.clipsToBounds = true
        card.layer.borderWidth = 0.5
        card.layer.borderColor = UIColor.abankSeparator.cgColor
        card.isAccessibilityElement = true
        card.accessibilityTraits = .button
        card.accessibilityLabel = "\(item.title)，\(item.subtitle)"
        card.addAction(UIAction { [weak self] _ in self?.onAction?(item.route) }, for: .touchUpInside)

        let title = UILabel()
        title.text = item.title
        title.font = .systemFont(ofSize: 14, weight: .semibold)
        title.textColor = .abankTextPrimary

        let subtitle = UILabel()
        subtitle.text = item.subtitle
        subtitle.font = .systemFont(ofSize: 11)
        subtitle.textColor = .abankTextTertiary

        let action = UILabel()
        action.text = item.actionTitle
        action.font = .systemFont(ofSize: 12, weight: .medium)
        action.textColor = .abankOrange

        [title, subtitle, action].forEach { card.addSubview($0) }
        title.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-10)
        }
        subtitle.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(4)
            make.leading.trailing.equalTo(title)
        }
        action.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
        }
        return card
    }
}
