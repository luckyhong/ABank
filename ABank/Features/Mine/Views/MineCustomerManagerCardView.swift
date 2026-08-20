//
//  MineCustomerManagerCardView.swift
//  ABank
//

import UIKit
import SnapKit

final class MineCustomerManagerCardView: UIView {

    var onWeChatTapped: (() -> Void)?

    private let card = UIView()
    private let avatarView = UIView()
    private let avatarIcon = UIImageView(image: UIImage(systemName: "person.fill"))
    private let nameLabel = UILabel()
    private let roleBadge = UILabel()
    private let branchLabel = UILabel()
    private let wechatButton = UIControl()
    private let wechatIcon = UIImageView(image: UIImage(systemName: "message.fill"))
    private let wechatLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with manager: MineCustomerManager) {
        nameLabel.text = manager.name
        roleBadge.text = manager.role
        branchLabel.text = manager.branch
    }

    private func setupUI() {
        card.backgroundColor = .abankCardBackground
        card.layer.cornerRadius = CornerRadius.lg
        card.addShadow(color: .black, opacity: 0.06, offset: CGSize(width: 0, height: 2), radius: 8)

        avatarView.backgroundColor = UIColor.abankPrimary.withAlphaComponent(0.15)
        avatarView.layer.cornerRadius = 24
        avatarIcon.tintColor = .abankPrimary
        avatarIcon.contentMode = .scaleAspectFit
        avatarView.addSubview(avatarIcon)
        avatarIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(24)
        }

        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .abankTextPrimary

        roleBadge.font = .systemFont(ofSize: 10)
        roleBadge.textColor = .abankPrimary
        roleBadge.backgroundColor = UIColor.abankPrimary.withAlphaComponent(0.12)
        roleBadge.layer.cornerRadius = 4
        roleBadge.textAlignment = .center
        roleBadge.layer.masksToBounds = true

        branchLabel.font = .systemFont(ofSize: 12)
        branchLabel.textColor = .abankTextTertiary

        wechatIcon.tintColor = .abankPrimary
        wechatIcon.contentMode = .scaleAspectFit
        wechatLabel.text = "企业微信"
        wechatLabel.font = .systemFont(ofSize: 11)
        wechatLabel.textColor = .abankTextSecondary
        wechatButton.addTarget(self, action: #selector(wechatTapped), for: .touchUpInside)

        addSubview(card)
        [avatarView, nameLabel, roleBadge, branchLabel, wechatButton].forEach { card.addSubview($0) }
        [wechatIcon, wechatLabel].forEach { wechatButton.addSubview($0) }

        card.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(80)
        }
        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.centerY.equalToSuperview()
            make.size.equalTo(48)
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.top.equalTo(avatarView).offset(4)
        }
        roleBadge.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.trailing).offset(8)
            make.centerY.equalTo(nameLabel)
            make.height.equalTo(18)
            make.width.greaterThanOrEqualTo(52)
        }
        branchLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(6)
            make.trailing.lessThanOrEqualTo(wechatButton.snp.leading).offset(-8)
        }
        wechatButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.centerY.equalToSuperview()
            make.width.equalTo(56)
        }
        wechatIcon.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(24)
        }
        wechatLabel.snp.makeConstraints { make in
            make.top.equalTo(wechatIcon.snp.bottom).offset(4)
            make.centerX.bottom.equalToSuperview()
        }
    }

    @objc private func wechatTapped() { onWeChatTapped?() }
}
