//
//  AccountSettingsModels.swift
//  ABank
//
//  借记卡别名、模拟交易权限与户名脱敏规则。仅依赖 Foundation，便于数据检查脚本编译。
//

import Foundation

/// 模拟交易权限：关闭后在确认前与提交时拦截对应业务。
struct AccountPermissions: Codable, Equatable {
    /// 手机银行转账
    var mobileTransfer: Bool
    /// 网上支付（手机充值、生活缴费）
    var onlinePayment: Bool

    static let allEnabled = AccountPermissions(mobileTransfer: true, onlinePayment: true)
}

nonisolated enum AccountSettingsError: LocalizedError, Equatable {
    case aliasTooLong, aliasInvalidCharacter, accountNotFound, persistence

    var errorDescription: String? {
        switch self {
        case .aliasTooLong: return "别名最多 \(AccountAliasRules.maxLength) 个字"
        case .aliasInvalidCharacter: return "别名不能包含换行"
        case .accountNotFound: return "账户不存在或暂不可用"
        case .persistence: return "本地保存失败，请重试"
        }
    }
}

nonisolated enum AccountAliasRules {
    static let maxLength = 10

    /// 返回规范化后的别名；空白返回 nil（表示清除）。
    static func normalized(_ raw: String) throws -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard !trimmed.contains(where: \.isNewline) else { throw AccountSettingsError.aliasInvalidCharacter }
        guard trimmed.count <= maxLength else { throw AccountSettingsError.aliasTooLong }
        return trimmed
    }
}

nonisolated enum AccountHolderName {
    /// 保留首尾字，中间每字一个 *；两字为“张*”，一字原样。
    static func masked(_ name: String) -> String {
        let chars = Array(name)
        switch chars.count {
        case 0, 1: return name
        case 2: return String(chars[0]) + "*"
        default: return String(chars[0]) + String(repeating: "*", count: chars.count - 2) + String(chars[chars.count - 1])
        }
    }
}
