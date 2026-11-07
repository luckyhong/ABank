//
//  PaymentSettingsViewController.swift
//  ABank
//
//  支付设置：小额免密支付开关与免密额度，仅为演示状态。
//

import UIKit

final class PaymentSettingsViewController: SecurityFlowViewController, RouteHosting {
    private let switchRow = SecuritySwitchRow(title: "小额免密支付", subtitle: "额度内付款无需输入支付密码",
                                              id: "paymentSettings.smallPayment")
    private let quotaTitle = makeSecuritySectionTitle("免密额度（单笔）")
    private var quotaGroup: UIView?
    private var quotaRows: [(Int64, SecurityOptionRow)] = []

    var hostedRoute: AppRoute? { .paymentSettings }

    override func setupUI() {
        super.setupUI()
        title = "支付设置"
        switchRow.onChange = { [weak self] enabled in
            guard let self else { return }
            let quota = self.security.settings.smallPaymentQuotaInCents
            self.handleSaveResult(self.security.setSmallPayment(enabled: enabled, quotaInCents: quota)) {
                self.switchRow.setOn(!enabled, animated: true)
            }
            self.refreshBankingData()
        }
        addGroup([switchRow])

        contentStack.addArrangedSubview(quotaTitle)
        quotaRows = SecuritySettingsStore.smallPaymentQuotas.map { quota in
            let yuan = String(quota / 100)
            let row = SecurityOptionRow(title: "\(yuan) 元", id: "paymentSettings.quota.\(quota / 100)")
            row.onTap = { [weak self] in self?.selectQuota(quota) }
            return (quota, row)
        }
        addGroup(quotaRows.map(\.1))
        quotaGroup = contentStack.arrangedSubviews.last
        addNotice("演示设置，不做真实验证")
    }

    override func refreshBankingData() {
        let settings = security.settings
        switchRow.setOn(settings.smallPaymentWithoutPasswordEnabled, animated: false)
        quotaTitle.isHidden = !settings.smallPaymentWithoutPasswordEnabled
        quotaGroup?.isHidden = !settings.smallPaymentWithoutPasswordEnabled
        for (quota, row) in quotaRows { row.setSelected(quota == settings.smallPaymentQuotaInCents) }
    }

    private func selectQuota(_ quota: Int64) {
        handleSaveResult(security.setSmallPayment(enabled: true, quotaInCents: quota)) {}
        refreshBankingData()
    }
}
