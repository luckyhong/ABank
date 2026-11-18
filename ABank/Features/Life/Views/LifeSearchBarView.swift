//
//  LifeSearchBarView.swift
//  ABank
//

import UIKit
import SnapKit

final class LifeSearchBarView: UIView {

    var onCityTapped: (() -> Void)?
    var onSearchTapped: ((String) -> Void)?
    var onOrdersTapped: (() -> Void)?
    var onCouponsTapped: (() -> Void)?

    private let cityButton = UIControl()
    private let cityIcon = UIImageView(image: UIImage.abankAsset("abc_life_toolbar_location", fallback: "location.fill", renderingMode: .alwaysTemplate))
    private let cityLabel = UILabel()
    private let ordersItem = LifeIconItemView()
    private let couponsItem = LifeIconItemView()
    private let searchContainer = UIControl()
    private let searchIcon = UIImageView(image: UIImage.abankAsset("abc_life_toolbar_search", fallback: "magnifyingglass", renderingMode: .alwaysTemplate))
    private let searchLabel = UILabel()

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

    private func setCity(_ city: String) {
        cityLabel.text = city
        cityButton.accessibilityValue = city
    }

    func configure(city: String, placeholders: [String]) {
        setCity(city)
        let suggestions = placeholders.isEmpty ? ["搜索"] : placeholders
        guard suggestions != self.placeholders else { return }
        self.placeholders = suggestions
        placeholderIndex = 0
        searchLabel.text = self.placeholders[0]
        restartPlaceholderRotation()
    }

    private func setupUI() {
        cityIcon.tintColor = .abankTextPrimary
        cityIcon.contentMode = .scaleAspectFit
        cityLabel.font = .systemFont(ofSize: 13, weight: .medium)
        cityLabel.textColor = .abankTextPrimary
        cityLabel.adjustsFontSizeToFitWidth = true
        cityLabel.minimumScaleFactor = 0.8
        cityButton.isAccessibilityElement = true
        cityButton.accessibilityLabel = "切换服务城市"
        cityButton.accessibilityTraits = .button
        cityButton.accessibilityIdentifier = "life.city"
        searchContainer.isAccessibilityElement = true
        searchContainer.accessibilityLabel = "搜索生活服务"
        searchContainer.accessibilityTraits = .button

        ordersItem.configure(imageName: "abc_life_toolbar_orders", systemIcon: "doc.text", title: "订单")
        couponsItem.configure(imageName: "abc_life_toolbar_coupons", systemIcon: "ticket", title: "卡券")

        searchContainer.backgroundColor = UIColor(white: 0.95, alpha: 1)
        searchContainer.layer.cornerRadius = CornerRadius.search
        searchIcon.tintColor = .abankTextSecondary
        searchLabel.font = .systemFont(ofSize: 14)
        searchLabel.textColor = .abankTextSecondary

        cityButton.addTarget(self, action: #selector(cityTapped), for: .touchUpInside)
        ordersItem.addTarget(self, action: #selector(ordersTapped), for: .touchUpInside)
        couponsItem.addTarget(self, action: #selector(couponsTapped), for: .touchUpInside)
        searchContainer.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)

        addSubview(cityButton)
        addSubview(searchContainer)
        addSubview(ordersItem)
        addSubview(couponsItem)
        cityButton.addSubview(cityIcon)
        cityButton.addSubview(cityLabel)
        [searchIcon, searchLabel].forEach { searchContainer.addSubview($0) }

        cityButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(80)
            make.height.equalTo(44)
        }
        cityIcon.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.size.equalTo(18)
        }
        cityLabel.snp.makeConstraints { make in
            make.leading.equalTo(cityIcon.snp.trailing).offset(2)
            make.centerY.equalTo(cityIcon)
            make.trailing.equalToSuperview().inset(2)
        }
        couponsItem.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
        ordersItem.snp.makeConstraints { make in
            make.trailing.equalTo(couponsItem.snp.leading).offset(-2)
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
        searchContainer.snp.makeConstraints { make in
            make.leading.equalTo(cityButton.snp.trailing).offset(6)
            make.trailing.equalTo(ordersItem.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
        }
        searchIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.size.equalTo(14)
        }
        searchLabel.snp.makeConstraints { make in
            make.leading.equalTo(searchIcon.snp.trailing).offset(6)
            make.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
        snp.makeConstraints { make in
            make.height.equalTo(44)
        }
    }

    private func restartPlaceholderRotation() {
        rotateTimer?.invalidate()
        guard placeholders.count > 1 else { return }
        rotateTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self, self.window != nil, !UIAccessibility.isReduceMotionEnabled, !UIAccessibility.isVoiceOverRunning else { return }
            self.placeholderIndex = (self.placeholderIndex + 1) % self.placeholders.count
            UIView.transition(with: self.searchLabel, duration: 0.25, options: .transitionCrossDissolve) {
                self.searchLabel.text = self.placeholders[self.placeholderIndex]
            }
        }
    }

    @objc private func cityTapped() { onCityTapped?() }
    @objc private func searchTapped() {
        onSearchTapped?(placeholders[safe: placeholderIndex] ?? searchLabel.text ?? "")
    }
    @objc private func ordersTapped() { onOrdersTapped?() }
    @objc private func couponsTapped() { onCouponsTapped?() }
}

private final class LifeIconItemView: UIControl {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        iconView.contentMode = .scaleAspectFit
        titleLabel.font = .systemFont(ofSize: 11, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .abankTextSecondary
        addSubview(iconView)
        addSubview(titleLabel)
        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(5)
            make.centerX.equalToSuperview()
            make.size.equalTo(18)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(imageName: String, systemIcon: String, title: String) {
        iconView.image = UIImage.abankAsset(imageName, fallback: systemIcon, renderingMode: .alwaysTemplate)
        iconView.tintColor = .abankTextPrimary
        titleLabel.text = title
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits = .button
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
