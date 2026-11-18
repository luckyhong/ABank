import Foundation

struct MonthlyBudget: Codable, Equatable {
    let month: String
    let categoryID: String?
    let limit: Int64
}

struct BudgetProgress {
    let budget: MonthlyBudget
    let used: Int64

    var balance: Int64 { budget.limit - used }
}

enum BudgetError: LocalizedError {
    case invalidMonth, invalidCategory, invalidAmount, persistence

    var errorDescription: String? {
        switch self {
        case .invalidMonth: return "请选择一个月份"
        case .invalidCategory: return "请选择支出分类"
        case .invalidAmount: return "预算须大于零，最多保留两位小数"
        case .persistence: return "预算未能保存，请重试"
        }
    }
}

extension FinanceLedgerStore {
    func budgetProgress(month: String) -> [BudgetProgress] {
        let budgets = load().monthlyBudgets.filter { $0.month == month }
        guard !budgets.isEmpty else { return [] }
        let result = analysis(query: IncomeExpenseQuery(dateMode: .month(month)))
        let expenses = Dictionary(uniqueKeysWithValues: result.categories.filter { $0.direction == .expense }.map {
            ($0.categoryID, TransferMoney.cents(from: $0.amount) ?? 0)
        })
        return budgets.sorted { ($0.categoryID ?? "") < ($1.categoryID ?? "") }.map {
            let used = $0.categoryID.map { expenses[$0] ?? 0 } ?? (TransferMoney.cents(from: result.summary.expense) ?? 0)
            return BudgetProgress(budget: $0, used: used)
        }
    }

    func setBudget(month: String, categoryID: String?, limit: Int64?) throws {
        guard dates.date(from: month + "-01") != nil else { throw BudgetError.invalidMonth }
        if let categoryID, !IncomeExpenseFilterCatalog.selectableOptions(for: .expense).contains(where: { $0.id == categoryID }) {
            throw BudgetError.invalidCategory
        }
        if let limit, !(1...999_999_999_999).contains(limit) { throw BudgetError.invalidAmount }
        var root = try loadForTransfer()
        root.monthlyBudgets.removeAll { $0.month == month && $0.categoryID == categoryID }
        if let limit { root.monthlyBudgets.append(MonthlyBudget(month: month, categoryID: categoryID, limit: limit)) }
        do { try persist(root) } catch { throw BudgetError.persistence }
    }
}
