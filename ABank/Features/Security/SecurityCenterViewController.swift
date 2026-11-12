//
//  SecurityCenterViewController.swift
//  ABank
//
//  安全中心首页：保护状态 + 账户安全入口 + 隐私开关。
//

import UIKit
import SnapKit

final class SecurityCenterViewController: SecurityFlowViewController, RouteHosting {
    private let statusTitle = UILabel()
    private let hideAmountsRow = SecuritySwitchRow(title: "隐藏金额", subtitle: "开启后“我的”和贷款页面金额以 **** 显示",
                                                   id: "security.hideAmounts")
    private let transferRow = SecurityNavigationRow(title: "转账设置", imageName: "abc_security_transfer",
                                                    fallback: "shield.lefthalf.filled", id: "security.transferSettings")
    private let devicesRow = SecurityNavigationRow(title: "登录设备", imageName: "abc_security_devices",
                                                   fallback: "iphone", id: "security.loginDevices")

    var hostedRoute: AppRoute? { .securityCenter }

    override func setupUI() {
        super.setupUI()
        title = "安全中心"
        contentStack.addArrangedSubview(makeStatusCard())

        contentStack.addArrangedSubview(makeSecuritySectionTitle("账户安全"))
        let loginRow = SecurityNavigationRow(title: "登录设置", imageName: "abc_security_login",
                                             fallback: "door.left.hand.open", id: "security.loginSettings")
        let paymentRow = SecurityNavigationRow(title: "支付设置", imageName: "abc_security_payment",
                                               fallback: "lock.shield", id: "security.paymentSettings")
        loginRow.onTap = { [weak self] in self?.open(.loginSettings) }
        transferRow.onTap = { [weak self] in self?.open(.transferLimits) }
        paymentRow.onTap = { [weak self] in self?.open(.paymentSettings) }
        devicesRow.onTap = { [weak self] in self?.open(.loginDevices) }
        addGroup([loginRow, transferRow, paymentRow, devicesRow])

        contentStack.addArrangedSubview(makeSecuritySectionTitle("隐私"))
        hideAmountsRow.onChange = { [weak self] hides in
            guard let self else { return }
            self.handleSaveResult(self.security.setHidesAmounts(hides)) {
                self.hideAmountsRow.setOn(!hides, animated: true)
            }
        }
        addGroup([hideAmountsRow])
        addNotice("管理账户安全与交易设置")
    }

    override func refreshBankingData() {
        statusTitle.text = "已开启 \(security.enabledProtectionCount) 项保护"
        hideAmountsRow.setOn(security.hidesAmounts, animated: false)
        let limits = security.transferLimits
        transferRow.setDetail("单笔 ¥" + TransferMoney.amount(limits.perTransferInCents).abankPlainAmountString())
        devicesRow.setDetail("\(security.devices.count) 台")
    }

    private func open(_ route: AppRoute) {
        router.open(route, from: self)
    }

    private func makeStatusCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .abankCardBackground
        card.layer.cornerRadius = 10
        let icon = UIImageView(image: UIImage.abankAsset("abc_security_center", fallback: "lock.shield.fill", pointSize: 40))
        icon.contentMode = .scaleAspectFit
        icon.tintColor = .abankPrimary
        statusTitle.font = .abankTitle3()
        statusTitle.textColor = .abankTextPrimary
        statusTitle.accessibilityIdentifier = "security.statusTitle"
        let subtitle = UILabel()
        subtitle.text = "账户信息"
        subtitle.font = .abankCaption()
        subtitle.textColor = .abankTextSecondary
        let labels = UIStackView(arrangedSubviews: [statusTitle, subtitle])
        labels.axis = .vertical
        labels.spacing = Spacing.xs
        let stack = UIStackView(arrangedSubviews: [icon, labels])
        stack.spacing = Spacing.md - 4
        stack.alignment = .center
        card.addSubview(stack)
        icon.snp.makeConstraints { $0.size.equalTo(40) }
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(Spacing.md) }
        return card
    }
}
