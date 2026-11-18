import UIKit

final class LedgerBudgetsViewController: TransferFlowViewController {
    override var maximumContentWidth: CGFloat? { 560 }

    private let ledger = FinanceLedgerStore.shared
    private var month: String

    init(month: String) {
        self.month = month
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func refreshBankingData() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        title = "月度预算"
        let monthRow = BenefitsRow(title: month, subtitle: nil, id: "budget.month", showsChevron: true, scalesType: true)
        monthRow.accessibilityHint = "切换预算月份"
        monthRow.onTap = { [weak self] in self?.chooseMonth() }
        contentStack.addArrangedSubview(monthRow)
        addNotice("预算按全部账户及账本中计入收支的支出计算。")
        let progress = ledger.budgetProgress(month: month)
        if let total = progress.first(where: { $0.budget.categoryID == nil }) {
            addProgress(total, title: "总预算")
        } else {
            _ = addButton("设置总预算", id: "budget.total") { [weak self] in self?.edit(categoryID: nil, limit: nil) }
        }

        let categories = progress.filter { $0.budget.categoryID != nil }
        if !categories.isEmpty { contentStack.addArrangedSubview(BankingPageStyle.section("分类预算")) }
        for item in categories {
            let name = item.budget.categoryID.flatMap { IncomeExpenseFilterCatalog.title(for: $0) } ?? "其他"
            addProgress(item, title: name)
        }
        _ = addButton("添加分类预算", id: "budget.addCategory", primary: false) { [weak self] in
            self?.chooseCategory(excluding: Set(categories.compactMap { $0.budget.categoryID }))
        }
    }

    private func addProgress(_ item: BudgetProgress, title: String) {
        let budget = item.budget
        let status = item.balance < 0 ? "已超支" : (item.balance == 0 ? "已达上限" : "剩余")
        let row = BenefitsRow(title: title, subtitle:
            "\(status) \(TransferMoney.text(abs(item.balance))) 元\n额度 \(TransferMoney.text(budget.limit)) 元\n已用 \(TransferMoney.text(item.used)) 元",
            id: "budget.row." + (budget.categoryID ?? "total"), showsChevron: true, scalesType: true)
        row.onTap = { [weak self] in self?.edit(categoryID: budget.categoryID, limit: budget.limit) }
        contentStack.addArrangedSubview(row)
    }

    private func chooseCategory(excluding: Set<String>) {
        let all = IncomeExpenseFilterCatalog.selectableOptions(for: .expense)
        let options = all.filter { !excluding.contains($0.id) }.map { ($0.id, $0.title) }
        guard !options.isEmpty else { return showToast("所有支出分类均已设置预算") }
        let sheet = IncomeExpenseOptionPickerSheet()
        sheet.onSelect = { [weak self] in self?.edit(categoryID: $0, limit: nil) }
        sheet.present(in: navigationController?.view ?? view, title: "选择支出分类", options: options, selectedId: nil)
    }

    private func chooseMonth() {
        let sheet = IncomeExpenseDatePickerSheet()
        sheet.onConfirm = { [weak self] mode in
            guard let self else { return }
            guard case .month(let value) = mode else { return self.showToast("请选择单个月份") }
            self.month = value
            self.refreshBankingData()
        }
        sheet.present(in: navigationController?.view ?? view, mode: .month(month))
    }

    private func edit(categoryID: String?, limit: Int64?) {
        let budgetTitle = categoryID.flatMap { IncomeExpenseFilterCatalog.title(for: $0) } ?? "总预算"
        let alert = UIAlertController(title: budgetTitle, message: month, preferredStyle: .alert)
        alert.addTextField {
            $0.keyboardType = .decimalPad
            $0.placeholder = "预算金额（元）"
            $0.accessibilityLabel = "预算金额"
            $0.text = limit.map(TransferMoney.text)
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        if limit != nil {
            alert.addAction(UIAlertAction(title: "清除预算", style: .destructive) { [weak self] _ in
                self?.save(categoryID: categoryID, limit: nil)
            })
        }
        alert.addAction(UIAlertAction(title: "保存", style: .default) { [weak self, weak alert] _ in
            guard let self else { return }
            guard let value = TransferMoney.parse(alert?.textFields?.first?.text ?? ""), value > 0 else {
                return self.showToast(BudgetError.invalidAmount.localizedDescription)
            }
            self.save(categoryID: categoryID, limit: value)
        })
        present(alert, animated: true)
    }

    private func save(categoryID: String?, limit: Int64?) {
        do { try ledger.setBudget(month: month, categoryID: categoryID, limit: limit) }
        catch { showToast(error.localizedDescription) }
    }
}
