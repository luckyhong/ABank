import UIKit
import SnapKit

final class WealthFunctionGridView: UIView {
    var onItemTapped: ((Int) -> Void)?

    private let stack = UIStackView()
    private var items: [WealthGridItem] = []
    private var columns: Int { traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 3 : 5 }

    override init(frame: CGRect) {
        super.init(frame: frame)
        stack.axis = .vertical
        stack.spacing = 10
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if let previousTraitCollection,
           previousTraitCollection.preferredContentSizeCategory.isAccessibilityCategory
            != traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            rebuildRows()
        }
    }

    func configure(with items: [WealthGridItem]) {
        self.items = items
        rebuildRows()
    }

    private func rebuildRows() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let count = columns
        for start in stride(from: 0, to: items.count, by: count) {
            let row = UIStackView()
            row.distribution = .fillEqually
            let end = min(start + count, items.count)
            for index in start..<end {
                row.addArrangedSubview(makeCell(item: items[index], index: index))
            }
            for _ in (end - start)..<count {
                row.addArrangedSubview(UIView())
            }
            stack.addArrangedSubview(row)
        }
    }

    private func makeCell(item: WealthGridItem, index: Int) -> UIControl {
        let cell = WealthGridControl()
        cell.accessibilityLabel = item.title
        cell.accessibilityIdentifier = "wealthGrid.\(item.featureID?.rawValue ?? "all")"
        if let id = item.featureID, !FeatureCatalog.descriptor(id).isAvailable {
            cell.accessibilityHint = "查看功能说明"
        }
        cell.addAction(UIAction { [weak self] _ in self?.onItemTapped?(index) }, for: .touchUpInside)

        let icon = UIImageView(image: UIImage.abankAsset(item.imageName, fallback: item.systemIcon))
        icon.tintColor = .abankTextPrimary
        icon.contentMode = .scaleAspectFit

        let title = UILabel()
        title.text = item.title
        title.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .abankCaptionMedium())
        title.adjustsFontForContentSizeCategory = true
        title.textColor = .abankTextPrimary
        title.textAlignment = .center
        title.numberOfLines = 0

        cell.addSubview(icon)
        cell.addSubview(title)
        icon.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.centerX.equalToSuperview()
            make.size.equalTo(30)
        }
        title.snp.makeConstraints { make in
            make.top.equalTo(icon.snp.bottom).offset(7)
            make.leading.trailing.equalToSuperview().inset(3)
            make.bottom.lessThanOrEqualToSuperview().inset(6)
        }
        cell.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44) }
        return cell
    }
}

private final class WealthGridControl: UIControl {
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 12
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UIColor.abankSeparator.withAlphaComponent(0.60) : .clear
        }
    }
}
