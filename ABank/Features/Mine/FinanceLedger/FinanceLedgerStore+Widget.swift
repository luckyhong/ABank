//
//  FinanceLedgerStore+Widget.swift
//  ABank
//
//  由账本构建 Widget 快照：默认借记卡余额 + 本月收支。
//

import Foundation

extension FinanceLedgerStore {
    func widgetSnapshot() -> WidgetSnapshot? {
        guard let account = account(id: FinanceLedgerRecord.defaultAccountId),
              let balance = TransferMoney.cents(from: account.balance) else { return nil }
        let flow = analysis(query: IncomeExpenseQuery(dateMode: .month(dates.currentMonth))).summary
        return WidgetSnapshot(
            balanceInCents: balance,
            monthIncomeInCents: TransferMoney.cents(from: flow.income) ?? 0,
            monthExpenseInCents: TransferMoney.cents(from: flow.expense) ?? 0,
            month: dates.currentMonth,
            updatedAt: dates.string(from: dates.now, format: "yyyy-MM-dd HH:mm:ss")
        )
    }
}
