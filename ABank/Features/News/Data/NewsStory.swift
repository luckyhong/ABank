import Foundation

/// Publisher metadata only; full articles remain on the publisher's website.
nonisolated struct NewsStory: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let summary: String
    let publisher: String
    let channel: NewsChannel
    let publishedAt: Date?
    let url: URL?
    var imageURL: URL?
    let isDemo: Bool
}

nonisolated enum NewsChannel: String, Codable, CaseIterable, Sendable {
    case finance, general, life, video

    var feedURL: URL {
        let name: String
        switch self {
        case .finance: name = "finance"
        case .general: name = "scroll-news"
        case .life: name = "life"
        case .video: name = "sp"
        }
        return URL(string: "https://www.chinanews.com.cn/rss/\(name).xml")!
    }
}

nonisolated struct NewsSnapshot: Sendable {
    enum Origin: Sendable { case live, cache, demo }
    let stories: [NewsStory]
    let updatedAt: Date
    let origin: Origin
    let unavailableChannels: Int

    func filtered(category: String) -> [NewsStory] {
        switch category {
        case "热点":
            let relevant = stories.filter { $0.channel == .finance || $0.channel == .life }
            return relevant.isEmpty ? stories : relevant
        case "财经": return stories.filter { $0.channel == .finance }
        case "服务": return stories.filter { $0.channel == .life }
        case "三农": return matching(["农业", "农村", "农民", "乡村", "粮食", "县域", "农产品"])
        case "基金": return matching(["基金", "公募", "ETF", "资管"], financialOnly: true)
        case "黄金": return matching(["黄金", "金价", "贵金属", "白银"], financialOnly: true)
        case "保险": return matching(["保险", "养老金", "社保", "医保"])
        case "房产": return matching(["房产", "楼市", "住房", "房地产", "公积金", "房贷"])
        default: return stories
        }
    }

    private func matching(_ keywords: [String], financialOnly: Bool = false) -> [NewsStory] {
        stories.filter { story in (!financialOnly || story.channel == .finance) && keywords.contains { story.title.localizedCaseInsensitiveContains($0) || story.summary.localizedCaseInsensitiveContains($0) } }
    }
}

/// Daily rotation applies only to educational demo material, never to fabricated news.
nonisolated enum NewsDemoContent {
    static func snapshot(now: Date) -> NewsSnapshot {
        let topics: [(String, String, NewsChannel)] = [
            ("银行卡安全：转账前核实收款信息", "确认姓名、银行和用途，遇到催促转账的来电，应通过可信渠道自行核实。", .life),
            ("认识基金净值与投资风险", "基金净值会波动。阅读产品说明，了解费用、期限及风险等级，再作判断。", .finance),
            ("公积金常见问题：提取与贷款有何区别", "提取与贷款是不同业务，具体条件请查阅当地公积金中心的公开说明。", .life),
            ("黄金知识：价格与交易成本", "了解报价方式、买卖价差、保管及交易成本，不把短期价格变化当作收益保证。", .finance),
            ("保险知识：读懂保障责任与除外条款", "关注合同约定、等待期、免赔额与除外责任。", .finance),
            ("乡村观察：认识农产品的产销链条", "从种植、仓储、物流到销售，了解农产品如何从田间走向市场。", .general),
            ("日常记账：区分消费与本人账户互转", "本人账户之间的资金移动不等同于新增收入，可以单独归类。", .life),
            ("数字生活：保护短信验证码", "验证码用于确认本人操作，不应通过聊天、电话等方式向他人提供。", .life),
            ("住房知识：认识等额本金与等额本息", "比较不同还款方式的现金流安排，具体金额以合同及实际测算为准。", .finance),
            ("基金知识：了解定期报告", "报告能帮助理解持仓与费用变化，过往表现不代表未来收益。", .finance),
            ("三农知识：认识农业保险", "农业保险保障范围与承保条件因合同而异，投保前应查看具体条款。", .general),
            ("消费提醒：为家庭保留应急资金", "结合家庭收入、固定支出和流动性需求安排日常预算。", .life)
        ]
        let day = Int(floor((now.timeIntervalSince1970 + 8 * 3600) / 86400))
        let offset = ((day % topics.count) + topics.count) % topics.count
        let stories = (0..<topics.count).map { index -> NewsStory in
            let position = (offset + index) % topics.count
            let item = topics[position]
            return NewsStory(id: "demo-\(position)", title: item.0, summary: item.1, publisher: "学习示例", channel: item.2, publishedAt: nil, url: nil, imageURL: nil, isDemo: true)
        }
        return NewsSnapshot(stories: stories, updatedAt: now, origin: .demo, unavailableChannels: NewsChannel.allCases.count)
    }
}
