//
//  FeatureGridCell.swift
//  ABank
//
//  全部功能与编辑常用共用的宫格单元：图标、名称和右上角角标。
//

import UIKit
import SnapKit

final class FeatureGridCell: UICollectionViewCell {
    static let reuseID = "FeatureGridCell"

    enum Accessory {
        case none, planned, add, delete, added
    }

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let plannedLabel = UILabel()
    private let accessoryView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .abankPrimary

        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textColor = .abankTextPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail

        plannedLabel.text = "待上线"
        plannedLabel.font = .systemFont(ofSize: 9, weight: .medium)
        plannedLabel.textColor = .abankTextTertiary
        plannedLabel.backgroundColor = .abankSectionBackground
        plannedLabel.textAlignment = .center
        plannedLabel.layer.cornerRadius = 6
        plannedLabel.layer.borderWidth = 0.5
        plannedLabel.layer.borderColor = UIColor.abankSeparator.cgColor
        plannedLabel.clipsToBounds = true

        accessoryView.contentMode = .scaleAspectFit

        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(plannedLabel)
        contentView.addSubview(accessoryView)

        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.size.equalTo(28)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(2)
            make.bottom.lessThanOrEqualToSuperview()
        }
        plannedLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(2)
            make.trailing.equalToSuperview().offset(-2)
            make.width.equalTo(32)
            make.height.equalTo(12)
        }
        accessoryView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(2)
            make.trailing.equalToSuperview().offset(-4)
            make.size.equalTo(18)
        }
    }

    func configure(_ descriptor: FeatureDescriptor, accessory: Accessory) {
        iconView.image = descriptor.iconImage(pointSize: 28)
        titleLabel.text = descriptor.title
        accessibilityIdentifier = "feature.\(descriptor.id.rawValue)"
        isAccessibilityElement = true
        accessibilityLabel = descriptor.isAvailable ? descriptor.title : "\(descriptor.title)，待上线"
        accessibilityTraits = .button

        plannedLabel.isHidden = accessory != .planned
        accessoryView.isHidden = true
        switch accessory {
        case .add:
            accessoryView.isHidden = false
            accessoryView.image = UIImage.abankAsset("abc_allmenus_add", fallback: "plus.circle.fill")
            accessoryView.tintColor = .abankPrimary
        case .delete:
            accessoryView.isHidden = false
            accessoryView.image = UIImage.abankAsset("abc_allmenus_delete", fallback: "minus.circle.fill")
            accessoryView.tintColor = .abankTextTertiary
        case .added:
            accessoryView.isHidden = false
            accessoryView.image = UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate)
            accessoryView.tintColor = .abankPrimary
        case .none, .planned:
            break
        }
    }
}

/// 区段标题：标题 + 可选右侧按钮（如“编辑”）。
final class FeatureSectionHeaderView: UICollectionReusableView {
    static let reuseID = "FeatureSectionHeaderView"

    private let titleLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private var action: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = .abankCaptionMedium()
        titleLabel.textColor = .abankTextPrimary
        actionButton.titleLabel?.font = .abankCaption()
        actionButton.setTitleColor(.abankPrimary, for: .normal)
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        addSubview(titleLabel)
        addSubview(actionButton)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.sm)
            make.centerY.equalToSuperview()
        }
        actionButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.sm)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, actionTitle: String? = nil, identifier: String? = nil, action: (() -> Void)? = nil) {
        titleLabel.text = title
        actionButton.setTitle(actionTitle, for: .normal)
        actionButton.isHidden = actionTitle == nil
        actionButton.accessibilityIdentifier = identifier
        self.action = action
    }

    @objc private func actionTapped() { action?() }
}

/// 空态提示单元。
final class FeatureMessageCell: UICollectionViewCell {
    static let reuseID = "FeatureMessageCell"
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = .abankCaption()
        label.textColor = .abankTextTertiary
        label.textAlignment = .center
        label.numberOfLines = 0
        contentView.addSubview(label)
        label.snp.makeConstraints { make in make.edges.equalToSuperview().inset(Spacing.sm) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(_ text: String) { label.text = text }
}
