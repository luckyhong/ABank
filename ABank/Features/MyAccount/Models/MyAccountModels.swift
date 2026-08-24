//
//  MyAccountModels.swift
//  ABank
//

import Foundation

struct MyAccountPageData {
    let debitCards: [MyAccountDebitCard]
    let creditAdImageName: String
    let creditAdTitle: String
}

struct MyAccountDebitCard {
    let accountClass: String
    let maskedNumber: String
    let fullNumber: String
    let availableBalance: Double
    let actions: [MyAccountDebitAction]
}

struct MyAccountDebitAction {
    let title: String
    let badge: String?
}

enum MyAccountAction: String {
    case viewShare = "查看/分享"
    case setAlias = "设置别名"
    case details = "详情"
    case queryDetail = "查询明细"
    case transfer = "我要转账"
    case flexibleWealth = "活钱理财"
    case openElectronic = "开通电子账户"
    case creditAd = "信用卡广告"
    case more = "更多"
}

// MARK: - 明细查询

enum AccountDetailQuickRange: Equatable {
    case week
    case month
    case threeMonths
    case custom
}

enum AccountDetailCurrency: Equatable, CaseIterable {
    case cnyLocal
    case foreign

    var title: String {
        switch self {
        case .cnyLocal: return "人民币 | 本币"
        case .foreign: return "外币"
        }
    }
}

struct AccountDetailQueryFilter: Equatable {
    var quickRange: AccountDetailQuickRange
    var startDate: String
    var endDate: String
    var currency: AccountDetailCurrency
    var advancedFilter: IncomeExpenseAdvancedFilter

    static func `default`(referenceDate: Date = AccountDetailQueryFilter.referenceDate) -> AccountDetailQueryFilter {
        var filter = AccountDetailQueryFilter(
            quickRange: .week,
            startDate: "",
            endDate: "",
            currency: .cnyLocal,
            advancedFilter: .empty
        )
        filter.applyQuickRange(.week, referenceDate: referenceDate)
        return filter
    }

    /// 与设计稿时间对齐，保证「近一周」能覆盖示例流水
    static var referenceDate: Date {
        date(from: "2026-08-24") ?? Date()
    }

    mutating func applyQuickRange(_ range: AccountDetailQuickRange, referenceDate: Date = referenceDate) {
        quickRange = range
        let calendar = Calendar.current
        let end = referenceDate
        let start: Date
        switch range {
        case .week:
            start = calendar.date(byAdding: .day, value: -7, to: end) ?? end
        case .month:
            start = calendar.date(byAdding: .month, value: -1, to: end) ?? end
        case .threeMonths:
            start = calendar.date(byAdding: .month, value: -3, to: end) ?? end
        case .custom:
            return
        }
        startDate = Self.string(from: start)
        endDate = Self.string(from: end)
    }

    mutating func applyCustom(start: String, end: String) {
        quickRange = .custom
        startDate = start
        endDate = end
    }

    var isAdvancedActive: Bool { advancedFilter.isActive }

    static func string(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func date(from string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }
}

struct AccountDetailQueryPageData {
    let maskedNumber: String
    let currencyTitle: String
    let transactions: [LedgerTransaction]
}

// MARK: - 借记卡详情

struct DebitCardDetailInfoItem: Equatable {
    let title: String
    let value: String
}

struct DebitCardDetailPageData {
    let accountClass: String
    let maskedNumber: String
    let fullNumber: String
    let infoItems: [DebitCardDetailInfoItem]
    let actions: [String]
    let currencyTitle: String
    let availableBalance: Double
    let accountBalance: Double
    let cashRemittanceMark: String
    let interestRateText: String
    let openDateText: String
}
