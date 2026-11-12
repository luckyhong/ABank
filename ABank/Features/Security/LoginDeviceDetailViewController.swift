//
//  LoginDeviceDetailViewController.swift
//  ABank
//
//  设备详情：型号、系统、登录时间与城市；非本机可确认后移除。
//

import UIKit

final class LoginDeviceDetailViewController: SecurityFlowViewController, RouteHosting {
    private let deviceID: String
    private let dates: BankingDateContext

    var hostedRoute: AppRoute? { .loginDeviceDetail(deviceID: deviceID) }

    init(deviceID: String, security: SecuritySettingsStore = .shared, dates: BankingDateContext = .system) {
        self.deviceID = deviceID
        self.dates = dates
        super.init(security: security)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "设备详情"
        guard let device = security.device(id: deviceID) else {
            addNotice(SecuritySettingsError.deviceNotFound.localizedDescription)
            return
        }
        let format = "yyyy-MM-dd HH:mm"
        addGroup([
            TransferInfoRow("设备名称", value: device.displayName),
            TransferInfoRow("型号", value: device.displayModel),
            TransferInfoRow("系统", value: device.displaySystem),
            TransferInfoRow("首次登录", value: device.isCurrent ? "—" : dates.string(from: device.firstLogin, format: format)),
            TransferInfoRow("最近登录", value: device.displayLastLogin(dates: dates)),
            TransferInfoRow("登录城市", value: device.isCurrent ? "—" : device.city)
        ])
        if device.isCurrent {
            addNotice(SecuritySettingsError.deviceNotRemovable.localizedDescription)
        } else {
            let button = addButton("移除此设备", id: "device.remove", primary: false) { [weak self] in self?.confirmRemoval() }
            button.setTitleColor(.abankError, for: .normal)
        }
    }

    private func confirmRemoval() {
        let alert = UIAlertController(title: "移除设备", message: "移除后该设备需重新验证才能登录", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "移除", style: .destructive) { [weak self] _ in self?.remove() })
        present(alert, animated: true)
    }

    private func remove() {
        do {
            try security.removeDevice(id: deviceID)
        } catch {
            showToast(error.localizedDescription)
            return
        }
        let previous = navigationController.flatMap { $0.viewControllers.dropLast().last } as? BaseViewController
        navigationController?.popViewController(animated: true)
        previous?.showToast("已移除")
    }
}
