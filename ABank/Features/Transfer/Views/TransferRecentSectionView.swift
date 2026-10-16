//
//  TransferRecentSectionView.swift
//  ABank
//

import UIKit
import SnapKit

final class TransferRecentSectionView: UIView {

    var onAllPartnersTapped: (() -> Void)?
    var onPartnerHeaderTapped: ((Int) -> Void)?
    var onAccountTapped: ((Int, Int) -> Void)?

    private let titleLabel = UILabel()
    private let allPartnersButton = UIButton(type: .system)
    private let newBadge = UILabel()
    private let listStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(partners: [TransferPartner]) {
        listStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, partner) in partners.enumerated() {
            let row = TransferPartnerRowView()
            row.configure(partner: partner, isLast: index == partners.count - 1)
            row.onHeaderTapped = { [weak self] in self?.onPartnerHeaderTapped?(index) }
            row.onAccountTapped = { [weak self] accountIndex in
                self?.onAccountTapped?(index, accountIndex)
            }
            listStack.addArrangedSubview(row)
        }
    }

    private func setupUI() {
        backgroundColor = .white

        titleLabel.text = "最近转账 · 一点即转"
        titleLabel.font = .systemFont(ofSize: 17, weight: .regular)
        titleLabel.textColor = .abankTextPrimary

        allPartnersButton.setTitle("全部转账伙伴", for: .normal)
        allPartnersButton.setTitleColor(.abankTeal, for: .normal)
        allPartnersButton.titleLabel?.font = .systemFont(ofSize: 14)
        allPartnersButton.addTarget(self, action: #selector(allPartnersTapped), for: .touchUpInside)

        newBadge.text = " NEW "
        newBadge.font = .systemFont(ofSize: 11, weight: .regular)
        newBadge.textColor = .white
        newBadge.backgroundColor = .abankBadge
        newBadge.layer.cornerRadius = 3
        newBadge.layer.masksToBounds = true
        newBadge.textAlignment = .center

        listStack.axis = .vertical
        listStack.alignment = .fill
        listStack.spacing = 0

        addSubview(titleLabel)
        addSubview(allPartnersButton)
        addSubview(newBadge)
        addSubview(listStack)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
        }
        allPartnersButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(titleLabel)
        }
        newBadge.snp.makeConstraints { make in
            make.trailing.equalTo(allPartnersButton.snp.trailing)
            make.bottom.equalTo(allPartnersButton.snp.top).offset(4)
            make.height.equalTo(14)
        }
        listStack.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(26)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    @objc private func allPartnersTapped() { onAllPartnersTapped?() }
}

// MARK: - Partner row

final class TransferPartnerRowView: UIView {

    var onHeaderTapped: (() -> Void)?
    var onAccountTapped: ((Int) -> Void)?

    private let headerControl = UIControl()
    private let avatarView = TransferBankBadgeView()
    private let nameLabel = UILabel()
    private let countBadge = UILabel()
    private let subtitleLabel = UILabel()
    private let dateLabel = UILabel()
    private let chevronView = UIImageView()
    private let accountsStack = UIStackView()
    private let separator = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(partner: TransferPartner, isLast: Bool) {
        nameLabel.text = partner.name
        dateLabel.text = partner.lastTransferDate
        dateLabel.isHidden = partner.lastTransferDate == nil

        if partner.isMultiAccount {
            countBadge.isHidden = false
            countBadge.text = " \(partner.accountCount) "
            subtitleLabel.isHidden = true
            chevronView.isHidden = false
            let symbol = partner.isExpanded ? "chevron.up" : "chevron.down"
            let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)
            chevronView.image = UIImage(systemName: symbol, withConfiguration: config)
            if let icon = partner.avatarSystemIcon {
                avatarView.configurePerson(systemIcon: icon, tintHex: partner.avatarTintHex ?? "4A90D9", imageName: partner.avatarImageName)
            }
            nameLabel.snp.remakeConstraints { make in
                make.leading.equalTo(avatarView.snp.trailing).offset(12)
                make.centerY.equalToSuperview()
            }
        } else {
            countBadge.isHidden = true
            subtitleLabel.isHidden = false
            subtitleLabel.text = partner.primarySubtitle
            chevronView.isHidden = true
            if let account = partner.accounts.first {
                avatarView.configureBank(
                    symbol: account.bankSymbol,
                    colorHex: account.bankColorHex, imageName: account.imageName
                )
            }
            nameLabel.snp.remakeConstraints { make in
                make.leading.equalTo(avatarView.snp.trailing).offset(12)
                make.top.equalToSuperview().offset(16)
            }
        }

        accountsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        accountsStack.isHidden = !(partner.isMultiAccount && partner.isExpanded)
        if partner.isMultiAccount && partner.isExpanded {
            for (index, account) in partner.accounts.enumerated() {
                let row = TransferNestedAccountRowView()
                row.configure(account: account)
                row.tag = index
                row.addTarget(self, action: #selector(accountTapped(_:)), for: .touchUpInside)
                accountsStack.addArrangedSubview(row)
            }
        }

        separator.isHidden = isLast
    }

    private func setupUI() {
        nameLabel.font = .systemFont(ofSize: 16, weight: .regular)
        nameLabel.textColor = .abankTextPrimary

        countBadge.font = .systemFont(ofSize: 11)
        countBadge.textColor = .abankTextSecondary
        countBadge.backgroundColor = UIColor(red: 240 / 255, green: 240 / 255, blue: 240 / 255, alpha: 1)
        countBadge.layer.cornerRadius = 8
        countBadge.layer.masksToBounds = true
        countBadge.textAlignment = .center

        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .abankTextSecondary
        subtitleLabel.lineBreakMode = .byTruncatingMiddle

        dateLabel.font = .systemFont(ofSize: 12)
        dateLabel.textColor = .abankTextTertiary
        dateLabel.textAlignment = .right

        let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)
        chevronView.image = UIImage(systemName: "chevron.down", withConfiguration: config)
        chevronView.tintColor = .abankTextTertiary
        chevronView.contentMode = .scaleAspectFit

        accountsStack.axis = .vertical
        accountsStack.spacing = 0
        accountsStack.isHidden = true

        separator.backgroundColor = .abankSeparator

        headerControl.addTarget(self, action: #selector(headerTapped), for: .touchUpInside)

        addSubview(headerControl)
        [avatarView, nameLabel, countBadge, subtitleLabel, dateLabel, chevronView].forEach {
            headerControl.addSubview($0)
        }
        addSubview(accountsStack)
        addSubview(separator)

        headerControl.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(78)
        }
        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(34)
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(16)
        }
        countBadge.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.trailing).offset(6)
            make.centerY.equalTo(nameLabel)
            make.height.equalTo(20)
            make.width.greaterThanOrEqualTo(32)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.trailing.lessThanOrEqualTo(dateLabel.snp.leading).offset(-8)
        }
        chevronView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(12)
        }
        dateLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(nameLabel)
        }
        accountsStack.snp.makeConstraints { make in
            make.top.equalTo(headerControl.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }
        separator.snp.makeConstraints { make in
            make.top.equalTo(accountsStack.snp.bottom)
            make.leading.equalToSuperview().offset(16)
            make.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    @objc private func headerTapped() { onHeaderTapped?() }
    @objc private func accountTapped(_ sender: UIControl) { onAccountTapped?(sender.tag) }
}

// MARK: - Nested account

final class TransferNestedAccountRowView: UIControl {

    private let badge = TransferBankBadgeView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(account: TransferAccount) {
        badge.configureBank(symbol: account.bankSymbol, colorHex: account.bankColorHex, imageName: account.imageName)
        titleLabel.text = "\(account.bankName)(\(account.maskedNumber))"
    }

    private func setupUI() {
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .abankTextPrimary
        titleLabel.lineBreakMode = .byTruncatingMiddle

        addSubview(badge)
        addSubview(titleLabel)
        badge.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(68)
            make.centerY.equalToSuperview()
            make.size.equalTo(28)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(badge.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        snp.makeConstraints { make in
            make.height.equalTo(44)
        }
    }
}

// MARK: - Bank / person badge

final class TransferBankBadgeView: UIView {

    private let label = UILabel()
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 20
        clipsToBounds = true

        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center

        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true

        addSubview(label)
        addSubview(imageView)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(28)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }

    func configureBank(symbol: String, colorHex: String, imageName: String? = nil) {
        imageView.image = nil
        imageView.isHidden = true
        label.isHidden = false
        label.text = symbol
        backgroundColor = UIColor(hex: colorHex) ?? .abankTeal
        guard let imageName, let artwork = UIImage(named: imageName) else { return }
        label.isHidden = true
        imageView.isHidden = false
        if imageName == "abc_transfer_bank_ccb_wordmark", let cgImage = artwork.cgImage,
           let mark = cgImage.cropping(to: CGRect(x: 0, y: 0, width: 38, height: 40)) {
            // The official wordmark starts with a standalone emblem; render that emblem
            // in the reference's white-on-blue circular bank badge.
            imageView.image = UIImage(cgImage: mark).withTintColor(.white, renderingMode: .alwaysOriginal)
            imageView.snp.remakeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(24) }
        } else {
            backgroundColor = .clear
            imageView.image = artwork.withRenderingMode(.alwaysOriginal)
            imageView.snp.remakeConstraints { $0.edges.equalToSuperview() }
        }
    }

    func configurePerson(systemIcon: String, tintHex: String, imageName: String? = nil) {
        label.isHidden = true
        imageView.isHidden = false
        if let imageName, let artwork = UIImage(named: imageName) {
            backgroundColor = .clear
            imageView.image = artwork.withRenderingMode(.alwaysOriginal)
            imageView.snp.remakeConstraints { $0.edges.equalToSuperview() }
        } else {
            backgroundColor = UIColor(hex: tintHex)?.withAlphaComponent(0.15) ?? UIColor.systemBlue.withAlphaComponent(0.15)
            let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
            imageView.image = UIImage(systemName: systemIcon, withConfiguration: config)
            imageView.tintColor = UIColor(hex: tintHex) ?? .systemBlue
            imageView.snp.remakeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(28) }
        }
    }

}

private extension UIColor {
    convenience init?(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else { return nil }
        self.init(
            red: CGFloat((value & 0xFF0000) >> 16) / 255,
            green: CGFloat((value & 0x00FF00) >> 8) / 255,
            blue: CGFloat(value & 0x0000FF) / 255,
            alpha: 1
        )
    }
}
