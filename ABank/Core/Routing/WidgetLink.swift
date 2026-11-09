//
//  WidgetLink.swift
//  ABank
//
//  Widget 点击链接：仅识别 abank://widget/<name>，无参数，只导航到已完成页面。
//  App 与 Widget 扩展共用本文件，只依赖 Foundation。
//

import Foundation

enum WidgetLink {
    enum Target: String, CaseIterable {
        case account, scan, transfer, incomeExpense

        var route: AppRoute {
            switch self {
            case .account: return .myAccount
            case .scan: return .scan
            case .transfer: return .transfer(payerAccountID: nil)
            case .incomeExpense: return .incomeExpense(accountID: nil)
            }
        }
    }

    private static let scheme = "abank"
    private static let host = "widget"

    static func url(for target: Target) -> URL {
        URL(string: "\(scheme)://\(host)/\(target.rawValue)")!
    }

    /// scheme、host、路径均区分大小写；带 query、fragment 或多段路径一律返回 nil。
    static func route(for url: URL) -> AppRoute? {
        guard let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
              parts.scheme == scheme, parts.host == host,
              parts.query == nil, parts.fragment == nil,
              parts.path.hasPrefix("/"),
              let target = Target(rawValue: String(parts.path.dropFirst())) else { return nil }
        return target.route
    }
}
