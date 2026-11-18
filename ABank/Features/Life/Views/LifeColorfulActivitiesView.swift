import UIKit
import SnapKit

final class LifeColorfulActivitiesView: UIView {
    var onHeaderTapped: (() -> Void)?
    var onFeaturedTapped: (() -> Void)?
    var onSideTapped: ((Int) -> Void)?
    var onPromoTapped: (() -> Void)?

    private let header = SectionHeaderView(title: "缤纷活动", titleFont: .abankTitle2())
    private let featuredCard = LifeActivityTile(featured: true)
    private let sideStack = UIStackView()
    private let promo = LifeActivityTile(featured: false, wide: true)

    override init(frame: CGRect) {
        super.init(frame: frame)
        sideStack.axis = .vertical
        sideStack.spacing = 12
        sideStack.distribution = .fillEqually
        [header, featuredCard, sideStack, promo].forEach { addSubview($0) }

        header.onTap = { [weak self] in self?.onHeaderTapped?() }
        featuredCard.addAction(UIAction { [weak self] _ in self?.onFeaturedTapped?() }, for: .touchUpInside)
        promo.addAction(UIAction { [weak self] _ in self?.onPromoTapped?() }, for: .touchUpInside)
        featuredCard.accessibilityIdentifier = "life.activity.featured"
        promo.accessibilityIdentifier = "life.activity.promo"

        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(36)
        }
        featuredCard.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(12)
            make.leading.equalToSuperview()
            make.width.equalTo(sideStack)
            make.height.equalTo(featuredCard.snp.width).multipliedBy(1.1).priority(999)
            make.height.greaterThanOrEqualTo(174)
        }
        sideStack.snp.makeConstraints { make in
            make.top.bottom.equalTo(featuredCard)
            make.leading.equalTo(featuredCard.snp.trailing).offset(12)
            make.trailing.equalToSuperview()
        }
        promo.snp.makeConstraints { make in
            make.top.equalTo(featuredCard.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.greaterThanOrEqualTo(96)
            make.height.equalTo(96).priority(999)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(featured: LifeActivityCard, sides: [LifeActivityCard], promo: LifeActivityCard) {
        featuredCard.configure(featured)
        sideStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, item) in sides.enumerated() {
            let tile = LifeActivityTile(featured: false)
            tile.configure(item)
            tile.accessibilityIdentifier = "life.activity.side.\(index)"
            tile.addAction(UIAction { [weak self] _ in self?.onSideTapped?(index) }, for: .touchUpInside)
            sideStack.addArrangedSubview(tile)
        }
        self.promo.configure(promo)
    }
}

private final class LifeActivityTile: UIControl {
    private let title = UILabel()
    private let subtitle = UILabel()
    private let art = UIImageView()

    init(featured: Bool, wide: Bool = false) {
        super.init(frame: .zero)
        layer.cornerRadius = 14
        clipsToBounds = true
        isAccessibilityElement = true
        accessibilityTraits = .button

        title.font = .systemFont(ofSize: wide ? 19 : 16, weight: .semibold)
        title.textColor = .abankTextPrimary
        title.numberOfLines = 2
        subtitle.font = .systemFont(ofSize: 13)
        subtitle.textColor = .abankTextSecondary
        subtitle.numberOfLines = 2
        art.contentMode = .scaleAspectFit

        let copy = UIStackView(arrangedSubviews: [title, subtitle])
        copy.axis = .vertical
        copy.spacing = 5
        copy.isUserInteractionEnabled = false
        addSubview(copy)
        addSubview(art)
        copy.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(14)
            if featured {
                make.top.trailing.equalToSuperview().inset(14)
            } else {
                make.top.greaterThanOrEqualToSuperview().inset(10)
                make.bottom.lessThanOrEqualToSuperview().inset(10)
                make.centerY.equalToSuperview()
                make.trailing.equalTo(art.snp.leading).offset(-4)
            }
        }
        art.snp.makeConstraints { make in
            if featured {
                make.top.equalTo(copy.snp.bottom).offset(4)
                make.leading.trailing.bottom.equalToSuperview().inset(6)
            } else {
                make.trailing.equalToSuperview().inset(6)
                make.centerY.equalToSuperview()
                make.width.equalToSuperview().multipliedBy(wide ? 0.29 : 0.30)
                make.height.equalToSuperview().multipliedBy(0.84)
            }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(_ item: LifeActivityCard) {
        backgroundColor = item.backgroundColor
        title.text = item.title
        subtitle.text = item.subtitle
        art.image = UIImage(named: item.artworkName)
        accessibilityLabel = "\(item.title)，\(item.subtitle)"
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.76 : 1 }
    }
}
