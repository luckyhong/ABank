//
//  MineProfileHeaderView.swift
//  ABank
//

import UIKit
import SnapKit

final class MineProfileHeaderView: UIView {

    var onBenefitsTapped: (() -> Void)?
    var onVIPTapped: (() -> Void)?
    var onAvatarTapped: (() -> Void)?

    private let avatarView = UIView()
    private let avatarIcon = UIImageView(image: UIImage.abankAsset("abc_mine_profile_avatar", fallback: "person.fill"))
    private let nameLabel = UILabel()
    private let loginDeviceLabel = UILabel()
    private let loginTimeLabel = UILabel()
    private let vipBadge = UIControl()
    private let vipLabel = UILabel()
    private let benefitsButton = UIButton(type: .system)
    private let benefitsGradient = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        benefitsGradient.frame = benefitsButton.bounds
    }

    func configure(with profile: MineProfileInfo) {
        nameLabel.text = profile.displayName
        loginDeviceLabel.text = profile.lastLoginDevice
        loginTimeLabel.text = profile.lastLoginTime
        vipLabel.text = "\(profile.vipLevel) ›"
        benefitsButton.setTitle(profile.benefitsTitle, for: .normal)
    }

    private func setupUI() {
        avatarView.backgroundColor = UIColor(red: 0.85, green: 0.92, blue: 0.98, alpha: 1)
        avatarView.layer.cornerRadius = 28
        avatarView.clipsToBounds = true
        avatarView.isUserInteractionEnabled = true
        avatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped)))
        avatarIcon.tintColor = UIColor(red: 0.45, green: 0.65, blue: 0.85, alpha: 1)
        avatarIcon.contentMode = .scaleAspectFit
        avatarView.addSubview(avatarIcon)
        avatarIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(56)
        }

        nameLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        nameLabel.textColor = .abankTextPrimary

        loginDeviceLabel.font = .systemFont(ofSize: 12)
        loginDeviceLabel.textColor = .abankTextSecondary

        loginTimeLabel.font = .systemFont(ofSize: 11)
        loginTimeLabel.textColor = .abankTextTertiary

        let starIcon = UIImageView(image: UIImage.abankAsset("abc_mine_profile_star", fallback: "star.fill"))
        starIcon.tintColor = .abankGold
        starIcon.contentMode = .scaleAspectFit
        vipLabel.font = .systemFont(ofSize: 13)
        vipLabel.textColor = .abankTextPrimary
        vipBadge.backgroundColor = .clear
        vipBadge.layer.cornerRadius = 10
        vipBadge.addTarget(self, action: #selector(vipTapped), for: .touchUpInside)
        vipBadge.addSubview(starIcon)
        vipBadge.addSubview(vipLabel)
        starIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.size.equalTo(14)
        }
        vipLabel.snp.makeConstraints { make in
            make.leading.equalTo(starIcon.snp.trailing).offset(4)
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
        }

        var benefitsStyle = UIButton.Configuration.plain()
        benefitsStyle.baseForegroundColor = .white
        benefitsStyle.image = UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 9, weight: .semibold))
        benefitsStyle.imagePlacement = .trailing
        benefitsStyle.imagePadding = 4
        benefitsStyle.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        benefitsStyle.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var result = attributes
            result.font = UIFont.systemFont(ofSize: 13, weight: .regular)
            return result
        }
        benefitsStyle.titleLineBreakMode = .byClipping
        benefitsButton.configuration = benefitsStyle
        benefitsButton.titleLabel?.numberOfLines = 1
        benefitsButton.titleLabel?.adjustsFontSizeToFitWidth = true
        benefitsGradient.colors = [
            UIColor(red: 0.83, green: 0.71, blue: 0.43, alpha: 1).cgColor,
            UIColor(red: 0.94, green: 0.85, blue: 0.61, alpha: 1).cgColor
        ]
        benefitsGradient.startPoint = CGPoint(x: 0, y: 0.5)
        benefitsGradient.endPoint = CGPoint(x: 1, y: 0.5)
        benefitsGradient.cornerRadius = 6
        benefitsButton.layer.insertSublayer(benefitsGradient, at: 0)
        benefitsButton.layer.shadowColor = UIColor(red: 0.78, green: 0.64, blue: 0.31, alpha: 1).cgColor
        benefitsButton.layer.shadowOpacity = 0.16
        benefitsButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        benefitsButton.layer.shadowRadius = 5
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
            make.centerY.equalTo(avatarView)
            make.height.equalTo(28)
            make.width.equalTo(88)
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
            make.leading.equalTo(avatarView).offset(6)
            make.top.equalTo(loginTimeLabel.snp.bottom).offset(24)
            make.height.equalTo(24)
            make.bottom.equalToSuperview()
        }
    }

    @objc private func benefitsTapped() { onBenefitsTapped?() }
    @objc private func vipTapped() { onVIPTapped?() }
    @objc private func avatarTapped() { onAvatarTapped?() }
}
