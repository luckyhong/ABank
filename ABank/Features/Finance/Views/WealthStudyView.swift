//
//  WealthStudyView.swift
//  ABank
//

import UIKit
import SnapKit

final class WealthStudyView: UIView {

    var onHeaderTapped: (() -> Void)?
    var onBannerTapped: (() -> Void)?
    var onCardTapped: ((Int) -> Void)?

    private let header = WealthSectionHeaderView(title: "财富研习所")
    private let bannerCard = UIView()
    private let bannerTitle = UILabel()
    private let bannerBrand = UILabel()
    private let adTag = UILabel()
    private let cardStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(banner: WealthStudyBanner, cards: [WealthStudyCard]) {
        bannerTitle.text = banner.title
        bannerBrand.text = banner.brand
        adTag.isHidden = !banner.isAd

        cardStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        cards.enumerated().forEach { index, card in
            cardStack.addArrangedSubview(makeStudyCard(card, index: index))
        }
    }

    private func setupUI() {
        header.onTap = { [weak self] in self?.onHeaderTapped?() }

        bannerCard.backgroundColor = UIColor(red: 0.75, green: 0.85, blue: 0.95, alpha: 1)
        bannerCard.layer.cornerRadius = CornerRadius.lg
        bannerCard.clipsToBounds = true
        bannerCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(bannerTapped)))

        bannerBrand.font = .systemFont(ofSize: 11, weight: .medium)
        bannerBrand.textColor = .white
        bannerBrand.backgroundColor = UIColor.abankPrimary.withAlphaComponent(0.8)
        bannerBrand.layer.cornerRadius = 4
        bannerBrand.clipsToBounds = true
        bannerBrand.textAlignment = .center

        bannerTitle.font = .systemFont(ofSize: 20, weight: .bold)
        bannerTitle.textColor = UIColor(red: 0.1, green: 0.35, blue: 0.65, alpha: 1)
        bannerTitle.numberOfLines = 2

        adTag.text = "【广告】"
        adTag.font = .systemFont(ofSize: 9)
        adTag.textColor = .abankTextTertiary

        cardStack.axis = .horizontal
        cardStack.spacing = 10
        cardStack.distribution = .fillEqually

        addSubview(header)
        addSubview(bannerCard)
        addSubview(cardStack)
        [bannerBrand, bannerTitle, adTag].forEach { bannerCard.addSubview($0) }

        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        bannerCard.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(140)
        }
        bannerBrand.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(12)
            make.height.equalTo(20)
            make.width.greaterThanOrEqualTo(80)
        }
        bannerTitle.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-20)
        }
        adTag.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(8)
        }
        cardStack.snp.makeConstraints { make in
            make.top.equalTo(bannerCard.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(100)
        }
    }

    private func makeStudyCard(_ item: WealthStudyCard, index: Int) -> UIView {
        let card = UIControl()
        card.tag = index
        card.addAction(UIAction { [weak self] _ in self?.onCardTapped?(index) }, for: .touchUpInside)
        card.backgroundColor = item.backgroundColor
        card.layer.cornerRadius = CornerRadius.md
        card.clipsToBounds = true

        let title = UILabel()
        title.text = item.title
        title.font = .systemFont(ofSize: 13, weight: .medium)
        title.textColor = .abankTextPrimary
        title.numberOfLines = 3

        let button = UILabel()
        button.text = item.actionTitle
        button.font = .systemFont(ofSize: 12, weight: .bold)
        button.textColor = .white
        button.backgroundColor = .abankOrange
        button.textAlignment = .center
        button.layer.cornerRadius = 10
        button.clipsToBounds = true

        card.addSubview(title)
        card.addSubview(button)
        title.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(10)
        }
        button.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
            make.width.equalTo(36)
            make.height.equalTo(20)
        }
        return card
    }

    @objc private func bannerTapped() { onBannerTapped?() }
}
