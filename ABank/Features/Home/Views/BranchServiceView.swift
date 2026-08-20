//
//  BranchServiceView.swift
//  ABank
//

import UIKit
import SnapKit

final class BranchServiceView: UIView {

    var onQueueTapped: (() -> Void)?
    var onPhoneTapped: (() -> Void)?
    var onRefreshTapped: (() -> Void)?

    private let header = SectionHeaderView(title: "网点服务")
    private let card = UIView()
    private let logoView = UIView()
    private let nameLabel = UILabel()
    private let statusLabel = UILabel()
    private let distanceLabel = UILabel()
    private let phoneButton = UIButton(type: .system)
    private let addressLabel = UILabel()
    private let mapView = UIView()
    private let mapPin = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
    private let serviceStack = UIStackView()
    private let queueButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with branch: HomeBranchInfo) {
        nameLabel.text = branch.name
        statusLabel.text = branch.status
        distanceLabel.text = branch.distance
        addressLabel.text = branch.address

        serviceStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        branch.services.forEach { serviceStack.addArrangedSubview(makeService(item: $0)) }
    }

    private func setupUI() {
        let refresh = UIButton(type: .system)
        refresh.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        refresh.tintColor = .abankPrimary
        refresh.addAction(UIAction { [weak self] _ in self?.onRefreshTapped?() }, for: .touchUpInside)
        header.addAccessory(refresh)

        card.backgroundColor = .abankCardBackground
        card.layer.cornerRadius = CornerRadius.lg
        card.addShadow(color: .black, opacity: 0.06, offset: CGSize(width: 0, height: 2), radius: 8)

        logoView.backgroundColor = .abankPrimary
        logoView.layer.cornerRadius = 12
        let logoIcon = UIImageView(image: UIImage(systemName: "building.columns.fill"))
        logoIcon.tintColor = .white
        logoIcon.contentMode = .scaleAspectFit
        logoView.addSubview(logoIcon)
        logoIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(14)
        }

        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .abankTextPrimary
        statusLabel.font = .systemFont(ofSize: 10)
        statusLabel.textColor = .abankPrimary
        statusLabel.layer.borderColor = UIColor.abankPrimary.cgColor
        statusLabel.layer.borderWidth = 0.8
        statusLabel.layer.cornerRadius = 4
        statusLabel.textAlignment = .center

        distanceLabel.font = .systemFont(ofSize: 12)
        distanceLabel.textColor = .abankTextSecondary
        phoneButton.setImage(UIImage(systemName: "phone.fill"), for: .normal)
        phoneButton.tintColor = .abankPrimary
        phoneButton.backgroundColor = UIColor.abankPrimary.withAlphaComponent(0.12)
        phoneButton.layer.cornerRadius = 12

        addressLabel.font = .systemFont(ofSize: 12)
        addressLabel.textColor = .abankTextTertiary
        addressLabel.lineBreakMode = .byTruncatingTail

        mapView.backgroundColor = UIColor(red: 0.90, green: 0.94, blue: 0.90, alpha: 1)
        mapView.layer.cornerRadius = CornerRadius.sm
        mapPin.tintColor = .abankOrange
        mapView.addSubview(mapPin)
        mapPin.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(22)
        }

        serviceStack.axis = .horizontal
        serviceStack.spacing = 16
        serviceStack.alignment = .center

        queueButton.setTitle("取号", for: .normal)
        queueButton.setTitleColor(.white, for: .normal)
        queueButton.backgroundColor = .abankOrange
        queueButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        queueButton.layer.cornerRadius = 18
        queueButton.addTarget(self, action: #selector(queueTapped), for: .touchUpInside)
        phoneButton.addTarget(self, action: #selector(phoneTapped), for: .touchUpInside)

        addSubview(header)
        addSubview(card)
        [logoView, nameLabel, statusLabel, distanceLabel, phoneButton, addressLabel, mapView, serviceStack, queueButton].forEach {
            card.addSubview($0)
        }

        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(24)
        }
        card.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }
        logoView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(14)
            make.size.equalTo(24)
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(logoView.snp.trailing).offset(8)
            make.centerY.equalTo(logoView)
        }
        statusLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.trailing).offset(8)
            make.centerY.equalTo(nameLabel)
            make.height.equalTo(18)
            make.width.equalTo(44)
            make.trailing.lessThanOrEqualTo(mapView.snp.leading).offset(-8)
        }
        mapView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-14)
            make.size.equalTo(64)
        }
        distanceLabel.snp.makeConstraints { make in
            make.top.equalTo(logoView.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(14)
        }
        phoneButton.snp.makeConstraints { make in
            make.leading.equalTo(distanceLabel.snp.trailing).offset(8)
            make.centerY.equalTo(distanceLabel)
            make.size.equalTo(24)
        }
        addressLabel.snp.makeConstraints { make in
            make.top.equalTo(distanceLabel.snp.bottom).offset(6)
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalTo(mapView.snp.leading).offset(-8)
        }
        serviceStack.snp.makeConstraints { make in
            make.top.equalTo(addressLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(14)
            make.bottom.equalToSuperview().offset(-16)
            make.height.equalTo(44)
        }
        queueButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalTo(serviceStack)
            make.width.equalTo(72)
            make.height.equalTo(36)
        }
    }

    private func makeService(item: HomeBranchServiceItem) -> UIView {
        let wrap = UIView()
        let icon = UIImageView(image: UIImage(systemName: item.systemIcon))
        icon.tintColor = .abankTextSecondary
        icon.contentMode = .scaleAspectFit
        let title = UILabel()
        title.text = item.title
        title.font = .systemFont(ofSize: 11)
        title.textColor = .abankTextSecondary
        title.textAlignment = .center
        wrap.addSubview(icon)
        wrap.addSubview(title)
        icon.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(18)
        }
        title.snp.makeConstraints { make in
            make.top.equalTo(icon.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview()
        }
        wrap.snp.makeConstraints { make in
            make.width.equalTo(56)
        }
        return wrap
    }

    @objc private func queueTapped() { onQueueTapped?() }
    @objc private func phoneTapped() { onPhoneTapped?() }
}
