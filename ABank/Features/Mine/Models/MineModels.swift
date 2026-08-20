//
//  MineModels.swift
//  ABank
//

import UIKit

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
}

struct MineAssetLiability {
    let assets: Double
    let liabilities: Double
    let billNotice: String
}

struct MineMonthlyFlow {
    let expense: Double
    let income: Double
    let billSectionTitle: String
    let billNotice: String
    let hasBillBadge: Bool
}

struct MineGridItem {
    let title: String
    let systemIcon: String
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
    let profile: MineProfileInfo
    let assetStats: [MineAssetStat]
    let assetLiability: MineAssetLiability
    let monthlyFlow: MineMonthlyFlow
    let branch: MineBranchInfo
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
