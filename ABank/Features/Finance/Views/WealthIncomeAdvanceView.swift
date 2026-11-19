import UIKit
import SnapKit

final class WealthIncomeAdvanceView: UIView {
    var onTap: (() -> Void)?

    private let header = WealthSectionHeaderView(title: "基金", subtitle: "模拟申购与赎回")
    private let card = UIControl()
    private let navLabel = UILabel()
    private let dateLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with quote: SimulatedFund.Quote) {
        navLabel.text = quote.navText
        dateLabel.text = quote.caption
        card.accessibilityLabel = "\(SimulatedFund.name)，\(quote.caption)，\(quote.navText)"
    }

    private func setupUI() {
        header.onTap = { [weak self] in self?.onTap?() }
        card.addAction(UIAction { [weak self] _ in self?.onTap?() }, for: .touchUpInside)
        card.isAccessibilityElement = true
        card.accessibilityTraits = .button
        card.accessibilityIdentifier = "wealth.fund.quote"

        card.backgroundColor = .abankCardBackground
        card.layer.cornerRadius = CornerRadius.lg
        card.addShadow(color: .black, opacity: 0.06, offset: CGSize(width: 0, height: 2), radius: 8)

        let nameLabel = UILabel()
        nameLabel.text = SimulatedFund.name
        nameLabel.font = .preferredFont(forTextStyle: .subheadline)
        nameLabel.textColor = .abankTextPrimary
        nameLabel.numberOfLines = 0

        navLabel.font = .preferredFont(forTextStyle: .title2)
        navLabel.textColor = .abankHighlight
        dateLabel.font = .preferredFont(forTextStyle: .caption1)
        dateLabel.textColor = .abankTextSecondary
        dateLabel.numberOfLines = 0
        [nameLabel, navLabel, dateLabel].forEach { $0.adjustsFontForContentSizeCategory = true }

        let metrics = UIStackView(arrangedSubviews: [navLabel, dateLabel])
        metrics.axis = .vertical
        metrics.spacing = 2
        let content = UIStackView(arrangedSubviews: [nameLabel, metrics])
        content.axis = .vertical
        content.spacing = 10
        content.isUserInteractionEnabled = false

        addSubview(header)
        addSubview(card)
        card.addSubview(content)
        header.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }
        card.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }
        content.snp.makeConstraints { $0.edges.equalToSuperview().inset(Spacing.md) }
    }
}
