//
//  FinanceLedgerModels.swift
//  ABank
//

import Foundation

// MARK: - 账本根模型

struct FinanceLedgerRecord: Codable, Equatable {
    var accounts: [LedgerAccount]
    var transactions: [LedgerTransaction]
    var loanContracts: [LoanContract]
    var assetLiabilityAnnouncement: String
    var dataTimestamp: String
}

// MARK: - 账户

struct LedgerAccount: Codable, Equatable, Identifiable {
    let id: String
    let tailNumber: String
    let currency: String
    var balance: Double
    var openingBalance: Double

    var displayName: String { "尾号\(tailNumber) (\(currency))" }
    var cardLabel: String { "借记卡\(tailNumber)" }
}

// MARK: - 流水

enum LedgerTransactionDirection: String, Codable {
    case expense
    case income
}

struct LedgerTransaction: Codable, Equatable, Identifiable {
    let id: String
    let accountId: String
    let date: String          // yyyy-MM-dd
    let time: String          // HH:mm
    var title: String
    var direction: LedgerTransactionDirection
    var amount: Double        // 正数
    var balanceAfter: Double
    var iconKey: String
}

// MARK: - 贷款合同

struct LoanContract: Codable, Equatable, Identifiable {
    let id: String
    var name: String
    var unpaidPrincipal: Double
    var contractLimit: Double
    var expiryDate: String
    var monthlyDue: Double
    var availableLimit: Double
    var isDetailExpanded: Bool
}

// MARK: - 派生快照

struct MonthlyFlowSummary {
    let expense: Double
    let income: Double
}

struct IncomeExpenseDayGroup: Equatable {
    let day: Int
    let transactions: [LedgerTransaction]
}

struct IncomeExpensePageData {
    let month: String
    let monthLabel: String
    let accountFilter: String
    let summary: MonthlyFlowSummary
    let dayGroups: [IncomeExpenseDayGroup]
}

struct MyLoanPageData {
    let monthlyDue: Double
    let totalUnpaidPrincipal: Double
    let availableLimit: Double
    let contracts: [LoanContract]
    let tip: String
}

extension FinanceLedgerRecord {
    static let defaultAccountId = "acct_8472"
    static let defaultLoanId = "loan_housing"
    static let demandDepositCategoryId = "demand_deposit"
    static let loanCategoryId = "loan"
}
