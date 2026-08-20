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
    let time: String          // HH:mm 或 HH:mm:ss
    var title: String
    var direction: LedgerTransactionDirection
    var amount: Double        // 正数
    var balanceAfter: Double
    var iconKey: String
    /// 业务分类，对应筛选面板标签 id
    var categoryId: String
    /// 是否手工记账
    var isManual: Bool
    /// 是否计入收支汇总
    var includeInFlow: Bool
    /// 对方户名
    var counterpartyName: String
    /// 对方账户（可脱敏）
    var counterpartyAccount: String
    /// 交易摘要
    var summary: String
    /// 交易附言
    var postscript: String
    /// 交易卡号（可脱敏）
    var cardNumber: String
    /// 交易类型展示文案，如「转账」
    var transactionType: String
    /// 归属账本 id，空表示未选择
    var ledgerId: String?
    /// 用户备注
    var note: String

    init(
        id: String,
        accountId: String,
        date: String,
        time: String,
        title: String,
        direction: LedgerTransactionDirection,
        amount: Double,
        balanceAfter: Double,
        iconKey: String,
        categoryId: String,
        isManual: Bool = false,
        includeInFlow: Bool = true,
        counterpartyName: String = "",
        counterpartyAccount: String = "",
        summary: String? = nil,
        postscript: String = "",
        cardNumber: String = "",
        transactionType: String = "转账",
        ledgerId: String? = nil,
        note: String = ""
    ) {
        self.id = id
        self.accountId = accountId
        self.date = date
        self.time = time
        self.title = title
        self.direction = direction
        self.amount = amount
        self.balanceAfter = balanceAfter
        self.iconKey = iconKey
        self.categoryId = categoryId
        self.isManual = isManual
        self.includeInFlow = includeInFlow
        self.counterpartyName = counterpartyName
        self.counterpartyAccount = counterpartyAccount
        self.summary = summary ?? title
        self.postscript = postscript
        self.cardNumber = cardNumber
        self.transactionType = transactionType
        self.ledgerId = ledgerId
        self.note = note
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        accountId = try container.decode(String.self, forKey: .accountId)
        date = try container.decode(String.self, forKey: .date)
        time = try container.decode(String.self, forKey: .time)
        title = try container.decode(String.self, forKey: .title)
        direction = try container.decode(LedgerTransactionDirection.self, forKey: .direction)
        amount = try container.decode(Double.self, forKey: .amount)
        balanceAfter = try container.decode(Double.self, forKey: .balanceAfter)
        iconKey = try container.decode(String.self, forKey: .iconKey)
        categoryId = try container.decodeIfPresent(String.self, forKey: .categoryId) ?? "other_expense"
        isManual = try container.decodeIfPresent(Bool.self, forKey: .isManual) ?? false
        includeInFlow = try container.decodeIfPresent(Bool.self, forKey: .includeInFlow) ?? true
        counterpartyName = try container.decodeIfPresent(String.self, forKey: .counterpartyName) ?? ""
        counterpartyAccount = try container.decodeIfPresent(String.self, forKey: .counterpartyAccount) ?? ""
        summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? title
        postscript = try container.decodeIfPresent(String.self, forKey: .postscript) ?? ""
        cardNumber = try container.decodeIfPresent(String.self, forKey: .cardNumber) ?? ""
        transactionType = try container.decodeIfPresent(String.self, forKey: .transactionType) ?? "转账"
        ledgerId = try container.decodeIfPresent(String.self, forKey: .ledgerId)
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
    }

    var datetimeText: String {
        if time.count >= 8 {
            return "\(date) \(time)"
        }
        return "\(date) \(time):00"
    }

    var categoryTitle: String {
        IncomeExpenseFilterCatalog.title(for: categoryId) ?? categoryId
    }

    var signedAmountText: String {
        let sign = direction == .income ? "+" : "-"
        return "\(sign)\(amount.abankPlainAmountString())"
    }
}

struct LedgerBookOption: Equatable, Identifiable {
    let id: String
    let title: String
}

enum LedgerBookCatalog {
    static let options: [LedgerBookOption] = [
        .init(id: "daily", title: "日常账本"),
        .init(id: "family", title: "家庭账本"),
        .init(id: "business", title: "生意账本")
    ]

    static func title(for id: String?) -> String? {
        guard let id else { return nil }
        return options.first(where: { $0.id == id })?.title
    }
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
    /// 合同合约号
    var contractNumber: String
    /// 合同签订日期 yyyy-MM-dd
    var signingDate: String
    /// 贷款发放日展示文案
    var disbursementDateText: String
    /// 贷款金额
    var loanAmount: Double
    /// 贷款年化利率，如 3.2
    var annualRatePercent: Double
    /// 利率定价方式
    var pricingMethod: String
    /// 利率定价基准
    var pricingBenchmark: String
    /// 利率浮动幅度
    var floatingRange: String
    /// 重定价周期
    var repricingCycle: String
    /// 重定价日
    var repricingDatesText: String
    /// 贷款到期日展示文案
    var maturityDateText: String
    /// 贷款状态
    var statusText: String

    var usedLimit: Double {
        max(0, contractLimit - availableLimit)
    }

    init(
        id: String,
        name: String,
        unpaidPrincipal: Double,
        contractLimit: Double,
        expiryDate: String,
        monthlyDue: Double,
        availableLimit: Double,
        isDetailExpanded: Bool,
        contractNumber: String = "",
        signingDate: String = "",
        disbursementDateText: String = "",
        loanAmount: Double? = nil,
        annualRatePercent: Double = 0,
        pricingMethod: String = "",
        pricingBenchmark: String = "",
        floatingRange: String = "",
        repricingCycle: String = "",
        repricingDatesText: String = "",
        maturityDateText: String = "",
        statusText: String = "正常"
    ) {
        self.id = id
        self.name = name
        self.unpaidPrincipal = unpaidPrincipal
        self.contractLimit = contractLimit
        self.expiryDate = expiryDate
        self.monthlyDue = monthlyDue
        self.availableLimit = availableLimit
        self.isDetailExpanded = isDetailExpanded
        self.contractNumber = contractNumber
        self.signingDate = signingDate
        self.disbursementDateText = disbursementDateText
        self.loanAmount = loanAmount ?? contractLimit
        self.annualRatePercent = annualRatePercent
        self.pricingMethod = pricingMethod
        self.pricingBenchmark = pricingBenchmark
        self.floatingRange = floatingRange
        self.repricingCycle = repricingCycle
        self.repricingDatesText = repricingDatesText
        self.maturityDateText = maturityDateText
        self.statusText = statusText
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        unpaidPrincipal = try container.decode(Double.self, forKey: .unpaidPrincipal)
        contractLimit = try container.decode(Double.self, forKey: .contractLimit)
        expiryDate = try container.decode(String.self, forKey: .expiryDate)
        monthlyDue = try container.decode(Double.self, forKey: .monthlyDue)
        availableLimit = try container.decode(Double.self, forKey: .availableLimit)
        isDetailExpanded = try container.decodeIfPresent(Bool.self, forKey: .isDetailExpanded) ?? false
        contractNumber = try container.decodeIfPresent(String.self, forKey: .contractNumber) ?? ""
        signingDate = try container.decodeIfPresent(String.self, forKey: .signingDate) ?? ""
        disbursementDateText = try container.decodeIfPresent(String.self, forKey: .disbursementDateText) ?? ""
        loanAmount = try container.decodeIfPresent(Double.self, forKey: .loanAmount) ?? contractLimit
        annualRatePercent = try container.decodeIfPresent(Double.self, forKey: .annualRatePercent) ?? 0
        pricingMethod = try container.decodeIfPresent(String.self, forKey: .pricingMethod) ?? ""
        pricingBenchmark = try container.decodeIfPresent(String.self, forKey: .pricingBenchmark) ?? ""
        floatingRange = try container.decodeIfPresent(String.self, forKey: .floatingRange) ?? ""
        repricingCycle = try container.decodeIfPresent(String.self, forKey: .repricingCycle) ?? ""
        repricingDatesText = try container.decodeIfPresent(String.self, forKey: .repricingDatesText) ?? ""
        maturityDateText = try container.decodeIfPresent(String.self, forKey: .maturityDateText) ?? ""
        statusText = try container.decodeIfPresent(String.self, forKey: .statusText) ?? "正常"
    }
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

// MARK: - 收支筛选

enum IncomeExpenseDateMode: Equatable {
    case month(String)                    // yyyy-MM
    case custom(start: String, end: String) // yyyy-MM-dd
}

enum IncomeExpenseAccountFilter: Equatable {
    case all
    case excludeManual
    case debitCard(id: String)
    case manual

    var displayTitle: String {
        switch self {
        case .all: return "全部账户"
        case .excludeManual: return "不含手工记账"
        case .debitCard: return "借记卡"
        case .manual: return "手工记账"
        }
    }
}

struct IncomeExpenseCategoryOption: Equatable {
    let id: String
    let title: String
    let isAll: Bool
}

struct IncomeExpenseCategoryGroup: Equatable {
    let title: String
    let options: [IncomeExpenseCategoryOption]
}

struct IncomeExpenseAdvancedFilter: Equatable {
    var minAmount: Double?
    var maxAmount: Double?
    /// 各组已选分类 id；空集合表示不限该组
    var selectedCategoryIds: Set<String>

    static let empty = IncomeExpenseAdvancedFilter(
        minAmount: nil,
        maxAmount: nil,
        selectedCategoryIds: []
    )

    var isActive: Bool {
        minAmount != nil || maxAmount != nil || !selectedCategoryIds.isEmpty
    }
}

enum IncomeExpenseFilterCatalog {
    static let incomeGroup = IncomeExpenseCategoryGroup(
        title: "收入",
        options: [
            .init(id: "income_all", title: "全部收入", isAll: true),
            .init(id: "salary", title: "工资福利", isAll: false),
            .init(id: "transfer_in", title: "他人转入", isAll: false),
            .init(id: "third_party_in", title: "三方转入", isAll: false),
            .init(id: "cash_deposit", title: "现金存入", isAll: false)
        ]
    )

    static let expenseGroup = IncomeExpenseCategoryGroup(
        title: "支出",
        options: [
            .init(id: "expense_all", title: "全部支出", isAll: true),
            .init(id: "transfer_out", title: "转账给他人", isAll: false),
            .init(id: "third_party_out", title: "三方转出", isAll: false),
            .init(id: "cash_withdraw", title: "现金取出", isAll: false),
            .init(id: "other_expense", title: "其他支出", isAll: false)
        ]
    )

    static let transferGroup = IncomeExpenseCategoryGroup(
        title: "本人资金往来",
        options: [
            .init(id: "self_all", title: "全部往来", isAll: true),
            .init(id: "self_transfer", title: "转账给自己", isAll: false),
            .init(id: "abc_credit_repay", title: "还农行信用卡", isAll: false),
            .init(id: "wealth_product", title: "理财产品", isAll: false),
            .init(id: "fund", title: "基金", isAll: false)
        ]
    )

    static let allGroups: [IncomeExpenseCategoryGroup] = [incomeGroup, expenseGroup, transferGroup]

    static let allCategoryIds: Set<String> = Set(
        allGroups.flatMap { $0.options.filter { !$0.isAll }.map(\.id) }
    )

    static let incomeCategoryIds: Set<String> = Set(
        incomeGroup.options.filter { !$0.isAll }.map(\.id)
    )
    static let expenseCategoryIds: Set<String> = Set(
        expenseGroup.options.filter { !$0.isAll }.map(\.id)
    )
    static let transferCategoryIds: Set<String> = Set(
        transferGroup.options.filter { !$0.isAll }.map(\.id)
    )

    static func title(for categoryId: String) -> String? {
        for group in allGroups {
            if let option = group.options.first(where: { $0.id == categoryId && !$0.isAll }) {
                return option.title
            }
        }
        return nil
    }

    static func selectableOptions(for direction: LedgerTransactionDirection) -> [IncomeExpenseCategoryOption] {
        let groups: [IncomeExpenseCategoryGroup]
        switch direction {
        case .income:
            groups = [incomeGroup, transferGroup]
        case .expense:
            groups = [expenseGroup, transferGroup]
        }
        return groups.flatMap { $0.options.filter { !$0.isAll } }
    }
}

struct IncomeExpenseQuery: Equatable {
    var dateMode: IncomeExpenseDateMode = .month("2026-08")
    var accountFilter: IncomeExpenseAccountFilter = .all
    var advancedFilter: IncomeExpenseAdvancedFilter = .empty

    var filterBarMonthText: String {
        switch dateMode {
        case .month(let month):
            return month
        case .custom(let start, let end):
            let s = String(start.prefix(7))
            let e = String(end.prefix(7))
            return s == e ? s : "\(s)~\(e)"
        }
    }

    var monthLabel: String {
        switch dateMode {
        case .month(let month):
            let number = Int(month.split(separator: "-").last.map(String.init) ?? "8") ?? 8
            return "\(number)月"
        case .custom(let start, let end):
            let startMonth = String(start.prefix(7))
            let endMonth = String(end.prefix(7))
            if startMonth == endMonth,
               let number = Int(startMonth.split(separator: "-").last.map(String.init) ?? "") {
                return "\(number)月"
            }
            return "自定义"
        }
    }
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
