//
//  MineTopActionBarView.swift
//  ABank
//

import UIKit
import SnapKit

final class MineTopActionBarView: UIView {

    var onLogoutTapped: (() -> Void)?
    var onSearchTapped: (() -> Void)?
    var onSettingsTapped: (() -> Void)?
    var onMoreTapped: (() -> Void)?

    private let logoutButton = UIControl()
    private let searchButton = UIControl()
    private let settingsButton = UIControl()
    private let moreButton = UIControl()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let logout = makeActionItem(
            icon: "rectangle.portrait.and.arrow.right",
            title: "退出",
            control: logoutButton,
            action: #selector(logoutTapped)
        )
        let search = makeActionItem(
            icon: "magnifyingglass",
            title: "搜索",
            control: searchButton,
            action: #selector(searchTapped)
        )
        let settings = makeActionItem(
            icon: "gearshape",
            title: "设置",
            control: settingsButton,
            action: #selector(settingsTapped)
        )
        let more = makeActionItem(
            icon: "plus.circle",
            title: "更多",
            control: moreButton,
            action: #selector(moreTapped),
            showsBadge: true
        )

        let rightStack = UIStackView(arrangedSubviews: [search, settings, more])
        rightStack.axis = .horizontal
        rightStack.spacing = 20
        rightStack.alignment = .center

        addSubview(logout)
        addSubview(rightStack)

        logout.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        rightStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        snp.makeConstraints { make in
            make.height.equalTo(44)
        }
    }

    private func makeActionItem(
        icon: String,
        title: String,
        control: UIControl,
        action: Selector,
        showsBadge: Bool = false
    ) -> UIView {
        let wrap = UIView()
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .abankTextPrimary
        iconView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 11)
        label.textColor = .abankTextSecondary
        label.textAlignment = .center

        control.addTarget(self, action: action, for: .touchUpInside)
        wrap.addSubview(control)
        wrap.addSubview(iconView)
        wrap.addSubview(label)

        control.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        iconView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(22)
        }
        label.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(2)
            make.centerX.bottom.equalToSuperview()
        }
        wrap.snp.makeConstraints { make in
            make.width.equalTo(36)
        }

        if showsBadge {
            let badge = UIView()
            badge.backgroundColor = .abankBadge
            badge.layer.cornerRadius = 3
            wrap.addSubview(badge)
            badge.snp.makeConstraints { make in
                make.top.equalTo(iconView).offset(-2)
                make.trailing.equalTo(iconView).offset(4)
                make.size.equalTo(6)
            }
        }
        return wrap
    }

    @objc private func logoutTapped() { onLogoutTapped?() }
    @objc private func searchTapped() { onSearchTapped?() }
    @objc private func settingsTapped() { onSettingsTapped?() }
    @objc private func moreTapped() { onMoreTapped?() }
}
