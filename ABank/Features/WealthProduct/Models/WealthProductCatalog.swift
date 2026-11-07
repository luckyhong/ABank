//
//  WealthProductCatalog.swift
//  ABank
//
//  静态产品目录。名称取自理财 Tab 的模拟数据，收益与期限均为演示值。
//

import Foundation

nonisolated enum WealthProductCatalog {
    private static func product(_ id: String, _ name: String, _ category: WealthCategory, _ risk: ProductRiskLevel,
                                bps: Int, hold: Int, minYuan: Int64, _ summary: String) -> WealthProduct {
        WealthProduct(id: id, name: name, category: category, risk: risk, rateBasisPoints: bps,
                      minHoldDays: hold, minPurchaseInCents: minYuan * 100, summary: summary)
    }

    static let products: [WealthProduct] = [
        product("w.shishifu", "农银时时付（现金管理类）", .daily, .r1, bps: 90, hold: 1, minYuan: 1,
                "现金管理类产品，适合放置随时可能动用的资金。"),
        product("w.tiantianli2", "农银匠心·天天利理财产品2号", .daily, .r2, bps: 240, hold: 1, minYuan: 1,
                "持有 1 天即可赎回，适合短期闲置资金。"),
        product("w.piaoxi", "农银安心·天天利理财产品（票息优选）", .steady, .r2, bps: 190, hold: 1, minYuan: 1,
                "以票息资产为主，净值波动较小。"),
        product("w.wenjian7", "农银安心·7天持有稳健", .steady, .r1, bps: 170, hold: 7, minYuan: 100,
                "最短持有 7 天，收益相对平稳。"),
        product("w.wenjian30", "农银安心·30天持有（纯债）", .steady, .r2, bps: 220, hold: 30, minYuan: 100,
                "投资高等级债券，持有满 30 天可赎回。"),
        product("w.lingdong90", "农银匠心·灵动90天理财产品（固收增强）", .performance, .r2, bps: 265, hold: 90, minYuan: 1_000,
                "固收为主并适度增强，最短持有 90 天。"),
        product("w.lingdong180", "农银匠心·灵动180天理财产品（量化多元增强）", .performance, .r2, bps: 296, hold: 180, minYuan: 1,
                "量化多元策略增强，最短持有 180 天。"),
        product("w.chengzhang", "农银匠心·成长优选180天（权益增强）", .performance, .r3, bps: 360, hold: 180, minYuan: 1_000,
                "配置少量权益资产追求更高收益，风险相对更高。")
    ]

    static func product(id: String) -> WealthProduct? { products.first { $0.id == id } }

    static func filtered(category: WealthCategory?, risk: ProductRiskLevel?, period: HoldingPeriodFilter) -> [WealthProduct] {
        products.filter { product in
            (category == nil || product.category == category)
                && (risk == nil || product.risk == risk)
                && period.matches(minHoldDays: product.minHoldDays)
        }
    }
}
