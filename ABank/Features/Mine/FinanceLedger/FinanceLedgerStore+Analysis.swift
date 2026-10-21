//
//  FinanceLedgerStore+Analysis.swift
//  ABank
//

import Foundation

/// 账单、搜索与电子回单：全部为只读派生，不写账本、不更新时间戳。
extension FinanceLedgerStore {

    // MARK: - 月度账单

    func monthlyBill(month: String, accountFilter: IncomeExpenseAccountFilter = .all) -> MonthlyBillData {
        let record = load()
        return LedgerAnalytics.monthlyBill(
            record: record,
            month: month,
            accountFilter: accountFilter,
            accountTitle: accountFilterTitle(accountFilter, accounts: record.accounts),
            dates: dates
        )
    }

    /// 可切换的月份范围：最早有流水的月份（至少回看 12 个月）到当前月。
    func billMonthRange() -> (earliest: String, latest: String) {
        let latest = dates.currentMonth
        let floor = dates.month(latest, offsetBy: -11) ?? latest
        let earliest = LedgerAnalytics.earliestMonth(record: load()).map { min($0, floor) } ?? floor
        return (earliest, latest)
    }

    /// 「我的」月账单入口打开上月账单。
    var defaultBillMonth: String { dates.previousMonth }

    // MARK: - 交易搜索

    func searchTransactions(keyword: String, accountFilter: IncomeExpenseAccountFilter = .all) -> [LedgerTransaction] {
        LedgerAnalytics.search(record: load(), keyword: keyword, accountFilter: accountFilter)
    }

    // MARK: - 电子回单

    /// 已成功的模拟转账回单，新到旧；可按付款账户筛选。
    func transferReceipts(accountID: String? = nil) -> [TransferReceipt] {
        let record = load()
        return transferRecords().compactMap { transfer in
            guard accountID == nil || transfer.payerAccountID == accountID else { return nil }
            return receipt(for: transfer, in: record)
        }
    }

    func transferReceipt(transactionID: String) -> TransferReceipt? {
        let record = load()
        guard let transfer = record.transferRecords.first(where: { $0.transactionID == transactionID }) else { return nil }
        return receipt(for: transfer, in: record)
    }

    func transferReceipt(recordID: String) -> TransferReceipt? {
        let record = load()
        guard let transfer = record.transferRecords.first(where: { $0.id == recordID }) else { return nil }
        return receipt(for: transfer, in: record)
    }

    private func receipt(for transfer: TransferRecord, in record: FinanceLedgerRecord) -> TransferReceipt? {
        TransferReceipt(
            record: transfer,
            transaction: transfer.transactionID.flatMap { id in record.transactions.first(where: { $0.id == id }) },
            account: record.accounts.first(where: { $0.id == transfer.payerAccountID })
        )
    }
}
