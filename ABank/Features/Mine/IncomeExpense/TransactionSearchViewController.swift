//
//  TransactionSearchViewController.swift
//  ABank
//

import UIKit
import SnapKit

/// 交易搜索：在本机账本全部月份中按关键词查找，结果按完整日期分组。
final class TransactionSearchViewController: BankingDataViewController {

    private let store: FinanceLedgerStore
    private let accountFilter: IncomeExpenseAccountFilter
    private var keyword = ""
    private var sections: [IncomeExpenseDayGroup] = []

    private let searchBar = UISearchBar()
    private let scopeLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()

    init(accountFilter: IncomeExpenseAccountFilter = .all, store: FinanceLedgerStore? = nil) {
        self.store = store ?? .shared
        self.accountFilter = accountFilter
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "搜索交易"
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.tintColor = .abankTextPrimary
        navigationItem.backButtonTitle = ""
    }

    override func setupUI() {
        view.backgroundColor = .white

        searchBar.placeholder = "交易对方、摘要、备注、分类或金额"
        searchBar.searchBarStyle = .minimal
        searchBar.returnKeyType = .search
        searchBar.delegate = self
        searchBar.searchTextField.accessibilityIdentifier = "transactionSearch.field"

        scopeLabel.font = .systemFont(ofSize: 12)
        scopeLabel.textColor = .abankTextTertiary
        scopeLabel.text = "搜索范围：\(store.accountFilterTitle(accountFilter, accounts: store.load().accounts)) · 全部月份"

        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.dataSource = self
        tableView.delegate = self
        tableView.sectionHeaderTopPadding = 0
        tableView.accessibilityIdentifier = "transactionSearch.table"
        tableView.register(IncomeExpenseTransactionCell.self, forCellReuseIdentifier: IncomeExpenseTransactionCell.reuseId)
        tableView.register(IncomeExpenseDayHeaderView.self, forHeaderFooterViewReuseIdentifier: IncomeExpenseDayHeaderView.reuseId)

        emptyLabel.font = .systemFont(ofSize: 14)
        emptyLabel.textColor = .abankTextTertiary
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.accessibilityIdentifier = "transactionSearch.emptyState"
        tableView.backgroundView = emptyLabel

        [searchBar, scopeLabel, tableView].forEach { view.addSubview($0) }
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(4)
            make.leading.trailing.equalToSuperview().inset(8)
        }
        scopeLabel.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(scopeLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
        }
        applyResults()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if keyword.isEmpty { searchBar.becomeFirstResponder() }
    }

    /// 返回或账本变化（如修改备注、分类）后按原关键词重查。
    override func refreshBankingData() {
        guard isViewLoaded else { return }
        applyResults()
    }

    private func applyResults() {
        let results = store.searchTransactions(keyword: keyword, accountFilter: accountFilter)
        sections = IncomeExpenseDayGroup.grouped(results)
        if LedgerAnalytics.normalizedKeyword(keyword).isEmpty {
            emptyLabel.text = "输入关键词，查找本机账本中的交易"
        } else {
            emptyLabel.text = "未找到与「\(keyword.trimmingCharacters(in: .whitespacesAndNewlines))」相关的交易"
        }
        emptyLabel.isHidden = !sections.isEmpty
        tableView.reloadData()
    }
}

extension TransactionSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        keyword = searchText
        applyResults()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension TransactionSearchViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].transactions.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: IncomeExpenseDayHeaderView.reuseId
        ) as? IncomeExpenseDayHeaderView else { return nil }
        // 搜索覆盖全部月份，日期标题始终带年月
        let date = sections[section].date
        header.configure(title: date.replacingOccurrences(of: "-", with: "/"))
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 40 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: IncomeExpenseTransactionCell.reuseId, for: indexPath
        ) as? IncomeExpenseTransactionCell else { return UITableViewCell() }
        let group = sections[indexPath.section]
        let tx = group.transactions[indexPath.row]
        cell.configure(transaction: tx, accountLabel: store.accountCardLabel(for: tx.accountId),
                       isLast: indexPath.row == group.transactions.count - 1)
        cell.onTap = { [weak self] in self?.openDetail(tx) }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        openDetail(sections[indexPath.section].transactions[indexPath.row])
    }

    private func openDetail(_ transaction: LedgerTransaction) {
        searchBar.resignFirstResponder()
        navigationController?.pushViewController(IncomeExpenseDetailViewController(transaction: transaction), animated: true)
    }
}
