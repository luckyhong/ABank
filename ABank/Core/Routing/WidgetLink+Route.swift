//
//  WidgetLink+Route.swift
//  ABank
//
//  Widget 链接到 App 路由的映射（仅 App 使用，依赖 AppRoute）。
//

import Foundation

extension WidgetLink.Target {
    var route: AppRoute {
        switch self {
        case .account: return .myAccount
        case .scan: return .scan
        case .transfer: return .transfer(payerAccountID: nil)
        case .incomeExpense: return .incomeExpense(accountID: nil)
        }
    }
}

extension WidgetLink {
    static func route(for url: URL) -> AppRoute? {
        target(for: url)?.route
    }
}
