//
//  IncomeExpenseViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class IncomeExpenseViewController: BaseViewController {

    private let filterAccountId: String?
    private var pageData: IncomeExpensePageData

    private let filterBar = IncomeExpenseFilterBarView()
    private let summaryCard = IncomeExpenseSummaryCardView()
    private let tableView = UITableView(frame: .zero, style: .plain)

    private var sections: [IncomeExpenseDayGroup] = []

    init(accountId: String? = nil) {
        self.filterAccountId = accountId
        self.pageData = FinanceLedgerStore.shared.incomeExpensePageData(accountId: accountId)
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "收支"
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.tintColor = .abankTextPrimary

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        let searchConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        let searchItem = UIBarButtonItem(
            image: UIImage(systemName: "magnifyingglass", withConfiguration: searchConfig),
            style: .plain,
            target: self,
            action: #selector(searchTapped)
        )
        let moreConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let moreItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis", withConfiguration: moreConfig),
            style: .plain,
            target: self,
            action: #selector(moreTapped)
        )
        navigationItem.rightBarButtonItems = [moreItem, searchItem]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    override func setupUI() {
        view.backgroundColor = .white

        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(IncomeExpenseTransactionCell.self, forCellReuseIdentifier: IncomeExpenseTransactionCell.reuseId)
        tableView.register(IncomeExpenseDayHeaderView.self, forHeaderFooterViewReuseIdentifier: IncomeExpenseDayHeaderView.reuseId)
        tableView.sectionHeaderTopPadding = 0

        view.addSubview(filterBar)
        view.addSubview(summaryCard)
        view.addSubview(tableView)

        filterBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }
        summaryCard.snp.makeConstraints { make in
            make.top.equalTo(filterBar.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(summaryCard.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }

        filterBar.onMonthTapped = { [weak self] in self?.showToast("选择月份") }
        filterBar.onAccountTapped = { [weak self] in self?.showToast("选择账户") }
        filterBar.onFilterTapped = { [weak self] in self?.showToast("筛选") }
        summaryCard.onAnalysisTapped = { [weak self] in self?.showToast("分析") }

        applyPageData()
    }

    private func reloadData() {
        pageData = FinanceLedgerStore.shared.incomeExpensePageData(
            month: pageData.month,
            accountId: filterAccountId
        )
        applyPageData()
    }

    private func applyPageData() {
        sections = pageData.dayGroups
        filterBar.configure(month: pageData.month, account: pageData.accountFilter)
        summaryCard.configure(
            monthLabelText: pageData.monthLabel,
            expense: pageData.summary.expense,
            income: pageData.summary.income
        )
        tableView.reloadData()
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func searchTapped() { showToast("搜索") }
    @objc private func moreTapped() { showToast("更多") }
}

extension IncomeExpenseViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].transactions.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: IncomeExpenseDayHeaderView.reuseId
        ) as? IncomeExpenseDayHeaderView else { return nil }
        header.configure(day: sections[section].day)
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 40 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: IncomeExpenseTransactionCell.reuseId,
            for: indexPath
        ) as? IncomeExpenseTransactionCell else {
            return UITableViewCell()
        }
        let tx = sections[indexPath.section].transactions[indexPath.row]
        let accountLabel = FinanceLedgerStore.shared.accountCardLabel(for: tx.accountId)
        let isLast = indexPath.row == sections[indexPath.section].transactions.count - 1
        cell.configure(transaction: tx, accountLabel: accountLabel, isLast: isLast)
        cell.onTap = { [weak self] in self?.showToast(tx.title) }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let tx = sections[indexPath.section].transactions[indexPath.row]
        showToast(tx.title)
    }
}
