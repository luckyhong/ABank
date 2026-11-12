//
//  WealthOrderDetailViewController.swift
//  ABank
//
//  订单详情：本金、累计收益、当前价值、持有天数、可赎回日；持有期满可赎回，本息回到账户。
//

import UIKit
import SnapKit

final class WealthOrderDetailViewController: WealthFlowViewController, RouteHosting {
    private let orderID: String
    private let justPurchased: Bool

    var hostedRoute: AppRoute? { .wealthOrderDetail(orderID: orderID, justPurchased: justPurchased) }

    init(orderID: String, justPurchased: Bool, ledger: FinanceLedgerStore = .shared,
         risk: RiskAssessmentStore = .shared, dates: BankingDateContext = .system) {
        self.orderID = orderID
        self.justPurchased = justPurchased
        super.init(ledger: ledger, risk: risk, dates: dates)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "订单详情"
    }

    override func refreshBankingData() {
        clearContent()
        guard let order = ledger.wealthOrder(id: orderID) else {
            addEmptyState("订单不存在", id: "wealth.order.missing")
            return
        }
        let status = ledger.wealthStatus(of: order)
        let days = WealthRules.holdingDays(since: order.createdAt, now: dates.now, dates: dates)
        let interest = ledger.accruedInterestInCents(of: order)
        let value = ledger.holdingValueInCents(of: order)

        if justPurchased, case .holding = status {
            let banner = UILabel()
            banner.text = "✓ 购买成功"
            banner.font = .abankBodyMedium()
            banner.textColor = .abankSuccess
            banner.accessibilityIdentifier = "wealth.success"
            addCard([banner])
        }

        let name = UILabel()
        name.text = order.productName
        name.font = .abankTitle3()
        name.textColor = .abankTextPrimary
        name.numberOfLines = 0
        let tag: BranchStatusTagView
        switch status {
        case .holding(let redeemable, _): tag = BranchStatusTagView(text: redeemable ? "可赎回" : "持有中", active: true)
        case .redeemed: tag = BranchStatusTagView(text: "已赎回", active: false)
        }
        let line = UIStackView(arrangedSubviews: [name, tag, UIView()])
        line.spacing = Spacing.sm
        line.alignment = .center
        addCard([line])

        var rows: [UIView] = [TransferInfoRow("本金", value: "\(wealthMoneyText(order.principalInCents)) 元")]
        switch status {
        case .holding:
            rows += [
                TransferInfoRow("累计收益", value: "\(wealthMoneyText(interest)) 元"),
                TransferInfoRow("当前价值", value: "\(wealthMoneyText(value)) 元"),
                TransferInfoRow("持有天数", value: "\(days) 天")
            ]
        case .redeemed:
            let redeemed = order.redeemedAmountInCents ?? order.principalInCents
            rows += [
                TransferInfoRow("赎回金额", value: "\(wealthMoneyText(redeemed)) 元"),
                TransferInfoRow("实现收益", value: "\(wealthMoneyText(redeemed - order.principalInCents)) 元"),
                TransferInfoRow("赎回时间", value: order.redeemedAt ?? "")
            ]
        }
        rows += [
            TransferInfoRow("年化", value: wealthRateText(order.rateBasisPoints)),
            TransferInfoRow("购买时间", value: order.createdAt),
            TransferInfoRow("可赎回日", value: WealthRules.redeemableDay(of: order, dates: dates))
        ]
        addGroup(rows)

        if case .holding(let redeemable, let remaining) = status {
            let button = addButton(redeemable ? "赎回" : "暂不可赎回", id: "wealth.redeem") { [weak self] in
                self?.confirm("赎回后本息约 \(wealthMoneyText(value)) 元将回到账户，确定赎回？", confirmTitle: "赎回") {
                    self?.redeem(order, expected: value)
                }
            }
            if !redeemable {
                button.isEnabled = false
                button.backgroundColor = .abankTextTertiary
                let note = branchCaption("还需持有 \(remaining) 天，\(WealthRules.redeemableDay(of: order, dates: dates)) 起可赎回。")
                note.accessibilityIdentifier = "wealth.redeem.note"
                contentStack.addArrangedSubview(note)
            }
        } else {
            contentStack.addArrangedSubview(branchCaption("订单已赎回，本息已回到付款账户。"))
        }
        addNotice("请核对账户与交易信息后办理")
    }

    private func redeem(_ order: WealthOrder, expected: Int64) {
        do {
            let result = try ledger.redeemWealthOrder(orderID: order.id)
            showToast("赎回成功，\(wealthMoneyText(result.redeemedAmountInCents ?? expected)) 元已到账")
        } catch {
            showError(error)
        }
    }
}
