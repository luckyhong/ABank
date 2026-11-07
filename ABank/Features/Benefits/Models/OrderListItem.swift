//
//  OrderListItem.swift
//  ABank
//
//  “我的订单”统一列表：兑换订单与充值缴费订单混排与筛选。仅依赖 Foundation，便于检查脚本编译。
//

import Foundation

nonisolated enum OrderListItem: Equatable {
    case reward(RewardOrder)
    case payment(PaymentOrder)

    var id: String {
        switch self {
        case .reward(let order): return order.id
        case .payment(let order): return order.id
        }
    }

    /// 缴费订单的创建时间解析失败时按最早处理，排在末尾。
    func createdAt(dates: BankingDateContext) -> Date {
        switch self {
        case .reward(let order): return order.createdAt
        case .payment(let order): return PaymentRules.createdDate(of: order, dates: dates) ?? .distantPast
        }
    }
}

nonisolated enum OrderListFilter: Int, CaseIterable {
    case all, pendingUse, used, expired, cancelled, payments

    var title: String {
        switch self {
        case .all: return "全部"
        case .pendingUse: return "待使用"
        case .used: return "已使用"
        case .expired: return "已失效"
        case .cancelled: return "已取消"
        case .payments: return "充值缴费"
        }
    }

    /// 状态筛选对应的兑换订单状态；“全部”“充值缴费”没有。
    var rewardStatus: OrderStatus? {
        switch self {
        case .pendingUse: return .pendingUse
        case .used: return .used
        case .expired: return .expired
        case .cancelled: return .cancelled
        case .all, .payments: return nil
        }
    }
}

nonisolated enum OrderListBuilder {
    /// `.all` 为全部兑换订单加全部缴费订单；状态筛选只含状态匹配的兑换订单；`.payments` 只含缴费订单。
    /// 按创建时间倒序，时间相同时缴费订单在前，其余保持输入顺序。
    static func items(filter: OrderListFilter, reward: [RewardOrder], payment: [PaymentOrder],
                      status: (RewardOrder) -> OrderStatus, dates: BankingDateContext) -> [OrderListItem] {
        var items: [OrderListItem] = []
        if filter == .all || filter == .payments { items += payment.map(OrderListItem.payment) }
        if filter != .payments {
            let wanted = filter.rewardStatus
            items += reward.filter { wanted == nil || status($0) == wanted }.map(OrderListItem.reward)
        }
        return items.enumerated().sorted { lhs, rhs in
            let (l, r) = (lhs.element.createdAt(dates: dates), rhs.element.createdAt(dates: dates))
            return l != r ? l > r : lhs.offset < rhs.offset
        }.map(\.element)
    }
}
