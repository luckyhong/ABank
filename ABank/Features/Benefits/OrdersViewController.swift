//
//  OrdersViewController.swift
//  ABank
//
//  我的订单：按状态筛选的兑换订单列表。
//

import UIKit
import SnapKit

final class OrdersViewController: BenefitsFlowViewController, RouteHosting {
    private static let filters: [(title: String, status: OrderStatus?)] = [
        ("全部", nil), ("待使用", .pendingUse), ("已使用", .used), ("已失效", .expired), ("已取消", .cancelled)
    ]
    private var filter = 0

    var hostedRoute: AppRoute? { .orders }

    override func setupUI() {
        super.setupUI()
        title = "我的订单"
    }

    override func refreshBankingData() {
        clearContent()
        let bar = BranchChipBar(titles: Self.filters.map(\.title), selected: filter, idPrefix: "orders.filter")
        bar.onSelect = { [weak self] index in
            self?.filter = index
            self?.refreshBankingData()
        }
        contentStack.addArrangedSubview(bar)

        let wanted = Self.filters[filter].status
        let visible = benefits.orders.filter { wanted == nil || benefits.status(of: $0) == wanted }
        guard !visible.isEmpty else {
            addEmptyState("暂无订单", id: "orders.empty")
            return
        }
        for order in visible {
            let status = benefits.status(of: order)
            let subtitle = "\(formattedAmount(order.cost)) \(order.currency.unit) · \(dateText(order.createdAt))"
            let row = BenefitsRow(title: order.title, subtitle: subtitle,
                                  trailing: BranchStatusTagView(text: status.title, active: status.tagActive),
                                  id: "orders.row.\(order.id)", showsChevron: true)
            row.onTap = { [weak self] in
                guard let self else { return }
                self.router.open(.orderDetail(orderID: order.id, justRedeemed: false), from: self)
            }
            contentStack.addArrangedSubview(row)
        }
    }
}
