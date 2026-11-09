//
//  AssistantEngine.swift
//  ABank
//
//  本地关键词助手：规整输入 → 敏感检查 → 意图匹配 → 功能搜索兜底。仅依赖 Foundation。
//

import Foundation

struct AssistantReply: Equatable {
    let text: String
    /// 仅已完成功能，最多 3 个。
    let features: [FeatureID]
    let isSensitiveWarning: Bool
}

enum AssistantEngine {
    static let welcomeText = "您好，我是 ABank 在线助手，可以帮您查找功能和解答常见问题。"
    static let quickQuestions = ["怎么转账", "查余额", "提前还款", "附近网点"]

    private static let sensitiveText = "为保障安全，请勿在对话中发送卡号、密码、验证码等信息。"
    private static let searchText = "为您找到以下功能："
    private static let fallbackText = "没找到相关内容，换个说法试试，或看看这些常用功能："
    private static let fallbackFeatures: [FeatureID] = [.transfer, .incomeExpense, .branchQuery]
    private static let maxCards = 3

    private struct Intent {
        let answer: String
        let triggers: [String]
        let features: [FeatureID]
    }

    /// 顺序即同分优先级。
    private static let intents: [Intent] = [
        Intent(answer: "转账支持账号和手机号，可在转账页查看记录与限额。",
               triggers: ["转账", "汇款", "打钱", "转钱"], features: [.transfer, .transferRecords, .transferLimits]),
        Intent(answer: "可以在账户和收支页查看余额与交易明细。",
               triggers: ["余额", "明细", "流水", "收支"], features: [.myAccount, .accountDetail, .incomeExpense]),
        Intent(answer: "贷款相关的还款计划、提前还款、结清证明都在“我的贷款”里。",
               triggers: ["贷款", "还贷", "提前还款", "月供", "房贷"], features: [.loan]),
        Intent(answer: "可以查询附近网点、取号或预约办理业务。",
               triggers: ["网点", "预约", "取号", "排队", "营业时间"], features: [.branchQuery, .branchQueue]),
        Intent(answer: "水电燃气缴费可在生活缴费里办理。",
               triggers: ["缴费", "水费", "电费", "燃气"], features: [.lifePayment]),
        Intent(answer: "手机话费可在手机充值里办理。",
               triggers: ["话费", "充值", "流量"], features: [.mobileRecharge]),
        Intent(answer: "理财产品可在理财页浏览，购买前需完成风险测评。",
               triggers: ["理财", "风险测评", "收益"], features: [.wealthProduct]),
        Intent(answer: "积分、小豆、卡券都在权益中心。",
               triggers: ["积分", "小豆", "卡券", "优惠券", "权益"], features: [.benefits, .pointsMall, .beans]),
        Intent(answer: "转账和网上支付权限可在交易权限里开启或关闭。",
               triggers: ["交易权限", "开通转账", "网上支付", "关闭转账"], features: [.accountPermissions]),
        Intent(answer: "登录与设备安全可在安全中心设置。",
               triggers: ["登录", "密码", "设备", "安全"], features: [.securityCenter, .loginSettings, .loginDevices]),
        Intent(answer: "扫一扫支持演示二维码，识别后可前往对应页面。",
               triggers: ["扫码", "扫一扫", "二维码", "收款码"], features: [.scan]),
        Intent(answer: "订单可在我的订单里查看。",
               triggers: ["订单", "兑换记录"], features: [.orders])
    ]

    static func reply(to input: String) -> AssistantReply? {
        let normalized = normalize(input)
        guard !normalized.isEmpty else { return nil }

        if normalized.range(of: "[0-9]{6,}", options: .regularExpression) != nil {
            return AssistantReply(text: sensitiveText, features: [], isSensitiveWarning: true)
        }

        var best: (score: Int, intent: Intent)?
        for intent in intents {
            let score = intent.triggers.filter { normalized.contains($0) }.reduce(0) { $0 + $1.count }
            if score > 0, score > (best?.score ?? 0) { best = (score, intent) }
        }
        if let best {
            return AssistantReply(text: best.intent.answer, features: available(best.intent.features), isSensitiveWarning: false)
        }

        let found = available(FeatureSearch.search(input.trimmingCharacters(in: .whitespacesAndNewlines)).map(\.id))
        if !found.isEmpty {
            return AssistantReply(text: searchText, features: found, isSensitiveWarning: false)
        }
        return AssistantReply(text: fallbackText, features: fallbackFeatures, isSensitiveWarning: false)
    }

    private static func available(_ ids: [FeatureID]) -> [FeatureID] {
        Array(ids.filter { FeatureCatalog.descriptor($0).isAvailable }.prefix(maxCards))
    }

    private static func normalize(_ input: String) -> String {
        let half = input.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? input
        let removed = CharacterSet.punctuationCharacters.union(.symbols).union(.whitespacesAndNewlines)
        return String(half.unicodeScalars.filter { !removed.contains($0) }).lowercased()
    }
}
