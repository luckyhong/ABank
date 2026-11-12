//
//  LoginDevicesViewController.swift
//  ABank
//
//  登录设备列表：本机 + 其他模拟设备，点击进入详情。
//

import UIKit
import SnapKit

final class LoginDevicesViewController: SecurityFlowViewController, RouteHosting {
    private let listContainer = UIStackView()

    var hostedRoute: AppRoute? { .loginDevices }

    override func setupUI() {
        super.setupUI()
        title = "登录设备"
        addNotice("以下为最近登录过本账户的设备（账户信息）")
        listContainer.axis = .vertical
        listContainer.spacing = 12
        contentStack.addArrangedSubview(listContainer)
    }

    override func refreshBankingData() {
        listContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let devices = security.devices
        let rows: [UIView] = devices.map { device in
            let row = LoginDeviceRow(device: device, dates: .system)
            row.onTap = { [weak self] in
                guard let self else { return }
                self.router.open(.loginDeviceDetail(deviceID: device.id), from: self)
            }
            return row
        }
        let group = UIStackView(arrangedSubviews: rows)
        group.axis = .vertical
        group.backgroundColor = .white
        group.layer.cornerRadius = 10
        group.clipsToBounds = true
        listContainer.addArrangedSubview(group)
        if devices.allSatisfy(\.isCurrent) {
            let empty = UILabel()
            empty.text = "没有其他登录设备"
            empty.font = .systemFont(ofSize: 13)
            empty.textColor = .abankTextSecondary
            empty.textAlignment = .center
            listContainer.addArrangedSubview(empty)
        }
    }
}

/// 设备行：图标、名称、“本机”标签、最近登录时间与城市。
final class LoginDeviceRow: UIControl {
    var onTap: (() -> Void)?

    init(device: LoginDevice, dates: BankingDateContext) {
        super.init(frame: .zero)
        accessibilityIdentifier = "loginDevices.\(device.id)"
        isAccessibilityElement = true
        accessibilityTraits = .button

        let icon = UIImageView(image: UIImage.abankAsset("abc_security_devices", fallback: "iphone", pointSize: 28))
        icon.contentMode = .scaleAspectFit
        icon.snp.makeConstraints { $0.size.equalTo(28) }

        let name = UILabel()
        name.text = device.name
        name.font = .abankBody()
        name.textColor = .abankTextPrimary
        let nameLine = UIStackView(arrangedSubviews: [name])
        nameLine.spacing = Spacing.sm
        nameLine.alignment = .center
        if device.isCurrent {
            let tagLabel = UILabel()
            tagLabel.text = "本机"
            tagLabel.font = .abankCaption()
            tagLabel.textColor = .abankPrimary
            let tag = UIView()
            tag.layer.borderColor = UIColor.abankPrimary.cgColor
            tag.layer.borderWidth = 0.5
            tag.layer.cornerRadius = 3
            tag.addSubview(tagLabel)
            tagLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 1, left: 4, bottom: 1, right: 4)) }
            tag.setContentHuggingPriority(.required, for: .horizontal)
            nameLine.addArrangedSubview(tag)
        }
        nameLine.addArrangedSubview(UIView())

        let detail = UILabel()
        detail.text = "最近登录 " + dates.string(from: device.lastLogin, format: "yyyy-MM-dd HH:mm") + " · " + device.city
        detail.font = .abankCaption()
        detail.textColor = .abankTextSecondary
        detail.numberOfLines = 0

        let labels = UIStackView(arrangedSubviews: [nameLine, detail])
        labels.axis = .vertical
        labels.spacing = Spacing.xs

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right",
                                                 withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)))
        chevron.tintColor = .abankTextTertiary
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [icon, labels, chevron])
        stack.spacing = Spacing.md - 4
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        addSubview(stack)
        stack.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Spacing.md)
            $0.top.bottom.equalToSuperview().inset(Spacing.md - 4)
        }
        let line = UIView()
        line.backgroundColor = .abankSeparator.withAlphaComponent(0.5)
        addSubview(line)
        line.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Spacing.md)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }
        accessibilityLabel = [device.name, device.isCurrent ? "本机" : nil, detail.text].compactMap { $0 }.joined(separator: "，")
        addAction(UIAction { [weak self] _ in self?.onTap?() }, for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isHighlighted: Bool {
        didSet { backgroundColor = isHighlighted ? .abankSectionBackground : .clear }
    }
}
