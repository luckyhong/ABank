//
//  LifeMasonryGridView.swift
//  ABank
//

import UIKit
import SnapKit

final class LifeMasonryGridView: UIView {

    var onItemTapped: ((Int) -> Void)?

    private let leftColumn = UIStackView()
    private let rightColumn = UIStackView()
    private let columnsContainer = UIStackView()
    private var items: [LifeFeedItem] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with items: [LifeFeedItem]) {
        self.items = items
        leftColumn.arrangedSubviews.forEach { $0.removeFromSuperview() }
        rightColumn.arrangedSubviews.forEach { $0.removeFromSuperview() }

        var leftHeight: CGFloat = 0
        var rightHeight: CGFloat = 0
        let spacing: CGFloat = 10

        items.enumerated().forEach { index, item in
            let card = makeFeedCard(item, index: index)
            let cardHeight = item.imageHeight + 56 + spacing
            if leftHeight <= rightHeight {
                leftColumn.addArrangedSubview(card)
                leftHeight += cardHeight
            } else {
                rightColumn.addArrangedSubview(card)
                rightHeight += cardHeight
            }
        }
    }

    private func setupUI() {
        leftColumn.axis = .vertical
        rightColumn.axis = .vertical
        leftColumn.spacing = 10
        rightColumn.spacing = 10
        columnsContainer.axis = .horizontal
        columnsContainer.spacing = 10
        columnsContainer.distribution = .fillEqually
        columnsContainer.alignment = .top
        columnsContainer.addArrangedSubview(leftColumn)
        columnsContainer.addArrangedSubview(rightColumn)
        addSubview(columnsContainer)
        columnsContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func makeFeedCard(_ item: LifeFeedItem, index: Int) -> UIView {
        let card = UIControl()
        card.tag = index
        card.addAction(UIAction { [weak self] _ in self?.onItemTapped?(index) }, for: .touchUpInside)
        card.backgroundColor = .abankCardBackground
        card.layer.cornerRadius = CornerRadius.md
        card.clipsToBounds = true
        card.addShadow(color: .black, opacity: 0.04, offset: CGSize(width: 0, height: 1), radius: 4)

        let imageArea = UIView()
        imageArea.backgroundColor = item.imageBackground
        let icon = UIImageView(image: UIImage(systemName: item.systemIcon))
        icon.tintColor = item.iconTint
        icon.contentMode = .scaleAspectFit
        imageArea.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(40)
        }

        let ad = UILabel()
        ad.text = "【广告】"
        ad.font = .systemFont(ofSize: 9)
        ad.textColor = .abankTextTertiary.withAlphaComponent(0.85)
        ad.isHidden = !item.isAd

        let title = UILabel()
        title.text = item.title
        title.font = .systemFont(ofSize: 14, weight: .medium)
        title.textColor = .abankTextPrimary
        title.numberOfLines = 2

        let subtitle = UILabel()
        subtitle.text = item.subtitle
        subtitle.font = .systemFont(ofSize: 11)
        subtitle.textColor = .abankTextTertiary
        subtitle.numberOfLines = 2

        [imageArea, ad, title, subtitle].forEach { card.addSubview($0) }
        imageArea.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(item.imageHeight)
        }
        ad.snp.makeConstraints { make in
            make.trailing.bottom.equalTo(imageArea).inset(6)
        }
        title.snp.makeConstraints { make in
            make.top.equalTo(imageArea.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(10)
        }
        subtitle.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(4)
            make.leading.trailing.equalTo(title)
            make.bottom.equalToSuperview().offset(-10)
        }
        return card
    }
}
