//
//  SecurityRowViews.swift
//  ABank
//
//  安全中心各页共用的设置行与页面基类。分组卡片沿用转账子页的 addGroup 样式。
//

import UIKit
import SnapKit

/// 安全设置页基类：监听设置变化并统一走 refreshBankingData 刷新。
class SecurityFlowViewController: TransferFlowViewController {
    let security: SecuritySettingsStore

    init(security: SecuritySettingsStore = .shared) {
        self.security = security
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(securitySettingsDidChange),
                                               name: SecuritySettingsStore.didChangeNotification, object: security)
    }

    @objc private func securitySettingsDidChange() {
        guard isViewLoaded else { return }
        refreshBankingData()
    }

    /// 开关写入失败：回弹并提示。
    func handleSaveResult(_ saved: Bool, revert: () -> Void) {
        guard !saved else { return }
        revert()
        showToast(SecuritySettingsError.persistence.localizedDescription)
    }
}

/// 带图标、标题、右侧说明与箭头的可点击行。
final class SecurityNavigationRow: UIControl {
    var onTap: (() -> Void)?
    private let detailLabel = UILabel()

    init(title: String, imageName: String?, fallback: String, detail: String? = nil, id: String) {
        super.init(frame: .zero)
        accessibilityIdentifier = id
        accessibilityTraits = .button
        isAccessibilityElement = true
        accessibilityLabel = title

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .abankBody()
        titleLabel.textColor = .abankTextPrimary
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        detailLabel.text = detail
        detailLabel.font = .abankCaption()
        detailLabel.textColor = .abankTextSecondary
        detailLabel.textAlignment = .right
        detailLabel.lineBreakMode = .byTruncatingTail

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right",
                                                 withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)))
        chevron.tintColor = .abankTextTertiary
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [titleLabel, detailLabel, chevron])
        stack.spacing = Spacing.sm
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        if let imageName {
            let icon = UIImageView(image: UIImage.abankAsset(imageName, fallback: fallback, pointSize: 24))
            icon.contentMode = .scaleAspectFit
            icon.tintColor = .abankPrimary
            icon.snp.makeConstraints { $0.size.equalTo(24) }
            stack.insertArrangedSubview(icon, at: 0)
            stack.setCustomSpacing(Spacing.md - 4, after: icon)
        }
        addSubview(stack)
        stack.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Spacing.md)
            $0.top.bottom.equalToSuperview().inset(Spacing.sm)
        }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(52) }
        addSeparator(to: self)
        addAction(UIAction { [weak self] _ in self?.onTap?() }, for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isHighlighted: Bool {
        didSet { backgroundColor = isHighlighted ? .abankSectionBackground : .clear }
    }

    func setDetail(_ text: String?) {
        detailLabel.text = text
        accessibilityValue = text
    }
}

/// 标题 + 可选说明 + 开关。
final class SecuritySwitchRow: UIView {
    var onChange: ((Bool) -> Void)?
    let toggle = UISwitch()

    init(title: String, subtitle: String? = nil, id: String) {
        super.init(frame: .zero)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .abankBody()
        titleLabel.textColor = .abankTextPrimary
        let labels = UIStackView(arrangedSubviews: [titleLabel])
        labels.axis = .vertical
        labels.spacing = 2
        if let subtitle {
            let subtitleLabel = UILabel()
            subtitleLabel.text = subtitle
            subtitleLabel.font = .abankCaption()
            subtitleLabel.textColor = .abankTextSecondary
            subtitleLabel.numberOfLines = 0
            labels.addArrangedSubview(subtitleLabel)
        }
        toggle.onTintColor = .abankPrimary
        toggle.accessibilityIdentifier = id
        toggle.accessibilityLabel = title
        toggle.setContentHuggingPriority(.required, for: .horizontal)
        toggle.setContentCompressionResistancePriority(.required, for: .horizontal)
        toggle.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.onChange?(self.toggle.isOn)
        }, for: .valueChanged)

        let stack = UIStackView(arrangedSubviews: [labels, toggle])
        stack.spacing = Spacing.md
        stack.alignment = .center
        addSubview(stack)
        stack.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Spacing.md)
            $0.top.bottom.equalToSuperview().inset(Spacing.sm)
        }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(52) }
        addSeparator(to: self)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setOn(_ on: Bool, animated: Bool) {
        guard toggle.isOn != on else { return }
        toggle.setOn(on, animated: animated)
    }
}

/// 单选行（右侧勾选）。
final class SecurityOptionRow: UIControl {
    var onTap: (() -> Void)?
    private let check = UIImageView(image: UIImage(systemName: "checkmark"))

    init(title: String, id: String) {
        super.init(frame: .zero)
        accessibilityIdentifier = id
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits = .button
        let label = UILabel()
        label.text = title
        label.font = .abankBody()
        label.textColor = .abankTextPrimary
        check.tintColor = .abankPrimary
        check.setContentHuggingPriority(.required, for: .horizontal)
        let stack = UIStackView(arrangedSubviews: [label, check])
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        addSubview(stack)
        stack.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(Spacing.md + Spacing.md)
            $0.trailing.equalToSuperview().inset(Spacing.md)
            $0.top.bottom.equalToSuperview().inset(Spacing.sm)
        }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(48) }
        addSeparator(to: self)
        addAction(UIAction { [weak self] _ in self?.onTap?() }, for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setSelected(_ selected: Bool) {
        check.isHidden = !selected
        accessibilityTraits = selected ? [.button, .selected] : .button
    }
}

/// 分组标题（卡片外的灰色小字）。
func makeSecuritySectionTitle(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .abankCaption()
    label.textColor = .abankTextSecondary
    return label
}

private func addSeparator(to view: UIView) {
    let line = UIView()
    line.backgroundColor = .abankSeparator.withAlphaComponent(0.5)
    view.addSubview(line)
    line.snp.makeConstraints {
        $0.leading.trailing.equalToSuperview().inset(Spacing.md)
        $0.bottom.equalToSuperview()
        $0.height.equalTo(0.5)
    }
}
