//
//  OrdersViewController.swift
//  ABank
//
//  我的订单：兑换订单与充值缴费订单统一列表，按状态或“充值缴费”筛选。
//

import UIKit
import SnapKit

final class OrdersViewController: BenefitsFlowViewController, RouteHosting {
    private var filter = OrderListFilter.all
    let ledger: FinanceLedgerStore

    var hostedRoute: AppRoute? { .orders }

    init(ledger: FinanceLedgerStore = .shared, benefits: BenefitsStore = .shared, dates: BankingDateContext = .system) {
        self.ledger = ledger
        super.init(benefits: benefits, dates: dates)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "我的订单"
    }

    override func refreshBankingData() {
        clearContent()
        let bar = BranchChipBar(titles: OrderListFilter.allCases.map(\.title), selected: filter.rawValue, idPrefix: "orders.filter")
        bar.onSelect = { [weak self] index in
            self?.filter = OrderListFilter(rawValue: index) ?? .all
            self?.refreshBankingData()
        }
        contentStack.addArrangedSubview(bar)

        let visible = OrderListBuilder.items(
            filter: filter, reward: benefits.orders, payment: ledger.paymentOrders(),
            status: { [benefits] in benefits.status(of: $0) }, dates: dates
        )
        guard !visible.isEmpty else {
            addEmptyState("暂无订单", id: "orders.empty")
            return
        }
        for item in visible {
            switch item {
            case .reward(let order):
                contentStack.addArrangedSubview(rewardRow(order))
            case .payment(let order):
                contentStack.addArrangedSubview(paymentOrderRow(order) { [weak self] in
                    guard let self else { return }
                    self.router.open(.paymentOrderDetail(orderID: order.id, justPaid: false), from: self)
                })
            }
        }
    }

    private func rewardRow(_ order: RewardOrder) -> BenefitsRow {
        let status = benefits.status(of: order)
        let subtitle = "\(formattedAmount(order.cost)) \(order.currency.unit) · \(dateText(order.createdAt))"
        let row = BenefitsRow(title: order.title, subtitle: subtitle,
                              trailing: BranchStatusTagView(text: status.title, active: status.tagActive),
                              id: "orders.row.\(order.id)", showsChevron: true)
        row.onTap = { [weak self] in
            guard let self else { return }
            self.router.open(.orderDetail(orderID: order.id, justRedeemed: false), from: self)
        }
        return row
    }
}
