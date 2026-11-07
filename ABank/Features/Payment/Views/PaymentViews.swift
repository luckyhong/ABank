//
//  PaymentViews.swift
//  ABank
//
//  充值缴费复用视图：订单行与时间文案。
//

import UIKit

/// `createdAt` 去掉秒，如 `2026-11-06 10:00`。
func paymentTimeText(_ order: PaymentOrder) -> String {
    String(order.createdAt.prefix(16))
}

/// 订单列表行：标题为对象快照，副标题为实付与时间，整行进入订单详情。
func paymentOrderRow(_ order: PaymentOrder, onTap: @escaping () -> Void) -> BenefitsRow {
    let row = BenefitsRow(
        title: order.kind.title + " · " + order.targetTitle,
        subtitle: "实付 \(wealthMoneyText(order.paidInCents)) 元 · \(paymentTimeText(order))",
        trailing: BranchStatusTagView(text: "已完成", active: false),
        id: "orders.payment.\(order.id)", showsChevron: true
    )
    row.onTap = onTap
    return row
}
