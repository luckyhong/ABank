//
//  QuickAction.swift
//  ABank
//
//  桌面快捷操作：type 字符串到路由的映射。仅依赖 Foundation。
//

import Foundation

enum QuickAction {
    static func route(forType type: String) -> AppRoute? {
        switch type {
        case "com.abank.shortcut.scan": return .scan
        case "com.abank.shortcut.transfer": return .transfer(payerAccountID: nil)
        case "com.abank.shortcut.incomeExpense": return .incomeExpense(accountID: nil)
        case "com.abank.shortcut.assistant": return .assistant
        default: return nil
        }
    }
}
