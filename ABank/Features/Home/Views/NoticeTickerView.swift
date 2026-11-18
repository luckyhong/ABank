import UIKit
import SnapKit

final class NoticeTickerView: UIView {
    var onItemTapped: ((HomeNoticeItem) -> Void)?

    private let stack = UIStackView()
    private var displayedItems: [HomeNoticeItem] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        stack.axis = .vertical
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with notices: [HomeNoticeItem]) {
        guard notices != displayedItems else { return }
        displayedItems = notices
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        notices.forEach { stack.addArrangedSubview(makeRow(item: $0)) }
    }

    private func makeRow(item: HomeNoticeItem) -> UIControl {
        let row = UIControl()
        row.addAction(UIAction { [weak self] _ in
            self?.onItemTapped?(item)
        }, for: .touchUpInside)
        row.isAccessibilityElement = true
        row.accessibilityTraits = .button
        row.accessibilityIdentifier = item.route == .messages ? "home.notice.todo" : "home.notice.focus"
        row.accessibilityLabel = "\(item.tag)，\(item.text)"

        let tag = UILabel()
        tag.text = item.tag
        tag.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .abankHeadline())
        tag.adjustsFontForContentSizeCategory = true
        tag.textColor = .abankTextPrimary
        tag.setContentCompressionResistancePriority(.required, for: .horizontal)
        tag.setContentHuggingPriority(.required, for: .horizontal)

        let accent = UIView()
        accent.backgroundColor = UIColor.abankOrange.withAlphaComponent(0.28)
        accent.layer.cornerRadius = 1.5
        accent.isUserInteractionEnabled = false

        let text = UILabel()
        text.text = item.text
        text.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .abankSubheadline())
        text.adjustsFontForContentSizeCategory = true
        text.textColor = .abankTextPrimary
        text.lineBreakMode = .byTruncatingTail

        let labels = UIStackView(arrangedSubviews: [tag, text])
        labels.alignment = .firstBaseline
        labels.spacing = 12
        labels.isUserInteractionEnabled = false
        row.addSubview(accent)
        row.addSubview(labels)

        labels.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(4)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().inset(6)
            make.bottom.lessThanOrEqualToSuperview().inset(6)
        }
        accent.snp.makeConstraints { make in
            make.leading.equalTo(tag)
            make.bottom.equalTo(tag.snp.bottom).offset(2)
            make.width.equalTo(18)
            make.height.equalTo(3)
        }
        row.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44) }
        return row
    }
}
