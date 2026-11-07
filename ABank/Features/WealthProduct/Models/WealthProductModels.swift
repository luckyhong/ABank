//
//  WealthProductModels.swift
//  ABank
//
//  理财产品模型：风险等级、分类、产品、订单与错误。仅依赖 Foundation，便于数据检查脚本编译。
//

import Foundation

nonisolated enum ProductRiskLevel: Int, CaseIterable, Comparable {
    case r1 = 1, r2, r3

    static func < (lhs: ProductRiskLevel, rhs: ProductRiskLevel) -> Bool { lhs.rawValue < rhs.rawValue }

    var title: String { ["低风险", "中低风险", "中风险"][rawValue - 1] }
    var shortTitle: String { "R\(rawValue)" }
    /// 购买该风险等级的产品所需的最低测评等级。
    var requiredProfile: RiskProfile { RiskProfile(rawValue: rawValue) ?? .c5 }
}

nonisolated enum RiskProfile: Int, Codable, CaseIterable, Comparable {
    case c1 = 1, c2, c3, c4, c5

    static func < (lhs: RiskProfile, rhs: RiskProfile) -> Bool { lhs.rawValue < rhs.rawValue }

    var title: String { ["保守型", "稳健型", "平衡型", "成长型", "进取型"][rawValue - 1] }
    var shortTitle: String { "C\(rawValue)" }
}

nonisolated enum WealthCategory: String, CaseIterable {
    case daily, steady, performance

    var title: String {
        switch self {
        case .daily: return "日日悦享"
        case .steady: return "低波稳健"
        case .performance: return "业绩优选"
        }
    }
}

nonisolated enum HoldingPeriodFilter: CaseIterable {
    case any, within7, within30, over30

    var title: String {
        switch self {
        case .any: return "不限"
        case .within7: return "7天内"
        case .within30: return "30天内"
        case .over30: return "30天以上"
        }
    }

    func matches(minHoldDays: Int) -> Bool {
        switch self {
        case .any: return true
        case .within7: return minHoldDays <= 7
        case .within30: return minHoldDays <= 30
        case .over30: return minHoldDays > 30
        }
    }
}

nonisolated struct WealthProduct: Equatable {
    let id: String
    let name: String
    let category: WealthCategory
    let risk: ProductRiskLevel
    /// 模拟年化，万分之一为单位（240 = 2.40%）。
    let rateBasisPoints: Int
    let minHoldDays: Int
    let minPurchaseInCents: Int64
    let summary: String

    var rateText: String { String(format: "%.2f%%", Double(rateBasisPoints) / 100) }
}

nonisolated struct WealthOrder: Codable, Equatable {
    let id: String
    let requestID: String
    let productID: String
    let productName: String
    let accountID: String
    let principalInCents: Int64
    let rateBasisPoints: Int
    let minHoldDays: Int
    /// 购买时间，`yyyy-MM-dd HH:mm:ss`（上海）。
    let createdAt: String
    let purchaseTransactionID: String
    var redeemedAt: String?
    var redeemedAmountInCents: Int64?
    var redeemTransactionID: String?
}

nonisolated enum WealthOrderStatus: Equatable {
    case holding(redeemable: Bool, daysUntilRedeemable: Int)
    case redeemed
}

nonisolated enum WealthError: LocalizedError, Equatable {
    case invalidRequest, productNotFound, assessmentRequired, assessmentExpired, riskLevelTooLow
    case invalidAmount, belowMinimum, aboveMaximum, insufficientBalance
    case orderNotFound, notRedeemable, alreadyRedeemed, corruptLedger, persistence

    var errorDescription: String? {
        switch self {
        case .invalidRequest: return "购买请求无效，请返回重新确认"
        case .productNotFound: return "产品不存在"
        case .assessmentRequired: return "请先完成风险测评"
        case .assessmentExpired: return "风险测评已过期，请重新测评"
        case .riskLevelTooLow: return "您的风险承受等级低于该产品风险等级"
        case .invalidAmount: return "请输入有效金额，最多保留两位小数"
        case .belowMinimum: return "低于起购金额"
        case .aboveMaximum: return "超过单笔购买上限"
        case .insufficientBalance: return "账户可用余额不足"
        case .orderNotFound: return "订单不存在"
        case .notRedeemable: return "未达最低持有期，暂不可赎回"
        case .alreadyRedeemed: return "该订单已赎回"
        case .corruptLedger: return "本地账本无法读取，请先检查账本数据"
        case .persistence: return "本地保存失败，本次未成交，请重试"
        }
    }
}
