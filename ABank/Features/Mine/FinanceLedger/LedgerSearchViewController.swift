import UIKit
import SnapKit

final class LedgerSearchViewController: BankingDataViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    private let query: IncomeExpenseQuery
    private let search = UISearchBar()
    private let table = UITableView(frame: .zero, style: .plain)
    private var transactions: [LedgerTransaction] = []
    init(query: IncomeExpenseQuery) {
        self.query = query
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func setupNavigationBar() {
    }
    override func setupUI() {
        title = "交易搜索"
        view.backgroundColor = .white
        search.placeholder = "名称、对方、备注、日期或金额"
        search.delegate = self
        let scope = UILabel()
        scope.text = "\(query.filterBarMonthText) · \(query.accountFilter.displayTitle) · 沿用收支筛选"
        scope.font = .systemFont(ofSize: 12)
        scope.numberOfLines = 0
        scope.textColor = .abankTextSecondary
        table.dataSource = self
        table.delegate = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 76
        table.keyboardDismissMode = .onDrag
        [search, scope, table].forEach { view.addSubview($0) }
        search.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide); $0.leading.trailing.equalToSuperview() }
        scope.snp.makeConstraints { $0.top.equalTo(search.snp.bottom).offset(8); $0.leading.trailing.equalToSuperview().inset(16) }
        table.snp.makeConstraints { $0.top.equalTo(scope.snp.bottom).offset(8); $0.leading.trailing.bottom.equalToSuperview() }
        refreshBankingData()
    }
    override func refreshBankingData() {
        transactions = FinanceLedgerStore.shared.searchTransactions(query: query, keyword: search.text ?? "")
        let empty = UILabel()
        empty.text = "暂无匹配交易"
        empty.textAlignment = .center
        empty.textColor = .abankTextSecondary
        table.backgroundView = transactions.isEmpty ? empty : nil
        table.reloadData()
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) { refreshBankingData() }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) { searchBar.resignFirstResponder() }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { transactions.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let transaction = transactions[indexPath.row]
        cell.textLabel?.text = "\(transaction.title)  \(transaction.signedAmountText)"
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = "\(transaction.datetimeText) · \(transaction.categoryTitle)" + (transaction.includeInFlow ? "" : " · 不计入收支")
        cell.detailTextLabel?.numberOfLines = 0
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController(IncomeExpenseDetailViewController(transaction: transactions[indexPath.row]), animated: true)
    }
}
