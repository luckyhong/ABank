//
//  FinanceLedgerStore.swift
//  ABank
//

import Foundation

extension Notification.Name {
    static let financeLedgerDidChange = Notification.Name("FinanceLedgerStore.didChange")
}

final class FinanceLedgerStore {
    static let shared = FinanceLedgerStore()

    private let defaultsKey = "abank.financeLedger.record.v5"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    // MARK: - CRUD

    func load() -> FinanceLedgerRecord {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let record = try? decoder.decode(FinanceLedgerRecord.self, from: data) {
            return record
        }
        let seeded = Self.makeSeedRecord()
        save(seeded)
        return seeded
    }

    func save(_ record: FinanceLedgerRecord) {
        guard let data = try? encoder.encode(record) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
        NotificationCenter.default.post(name: .financeLedgerDidChange, object: nil)
    }

    func update(_ transform: (inout FinanceLedgerRecord) -> Void) {
        var record = load()
        transform(&record)
        recalculate(&record)
        save(record)
    }

    // MARK: - 派生读取

    func totalAssets() -> Double {
        load().accounts.reduce(0) { $0 + $1.balance }
    }

    func totalLiabilities() -> Double {
        load().loanContracts.reduce(0) { $0 + $1.unpaidPrincipal }
    }

    func monthlyFlow(for month: String) -> MonthlyFlowSummary {
        let record = load()
        let txs = record.transactions.filter { $0.date.hasPrefix(month) && $0.includeInFlow }
        let expense = txs.filter { $0.direction == .expense }.reduce(0) { $0 + $1.amount }
        let income = txs.filter { $0.direction == .income }.reduce(0) { $0 + $1.amount }
        return MonthlyFlowSummary(expense: expense, income: income)
    }

    func transaction(id: String) -> LedgerTransaction? {
        load().transactions.first(where: { $0.id == id })
    }

    func updateTransactionDetail(
        id: String,
        includeInFlow: Bool? = nil,
        categoryId: String? = nil,
        note: String? = nil
    ) {
        update { record in
            guard let index = record.transactions.firstIndex(where: { $0.id == id }) else { return }
            if let includeInFlow { record.transactions[index].includeInFlow = includeInFlow }
            if let categoryId { record.transactions[index].categoryId = categoryId }
            if let note { record.transactions[index].note = note }
        }
    }

    func updateTransactionLedger(id: String, ledgerId: String?) {
        update { record in
            guard let index = record.transactions.firstIndex(where: { $0.id == id }) else { return }
            record.transactions[index].ledgerId = ledgerId
        }
    }

    func mineAssetLiability() -> MineAssetLiability {
        MineAssetLiability(
            assets: totalAssets(),
            liabilities: totalLiabilities(),
            billNotice: "您的月度账单已出，请查看"
        )
    }

    func mineMonthlyFlow(for month: String = "2026-08") -> MineMonthlyFlow {
        let summary = monthlyFlow(for: month)
        return MineMonthlyFlow(
            expense: summary.expense,
            income: summary.income,
            billSectionTitle: "月度账单",
            billNotice: "您的7月份账单已出",
            hasBillBadge: true
        )
    }

    func assetLiabilityPageData() -> AssetLiabilityPageData {
        let record = load()
        let account = record.accounts.first(where: { $0.id == FinanceLedgerRecord.defaultAccountId })
        let loan = record.loanContracts.first(where: { $0.id == FinanceLedgerRecord.defaultLoanId })

        return AssetLiabilityPageData(
            totalAssets: totalAssets(),
            totalLiabilities: totalLiabilities(),
            dataTimestamp: record.dataTimestamp,
            announcement: record.assetLiabilityAnnouncement,
            assetCategories: [
                AssetLiabilityCategory(
                    id: FinanceLedgerRecord.demandDepositCategoryId,
                    title: "活期",
                    totalAmount: account?.balance,
                    items: record.accounts.map { acct in
                        AssetLiabilityItem(
                            id: acct.id,
                            title: acct.displayName,
                            amount: acct.balance,
                            showsCurrencySymbol: true,
                            subtitle: nil,
                            showsMenu: true
                        )
                    }
                )
            ],
            liabilityCategories: [
                AssetLiabilityCategory(
                    id: FinanceLedgerRecord.loanCategoryId,
                    title: "贷款",
                    totalAmount: nil,
                    items: record.loanContracts.map { contract in
                        AssetLiabilityItem(
                            id: contract.id,
                            title: contract.name,
                            amount: contract.unpaidPrincipal,
                            showsCurrencySymbol: false,
                            subtitle: "贷款余额",
                            showsMenu: false
                        )
                    }
                )
            ],
            assetTips: [
                "资产负债视图展示的是您在中国农业银行的资产信息，包含存款、理财、基金等，包含未签约掌银的账户，数据仅供参考。其中，外币资产折算成人民币统计。",
                "如有疑问，请联系我行客服电话95599或亲临农行网点。"
            ],
            liabilityTips: [
                "负债视图功能展示您在农业银行的信用卡和个人贷款相关负债信息，统计范围不限于掌上银行签约账户，所有数据仅供参考，不作为对账依据。如果您有外币负债，将被折算成人民币计入负债总额。",
                "如有疑问，请联系我行客服电话95599或亲临农行网点。"
            ]
        )
    }

    func incomeExpensePageData(month: String = "2026-08", accountId: String? = nil) -> IncomeExpensePageData {
        var query = IncomeExpenseQuery(dateMode: .month(month))
        if let accountId {
            query.accountFilter = .debitCard(id: accountId)
        }
        return incomeExpensePageData(query: query)
    }

    func incomeExpensePageData(query: IncomeExpenseQuery) -> IncomeExpensePageData {
        let record = load()
        var txs = record.transactions.filter { matchesDate($0, query: query) }
        txs = txs.filter { matchesAccount($0, filter: query.accountFilter) }
        txs = txs.filter { matchesAdvanced($0, filter: query.advancedFilter) }
        txs.sort { lhs, rhs in
            if lhs.date != rhs.date { return lhs.date > rhs.date }
            return lhs.time > rhs.time
        }

        let flowTxs = txs.filter(\.includeInFlow)
        let expense = flowTxs.filter { $0.direction == .expense }.reduce(0) { $0 + $1.amount }
        let income = flowTxs.filter { $0.direction == .income }.reduce(0) { $0 + $1.amount }

        let grouped = Dictionary(grouping: txs) { tx -> Int in
            Int(tx.date.split(separator: "-").last ?? "0") ?? 0
        }
        let dayGroups = grouped.keys.sorted(by: >).map { day in
            let dayTxs = (grouped[day] ?? []).sorted { lhs, rhs in
                if lhs.time != rhs.time { return lhs.time > rhs.time }
                return lhs.id > rhs.id
            }
            return IncomeExpenseDayGroup(day: day, transactions: dayTxs)
        }

        return IncomeExpensePageData(
            month: query.filterBarMonthText,
            monthLabel: query.monthLabel,
            accountFilter: accountFilterTitle(query.accountFilter, accounts: record.accounts),
            summary: MonthlyFlowSummary(expense: expense, income: income),
            dayGroups: dayGroups
        )
    }

    func accountFilterOptions() -> [(filter: IncomeExpenseAccountFilter, title: String, icon: String)] {
        let record = load()
        var options: [(IncomeExpenseAccountFilter, String, String)] = [
            (.all, "全部账户", "square.stack.3d.up"),
            (.excludeManual, "不含手工记账", "person.crop.circle")
        ]
        for account in record.accounts {
            options.append((.debitCard(id: account.id), account.cardLabel, "creditcard"))
        }
        options.append((.manual, "手工记账", "pencil"))
        return options.map { (filter: $0.0, title: $0.1, icon: $0.2) }
    }

    private func matchesDate(_ tx: LedgerTransaction, query: IncomeExpenseQuery) -> Bool {
        switch query.dateMode {
        case .month(let month):
            return tx.date.hasPrefix(month)
        case .custom(let start, let end):
            return tx.date >= start && tx.date <= end
        }
    }

    private func matchesAccount(
        _ tx: LedgerTransaction,
        filter: IncomeExpenseAccountFilter
    ) -> Bool {
        switch filter {
        case .all:
            return true
        case .excludeManual:
            return !tx.isManual
        case .debitCard(let id):
            return tx.accountId == id && !tx.isManual
        case .manual:
            return tx.isManual
        }
    }

    private func matchesAdvanced(_ tx: LedgerTransaction, filter: IncomeExpenseAdvancedFilter) -> Bool {
        if let min = filter.minAmount, tx.amount < min { return false }
        if let max = filter.maxAmount, tx.amount > max { return false }

        let selected = filter.selectedCategoryIds
        guard !selected.isEmpty else { return true }

        // 「全部」类标签展开为组内具体分类
        var effective = selected
        if selected.contains("income_all") {
            effective.formUnion(IncomeExpenseFilterCatalog.incomeCategoryIds)
        }
        if selected.contains("expense_all") {
            effective.formUnion(IncomeExpenseFilterCatalog.expenseCategoryIds)
        }
        if selected.contains("self_all") {
            effective.formUnion(IncomeExpenseFilterCatalog.transferCategoryIds)
        }
        effective = effective.subtracting(["income_all", "expense_all", "self_all"])
        return effective.contains(tx.categoryId)
    }

    private func accountFilterTitle(_ filter: IncomeExpenseAccountFilter, accounts: [LedgerAccount]) -> String {
        switch filter {
        case .all: return "全部账户"
        case .excludeManual: return "不含手工记账"
        case .debitCard(let id):
            return accounts.first(where: { $0.id == id })?.cardLabel ?? "借记卡"
        case .manual: return "手工记账"
        }
    }

    func myLoanPageData() -> MyLoanPageData {
        let record = load()
        let contracts = record.loanContracts
        return MyLoanPageData(
            monthlyDue: contracts.reduce(0) { $0 + $1.monthlyDue },
            totalUnpaidPrincipal: contracts.reduce(0) { $0 + $1.unpaidPrincipal },
            availableLimit: contracts.reduce(0) { $0 + $1.availableLimit },
            contracts: contracts,
            tip: "温馨提示：以上内容仅供参考，如需了解详情请联系您的客户经理。"
        )
    }

    func accountCardLabel(for accountId: String) -> String {
        load().accounts.first(where: { $0.id == accountId })?.cardLabel ?? "借记卡"
    }

    // MARK: - 重算

    func recalculate(_ record: inout FinanceLedgerRecord) {
        recalculateBalances(&record)
    }

    private static func recalculateBalancesStatic(_ record: inout FinanceLedgerRecord) {
        for accountIndex in record.accounts.indices {
            let accountId = record.accounts[accountIndex].id
            var txs = record.transactions.enumerated().filter { $0.element.accountId == accountId }
            txs.sort { lhs, rhs in
                let l = lhs.element, r = rhs.element
                if l.date != r.date { return l.date < r.date }
                return l.time < r.time
            }

            var balance = record.accounts[accountIndex].openingBalance
            for (globalIndex, var tx) in txs {
                balance += tx.direction == .income ? tx.amount : -tx.amount
                tx.balanceAfter = balance
                record.transactions[globalIndex] = tx
            }
            record.accounts[accountIndex].balance = balance
        }
    }

    private func recalculateBalances(_ record: inout FinanceLedgerRecord) {
        Self.recalculateBalancesStatic(&record)
    }

    // MARK: - 后续改账 API

    func updateTransaction(id: String, amount: Double? = nil, title: String? = nil) {
        update { record in
            guard let index = record.transactions.firstIndex(where: { $0.id == id }) else { return }
            if let amount { record.transactions[index].amount = amount }
            if let title { record.transactions[index].title = title }
        }
    }

    func updateLoanUnpaidPrincipal(id: String, amount: Double) {
        update { record in
            guard let index = record.loanContracts.firstIndex(where: { $0.id == id }) else { return }
            record.loanContracts[index].unpaidPrincipal = amount
        }
    }

    func loanContract(id: String) -> LoanContract? {
        load().loanContracts.first(where: { $0.id == id })
    }

    func toggleLoanDetailExpanded(id: String) {
        var record = load()
        guard let index = record.loanContracts.firstIndex(where: { $0.id == id }) else { return }
        record.loanContracts[index].isDetailExpanded.toggle()
        save(record)
    }

    // MARK: - 贷款还款 / 使用记录

    func loanRepaymentPageData(
        contractId: String,
        filter: LoanRepaymentFilter
    ) -> LoanRepaymentPageData {
        let contract = loanContract(id: contractId)
        let contractNumber = contract?.contractNumber.isEmpty == false
            ? (contract?.contractNumber ?? "")
            : "26135157700004774"

        let plans = Self.seedRepaymentPlans(contractNumber: contractNumber)
            .filter { Self.isDate($0.date, in: filter) }
            .sorted { lhs, rhs in
                filter.sortOrder == .nearToFar
                    ? lhs.date > rhs.date || (lhs.date == rhs.date && lhs.period > rhs.period)
                    : lhs.date < rhs.date || (lhs.date == rhs.date && lhs.period < rhs.period)
            }

        let details = Self.seedRepaymentDetails(contractNumber: contractNumber)
            .filter { Self.isDate($0.date, in: filter) }
            .sorted { lhs, rhs in
                filter.sortOrder == .nearToFar ? lhs.date > rhs.date : lhs.date < rhs.date
            }

        return LoanRepaymentPageData(planItems: plans, detailItems: details)
    }

    func loanUsageRecordsPageData(
        contractId: String,
        page: Int,
        pageSize: Int = 10
    ) -> LoanUsageRecordsPageData {
        _ = contractId
        let all = Self.seedUsageRecords()
        let start = max(0, page * pageSize)
        guard start < all.count else {
            return LoanUsageRecordsPageData(records: [], hasMore: false)
        }
        let end = min(all.count, start + pageSize)
        let slice = Array(all[start..<end])
        return LoanUsageRecordsPageData(records: slice, hasMore: end < all.count)
    }

    func loanPrepaymentInfo(contractId: String) -> LoanPrepaymentInfo? {
        guard let contract = loanContract(id: contractId) else { return nil }
        return LoanPrepaymentInfo(
            voucherNumber: "610220170047751",
            contractNumber: contract.contractNumber.isEmpty
                ? "26135157700004774"
                : contract.contractNumber,
            maturityDate: "2037-10-08",
            usageDate: "2017-10-09",
            annualRatePercent: contract.annualRatePercent,
            unpaidPrincipal: contract.unpaidPrincipal
        )
    }

    func loanDuePageData(period: LoanDuePeriod) -> LoanDuePageData {
        let tip = "温馨提示：以上内容仅供参考，如需了解详情请联系您的客户经理。"
        let contracts = load().loanContracts
        switch period {
        case .thisMonth:
            // 参考日 2026-08：本月已还清，应还为 0
            return LoanDuePageData(
                period: .thisMonth,
                totalAmount: contracts.reduce(0) { $0 + $1.monthlyDue },
                installments: [],
                tip: tip
            )
        case .nextMonth:
            let items: [LoanDueInstallment] = contracts.map { contract in
                LoanDueInstallment(
                    id: "due_next_\(contract.id)",
                    date: "2026-09-09",
                    amount: 2_934.91,
                    loanName: contract.name,
                    contractNumber: contract.contractNumber.isEmpty
                        ? "26135157700004774"
                        : contract.contractNumber
                )
            }
            let total = items.reduce(0) { $0 + $1.amount }
            return LoanDuePageData(
                period: .nextMonth,
                totalAmount: total,
                installments: items,
                tip: tip
            )
        }
    }

    private static func isDate(_ date: String, in filter: LoanRepaymentFilter) -> Bool {
        date >= filter.startDate && date <= filter.endDate
    }

    private static func seedRepaymentPlans(contractNumber: String) -> [LoanRepaymentPlanItem] {
        let payment = 2_934.91
        var balance = 334_420.99
        var principal = 2_037.71
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents(year: 2026, month: 6, day: 9)
        var items: [LoanRepaymentPlanItem] = []

        for period in 104...120 {
            guard let date = calendar.date(from: components) else { break }
            let roundedPrincipal = (principal * 100).rounded() / 100
            let roundedInterest = ((payment - roundedPrincipal) * 100).rounded() / 100
            balance = max(0, ((balance - roundedPrincipal) * 100).rounded() / 100)
            items.append(
                LoanRepaymentPlanItem(
                    id: "plan_\(period)",
                    contractNumber: contractNumber,
                    period: period,
                    date: LoanRepaymentFilter.string(from: date),
                    repaymentAmount: payment,
                    principal: roundedPrincipal,
                    interest: roundedInterest,
                    balance: balance
                )
            )
            principal += 5.45
            if let next = calendar.date(byAdding: .month, value: 1, to: date) {
                components = calendar.dateComponents([.year, .month, .day], from: next)
            }
        }

        let overrides: [(Int, String, Double, Double, Double, Double)] = [
            (107, "2026-09-09", 2_934.91, 2_054.06, 880.85, 328_264.87),
            (108, "2026-10-09", 2_934.91, 2_059.54, 875.37, 326_205.33),
            (109, "2026-11-09", 2_934.91, 2_065.03, 869.88, 324_140.30)
        ]
        for item in overrides {
            guard let idx = items.firstIndex(where: { $0.period == item.0 }) else { continue }
            items[idx] = LoanRepaymentPlanItem(
                id: items[idx].id,
                contractNumber: contractNumber,
                period: item.0,
                date: item.1,
                repaymentAmount: item.2,
                principal: item.3,
                interest: item.4,
                balance: item.5
            )
        }
        return items
    }

    private static func seedRepaymentDetails(contractNumber: String) -> [LoanRepaymentDetailItem] {
        let rows: [(String, Double, Double)] = [
            ("2026-03-09", 2_021.45, 913.46),
            ("2026-04-09", 2_026.84, 908.07),
            ("2026-05-09", 2_032.26, 902.65),
            ("2026-06-09", 2_037.71, 897.20),
            ("2026-07-09", 2_043.15, 891.76),
            ("2026-08-09", 2_048.60, 886.31),
            ("2025-12-09", 2_005.12, 929.79),
            ("2025-09-09", 1_988.40, 946.51)
        ]
        return rows.enumerated().map { index, row in
            LoanRepaymentDetailItem(
                id: "detail_\(index)",
                contractNumber: contractNumber,
                date: row.0,
                principal: row.1,
                interest: row.2,
                penalty: 0,
                compoundInterest: 0
            )
        }
    }

    private static func seedUsageRecords() -> [LoanUsageRecord] {
        [
            LoanUsageRecord(
                id: "usage_001", title: "还款", dateTime: "2026-08-09 00:48",
                totalAmount: 2_934.91, principal: 2_048.60, interest: 886.31,
                penalty: 0, compoundPenalty: 0
            ),
            LoanUsageRecord(
                id: "usage_002", title: "还款", dateTime: "2026-07-09 00:48",
                totalAmount: 2_934.91, principal: 2_043.15, interest: 891.76,
                penalty: 0, compoundPenalty: 0
            ),
            LoanUsageRecord(
                id: "usage_003", title: "还款", dateTime: "2026-06-09 00:48",
                totalAmount: 2_934.91, principal: 2_037.71, interest: 897.20,
                penalty: 0, compoundPenalty: 0
            ),
            LoanUsageRecord(
                id: "usage_004", title: "还款", dateTime: "2026-05-09 00:48",
                totalAmount: 2_934.91, principal: 2_032.26, interest: 902.65,
                penalty: 0, compoundPenalty: 0
            ),
            LoanUsageRecord(
                id: "usage_005", title: "还款", dateTime: "2026-04-09 00:48",
                totalAmount: 2_934.91, principal: 2_026.84, interest: 908.07,
                penalty: 0, compoundPenalty: 0
            ),
            LoanUsageRecord(
                id: "usage_006", title: "还款", dateTime: "2026-03-09 00:48",
                totalAmount: 2_934.91, principal: 2_021.45, interest: 913.46,
                penalty: 0, compoundPenalty: 0
            ),
            LoanUsageRecord(
                id: "usage_007", title: "还款", dateTime: "2026-02-09 00:48",
                totalAmount: 2_934.91, principal: 2_016.08, interest: 918.83,
                penalty: 0, compoundPenalty: 0
            ),
            LoanUsageRecord(
                id: "usage_008", title: "还款", dateTime: "2026-01-09 00:48",
                totalAmount: 2_934.91, principal: 2_010.72, interest: 924.19,
                penalty: 0, compoundPenalty: 0
            ),
            LoanUsageRecord(
                id: "usage_009", title: "还款", dateTime: "2025-12-09 00:48",
                totalAmount: 2_934.91, principal: 2_005.12, interest: 929.79,
                penalty: 0, compoundPenalty: 0
            ),
            LoanUsageRecord(
                id: "usage_010", title: "还款", dateTime: "2025-11-09 00:48",
                totalAmount: 2_934.91, principal: 1_999.80, interest: 935.11,
                penalty: 0, compoundPenalty: 0
            ),
            LoanUsageRecord(
                id: "usage_011", title: "还款", dateTime: "2025-10-09 00:48",
                totalAmount: 2_934.91, principal: 1_994.20, interest: 940.71,
                penalty: 0, compoundPenalty: 0
            ),
            LoanUsageRecord(
                id: "usage_012", title: "还款", dateTime: "2025-09-09 00:48",
                totalAmount: 2_934.91, principal: 1_988.40, interest: 946.51,
                penalty: 0, compoundPenalty: 0
            )
        ]
    }

    // MARK: - 种子数据

    static func makeSeedRecord() -> FinanceLedgerRecord {
        let accountId = FinanceLedgerRecord.defaultAccountId
        var record = FinanceLedgerRecord(
            accounts: [
                LedgerAccount(
                    id: accountId,
                    tailNumber: "8472",
                    currency: "人民币",
                    balance: 2660.66,
                    openingBalance: -489.47
                )
            ],
            transactions: seedTransactions(accountId: accountId),
            loanContracts: [
                LoanContract(
                    id: FinanceLedgerRecord.defaultLoanId,
                    name: "个人住房贷款",
                    unpaidPrincipal: 330_318.93,
                    contractLimit: 670_000,
                    expiryDate: "2047-09-14",
                    monthlyDue: 0,
                    availableLimit: 0,
                    isDetailExpanded: true,
                    contractNumber: "26135157700004774",
                    signingDate: "2017-09-15",
                    disbursementDateText: "2017年10月9日",
                    loanAmount: 670_000,
                    annualRatePercent: 3.2,
                    pricingMethod: "浮动利率",
                    pricingBenchmark: "LPR",
                    floatingRange: "-30bp",
                    repricingCycle: "3个月",
                    repricingDatesText: "1月9日,4月9日,7月9日,10月9日",
                    maturityDateText: "2037年10月8日",
                    statusText: "正常"
                )
            ],
            assetLiabilityAnnouncement: "美好生活，从一点一滴存钱开始~",
            dataTimestamp: "2026-08-20 13:41:58"
        )
        recalculateBalancesStatic(&record)
        return record
    }

    private static func seedTransactions(accountId: String) -> [LedgerTransaction] {
        let card = "6230****8472"
        return [
            LedgerTransaction(
                id: "tx_001", accountId: accountId, date: "2026-08-01", time: "09:12:08",
                title: "ATM取款", direction: .expense, amount: 1934.91, balanceAfter: 0,
                iconKey: "banknote", categoryId: "cash_withdraw",
                counterpartyName: "中国农业银行ATM", counterpartyAccount: "ATM****1201",
                summary: "ATM取款", postscript: "现金支取", cardNumber: card, transactionType: "取现"
            ),
            LedgerTransaction(
                id: "tx_002", accountId: accountId, date: "2026-08-02", time: "11:30:15",
                title: "转账-收入", direction: .income, amount: 3000, balanceAfter: 0,
                iconKey: "arrow.down.left", categoryId: "transfer_in",
                counterpartyName: "张三", counterpartyAccount: "6228****3312",
                summary: "转账", postscript: "还款", cardNumber: card, transactionType: "转账"
            ),
            LedgerTransaction(
                id: "tx_003", accountId: accountId, date: "2026-08-10", time: "17:24:24",
                title: "工资", direction: .income, amount: 14_116.04, balanceAfter: 0,
                iconKey: "yensign.circle", categoryId: "salary",
                counterpartyName: "安星达（西安）科技有限公司", counterpartyAccount: "26-1****0898",
                summary: "工资", postscript: "7月工资", cardNumber: card, transactionType: "转账"
            ),
            LedgerTransaction(
                id: "tx_004", accountId: accountId, date: "2026-08-10", time: "14:22:03",
                title: "微信支付", direction: .expense, amount: 571, balanceAfter: 0,
                iconKey: "message", categoryId: "third_party_out",
                counterpartyName: "财付通支付科技有限公司", counterpartyAccount: "1000****8899",
                summary: "微信支付", postscript: "消费", cardNumber: card, transactionType: "转账"
            ),
            LedgerTransaction(
                id: "tx_005", accountId: accountId, date: "2026-08-10", time: "16:45:41",
                title: "转账-欧梦瑶", direction: .expense, amount: 11_500, balanceAfter: 0,
                iconKey: "person.crop.circle", categoryId: "transfer_out",
                counterpartyName: "欧梦瑶", counterpartyAccount: "6217****5521",
                summary: "转账", postscript: "生活费", cardNumber: card, transactionType: "转账"
            ),
            LedgerTransaction(
                id: "tx_006", accountId: accountId, date: "2026-08-11", time: "18:06:12",
                title: "财付通", direction: .income, amount: 89, balanceAfter: 0,
                iconKey: "creditcard", categoryId: "third_party_in",
                counterpartyName: "财付通支付科技有限公司", counterpartyAccount: "1000****8899",
                summary: "财付通", postscript: "退款", cardNumber: card, transactionType: "转账"
            ),
            LedgerTransaction(
                id: "tx_007", accountId: accountId, date: "2026-08-15", time: "19:58:06",
                title: "支付宝", direction: .expense, amount: 10, balanceAfter: 0,
                iconKey: "a.circle", categoryId: "third_party_out",
                counterpartyName: "支付宝（中国）网络技术有限公司", counterpartyAccount: "2088****1024",
                summary: "支付宝", postscript: "消费", cardNumber: card, transactionType: "转账"
            ),
            LedgerTransaction(
                id: "tx_008", accountId: accountId, date: "2026-08-15", time: "20:14:19",
                title: "抖音支付(河南好莱坞影院管理有限公司)", direction: .expense, amount: 39, balanceAfter: 0,
                iconKey: "music.note", categoryId: "third_party_out",
                counterpartyName: "河南好莱坞影院管理有限公司", counterpartyAccount: "7020****6346",
                summary: "抖音支付",
                postscript: "NA|202608150012342178 4127400300000|河南好莱坞影院管理有限公司",
                cardNumber: card, transactionType: "转账"
            ),
            LedgerTransaction(
                id: "tx_009", accountId: accountId, date: "2026-08-12", time: "10:20:00",
                title: "手工记账-餐饮", direction: .expense, amount: 68, balanceAfter: 0,
                iconKey: "pencil", categoryId: "other_expense", isManual: true,
                counterpartyName: "手工记账", counterpartyAccount: "-",
                summary: "餐饮", postscript: "午餐", cardNumber: card, transactionType: "记账"
            )
        ]
    }
}
