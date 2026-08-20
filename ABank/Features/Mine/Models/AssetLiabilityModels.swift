//
//  AssetLiabilityModels.swift
//  ABank
//

import UIKit

enum AssetLiabilityTab: Int, CaseIterable {
    case assets
    case liabilities
}

struct AssetLiabilityPageData {
    let totalAssets: Double
    let totalLiabilities: Double
    let dataTimestamp: String
    let announcement: String
    let assetCategories: [AssetLiabilityCategory]
    let liabilityCategories: [AssetLiabilityCategory]
    let assetTips: [String]
    let liabilityTips: [String]
}

struct AssetLiabilityCategory {
    let title: String
    let totalAmount: Double?
    let items: [AssetLiabilityItem]
}

struct AssetLiabilityItem {
    let title: String
    let amount: Double
    let showsCurrencySymbol: Bool
    let subtitle: String?
    let showsMenu: Bool
}

extension Double {
    /// 纯数字金额（无货币符号），如 2,660.66
    func abankPlainAmountString() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? String(format: "%.2f", self)
    }
}
