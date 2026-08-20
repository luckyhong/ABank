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

    private let defaultsKey = "abank.financeLedger.record.v2"
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
        let txs = record.transactions.filter { $0.date.hasPrefix(month) }
        let expense = txs.filter { $0.direction == .expense }.reduce(0) { $0 + $1.amount }
        let income = txs.filter { $0.direction == .income }.reduce(0) { $0 + $1.amount }
        return MonthlyFlowSummary(expense: expense, income: income)
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

        let expense = txs.filter { $0.direction == .expense }.reduce(0) { $0 + $1.amount }
        let income = txs.filter { $0.direction == .income }.reduce(0) { $0 + $1.amount }

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

    func toggleLoanDetailExpanded(id: String) {
        var record = load()
        guard let index = record.loanContracts.firstIndex(where: { $0.id == id }) else { return }
        record.loanContracts[index].isDetailExpanded.toggle()
        save(record)
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
                    isDetailExpanded: true
                )
            ],
            assetLiabilityAnnouncement: "美好生活，从一点一滴存钱开始~",
            dataTimestamp: "2026-08-20 13:41:58"
        )
        recalculateBalancesStatic(&record)
        return record
    }

    private static func seedTransactions(accountId: String) -> [LedgerTransaction] {
        [
            LedgerTransaction(id: "tx_001", accountId: accountId, date: "2026-08-01", time: "09:12", title: "ATM取款", direction: .expense, amount: 1934.91, balanceAfter: 0, iconKey: "banknote", categoryId: "cash_withdraw"),
            LedgerTransaction(id: "tx_002", accountId: accountId, date: "2026-08-02", time: "11:30", title: "转账-收入", direction: .income, amount: 3000, balanceAfter: 0, iconKey: "arrow.down.left", categoryId: "transfer_in"),
            LedgerTransaction(id: "tx_003", accountId: accountId, date: "2026-08-10", time: "09:30", title: "工资", direction: .income, amount: 14_116.04, balanceAfter: 0, iconKey: "yensign.circle", categoryId: "salary"),
            LedgerTransaction(id: "tx_004", accountId: accountId, date: "2026-08-10", time: "14:22", title: "微信支付", direction: .expense, amount: 571, balanceAfter: 0, iconKey: "message", categoryId: "third_party_out"),
            LedgerTransaction(id: "tx_005", accountId: accountId, date: "2026-08-10", time: "16:45", title: "转账-欧梦瑶", direction: .expense, amount: 11_500, balanceAfter: 0, iconKey: "person.crop.circle", categoryId: "transfer_out"),
            LedgerTransaction(id: "tx_006", accountId: accountId, date: "2026-08-11", time: "18:06", title: "财付通", direction: .income, amount: 89, balanceAfter: 0, iconKey: "creditcard", categoryId: "third_party_in"),
            LedgerTransaction(id: "tx_007", accountId: accountId, date: "2026-08-15", time: "19:58", title: "支付宝", direction: .expense, amount: 10, balanceAfter: 0, iconKey: "a.circle", categoryId: "third_party_out"),
            LedgerTransaction(id: "tx_008", accountId: accountId, date: "2026-08-15", time: "20:14", title: "抖音支付(河南...", direction: .expense, amount: 39, balanceAfter: 0, iconKey: "music.note", categoryId: "other_expense"),
            LedgerTransaction(id: "tx_009", accountId: accountId, date: "2026-08-12", time: "10:20", title: "手工记账-餐饮", direction: .expense, amount: 68, balanceAfter: 0, iconKey: "pencil", categoryId: "other_expense", isManual: true)
        ]
    }
}
