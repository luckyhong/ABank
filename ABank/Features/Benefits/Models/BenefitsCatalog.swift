//
//  BenefitsCatalog.swift
//  ABank
//
//  静态目录：卡券模板、可领取权益、可兑换商品与种子流水。品牌均为虚构。
//

import Foundation

nonisolated enum BenefitsCatalog {
    private static func template(_ id: String, _ title: String, _ brand: String, _ face: String,
                                 days: Int = 30, note: String = "到店或线上出示券码即可使用，每次限用一张，不可叠加。") -> CouponTemplate {
        CouponTemplate(id: id, title: title, brand: brand, faceText: face, validDays: days, note: note)
    }

    static let templates: [CouponTemplate] = [
        // 权益发放
        template("coffee10", "咖啡10元券", "豆香咖啡", "10元"),
        template("takeout15", "外卖15元红包", "悦享外卖", "15元", days: 15),
        template("movie20", "电影20元券", "星幕影城", "20元"),
        template("travel30", "出行30元券", "优行出行", "30元"),
        // 积分商品
        template("coffee30", "咖啡30元券", "豆香咖啡", "30元"),
        template("phone10", "话费10元充值券", "通联话费", "10元"),
        template("cinema40", "观影40元券", "星幕影城", "40元"),
        template("ride20", "出行20元券", "优行出行", "20元"),
        template("market50", "超市50元券", "鲜选超市", "50元"),
        template("book30", "书店30元券", "墨香书店", "30元"),
        // 小豆商品
        template("phone5", "话费5元充值券", "通联话费", "5元"),
        template("coffeeBogo", "咖啡买一赠一券", "豆香咖啡", "买一赠一"),
        template("videoMonth", "视频月卡立减券", "云映视频", "立减10元"),
        template("carWash", "洗车券", "净驰洗车", "单次洗车"),
        template("bus5", "公交5元乘车券", "城市通", "5元"),
        template("bookstore10", "书店10元券", "墨香书店", "10元")
    ]

    static let benefits: [Benefit] = [
        Benefit(id: "welcomeGift", title: "新客礼", subtitle: "首次领取送 500 积分",
                minLevel: .none, period: .once, reward: .points(500)),
        Benefit(id: "takeoutPack", title: "外卖红包", subtitle: "领取外卖 15 元红包",
                minLevel: .none, period: .once, reward: .coupon(templateID: "takeout15")),
        Benefit(id: "monthlyPoints", title: "月度积分礼", subtitle: "每月领取 200 积分",
                minLevel: .one, period: .monthly, reward: .points(200)),
        Benefit(id: "coffeeMonthly", title: "咖啡月礼", subtitle: "每月领取咖啡 10 元券",
                minLevel: .one, period: .monthly, reward: .coupon(templateID: "coffee10")),
        Benefit(id: "star2Points", title: "二星月度加成", subtitle: "每月领取 500 积分",
                minLevel: .two, period: .monthly, reward: .points(500)),
        Benefit(id: "movieMonthly", title: "观影月礼", subtitle: "每月领取电影 20 元券",
                minLevel: .two, period: .monthly, reward: .coupon(templateID: "movie20")),
        Benefit(id: "star3Points", title: "三星月度加成", subtitle: "每月领取 1,000 积分",
                minLevel: .three, period: .monthly, reward: .points(1_000)),
        Benefit(id: "travelMonthly", title: "贵宾出行礼", subtitle: "每月领取出行 30 元券",
                minLevel: .three, period: .monthly, reward: .coupon(templateID: "travel30"))
    ]

    private static func goods(_ templateID: String, _ currency: RewardCurrency, _ price: Int, _ limit: Int) -> RewardGoods {
        RewardGoods(id: "g." + templateID, templateID: templateID, currency: currency, price: price, monthlyLimit: limit)
    }

    static let goods: [RewardGoods] = [
        goods("coffee30", .points, 3_000, 3), goods("phone10", .points, 1_000, 3),
        goods("cinema40", .points, 4_000, 2), goods("ride20", .points, 2_000, 3),
        goods("market50", .points, 5_000, 2), goods("book30", .points, 2_500, 2),
        goods("phone5", .beans, 100, 3), goods("coffeeBogo", .beans, 150, 2),
        goods("videoMonth", .beans, 200, 2), goods("carWash", .beans, 120, 2),
        goods("bus5", .beans, 50, 3), goods("bookstore10", .beans, 80, 2)
    ]

    static func template(id: String) -> CouponTemplate? { templates.first { $0.id == id } }
    static func benefit(id: String) -> Benefit? { benefits.first { $0.id == id } }
    static func goods(id: String) -> RewardGoods? { goods.first { $0.id == id } }
    static func goods(in currency: RewardCurrency) -> [RewardGoods] { goods.filter { $0.currency == currency } }

    // MARK: - 种子流水

    private static func seed(_ index: Int, _ currency: RewardCurrency, _ day: String, _ title: String, _ amount: Int) -> RewardEntry {
        let date = BankingDateContext.system.date(from: day + " 10:00", format: "yyyy-MM-dd HH:mm")!
        return RewardEntry(id: "seed.\(currency.rawValue).\(index)", currency: currency, amount: amount,
                           kind: .seed, title: title, createdAt: date, orderID: nil)
    }

    /// 固定的历史流水：积分余额 12,860（累计获得 14,360），小豆余额 260。
    static let seedEntries: [RewardEntry] = [
        seed(1, .points, "2026-02-10", "新户开通礼", 3_000),
        seed(2, .points, "2026-04-05", "月度活跃奖励", 2_500),
        seed(3, .points, "2026-05-20", "消费积分", 1_860),
        seed(4, .points, "2026-07-12", "理财达标奖励", 4_000),
        seed(5, .points, "2026-08-30", "代发工资奖励", 3_000),
        seed(6, .points, "2026-09-18", "兑换咖啡券", -1_500),
        seed(1, .beans, "2026-06-01", "新手礼", 100),
        seed(2, .beans, "2026-08-15", "活动奖励", 80),
        seed(3, .beans, "2026-10-01", "国庆签到礼", 120),
        seed(4, .beans, "2026-10-10", "兑换公交券", -40)
    ]
}
