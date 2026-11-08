//
//  AccountPermissionsViewController.swift
//  ABank
//
//  模拟交易权限：切换即保存；关闭后转账、充值缴费在确认前与提交时被拦截。
//

import UIKit

final class AccountPermissionsViewController: TransferFlowViewController, RouteHosting {
    private let accountID: String
    private let ledger: FinanceLedgerStore
    private let transferRow = SecuritySwitchRow(title: "手机银行转账", subtitle: "关闭后无法转账", id: "permissions.transfer")
    private let paymentRow = SecuritySwitchRow(title: "网上支付", subtitle: "关闭后无法手机充值和生活缴费", id: "permissions.payment")

    var hostedRoute: AppRoute? { .accountPermissions(accountID: accountID) }

    init(accountID: String, ledger: FinanceLedgerStore = .shared) {
        self.accountID = accountID
        self.ledger = ledger
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "交易权限"
        guard let account = ledger.account(id: accountID) else {
            addNotice(AccountSettingsError.accountNotFound.localizedDescription)
            return
        }
        addNotice(account.cardLabel)
        transferRow.onChange = { [weak self] isOn in self?.update { $0.mobileTransfer = isOn } }
        paymentRow.onChange = { [weak self] isOn in self?.update { $0.onlinePayment = isOn } }
        addGroup([transferRow, paymentRow])
        addNotice("本机模拟权限，不涉及真实账户")
    }

    override func refreshBankingData() {
        guard let permissions = ledger.account(id: accountID)?.permissions else { return }
        transferRow.toggle.setOn(permissions.mobileTransfer, animated: false)
        paymentRow.toggle.setOn(permissions.onlinePayment, animated: false)
    }

    private func update(_ change: (inout AccountPermissions) -> Void) {
        guard var permissions = ledger.account(id: accountID)?.permissions else { return }
        change(&permissions)
        do {
            try ledger.setPermissions(permissions, accountID: accountID)
        } catch {
            showToast(error.localizedDescription)
            refreshBankingData()  // 开关回弹到已保存的状态
        }
    }
}
