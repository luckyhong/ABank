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
    private let cityIcon = UIImageView(image: UIImage(systemName: "location.fill"))
    private let cityLabel = UILabel()
    private let cityArrow = UIImageView(image: UIImage(systemName: "chevron.down"))
    private let ordersItem = LifeIconItemView()
    private let couponsItem = LifeIconItemView()
    private let searchContainer = UIView()
    private let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
    private let micIcon = UIImageView(image: UIImage(systemName: "mic"))
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

    func configure(city: String, placeholders: [String]) {
        cityLabel.text = city
        self.placeholders = placeholders.isEmpty ? ["搜索"] : placeholders
        placeholderIndex = 0
        searchLabel.text = self.placeholders[0]
        restartPlaceholderRotation()
    }

    private func setupUI() {
        cityIcon.tintColor = .abankPrimary
        cityIcon.contentMode = .scaleAspectFit
        cityLabel.font = .systemFont(ofSize: 13, weight: .medium)
        cityLabel.textColor = .abankTextPrimary
        cityArrow.tintColor = .abankTextTertiary
        cityArrow.contentMode = .scaleAspectFit

        ordersItem.configure(systemIcon: "doc.text", title: "订单")
        couponsItem.configure(systemIcon: "ticket", title: "卡券")

        searchContainer.backgroundColor = UIColor(white: 0.95, alpha: 1)
        searchContainer.layer.cornerRadius = CornerRadius.search
        searchIcon.tintColor = .abankTextTertiary
        micIcon.tintColor = .abankTextTertiary
        searchLabel.font = .systemFont(ofSize: 14)
        searchLabel.textColor = .abankTextTertiary

        cityButton.addTarget(self, action: #selector(cityTapped), for: .touchUpInside)
        ordersItem.addTarget(self, action: #selector(ordersTapped), for: .touchUpInside)
        couponsItem.addTarget(self, action: #selector(couponsTapped), for: .touchUpInside)
        searchContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(searchTapped)))

        addSubview(cityButton)
        addSubview(searchContainer)
        addSubview(ordersItem)
        addSubview(couponsItem)
        cityButton.addSubview(cityIcon)
        cityButton.addSubview(cityLabel)
        cityButton.addSubview(cityArrow)
        [searchIcon, searchLabel, micIcon].forEach { searchContainer.addSubview($0) }

        cityButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(72)
        }
        cityIcon.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.size.equalTo(14)
        }
        cityLabel.snp.makeConstraints { make in
            make.leading.equalTo(cityIcon.snp.trailing).offset(2)
            make.centerY.equalTo(cityIcon)
        }
        cityArrow.snp.makeConstraints { make in
            make.leading.equalTo(cityLabel.snp.trailing).offset(2)
            make.centerY.equalTo(cityLabel)
            make.size.equalTo(10)
            make.bottom.equalToSuperview()
        }
        couponsItem.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(36)
        }
        ordersItem.snp.makeConstraints { make in
            make.trailing.equalTo(couponsItem.snp.leading).offset(-2)
            make.centerY.equalToSuperview()
            make.width.equalTo(36)
        }
        searchContainer.snp.makeConstraints { make in
            make.leading.equalTo(cityButton.snp.trailing).offset(6)
            make.trailing.equalTo(ordersItem.snp.leading).offset(-8)
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
        snp.makeConstraints { make in
            make.height.equalTo(44)
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
        iconView.tintColor = .abankTextPrimary
        titleLabel.text = title
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
