//
//  LoanModels.swift
//  ABank
//
//  M9b 贷款：提前还款方式、办理记录、试算结果、错误与历史（已结清）贷款目录。
//

import Foundation

enum LoanRepaymentMethod: String, Codable, CaseIterable {
    case shortenTerm
    case reduceInstallment

    var title: String {
        switch self {
        case .shortenTerm: return "缩短期限"
        case .reduceInstallment: return "减少月供"
        }
    }
}

enum LoanServiceKind: String, Codable {
    case prepayment
    case settlementCertificate

    var title: String {
        switch self {
        case .prepayment: return "提前还款"
        case .settlementCertificate: return "结清证明申请"
        }
    }
}

/// 贷款办理记录：提前还款与结清证明申请都存在账本 `loanServiceRecords`。
struct LoanServiceRecord: Codable, Equatable, Identifiable {
    let id: String
    let requestID: String
    let kind: LoanServiceKind
    let contractID: String
    let contractNumber: String
    let loanName: String
    /// yyyy-MM-dd HH:mm:ss 北京时间
    let createdAt: String
    let businessNo: String
    var amountInCents: Int64? = nil
    var method: LoanRepaymentMethod? = nil
    var accountID: String? = nil
    var transactionID: String? = nil
    var principalBefore: Int64? = nil
    var principalAfter: Int64? = nil
    var installmentBefore: Int64? = nil
    var installmentAfter: Int64? = nil
    var termsBefore: Int? = nil
    var termsAfter: Int? = nil
    /// yyyy-MM-dd
    var maturityBefore: String? = nil
    var maturityAfter: String? = nil
    var certificateNo: String? = nil
}

/// 提前还款试算结果（金额为分，到期日 yyyy-MM-dd）。
struct LoanPrepaymentPreview: Equatable {
    let amountInCents: Int64
    let balanceInCents: Int64
    let principalBefore: Int64
    let principalAfter: Int64
    let installmentBefore: Int64
    let installmentAfter: Int64
    let termsBefore: Int
    let termsAfter: Int
    let maturityBefore: String
    let maturityAfter: String
    let lastInstallmentAfter: Int64
}

enum LoanError: LocalizedError, Equatable {
    case amountInvalid
    case amountNotLessThanPrincipal
    case insufficientBalance
    case contractUnavailable
    case changed
    case corruptLedger
    case persistence
    case invalidRequest

    var errorDescription: String? {
        switch self {
        case .amountInvalid: return "提前还款金额最低 100 元，最多两位小数"
        case .amountNotLessThanPrincipal: return "提前还款金额须小于未还本金"
        case .insufficientBalance: return "账户余额不足"
        case .contractUnavailable: return "贷款不存在或已结清"
        case .changed: return "信息已变化，请重新确认"
        case .corruptLedger: return "账本数据异常，暂不能办理"
        case .persistence: return "本地保存失败，请重试"
        case .invalidRequest: return "请求无效，请重试"
        }
    }
}

enum LoanRules {
    static let minimumPrepaymentInCents: Int64 = 10_000

    /// 解析输入金额：最多两位小数且不低于 100 元。
    static func amount(_ text: String) throws -> Int64 {
        guard let cents = TransferMoney.parse(text), cents >= minimumPrepaymentInCents else {
            throw LoanError.amountInvalid
        }
        return cents
    }
}

/// 已结清的历史贷款（只读种子，不进账本、不计入任何汇总）。
struct SettledLoan: Equatable, Identifiable {
    let id: String
    let name: String
    let contractNumber: String
    let amountInCents: Int64
    let annualRatePercent: Double
    /// yyyy-MM-dd
    let startDate: String
    let endDate: String
    let settledDate: String
}

enum LoanHistoryCatalog {
    static let settledLoans: [SettledLoan] = [
        SettledLoan(id: "loan_consumer_2019", name: "个人消费贷款", contractNumber: "26135157700001288",
                    amountInCents: 5_000_000, annualRatePercent: 4.35,
                    startDate: "2019-03-12", endDate: "2022-03-11", settledDate: "2021-12-20")
    ]

    static func loan(id: String) -> SettledLoan? {
        settledLoans.first { $0.id == id }
    }
}
