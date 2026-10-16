import Foundation

struct LedgerCategoryTotal {
    let categoryID: String
    let direction: LedgerTransactionDirection
    let amount: Double
    let share: Double
}

struct LedgerAnalysis {
    let summary: MonthlyFlowSummary
    let categories: [LedgerCategoryTotal]
    let majorTransactions: [LedgerTransaction]
}

extension FinanceLedgerStore {
    func searchTransactions(query: IncomeExpenseQuery, keyword: String) -> [LedgerTransaction] {
        let transactions = incomeExpensePageData(query: query).dayGroups.flatMap(\.transactions)
        let terms = keyword.split(whereSeparator: \.isWhitespace).map(String.init)
        return transactions.filter { transaction in
            let text = [transaction.title, transaction.counterpartyName, transaction.counterpartyAccount,
                        transaction.summary, transaction.postscript, transaction.note, transaction.categoryTitle,
                        transaction.date, transaction.signedAmountText, accountCardLabel(for: transaction.accountId)]
                .joined(separator: " ")
            return terms.allSatisfy { text.localizedStandardContains($0) }
        }
    }

    func analysis(query: IncomeExpenseQuery) -> LedgerAnalysis {
        let page = incomeExpensePageData(query: query)
        let transactions = page.dayGroups.flatMap(\.transactions).filter(\.includeInFlow)
        var categories: [LedgerCategoryTotal] = []
        for direction in [LedgerTransactionDirection.income, .expense] {
            let items = transactions.filter { $0.direction == direction }
            let total = items.reduce(0) { $0 + $1.amount }
            for (id, group) in Dictionary(grouping: items, by: \.categoryId) {
                let amount = group.reduce(0) { $0 + $1.amount }
                categories.append(.init(categoryID: id, direction: direction, amount: amount,
                                        share: total > 0 ? amount / total : 0))
            }
        }
        categories.sort { $0.amount == $1.amount ? $0.categoryID < $1.categoryID : $0.amount > $1.amount }
        let major = transactions.enumerated().sorted {
            $0.element.amount == $1.element.amount ? $0.offset < $1.offset : $0.element.amount > $1.element.amount
        }.prefix(10).map(\.element)
        return LedgerAnalysis(summary: page.summary, categories: categories, majorTransactions: major)
    }

    /// Only persisted successful transfers linked to an existing ledger transaction qualify.
    func receiptRecords(accountID: String? = nil) -> [TransferRecord] {
        let root = load()
        let ids = Set(root.transactions.map(\.id))
        return root.transferRecords.enumerated().filter {
            let record = $0.element
            return record.status == .succeeded && record.transactionID.map(ids.contains) == true
                && (accountID == nil || record.payerAccountID == accountID)
        }.sorted {
            $0.element.createdAt == $1.element.createdAt ? $0.offset > $1.offset : $0.element.createdAt > $1.element.createdAt
        }.map(\.element)
    }
}

extension TransferRecord {
    var receiptText: String {
        """
        模拟交易 · 电子回单
        仅供学习演示，无真实资金交易，不作为银行凭证

        模拟单号：\(id)
        关联流水：\(transactionID ?? "无")
        交易时间：\(createdAt)
        状态：\(status.title)
        金额：人民币 \(TransferMoney.text(amountInCents)) 元
        付款账户：\(payerLabel)
        收款人：\(recipientName)
        收款标识：\(maskedDestination)
        收款银行：\(bankName)
        附言：\(note.isEmpty ? "无" : note)

        模拟交易 · 非银行凭证
        """
    }
}
