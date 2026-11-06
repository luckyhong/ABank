//
//  SecuritySettings.swift
//  ABank
//
//  安全中心本地模拟设置：转账限额、金额隐私、登录/支付演示开关与登录设备。
//  仅依赖 Foundation，便于数据检查脚本在 macOS 上编译。
//

import Foundation

nonisolated struct SecuritySettings: Codable, Equatable {
    var perTransferLimitInCents: Int64 = 5_000_000
    var dailyLimitInCents: Int64 = 20_000_000
    var hidesAmounts = false
    var faceIDLoginEnabled = true
    var gestureLoginEnabled = false
    var smallPaymentWithoutPasswordEnabled = false
    var smallPaymentQuotaInCents: Int64 = 50_000
    var removedDeviceIDs: [String] = []

    static let `default` = SecuritySettings()

    var transferLimits: TransferLimits {
        TransferLimits(perTransferInCents: perTransferLimitInCents, dailyInCents: dailyLimitInCents)
    }

    init() {}

    /// 缺失字段使用默认值，便于后续版本新增设置项。
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = SecuritySettings()
        perTransferLimitInCents = try container.decodeIfPresent(Int64.self, forKey: .perTransferLimitInCents) ?? fallback.perTransferLimitInCents
        dailyLimitInCents = try container.decodeIfPresent(Int64.self, forKey: .dailyLimitInCents) ?? fallback.dailyLimitInCents
        hidesAmounts = try container.decodeIfPresent(Bool.self, forKey: .hidesAmounts) ?? fallback.hidesAmounts
        faceIDLoginEnabled = try container.decodeIfPresent(Bool.self, forKey: .faceIDLoginEnabled) ?? fallback.faceIDLoginEnabled
        gestureLoginEnabled = try container.decodeIfPresent(Bool.self, forKey: .gestureLoginEnabled) ?? fallback.gestureLoginEnabled
        smallPaymentWithoutPasswordEnabled = try container.decodeIfPresent(Bool.self, forKey: .smallPaymentWithoutPasswordEnabled)
            ?? fallback.smallPaymentWithoutPasswordEnabled
        smallPaymentQuotaInCents = try container.decodeIfPresent(Int64.self, forKey: .smallPaymentQuotaInCents) ?? fallback.smallPaymentQuotaInCents
        removedDeviceIDs = try container.decodeIfPresent([String].self, forKey: .removedDeviceIDs) ?? fallback.removedDeviceIDs
    }
}

// MARK: - 限额规则

nonisolated enum TransferLimitError: LocalizedError, Equatable {
    case invalidAmount, perTransferOutOfRange, dailyOutOfRange, perTransferAboveDaily

    var errorDescription: String? {
        switch self {
        case .invalidAmount: return "请输入正确金额"
        case .perTransferOutOfRange: return "单笔限额需在 1 元至 50 万元之间"
        case .dailyOutOfRange: return "日累计限额需在 1 元至 100 万元之间"
        case .perTransferAboveDaily: return "单笔限额不能高于日累计限额"
        }
    }
}

nonisolated enum TransferLimitRules {
    static let perTransferRange: ClosedRange<Int64> = 100...50_000_000
    static let dailyRange: ClosedRange<Int64> = 100...100_000_000

    static func validate(perTransfer: Int64, daily: Int64) throws {
        guard perTransferRange.contains(perTransfer) else { throw TransferLimitError.perTransferOutOfRange }
        guard dailyRange.contains(daily) else { throw TransferLimitError.dailyOutOfRange }
        guard perTransfer <= daily else { throw TransferLimitError.perTransferAboveDaily }
    }

    /// 元为单位的输入转为分；最多两位小数的正数。
    static func parse(_ text: String) throws -> Int64 {
        guard let cents = TransferMoney.parse(text), cents > 0 else { throw TransferLimitError.invalidAmount }
        return cents
    }
}

// MARK: - 登录设备

nonisolated struct LoginDevice: Equatable {
    let id: String
    let name: String
    let model: String
    let system: String
    let firstLogin: Date
    let lastLogin: Date
    let city: String
    let isCurrent: Bool

    /// 演示种子：本机 + 两台其他设备，日期相对当前时间推算。
    static func seed(dates: BankingDateContext) -> [LoginDevice] {
        let now = dates.now
        func daysAgo(_ days: Int) -> Date {
            dates.calendar.date(byAdding: .day, value: -days, to: now) ?? now
        }
        return [
            LoginDevice(id: "current-iphone", name: "本机 iPhone", model: "iPhone 16 Pro", system: "iOS 18.3",
                        firstLogin: daysAgo(120), lastLogin: now, city: "北京", isCurrent: true),
            LoginDevice(id: "ipad-air", name: "iPad Air", model: "iPad Air", system: "iPadOS 17.5",
                        firstLogin: daysAgo(60), lastLogin: daysAgo(3), city: "上海", isCurrent: false),
            LoginDevice(id: "iphone-12", name: "iPhone 12", model: "iPhone 12", system: "iOS 16.7",
                        firstLogin: daysAgo(400), lastLogin: daysAgo(40), city: "广州", isCurrent: false)
        ]
    }
}
