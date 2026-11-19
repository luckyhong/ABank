//
//  MineModels.swift
//  ABank
//

import Foundation

struct MineProfileInfo {
    let displayName: String
    let lastLoginDevice: String
    let lastLoginTime: String
    let vipLevel: String
    let benefitsTitle: String
}

struct MineAssetStat {
    let value: Int
    let label: String
    let route: AppRoute?
}

struct MineAssetLiability {
    let assets: Double
    let liabilities: Double
    let billNotice: String
}

struct MineMonthlyFlow {
    let expense: Double
    let income: Double
    let title: String
}

struct MonthlyLedgerStatement {
    let month: String
    let monthTitle: String
    let closedOn: String
    let hasTransactions: Bool

    var notice: String { hasTransactions ? "您的\(monthTitle)账单已出" : "\(monthTitle)暂无收支记录" }
    var messageID: String { "bill_" + month }
    var route: AppRoute { .monthlyStatement(month: month) }
}

struct MineGridItem {
    let title: String
    var imageName: String? = nil
    let systemIcon: String
    var featureID: FeatureID? = nil
}

struct MineBranchInfo {
    let name: String
    let distance: String
    let services: [MineGridItem]
}

struct MineCustomerManager {
    let name: String
    let role: String
    let branch: String
}

struct MinePageData {
    let securityItems: [MineGridItem]
    let customerManager: MineCustomerManager
}

extension Double {
    func abankCurrencyString(hidden: Bool = false) -> String {
        if hidden { return "¥ ****" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let value = formatter.string(from: NSNumber(value: self)) ?? String(format: "%.2f", self)
        return "¥ \(value)"
    }
}
