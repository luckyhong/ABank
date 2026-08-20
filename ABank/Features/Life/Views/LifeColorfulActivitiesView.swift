//
//  LifeColorfulActivitiesView.swift
//  ABank
//

import UIKit
import SnapKit

final class LifeColorfulActivitiesView: UIView {

    var onHeaderTapped: (() -> Void)?
    var onFeaturedTapped: (() -> Void)?
    var onSideTapped: ((Int) -> Void)?
    var onPromoTapped: (() -> Void)?

    private let header = SectionHeaderView(title: "缤纷活动")
    private let featuredCard = UIView()
    private let sideStack = UIStackView()
    private let promoBanner = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(
        featured: LifeActivityCard,
        sides: [LifeActivityCard],
        promo: LifePromoBanner
    ) {
        buildFeaturedCard(featured)
        sideStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        sides.enumerated().forEach { index, card in
            sideStack.addArrangedSubview(makeSideCard(card, index: index))
        }
        buildPromoBanner(promo)
    }

    private func setupUI() {
        header.onTap = { [weak self] in self?.onHeaderTapped?() }
        sideStack.axis = .vertical
        sideStack.spacing = 8
        sideStack.distribution = .fillEqually

        addSubview(header)
        addSubview(featuredCard)
        addSubview(sideStack)
        addSubview(promoBanner)

        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(24)
        }
        featuredCard.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(12)
            make.leading.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.48)
            make.height.equalTo(148)
        }
        sideStack.snp.makeConstraints { make in
            make.top.equalTo(featuredCard)
            make.trailing.equalToSuperview()
            make.leading.equalTo(featuredCard.snp.trailing).offset(8)
            make.height.equalTo(featuredCard)
        }
        promoBanner.snp.makeConstraints { make in
            make.top.equalTo(featuredCard.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(72)
        }
    }

    private func buildFeaturedCard(_ item: LifeActivityCard) {
        featuredCard.subviews.forEach { $0.removeFromSuperview() }
        styleCard(featuredCard, bg: item.backgroundColor)
        featuredCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(featuredTapped)))

        let title = UILabel()
        title.text = item.title
        title.font = .systemFont(ofSize: 15, weight: .semibold)
        title.textColor = .abankTextPrimary
        let subtitle = UILabel()
        subtitle.text = item.subtitle
        subtitle.font = .systemFont(ofSize: 12)
        subtitle.textColor = .abankTextSecondary
        let icon = UIImageView(image: UIImage(systemName: item.systemIcon))
        icon.tintColor = .abankOrange
        icon.contentMode = .scaleAspectFit
        let ad = adTag(isAd: item.isAd)
        [title, subtitle, icon, ad].forEach { featuredCard.addSubview($0) }
        title.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }
        subtitle.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(6)
            make.leading.trailing.equalTo(title)
        }
        icon.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(12)
            make.size.equalTo(44)
        }
        ad.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-10)
        }
    }

    private func makeSideCard(_ item: LifeActivityCard, index: Int) -> UIView {
        let card = UIControl()
        card.addAction(UIAction { [weak self] _ in self?.onSideTapped?(index) }, for: .touchUpInside)
        styleCard(card, bg: item.backgroundColor)
        card.layer.borderWidth = 0.5
        card.layer.borderColor = UIColor.abankSeparator.cgColor

        let title = UILabel()
        title.text = item.title
        title.font = .systemFont(ofSize: 14, weight: .semibold)
        title.textColor = .abankTextPrimary
        let subtitle = UILabel()
        subtitle.text = item.subtitle
        subtitle.font = .systemFont(ofSize: 11)
        subtitle.textColor = .abankTextTertiary
        let icon = UIImageView(image: UIImage(systemName: item.systemIcon))
        icon.tintColor = item.title == "茶影优惠享"
            ? UIColor(red: 0.55, green: 0.32, blue: 0.18, alpha: 1)
            : .abankPrimary
        icon.contentMode = .scaleAspectFit
        let ad = adTag(isAd: item.isAd)
        [title, subtitle, icon, ad].forEach { card.addSubview($0) }
        title.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-10)
        }
        subtitle.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(4)
            make.leading.trailing.equalTo(title)
        }
        icon.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview().offset(4)
            make.size.equalTo(28)
        }
        ad.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.bottom.equalToSuperview().offset(-8)
        }
        return card
    }

    private func buildPromoBanner(_ item: LifePromoBanner) {
        promoBanner.subviews.forEach { $0.removeFromSuperview() }
        styleCard(promoBanner, bg: item.backgroundColor)
        promoBanner.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(promoTapped)))

        let title = UILabel()
        title.text = item.title
        title.font = .systemFont(ofSize: 16, weight: .semibold)
        title.textColor = .abankTextPrimary
        let subtitle = UILabel()
        subtitle.text = item.subtitle
        subtitle.font = .systemFont(ofSize: 12)
        subtitle.textColor = .abankTextSecondary
        let icon = UIImageView(image: UIImage(systemName: item.systemIcon))
        icon.tintColor = .abankHighlight
        icon.contentMode = .scaleAspectFit
        let ad = adTag(isAd: item.isAd)
        [title, subtitle, icon, ad].forEach { promoBanner.addSubview($0) }
        title.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.top.equalToSuperview().offset(14)
        }
        subtitle.snp.makeConstraints { make in
            make.leading.equalTo(title)
            make.top.equalTo(title.snp.bottom).offset(4)
        }
        icon.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }
        ad.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(8)
        }
    }

    private func styleCard(_ view: UIView, bg: UIColor) {
        view.backgroundColor = bg
        view.layer.cornerRadius = CornerRadius.md
        view.clipsToBounds = true
    }

    private func adTag(isAd: Bool) -> UILabel {
        let label = UILabel()
        label.text = "【广告】"
        label.font = .systemFont(ofSize: 9)
        label.textColor = .abankTextTertiary
        label.isHidden = !isAd
        return label
    }

    @objc private func featuredTapped() { onFeaturedTapped?() }
    @objc private func promoTapped() { onPromoTapped?() }
}
