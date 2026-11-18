import UIKit
import SnapKit

final class LifeMasonryGridView: UIView {
    var onItemTapped: ((Int) -> Void)?

    private let columns = [UIStackView(), UIStackView()]

    override init(frame: CGRect) {
        super.init(frame: frame)
        for column in columns {
            column.axis = .vertical
            column.spacing = 12
        }

        let stack = UIStackView(arrangedSubviews: columns)
        stack.spacing = 12
        stack.distribution = .fillEqually
        stack.alignment = .top
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with items: [LifeFeedItem]) {
        columns.forEach { $0.arrangedSubviews.forEach { $0.removeFromSuperview() } }
        var columnHeights: [CGFloat] = [0, 0]
        for (index, item) in items.enumerated() {
            let column = columnHeights[0] <= columnHeights[1] ? 0 : 1
            let card = makeFeedCard(item, index: index)
            columns[column].addArrangedSubview(card)
            columnHeights[column] += item.imageAspectRatio + 0.38
        }
    }

    private func makeFeedCard(_ item: LifeFeedItem, index: Int) -> UIView {
        let card = UIControl()
        card.backgroundColor = .abankCardBackground
        card.layer.cornerRadius = 12
        card.clipsToBounds = true
        card.isAccessibilityElement = true
        card.accessibilityTraits = .button
        card.accessibilityLabel = "\(item.title)，\(item.subtitle)"
        card.accessibilityIdentifier = "life.feed.\(index)"
        card.addAction(UIAction { [weak self] _ in self?.onItemTapped?(index) }, for: .touchUpInside)

        let cover = UIView()
        cover.backgroundColor = item.imageBackground
        let art = UIImageView(image: UIImage(named: item.artworkName))
        art.contentMode = .scaleAspectFit
        cover.addSubview(art)

        let title = UILabel()
        title.text = item.title
        title.font = .systemFont(ofSize: 16, weight: .medium)
        title.textColor = .abankTextPrimary
        title.numberOfLines = 2
        let subtitle = UILabel()
        subtitle.text = item.subtitle
        subtitle.font = .abankCaption()
        subtitle.textColor = .abankTextSecondary
        subtitle.numberOfLines = 2

        let copy = UIStackView(arrangedSubviews: [title, subtitle])
        copy.axis = .vertical
        copy.spacing = 4
        copy.isUserInteractionEnabled = false
        cover.isUserInteractionEnabled = false
        card.addSubview(cover)
        card.addSubview(copy)
        cover.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(cover.snp.width).multipliedBy(item.imageAspectRatio)
        }
        art.snp.makeConstraints { $0.edges.equalToSuperview().inset(7) }
        copy.snp.makeConstraints { make in
            make.top.equalTo(cover.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }
        return card
    }
}
