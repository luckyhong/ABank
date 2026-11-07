//
//  BenefitsCardSummary.swift
//  ABank
//
//  “我的”资产统计卡（银行卡/小豆/积分/礼券）的取值与跳转路由。仅依赖 Foundation，
//  便于数据检查脚本编译。
//

import Foundation

enum MineAssetStats {
    static func make(benefits: BenefitsStore) -> [MineAssetStat] {
        [
            MineAssetStat(value: 1, label: "银行卡", route: .myAccount),
            MineAssetStat(value: benefits.balance(.beans), label: "小豆", route: .rewardLedger(currency: .beans)),
            MineAssetStat(value: benefits.balance(.points), label: "积分", route: .rewardLedger(currency: .points)),
            MineAssetStat(value: benefits.unusedCouponCount, label: "礼券", route: .coupons)
        ]
    }
}
