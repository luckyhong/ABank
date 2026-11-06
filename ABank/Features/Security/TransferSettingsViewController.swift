//
//  TransferSettingsViewController.swift
//  ABank
//
//  转账设置：查看并修改模拟限额，显示今日已转金额。限额在确认前及提交时均会校验。
//

import UIKit

final class TransferSettingsViewController: SecurityFlowViewController, RouteHosting {
    private let ledger: FinanceLedgerStore
    private let perTransferRow = SecurityNavigationRow(title: "单笔限额", imageName: nil, fallback: "",
                                                       id: "transferSettings.perTransfer")
    private let dailyRow = SecurityNavigationRow(title: "日累计限额", imageName: nil, fallback: "",
                                                 id: "transferSettings.daily")
    private let todayRow = TransferInfoRow("今日已转", value: "")

    var hostedRoute: AppRoute? { .transferLimits }

    init(ledger: FinanceLedgerStore? = nil, security: SecuritySettingsStore = .shared) {
        self.ledger = ledger ?? .shared
        super.init(security: security)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "转账设置"
        addNotice("本机模拟规则 · 点击限额可修改")
        perTransferRow.onTap = { [weak self] in self?.openEditor() }
        dailyRow.onTap = { [weak self] in self?.openEditor() }
        todayRow.valueLabel.accessibilityIdentifier = "transferSettings.today"
        addGroup([perTransferRow, dailyRow, todayRow])
        addNotice("金额和限额在确认前及提交时均会校验")
    }

    override func refreshBankingData() {
        let limits = security.transferLimits
        perTransferRow.setDetail(Self.yuan(limits.perTransferInCents))
        dailyRow.setDetail(Self.yuan(limits.dailyInCents))
        todayRow.valueLabel.text = Self.yuan(ledger.transferredTodayInCents())
    }

    private func openEditor() {
        navigationController?.pushViewController(TransferLimitEditViewController(security: security), animated: true)
    }

    static func yuan(_ cents: Int64) -> String {
        "¥ " + TransferMoney.amount(cents).abankPlainAmountString()
    }
}
