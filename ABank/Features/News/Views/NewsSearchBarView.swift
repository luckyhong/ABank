//
//  NewsSearchBarView.swift
//  ABank
//

import UIKit
import SnapKit

final class NewsSearchBarView: UIView {

    var onScanTapped: (() -> Void)?
    var onSearchTapped: ((String) -> Void)?
    var onServiceTapped: (() -> Void)?
    var onMessageTapped: (() -> Void)?

    private let scanItem = NewsIconItemView()
    private let serviceItem = NewsIconItemView()
    private let messageItem = NewsIconItemView()
    private let searchContainer = UIView()
    private let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
    private let micIcon = UIImageView(image: UIImage(systemName: "mic"))
    private let searchLabel = UILabel()
    private let badgeLabel = UILabel()

    private var placeholders: [String] = []
    private var placeholderIndex = 0
    private var rotateTimer: Timer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { rotateTimer?.invalidate() }

    func configure(placeholders: [String], badgeCount: Int) {
        self.placeholders = placeholders.isEmpty ? ["资讯热榜"] : placeholders
        placeholderIndex = 0
        searchLabel.text = self.placeholders[0]
        badgeLabel.isHidden = badgeCount <= 0
        badgeLabel.text = badgeCount > 99 ? "99+" : "\(badgeCount)"
        restartPlaceholderRotation()
    }

    private func setupUI() {
        backgroundColor = .white

        scanItem.configure(systemIcon: "viewfinder", title: "扫一扫")
        serviceItem.configure(systemIcon: "headphones", title: "客服")
        messageItem.configure(systemIcon: "envelope", title: "消息")

        searchContainer.backgroundColor = UIColor(red: 0.945, green: 0.945, blue: 0.95, alpha: 1)
        searchContainer.layer.cornerRadius = 18
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

        scanItem.addTarget(self, action: #selector(scanTapped), for: .touchUpInside)
        serviceItem.addTarget(self, action: #selector(serviceTapped), for: .touchUpInside)
        messageItem.addTarget(self, action: #selector(messageTapped), for: .touchUpInside)
        searchContainer.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(searchTapped))
        )

        addSubview(scanItem)
        addSubview(searchContainer)
        addSubview(serviceItem)
        addSubview(messageItem)
        addSubview(badgeLabel)
        [searchIcon, searchLabel, micIcon].forEach { searchContainer.addSubview($0) }

        scanItem.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.equalTo(40)
            make.height.equalTo(40)
        }
        messageItem.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.equalTo(36)
        }
        serviceItem.snp.makeConstraints { make in
            make.trailing.equalTo(messageItem.snp.leading).offset(-4)
            make.centerY.equalToSuperview()
            make.width.equalTo(36)
        }
        searchContainer.snp.makeConstraints { make in
            make.leading.equalTo(scanItem.snp.trailing).offset(8)
            make.trailing.equalTo(serviceItem.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
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
    }

    private func restartPlaceholderRotation() {
        rotateTimer?.invalidate()
        guard placeholders.count > 1 else { return }
        rotateTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.placeholderIndex = (self.placeholderIndex + 1) % self.placeholders.count
            UIView.transition(with: self.searchLabel, duration: 0.25, options: .transitionCrossDissolve) {
                self.searchLabel.text = self.placeholders[self.placeholderIndex]
            }
        }
    }

    @objc private func scanTapped() { onScanTapped?() }
    @objc private func serviceTapped() { onServiceTapped?() }
    @objc private func messageTapped() { onMessageTapped?() }
    @objc private func searchTapped() {
        onSearchTapped?(placeholders[safe: placeholderIndex] ?? searchLabel.text ?? "")
    }
}

private final class NewsIconItemView: UIControl {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .abankTextPrimary
        titleLabel.font = .systemFont(ofSize: 10)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .abankTextSecondary
        addSubview(iconView)
        addSubview(titleLabel)
        iconView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(18)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(2)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(systemIcon: String, title: String) {
        iconView.image = UIImage(systemName: systemIcon)
        titleLabel.text = title
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
