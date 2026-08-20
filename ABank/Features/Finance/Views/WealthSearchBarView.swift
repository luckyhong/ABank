//
//  WealthSearchBarView.swift
//  ABank
//

import UIKit
import SnapKit

final class WealthSearchBarView: UIView {

    var onScanTapped: (() -> Void)?
    var onSearchTapped: (() -> Void)?
    var onServiceTapped: (() -> Void)?
    var onMessageTapped: (() -> Void)?

    private let scanItem = IconLabelItemView()
    private let serviceItem = IconLabelItemView()
    private let messageItem = IconLabelItemView()
    private let searchContainer = UIView()
    private let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
    private let micIcon = UIImageView(image: UIImage(systemName: "mic"))
    private let searchLabel = UILabel()
    private let badgeLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(placeholder: String, badgeCount: Int) {
        searchLabel.text = placeholder
        badgeLabel.isHidden = badgeCount <= 0
        badgeLabel.text = badgeCount > 99 ? "99+" : "\(badgeCount)"
    }

    private func setupUI() {
        scanItem.configure(systemIcon: "qrcode.viewfinder", title: "扫一扫")
        serviceItem.configure(systemIcon: "headphones", title: "客服")
        messageItem.configure(systemIcon: "envelope", title: "消息")

        searchContainer.backgroundColor = UIColor(white: 0.95, alpha: 1)
        searchContainer.layer.cornerRadius = CornerRadius.search
        searchIcon.tintColor = .abankTextTertiary
        micIcon.tintColor = .abankTextTertiary
        searchLabel.font = .systemFont(ofSize: 14)
        searchLabel.textColor = .abankTextTertiary

        badgeLabel.backgroundColor = .abankBadge
        badgeLabel.textColor = .white
        badgeLabel.font = .systemFont(ofSize: 9, weight: .bold)
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = 8
        badgeLabel.layer.masksToBounds = true

        [scanItem, searchContainer, serviceItem, messageItem, badgeLabel].forEach { addSubview($0) }
        [searchIcon, searchLabel, micIcon].forEach { searchContainer.addSubview($0) }

        scanItem.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(36)
        }
        messageItem.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(36)
        }
        serviceItem.snp.makeConstraints { make in
            make.trailing.equalTo(messageItem.snp.leading).offset(-2)
            make.centerY.equalToSuperview()
            make.width.equalTo(36)
        }
        searchContainer.snp.makeConstraints { make in
            make.leading.equalTo(scanItem.snp.trailing).offset(8)
            make.trailing.equalTo(serviceItem.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
            make.height.equalTo(34)
        }
        searchIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.size.equalTo(14)
        }
        micIcon.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
            make.size.equalTo(14)
        }
        searchLabel.snp.makeConstraints { make in
            make.leading.equalTo(searchIcon.snp.trailing).offset(6)
            make.trailing.lessThanOrEqualTo(micIcon.snp.leading).offset(-6)
            make.centerY.equalToSuperview()
        }
        badgeLabel.snp.makeConstraints { make in
            make.top.equalTo(messageItem.snp.top).offset(-2)
            make.trailing.equalTo(messageItem.snp.trailing).offset(4)
            make.height.equalTo(16)
            make.width.greaterThanOrEqualTo(16)
        }
        snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        let iconColor = UIColor.abankTextPrimary
        [scanItem, serviceItem, messageItem].forEach {
            $0.apply(tint: iconColor, labelColor: .abankTextSecondary)
        }

        scanItem.addTarget(self, action: #selector(scanTapped), for: .touchUpInside)
        serviceItem.addTarget(self, action: #selector(serviceTapped), for: .touchUpInside)
        messageItem.addTarget(self, action: #selector(messageTapped), for: .touchUpInside)
        searchContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(searchTapped)))
    }

    @objc private func scanTapped() { onScanTapped?() }
    @objc private func searchTapped() { onSearchTapped?() }
    @objc private func serviceTapped() { onServiceTapped?() }
    @objc private func messageTapped() { onMessageTapped?() }
}

private final class IconLabelItemView: UIControl {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        iconView.contentMode = .scaleAspectFit
        titleLabel.font = .systemFont(ofSize: 10)
        titleLabel.textAlignment = .center
        addSubview(iconView)
        addSubview(titleLabel)
        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.size.equalTo(18)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(2)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(systemIcon: String, title: String) {
        iconView.image = UIImage(systemName: systemIcon)
        titleLabel.text = title
    }

    func apply(tint: UIColor, labelColor: UIColor) {
        iconView.tintColor = tint
        titleLabel.textColor = labelColor
    }
}
