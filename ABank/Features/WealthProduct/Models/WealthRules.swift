//
//  WealthRules.swift
//  ABank
//
//  收益、持有天数、可赎回判断。全部为纯函数，时间来自注入的 BankingDateContext（Asia/Shanghai）。
//

import Foundation

nonisolated enum WealthRules {
    static let maxPurchaseInCents: Int64 = 100_000_000
    static let maxAccrualDays = 3650

    private static func day(of createdAt: String, dates: BankingDateContext) -> Date? {
        dates.date(from: String(createdAt.prefix(10)))
    }

    /// 购买日到今天的上海自然日差；购买当日为 0，不为负，封顶 `maxAccrualDays`。
    static func holdingDays(since createdAt: String, now: Date, dates: BankingDateContext) -> Int {
        guard let start = day(of: createdAt, dates: dates) else { return 0 }
        let today = dates.calendar.startOfDay(for: now)
        let days = dates.calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return min(max(days, 0), maxAccrualDays)
    }

    /// 累计收益（分）= 本金 × 年化(万分比) × 天数 / (10_000 × 365)，整数向下取整。
    static func accruedInterestInCents(principal: Int64, rateBasisPoints: Int, days: Int) -> Int64 {
        guard principal > 0, rateBasisPoints > 0, days > 0 else { return 0 }
        let step = principal.multipliedReportingOverflow(by: Int64(rateBasisPoints))
        guard !step.overflow else { return .max }
        let total = step.partialValue.multipliedReportingOverflow(by: Int64(days))
        guard !total.overflow else { return .max }
        return total.partialValue / (10_000 * 365)
    }

    static func holdingValueInCents(of order: WealthOrder, now: Date, dates: BankingDateContext) -> Int64 {
        guard order.redeemedAt == nil else { return 0 }
        let days = holdingDays(since: order.createdAt, now: now, dates: dates)
        return order.principalInCents
            + accruedInterestInCents(principal: order.principalInCents, rateBasisPoints: order.rateBasisPoints, days: days)
    }

    /// 可赎回日（`yyyy-MM-dd`）：购买日 + 最低持有天数。
    static func redeemableDay(of order: WealthOrder, dates: BankingDateContext) -> String {
        guard let start = day(of: order.createdAt, dates: dates),
              let date = dates.calendar.date(byAdding: .day, value: order.minHoldDays, to: start) else { return "" }
        return dates.string(from: date)
    }

    static func status(of order: WealthOrder, now: Date, dates: BankingDateContext) -> WealthOrderStatus {
        guard order.redeemedAt == nil else { return .redeemed }
        let days = holdingDays(since: order.createdAt, now: now, dates: dates)
        return .holding(redeemable: days >= order.minHoldDays, daysUntilRedeemable: max(0, order.minHoldDays - days))
    }

    static func canBuy(_ product: WealthProduct, with profile: RiskProfile) -> Bool {
        profile >= product.risk.requiredProfile
    }
}
