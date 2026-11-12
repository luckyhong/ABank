import UIKit
import SnapKit

/// Native sections shared by high-frequency read and query pages.
enum BankingPageStyle {
    static func text(_ value: String, style: UIFont.TextStyle = .body, color: UIColor = .abankTextPrimary) -> UILabel {
        let label = UILabel()
        label.text = value; label.font = .preferredFont(forTextStyle: style); label.adjustsFontForContentSizeCategory = true
        label.textColor = color; label.numberOfLines = 0
        return label
    }
    static func section(_ title: String) -> UILabel { text(title, style: .headline) }
    static func surface(_ views: [UIView], spacing: CGFloat = 14, inset: CGFloat = 16) -> UIView {
        let stack = UIStackView(arrangedSubviews: views); stack.axis = .vertical; stack.spacing = spacing
        let container = UIView(); container.backgroundColor = .white; container.layer.cornerRadius = 12
        container.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(inset) }
        return container
    }
    static func empty(_ title: String, detail: String, actionTitle: String? = nil, action: (() -> Void)? = nil) -> UIView {
        let icon = UIImageView(image: UIImage(systemName: "doc.text.magnifyingglass")); icon.tintColor = .abankTextTertiary; icon.contentMode = .scaleAspectFit
        icon.snp.makeConstraints { $0.height.equalTo(44) }
        let heading = text(title, style: .headline); heading.textAlignment = .center
        let caption = text(detail, style: .subheadline, color: .abankTextSecondary); caption.textAlignment = .center
        var views: [UIView] = [icon, heading, caption]
        if let actionTitle, let action {
            let button = UIButton(type: .system); button.setTitle(actionTitle, for: .normal); button.tintColor = .abankPrimaryDark
            button.titleLabel?.font = .preferredFont(forTextStyle: .body)
            button.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44) }
            button.addAction(UIAction { _ in action() }, for: .touchUpInside); views.append(button)
        }
        return surface(views, inset: 24)
    }
}

final class BankingReadSection: UIView {
    init(title: String, body: String) {
        super.init(frame: .zero)
        let stack = UIStackView(arrangedSubviews: [BankingPageStyle.section(title), BankingPageStyle.text(body, style: .subheadline, color: .abankTextSecondary)])
        stack.axis = .vertical; stack.spacing = 10
        addSubview(stack); stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        backgroundColor = .white
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
