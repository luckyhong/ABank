//
//  PensionZoneView.swift
//  ABank
//

import UIKit
import SnapKit

final class PensionZoneView: UIView {

    private let header = SectionHeaderView(title: "养老专区")
    private let card = UIView()
    private let banner = UIView()
    private let sloganLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let artView = UIImageView()
    private let serviceStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(slogan: String, subtitle: String, services: [HomePensionServiceItem]) {
        sloganLabel.text = slogan
        subtitleLabel.text = subtitle
        serviceStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        services.forEach { serviceStack.addArrangedSubview(makeService(item: $0)) }
    }

    private func setupUI() {
        card.backgroundColor = .abankCardBackground
        card.layer.cornerRadius = CornerRadius.lg
        card.addShadow(color: .black, opacity: 0.06, offset: CGSize(width: 0, height: 2), radius: 8)

        banner.backgroundColor = UIColor(red: 0.90, green: 0.95, blue: 1.0, alpha: 1)
        banner.layer.cornerRadius = CornerRadius.md
        banner.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        banner.clipsToBounds = true

        sloganLabel.font = .systemFont(ofSize: 18, weight: .bold)
        sloganLabel.textColor = UIColor(red: 0.25, green: 0.45, blue: 0.75, alpha: 1)
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = UIColor(red: 0.40, green: 0.55, blue: 0.75, alpha: 1)
        artView.image = UIImage(systemName: "person.2.fill")
        artView.tintColor = UIColor(red: 0.35, green: 0.55, blue: 0.85, alpha: 1)
        artView.contentMode = .scaleAspectFit

        serviceStack.axis = .horizontal
        serviceStack.distribution = .fillEqually

        addSubview(header)
        addSubview(card)
        card.addSubview(banner)
        card.addSubview(serviceStack)
        banner.addSubview(sloganLabel)
        banner.addSubview(subtitleLabel)
        banner.addSubview(artView)

        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(24)
        }
        card.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }
        banner.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(96)
        }
        sloganLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(24)
            make.trailing.lessThanOrEqualTo(artView.snp.leading).offset(-8)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(sloganLabel)
            make.top.equalTo(sloganLabel.snp.bottom).offset(6)
        }
        artView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(56)
        }
        serviceStack.snp.makeConstraints { make in
            make.top.equalTo(banner.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().offset(-14)
            make.height.equalTo(64)
        }
    }

    private func makeService(item: HomePensionServiceItem) -> UIView {
        let wrap = UIView()
        let icon = UIImageView(image: UIImage(systemName: item.systemIcon))
        icon.tintColor = .abankPrimary
        icon.contentMode = .scaleAspectFit
        let title = UILabel()
        title.text = item.title
        title.font = .systemFont(ofSize: 12)
        title.textColor = .abankTextPrimary
        title.textAlignment = .center
        wrap.addSubview(icon)
        wrap.addSubview(title)
        icon.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.size.equalTo(26)
        }
        title.snp.makeConstraints { make in
            make.top.equalTo(icon.snp.bottom).offset(6)
            make.leading.trailing.bottom.equalToSuperview()
        }
        return wrap
    }
}
