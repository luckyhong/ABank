//
//  RiskAssessmentStore.swift
//  ABank
//
//  风险测评结果的本地持久化。无法解码时视为未测评，原字节保留到下一次成功保存；
//  写入失败时内存不变且不发通知。状态（有效/过期）在读取时按时钟推算。
//

import Foundation

final class RiskAssessmentStore {
    static let shared = RiskAssessmentStore()
    static let storageKey = "abank.riskAssessment.v1"
    static let didChangeNotification = Notification.Name("ABank.riskAssessmentDidChange")

    private let defaults: UserDefaults
    private let notificationCenter: NotificationCenter
    private let dates: BankingDateContext
    private let dataWriter: ((Data) throws -> Void)?
    private(set) var record: RiskAssessmentRecord?

    init(defaults: UserDefaults = .standard,
         notificationCenter: NotificationCenter = .default,
         dates: BankingDateContext = .system,
         dataWriter: ((Data) throws -> Void)? = nil) {
        self.defaults = defaults
        self.notificationCenter = notificationCenter
        self.dates = dates
        self.dataWriter = dataWriter
        if let data = defaults.data(forKey: Self.storageKey),
           let stored = try? JSONDecoder().decode(RiskAssessmentRecord.self, from: data) {
            record = stored
        }
    }

    var state: RiskAssessmentState {
        RiskAssessmentRules.state(of: record, now: dates.now, dates: dates)
    }

    @discardableResult
    func submit(answers: [Int]) throws -> RiskAssessmentRecord {
        guard let score = RiskQuestionnaire.score(answers: answers) else { throw RiskAssessmentError.incompleteAnswers }
        let updated = RiskAssessmentRecord(answers: answers, level: RiskQuestionnaire.profile(forScore: score),
                                           assessedAt: dates.now)
        do {
            let data = try JSONEncoder().encode(updated)
            if let dataWriter {
                try dataWriter(data)
            } else {
                defaults.set(data, forKey: Self.storageKey)
            }
        } catch {
            throw RiskAssessmentError.saveFailed
        }
        record = updated
        notificationCenter.post(name: Self.didChangeNotification, object: self)
        return updated
    }
}
