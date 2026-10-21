//
//  LedgerAnalysisModels.swift
//  ABank
//

import Foundation

// MARK: - 月度账单 / 收支分析

/// 某方向下单个分类的合计；金额统一以分计算，避免 Double 累加误差。
struct LedgerCategoryStat: Equatable, Identifiable {
    let categoryId: String
    let title: String
    let amountInCents: Int64
    let count: Int
    /// 占该方向合计的比例 0...1
    let ratio: Double

    var id: String { categoryId }
}

struct LedgerMonthTrendPoint: Equatable {
    let month: String         // yyyy-MM
    let incomeInCents: Int64
    let expenseInCents: Int64
}

/// 账单统计口径：只统计「计入收支」的交易；不计入收支的交易单独计数，不参与金额。
struct MonthlyBillData: Equatable {
    let month: String
    let accountFilter: IncomeExpenseAccountFilter
    let accountTitle: String
    let incomeInCents: Int64
    let expenseInCents: Int64
    let flowCount: Int
    let excludedCount: Int
    let expenseCategories: [LedgerCategoryStat]
    let incomeCategories: [LedgerCategoryStat]
    /// 截至当月的近 6 个月，按时间正序
    let trend: [LedgerMonthTrendPoint]
    let topExpenses: [LedgerTransaction]
    let topIncomes: [LedgerTransaction]

    var balanceInCents: Int64 { incomeInCents - expenseInCents }
    var isEmpty: Bool { flowCount == 0 && excludedCount == 0 }

    func categories(for direction: LedgerTransactionDirection) -> [LedgerCategoryStat] {
        direction == .expense ? expenseCategories : incomeCategories
    }

    func topTransactions(for direction: LedgerTransactionDirection) -> [LedgerTransaction] {
        direction == .expense ? topExpenses : topIncomes
    }
}

enum LedgerAnalytics {
    static let trendMonthCount = 6
    static let topTransactionCount = 3

    static func cents(_ tx: LedgerTransaction) -> Int64 {
        TransferMoney.cents(from: tx.amount) ?? 0
    }

    static func monthlyBill(
        record: FinanceLedgerRecord,
        month: String,
        accountFilter: IncomeExpenseAccountFilter,
        accountTitle: String,
        dates: BankingDateContext
    ) -> MonthlyBillData {
        let scoped = record.transactions.filter { accountFilter.matches($0) }
        let monthTxs = scoped.filter { $0.date.hasPrefix(month) }
        let flow = monthTxs.filter(\.includeInFlow)
        let expenses = flow.filter { $0.direction == .expense }
        let incomes = flow.filter { $0.direction == .income }

        let trendMonths = (0..<trendMonthCount).reversed().compactMap { dates.month(month, offsetBy: -$0) }
        let trend = trendMonths.map { trendMonth -> LedgerMonthTrendPoint in
            let txs = scoped.filter { $0.includeInFlow && $0.date.hasPrefix(trendMonth) }
            return LedgerMonthTrendPoint(
                month: trendMonth,
                incomeInCents: sum(txs.filter { $0.direction == .income }),
                expenseInCents: sum(txs.filter { $0.direction == .expense })
            )
        }

        return MonthlyBillData(
            month: month,
            accountFilter: accountFilter,
            accountTitle: accountTitle,
            incomeInCents: sum(incomes),
            expenseInCents: sum(expenses),
            flowCount: flow.count,
            excludedCount: monthTxs.count - flow.count,
            expenseCategories: categoryStats(expenses),
            incomeCategories: categoryStats(incomes),
            trend: trend,
            topExpenses: topTransactions(expenses),
            topIncomes: topTransactions(incomes)
        )
    }

    static func sum(_ txs: [LedgerTransaction]) -> Int64 {
        txs.reduce(Int64(0)) { $0 + cents($1) }
    }

    static func categoryStats(_ txs: [LedgerTransaction]) -> [LedgerCategoryStat] {
        let total = sum(txs)
        let grouped = Dictionary(grouping: txs, by: \.categoryId)
        return grouped.map { categoryId, items -> LedgerCategoryStat in
            let amount = sum(items)
            return LedgerCategoryStat(
                categoryId: categoryId,
                title: IncomeExpenseFilterCatalog.title(for: categoryId) ?? "其他",
                amountInCents: amount,
                count: items.count,
                ratio: total > 0 ? Double(amount) / Double(total) : 0
            )
        }.sorted {
            $0.amountInCents == $1.amountInCents ? $0.categoryId < $1.categoryId : $0.amountInCents > $1.amountInCents
        }
    }

    /// 金额由大到小；同额时较新的交易在前。
    static func topTransactions(_ txs: [LedgerTransaction]) -> [LedgerTransaction] {
        Array(txs.sorted {
            let l = cents($0), r = cents($1)
            if l != r { return l > r }
            return $0.datetimeText > $1.datetimeText
        }.prefix(topTransactionCount))
    }

    /// 有流水的最早月份；空账本返回 nil。
    static func earliestMonth(record: FinanceLedgerRecord) -> String? {
        record.transactions.map { String($0.date.prefix(7)) }.min()
    }

    // MARK: - 交易搜索

    static let maxKeywordLength = 40

    static func normalizedKeyword(_ keyword: String) -> String {
        String(keyword.filter { !$0.isWhitespace }.prefix(maxKeywordLength)).lowercased()
    }

    /// 在对方户名/账号、摘要、附言、备注、分类、账本、交易类型、渠道及金额中搜索；空关键词不返回结果。
    static func search(record: FinanceLedgerRecord, keyword: String,
                       accountFilter: IncomeExpenseAccountFilter = .all) -> [LedgerTransaction] {
        let needle = normalizedKeyword(keyword)
        guard !needle.isEmpty else { return [] }
        return record.transactions.enumerated().filter {
            accountFilter.matches($0.element) && searchableText($0.element).contains(needle)
        }.sorted { lhs, rhs in
            let l = lhs.element, r = rhs.element
            if l.date != r.date { return l.date > r.date }
            if l.time != r.time { return l.time > r.time }
            return lhs.offset > rhs.offset
        }.map(\.element)
    }

    static func searchableText(_ tx: LedgerTransaction) -> String {
        [
            tx.title, tx.counterpartyName, tx.counterpartyAccount, tx.summary, tx.postscript, tx.note,
            tx.categoryTitle, LedgerBookCatalog.title(for: tx.ledgerId) ?? "", tx.transactionType, tx.channel,
            String(format: "%.2f", tx.amount), tx.amount.abankPlainAmountString()
        ].joined(separator: "\n").filter { !$0.isWhitespace || $0 == "\n" }.lowercased()
    }
}
