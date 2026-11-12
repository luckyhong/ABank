//
//  WealthHoldingsViewController.swift
//  ABank
//
//  我的持仓：持仓价值与累计收益汇总，持有中 / 已赎回两段。
//

import UIKit
import SnapKit

final class WealthHoldingsViewController: WealthFlowViewController, RouteHosting {
    private var segment = 0

    var hostedRoute: AppRoute? { .wealthHoldings }

    override func setupUI() {
        super.setupUI()
        title = "我的持仓"
    }

    override func refreshBankingData() {
        clearContent()
        let orders = ledger.wealthOrders()
        let holding = orders.filter { $0.redeemedAt == nil }
        let redeemed = orders.filter { $0.redeemedAt != nil }
        let totalValue = holding.reduce(Int64(0)) { $0 + ledger.holdingValueInCents(of: $1) }
        let totalInterest = holding.reduce(Int64(0)) { $0 + ledger.accruedInterestInCents(of: $1) }

        let value = UILabel()
        value.text = wealthMoneyText(totalValue)
        value.font = .systemFont(ofSize: 32, weight: .semibold)
        value.textColor = .abankPrimary
        value.accessibilityIdentifier = "holdings.total"
        addCard([branchCaption("持仓价值（元）"), value,
                 branchCaption("累计收益 \(wealthMoneyText(totalInterest)) 元 · 持有 \(holding.count) 笔")])

        let control = UISegmentedControl(items: ["持有中", "已赎回"])
        control.selectedSegmentIndex = segment
        control.accessibilityIdentifier = "holdings.segment"
        control.addAction(UIAction { [weak self, weak control] _ in
            self?.segment = control?.selectedSegmentIndex ?? 0
            self?.refreshBankingData()
        }, for: .valueChanged)
        contentStack.addArrangedSubview(control)

        let visible = segment == 0 ? holding : redeemed
        guard !visible.isEmpty else {
            addEmptyState(segment == 0 ? "暂无持仓，去看看理财产品" : "暂无已赎回订单", id: "holdings.empty")
            if segment == 0 {
                _ = addButton("去选产品", id: "holdings.browse") { [weak self] in
                    guard let self else { return }
                    self.router.open(.wealthProducts, from: self)
                }
            }
            return
        }
        for order in visible {
            let status = ledger.wealthStatus(of: order)
            let tag: BranchStatusTagView
            let subtitle: String
            switch status {
            case .holding(let redeemable, let remaining):
                tag = BranchStatusTagView(text: redeemable ? "可赎回" : "\(remaining) 天后可赎回", active: true)
                subtitle = "本金 \(wealthMoneyText(order.principalInCents)) 元 · 当前价值 \(wealthMoneyText(ledger.holdingValueInCents(of: order))) 元"
            case .redeemed:
                tag = BranchStatusTagView(text: "已赎回", active: false)
                subtitle = "本金 \(wealthMoneyText(order.principalInCents)) 元 · 赎回 \(wealthMoneyText(order.redeemedAmountInCents ?? 0)) 元"
            }
            let row = BenefitsRow(title: order.productName, subtitle: subtitle, trailing: tag,
                                  id: "holdings.row.\(order.id)", showsChevron: true)
            row.onTap = { [weak self] in
                guard let self else { return }
                self.router.open(.wealthOrderDetail(orderID: order.id, justPurchased: false), from: self)
            }
            contentStack.addArrangedSubview(row)
        }
        addNotice("收益按年化与持有天数推算")
    }
}
