//
//  RiskAssessmentModels.swift
//  ABank
//
//  风险测评：5 题问卷（选项按风险偏好由低到高）、结果记录与有效期规则。仅依赖 Foundation。
//

import Foundation

nonisolated struct RiskQuestion: Equatable {
    let title: String
    let options: [String]
}

nonisolated enum RiskQuestionnaire {
    static let questions: [RiskQuestion] = [
        RiskQuestion(title: "您的投资经验如何？",
                     options: ["没有投资经验", "仅有存款经验", "有理财或基金投资经验", "有股票或衍生品投资经验"]),
        RiskQuestion(title: "您可以承受的最大亏损是多少？",
                     options: ["不能接受任何本金亏损", "本金亏损 5% 以内", "本金亏损 5%–20%", "本金亏损 20% 以上"]),
        RiskQuestion(title: "您计划的投资期限是？",
                     options: ["1 年以内", "1–3 年", "3–5 年", "5 年以上"]),
        RiskQuestion(title: "您的收入情况如何？",
                     options: ["收入不稳定，主要依靠储蓄", "收入较稳定，但家庭负担较重", "收入稳定，有一定积累", "收入稳定，资产充裕"]),
        RiskQuestion(title: "您的投资目的是什么？",
                     options: ["保证本金安全", "获得略高于存款的收益", "平衡收益与风险", "追求较高收益"])
    ]

    /// 每题得分 = 选项下标 + 1；答案数量不符或下标越界返回 nil。
    static func score(answers: [Int]) -> Int? {
        guard answers.count == questions.count else { return nil }
        var total = 0
        for (index, answer) in answers.enumerated() {
            guard questions[index].options.indices.contains(answer) else { return nil }
            total += answer + 1
        }
        return total
    }

    static func profile(forScore score: Int) -> RiskProfile {
        switch score {
        case ..<9: return .c1
        case 9...11: return .c2
        case 12...14: return .c3
        case 15...17: return .c4
        default: return .c5
        }
    }
}

nonisolated struct RiskAssessmentRecord: Codable, Equatable {
    let answers: [Int]
    let level: RiskProfile
    let assessedAt: Date
}

nonisolated enum RiskAssessmentState: Equatable {
    case none
    case valid(RiskProfile, expiresOn: String)
    case expired(RiskProfile)
}

nonisolated enum RiskAssessmentRules {
    static let validDays = 365

    /// 测评日（上海）0 点 + 365 天。
    static func expiresAt(_ record: RiskAssessmentRecord, dates: BankingDateContext) -> Date {
        let start = dates.calendar.startOfDay(for: record.assessedAt)
        return dates.calendar.date(byAdding: .day, value: validDays, to: start)!
    }

    static func state(of record: RiskAssessmentRecord?, now: Date, dates: BankingDateContext) -> RiskAssessmentState {
        guard let record else { return .none }
        let expires = expiresAt(record, dates: dates)
        guard now < expires else { return .expired(record.level) }
        let lastDay = dates.calendar.date(byAdding: .day, value: -1, to: expires)!
        return .valid(record.level, expiresOn: dates.string(from: lastDay))
    }
}

nonisolated enum RiskAssessmentError: LocalizedError, Equatable {
    case incompleteAnswers, saveFailed

    var errorDescription: String? {
        switch self {
        case .incompleteAnswers: return "请完成全部题目"
        case .saveFailed: return "保存失败，请稍后重试"
        }
    }
}
