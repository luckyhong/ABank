//
//  MineProfileHeaderView.swift
//  ABank
//

import UIKit
import SnapKit

final class MineProfileHeaderView: UIView {

    var onBenefitsTapped: (() -> Void)?
    var onVIPTapped: (() -> Void)?

    private let avatarView = UIView()
    private let avatarIcon = UIImageView(image: UIImage(systemName: "person.fill"))
    private let nameLabel = UILabel()
    private let loginDeviceLabel = UILabel()
    private let loginTimeLabel = UILabel()
    private let vipBadge = UIControl()
    private let vipLabel = UILabel()
    private let benefitsButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with profile: MineProfileInfo) {
        nameLabel.text = profile.displayName
        loginDeviceLabel.text = profile.lastLoginDevice
        loginTimeLabel.text = profile.lastLoginTime
        vipLabel.text = "\(profile.vipLevel) >"
        benefitsButton.setTitle("\(profile.benefitsTitle) >", for: .normal)
    }

    private func setupUI() {
        avatarView.backgroundColor = UIColor(red: 0.85, green: 0.92, blue: 0.98, alpha: 1)
        avatarView.layer.cornerRadius = 28
        avatarView.clipsToBounds = true
        avatarIcon.tintColor = UIColor(red: 0.45, green: 0.65, blue: 0.85, alpha: 1)
        avatarIcon.contentMode = .scaleAspectFit
        avatarView.addSubview(avatarIcon)
        avatarIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(32)
        }

        nameLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        nameLabel.textColor = .abankTextPrimary

        loginDeviceLabel.font = .systemFont(ofSize: 12)
        loginDeviceLabel.textColor = .abankTextSecondary

        loginTimeLabel.font = .systemFont(ofSize: 11)
        loginTimeLabel.textColor = .abankTextTertiary

        let starIcon = UIImageView(image: UIImage(systemName: "star.fill"))
        starIcon.tintColor = .abankGold
        starIcon.contentMode = .scaleAspectFit
        vipLabel.font = .systemFont(ofSize: 11)
        vipLabel.textColor = .abankGold
        vipBadge.backgroundColor = UIColor.abankGold.withAlphaComponent(0.12)
        vipBadge.layer.cornerRadius = 10
        vipBadge.addTarget(self, action: #selector(vipTapped), for: .touchUpInside)
        vipBadge.addSubview(starIcon)
        vipBadge.addSubview(vipLabel)
        starIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.size.equalTo(10)
        }
        vipLabel.snp.makeConstraints { make in
            make.leading.equalTo(starIcon.snp.trailing).offset(4)
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
        }

        benefitsButton.setTitleColor(UIColor(red: 0.55, green: 0.38, blue: 0.15, alpha: 1), for: .normal)
        benefitsButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        benefitsButton.backgroundColor = UIColor(red: 1.0, green: 0.93, blue: 0.78, alpha: 1)
        benefitsButton.layer.cornerRadius = 16
        benefitsButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        benefitsButton.addTarget(self, action: #selector(benefitsTapped), for: .touchUpInside)

        addSubview(avatarView)
        addSubview(nameLabel)
        addSubview(loginDeviceLabel)
        addSubview(loginTimeLabel)
        addSubview(vipBadge)
        addSubview(benefitsButton)

        avatarView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.size.equalTo(56)
            make.bottom.lessThanOrEqualToSuperview()
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.top.equalTo(avatarView).offset(2)
            make.trailing.lessThanOrEqualTo(benefitsButton.snp.leading).offset(-8)
        }
        benefitsButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(nameLabel)
        }
        loginDeviceLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(6)
        }
        loginTimeLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(loginDeviceLabel.snp.bottom).offset(2)
        }
        vipBadge.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(loginTimeLabel.snp.bottom).offset(8)
            make.height.equalTo(20)
            make.bottom.equalToSuperview()
        }
    }

    @objc private func benefitsTapped() { onBenefitsTapped?() }
    @objc private func vipTapped() { onVIPTapped?() }
}
