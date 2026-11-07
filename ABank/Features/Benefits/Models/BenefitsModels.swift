//
//  BenefitsModels.swift
//  ABank
//
//  权益订单模型：币种、流水、等级、权益、商品、卡券、订单与存储快照。仅依赖 Foundation，
//  便于数据检查脚本在 macOS 上编译。
//

import Foundation

nonisolated enum RewardCurrency: String, Codable, CaseIterable {
    case points, beans

    var title: String { self == .points ? "积分" : "小豆" }
}

nonisolated enum RewardEntryKind: String, Codable {
    case seed, checkIn, claim, redeem, refund
}

nonisolated struct RewardEntry: Codable, Equatable {
    let id: String
    let currency: RewardCurrency
    let amount: Int
    let kind: RewardEntryKind
    let title: String
    let createdAt: Date
    let orderID: String?
}

nonisolated enum CustomerLevel: Int, CaseIterable, Comparable {
    case none, one, two, three, four, five

    static func < (lhs: CustomerLevel, rhs: CustomerLevel) -> Bool { lhs.rawValue < rhs.rawValue }

    /// 累计获得积分门槛。
    var threshold: Int { [0, 2_000, 10_000, 30_000, 80_000, 200_000][rawValue] }
    var next: CustomerLevel? { CustomerLevel(rawValue: rawValue + 1) }
    var shortTitle: String { ["普通", "一星", "二星", "三星", "四星", "五星"][rawValue] }
    var title: String { self == .none ? "普通客户" : shortTitle + "客户" }
}

nonisolated enum BenefitPeriod: Equatable {
    case once, monthly
}

nonisolated enum BenefitReward: Equatable {
    case points(Int)
    case coupon(templateID: String)
}

nonisolated struct Benefit: Equatable {
    let id: String
    let title: String
    let subtitle: String
    let minLevel: CustomerLevel
    let period: BenefitPeriod
    let reward: BenefitReward
}

nonisolated struct CouponTemplate: Equatable {
    let id: String
    let title: String
    let brand: String
    let faceText: String
    let validDays: Int
    let note: String
}

nonisolated struct RewardGoods: Equatable {
    let id: String
    let templateID: String
    let currency: RewardCurrency
    let price: Int
    let monthlyLimit: Int
}

nonisolated struct Coupon: Codable, Equatable {
    let id: String
    let templateID: String
    let benefitID: String?
    var orderID: String?
    let receivedAt: Date
    var usedAt: Date?
    var voidedAt: Date?
}

nonisolated enum CouponStatus: Equatable {
    case unused, used, expired, voided

    var title: String {
        switch self {
        case .unused: return "待使用"
        case .used: return "已使用"
        case .expired: return "已过期"
        case .voided: return "已作废"
        }
    }

    var isActive: Bool { self == .unused }
}

nonisolated struct RewardOrder: Codable, Equatable {
    let id: String
    let orderNo: String
    let goodsID: String
    let title: String
    let currency: RewardCurrency
    let cost: Int
    let quantity: Int
    let createdAt: Date
    let couponID: String
    var cancelledAt: Date?
}

nonisolated enum OrderStatus: Equatable {
    case pendingUse, used, expired, cancelled

    var title: String {
        switch self {
        case .pendingUse: return "待使用"
        case .used: return "已使用"
        case .expired: return "已过期"
        case .cancelled: return "已取消"
        }
    }
}

nonisolated struct BenefitClaim: Codable, Equatable {
    let id: String
    let benefitID: String
    let createdAt: Date
    let couponID: String?
}

nonisolated enum ClaimState: Equatable {
    case available, claimedOnce, claimedThisMonth, levelTooLow(CustomerLevel)

    var title: String {
        switch self {
        case .available: return "领取"
        case .claimedOnce: return "已领取"
        case .claimedThisMonth: return "本月已领"
        case .levelTooLow(let level): return "需" + level.shortTitle
        }
    }
}

nonisolated struct BenefitsRecords: Codable, Equatable {
    var entries: [RewardEntry]
    var coupons: [Coupon]
    var orders: [RewardOrder]
    var claims: [BenefitClaim]
    /// 已签到日，格式 yyyy-MM-dd（上海）。
    var checkInDays: [String]

    static let empty = BenefitsRecords(entries: [], coupons: [], orders: [], claims: [], checkInDays: [])
}

nonisolated enum BenefitsError: LocalizedError, Equatable {
    case insufficientBalance, monthlyLimitReached, alreadyCheckedIn, alreadyClaimed
    case levelTooLow, notCancellable, notUsable, unknownItem, saveFailed

    var errorDescription: String? {
        switch self {
        case .insufficientBalance: return "余额不足"
        case .monthlyLimitReached: return "本月兑换次数已达上限"
        case .alreadyCheckedIn: return "今日已签到"
        case .alreadyClaimed: return "已领取"
        case .levelTooLow: return "客户等级不足"
        case .notCancellable: return "当前订单不可取消"
        case .notUsable: return "卡券当前不可使用"
        case .unknownItem: return "内容不存在"
        case .saveFailed: return "保存失败，请稍后重试"
        }
    }
}
