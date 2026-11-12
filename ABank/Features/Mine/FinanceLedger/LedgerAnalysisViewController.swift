import UIKit

final class LedgerAnalysisViewController: TransferFlowViewController {
    private var query: IncomeExpenseQuery
    private let store = FinanceLedgerStore.shared
    init(query: IncomeExpenseQuery = IncomeExpenseQuery(dateMode: .month(BankingDateContext.system.previousMonth))) {
        self.query = query
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func setupUI() {
        super.setupUI()
        title = "账单分析"
        refreshBankingData()
    }
    override func refreshBankingData() {
        guard isViewLoaded else { return }
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let result = store.analysis(query: query)
        addNotice("\(query.filterBarMonthText) · \(store.incomeExpensePageData(query: query).accountFilter) · \(LedgerBookCatalog.title(for: query.ledgerID) ?? "全部账本")")
        _ = addButton("选择月份", id: "analysis.month", primary: false) { [weak self] in self?.chooseMonth() }
        addGroup([
            TransferInfoRow("收入", value: result.summary.income.abankPlainAmountString()),
            TransferInfoRow("支出", value: result.summary.expense.abankPlainAmountString()),
            TransferInfoRow("结余", value: (result.summary.income - result.summary.expense).abankPlainAmountString())
        ])
        addNotice("收入 / 支出分类 · 占各自收支比例；不计入收支的交易不参与统计")
        if result.categories.isEmpty { addNotice("该范围暂无计入收支的交易") }
        for category in result.categories {
            let name = IncomeExpenseFilterCatalog.title(for: category.categoryID) ?? category.categoryID
            let direction = category.direction == .income ? "收入" : "支出"
            _ = addButton("\(direction) · \(name)  \(category.amount.abankPlainAmountString())  \(Int((category.share * 100).rounded()))%", id: "analysis.category.\(category.categoryID)", primary: false) { [weak self] in
                guard let self else { return }
                var filter = self.query
                filter.advancedFilter.selectedCategoryIds = [category.categoryID]
                self.navigationController?.pushViewController(LedgerSearchViewController(query: filter), animated: true)
            }
        }
        addNotice("主要收支 · 按金额排序前10笔")
        for transaction in result.majorTransactions {
            _ = addButton("\(transaction.title)  \(transaction.signedAmountText)", id: "analysis.transaction.\(transaction.id)", primary: false) { [weak self] in
                self?.navigationController?.pushViewController(IncomeExpenseDetailViewController(transaction: transaction), animated: true)
            }
        }
        if case .month(let month) = query.dateMode, let date = BankingDateContext.system.date(from: month + "-01") {
            addNotice("近6个月趋势 · 同一账户与分类筛选，空月显示0")
            for offset in (-5...0) {
                let dates = BankingDateContext.system
                let value = dates.calendar.date(byAdding: .month, value: offset, to: date)!
                let label = dates.string(from: value, format: "yyyy-MM")
                var filter = query
                filter.dateMode = .month(label)
                let summary = store.analysis(query: filter).summary
                addGroup([TransferInfoRow(label, value: "收 \(summary.income.abankPlainAmountString())\n支 \(summary.expense.abankPlainAmountString())")])
            }
        }
        _ = addButton("导出当前明细", id: "analysis.export", primary: false) { [weak self] in
            guard let self else { return }
            LedgerStatementSharing.present(query: self.query, from: self)
        }
        _ = addButton("搜索该范围交易", id: "analysis.search", primary: false) { [weak self] in
            guard let self else { return }
            self.navigationController?.pushViewController(LedgerSearchViewController(query: self.query), animated: true)
        }
    }
    private func chooseMonth() {
        let sheet = IncomeExpenseDatePickerSheet()
        sheet.onConfirm = { [weak self] mode in self?.query.dateMode = mode; self?.refreshBankingData() }
        sheet.present(in: view, mode: query.dateMode)
    }
}
