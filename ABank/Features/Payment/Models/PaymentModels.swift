//
//  PaymentModels.swift
//  ABank
//
//  充值缴费模型：类型、户号、账单、订单与错误。仅依赖 Foundation，便于数据检查脚本在 macOS 上编译。
//

import Foundation

nonisolated enum PaymentKind: String, Codable, CaseIterable {
    case mobile, water, electric, gas

    var title: String {
        switch self {
        case .mobile: return "手机充值"
        case .water: return "水费"
        case .electric: return "电费"
        case .gas: return "燃气费"
        }
    }

    var isUtility: Bool { self != .mobile }

    var iconKey: String {
        switch self {
        case .mobile: return "iphone"
        case .water: return "drop.fill"
        case .electric: return "bolt.fill"
        case .gas: return "flame.fill"
        }
    }

    /// 账本流水类别。
    var categoryId: String { isUtility ? "life_payment" : "mobile_recharge" }
    var transactionType: String { isUtility ? "生活缴费" : "手机充值" }
}

nonisolated enum PhoneOperator: String {
    case mobile, unicom, telecom, other

    var title: String {
        switch self {
        case .mobile: return "中国移动"
        case .unicom: return "中国联通"
        case .telecom: return "中国电信"
        case .other: return "其他运营商"
        }
    }
}

nonisolated struct BillAccount: Equatable {
    let id: String
    let kind: PaymentKind
    let name: String
    let accountNo: String
    let address: String
    let provider: String
}

nonisolated struct UtilityBill: Equatable {
    let account: BillAccount
    /// 账期，`yyyy-MM`（上海自然月）。
    let period: String
    /// 到期日，`yyyy-MM-dd`（账期最后一天）。
    let dueDate: String
    let amountInCents: Int64
    let isPaid: Bool
}

nonisolated struct PaymentOrder: Codable, Equatable {
    let id: String
    let orderNo: String
    let requestID: String
    let kind: PaymentKind
    /// 规范化手机号或户号 ID。
    let targetID: String
    /// 创建时快照，如“手机号 152****8684”“水费 · 家庭住宅”。
    let targetTitle: String
    /// 缴费账期；手机充值为空。
    let period: String?
    /// 面额或账单额（分）。
    let faceInCents: Int64
    let couponID: String?
    let couponDiscountInCents: Int64
    let paidInCents: Int64
    let accountID: String
    /// `yyyy-MM-dd HH:mm:ss`，上海。
    let createdAt: String
    let transactionID: String
}

nonisolated enum PaymentError: LocalizedError, Equatable {
    case invalidRequest, invalidPhone, invalidDenomination, billNotFound, alreadyPaid
    case couponUnavailable, insufficientBalance, orderNotFound, corruptLedger, persistence

    var errorDescription: String? {
        switch self {
        case .invalidRequest: return "请求无效"
        case .invalidPhone: return "请输入正确的 11 位手机号"
        case .invalidDenomination: return "请选择有效面额"
        case .billNotFound: return "账单不存在"
        case .alreadyPaid: return "本期账单已缴清"
        case .couponUnavailable: return "话费券不可用"
        case .insufficientBalance: return "账户可用余额不足"
        case .orderNotFound: return "订单不存在"
        case .corruptLedger: return "本地账本无法读取，请先检查账本数据"
        case .persistence: return "本地保存失败，本次未成交，请重试"
        }
    }
}
