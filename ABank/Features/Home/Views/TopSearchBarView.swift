//
//  TopSearchBarView.swift
//  ABank
//
//  Created by 韩继宏 on 2025/11/06.
//

import UIKit
import SnapKit

enum TopSearchBarStyle {
    case light
    case dark
}

final class TopSearchBarView: UIView {

    var onSearchTapped: ((String) -> Void)?
    var onGiftTapped: (() -> Void)?
    var onVersionTapped: (() -> Void)?
    var onServiceTapped: (() -> Void)?
    var onMessageTapped: (() -> Void)?

    private let giftItem = IconLabelItemView()
    private let versionItem = IconLabelItemView()
    private let serviceItem = IconLabelItemView()
    private let messageItem = IconLabelItemView()
    private let searchContainer = UIView()
    private let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
    private let micIcon = UIImageView(image: UIImage(systemName: "mic"))
    private let searchLabel = UILabel()
    private let badgeLabel = UILabel()
    private var placeholders: [String] = []
    private var placeholderIndex = 0
    private var rotateTimer: Timer?
    private var currentStyle: TopSearchBarStyle?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        rotateTimer?.invalidate()
    }

    func configure(placeholders: [String], badgeCount: Int) {
        self.placeholders = placeholders.isEmpty ? ["搜索"] : placeholders
        placeholderIndex = 0
        searchLabel.text = self.placeholders[0]
        badgeLabel.isHidden = badgeCount <= 0
        badgeLabel.text = badgeCount > 99 ? "99+" : "\(badgeCount)"
        restartPlaceholderRotation()
    }

    func currentPlaceholder() -> String {
        placeholders[safe: placeholderIndex] ?? searchLabel.text ?? ""
    }

    func apply(style: TopSearchBarStyle) {
        if currentStyle == style { return }
        currentStyle = style
        switch style {
        case .light:
            [giftItem, versionItem, serviceItem, messageItem].forEach { $0.apply(tint: .white, labelColor: .white) }
            searchIcon.tintColor = .white
            micIcon.tintColor = .white
            searchLabel.textColor = UIColor.white.withAlphaComponent(0.92)
            searchContainer.backgroundColor = UIColor.white.withAlphaComponent(0.28)
        case .dark:
            let iconColor = UIColor.abankTextPrimary
            [giftItem, versionItem, serviceItem, messageItem].forEach {
                $0.apply(tint: iconColor, labelColor: .abankTextSecondary)
            }
            searchIcon.tintColor = .abankTextTertiary
            micIcon.tintColor = .abankTextTertiary
            searchLabel.textColor = .abankTextTertiary
            searchContainer.backgroundColor = UIColor(white: 0.95, alpha: 1)
        }
    }

    private func setupUI() {
        giftItem.configure(systemIcon: "gift", title: "抽奖")
        versionItem.configure(systemIcon: "arrow.left.arrow.right", title: "版本")
        serviceItem.configure(systemIcon: "headphones", title: "客服")
        messageItem.configure(systemIcon: "envelope", title: "消息")

        searchContainer.layer.cornerRadius = CornerRadius.search
        searchLabel.font = .systemFont(ofSize: 14)
        searchIcon.contentMode = .scaleAspectFit
        micIcon.contentMode = .scaleAspectFit

        badgeLabel.backgroundColor = .abankBadge
        badgeLabel.textColor = .white
        badgeLabel.font = .systemFont(ofSize: 9, weight: .bold)
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = 8
        badgeLabel.layer.masksToBounds = true

        addSubview(giftItem)
        addSubview(searchContainer)
        addSubview(versionItem)
        addSubview(serviceItem)
        addSubview(messageItem)
        addSubview(badgeLabel)
        searchContainer.addSubview(searchIcon)
        searchContainer.addSubview(searchLabel)
        searchContainer.addSubview(micIcon)

        giftItem.snp.makeConstraints { make in
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
        versionItem.snp.makeConstraints { make in
            make.trailing.equalTo(serviceItem.snp.leading).offset(-2)
            make.centerY.equalToSuperview()
            make.width.equalTo(36)
        }
        searchContainer.snp.makeConstraints { make in
            make.leading.equalTo(giftItem.snp.trailing).offset(8)
            make.trailing.equalTo(versionItem.snp.leading).offset(-8)
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

        giftItem.addTarget(self, action: #selector(giftTapped), for: .touchUpInside)
        versionItem.addTarget(self, action: #selector(versionTapped), for: .touchUpInside)
        serviceItem.addTarget(self, action: #selector(serviceTapped), for: .touchUpInside)
        messageItem.addTarget(self, action: #selector(messageTapped), for: .touchUpInside)
        searchContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(searchTapped)))

        apply(style: .light)
    }

    private func restartPlaceholderRotation() {
        rotateTimer?.invalidate()
        guard placeholders.count > 1 else { return }
        rotateTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.showNextPlaceholder()
        }
    }

    private func showNextPlaceholder() {
        guard placeholders.count > 1 else { return }
        placeholderIndex = (placeholderIndex + 1) % placeholders.count
        let next = placeholders[placeholderIndex]
        UIView.transition(with: searchLabel, duration: 0.25, options: .transitionCrossDissolve) {
            self.searchLabel.text = next
        }
    }

    @objc private func giftTapped() { onGiftTapped?() }
    @objc private func versionTapped() { onVersionTapped?() }
    @objc private func serviceTapped() { onServiceTapped?() }
    @objc private func messageTapped() { onMessageTapped?() }
    @objc private func searchTapped() { onSearchTapped?(currentPlaceholder()) }
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

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
