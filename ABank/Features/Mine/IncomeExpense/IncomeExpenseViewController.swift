//
//  IncomeExpenseViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class IncomeExpenseViewController: BankingDataViewController {

    private var followsCurrentMonth = true
    private var query: IncomeExpenseQuery
    private var pageData: IncomeExpensePageData

    private let filterBar = IncomeExpenseFilterBarView()
    private let summaryCard = IncomeExpenseSummaryCardView()
    private let tableView = UITableView(frame: .zero, style: .plain)

    private var sections: [IncomeExpenseDayGroup] = []
    private var headersShowMonth = false
    private let emptyLabel = UILabel()
    private weak var activeSheet: UIView?

    init(accountId: String? = nil) {
        var initial = IncomeExpenseQuery()
        if let accountId {
            initial.accountFilter = .debitCard(id: accountId)
        }
        self.query = initial
        self.pageData = FinanceLedgerStore.shared.incomeExpensePageData(query: initial)
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    /// 从账单分类等入口带入固定月份/账户/分类，不再跟随当前月。
    init(query: IncomeExpenseQuery) {
        self.query = query
        self.pageData = FinanceLedgerStore.shared.incomeExpensePageData(query: query)
        self.followsCurrentMonth = false
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "收支"
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.tintColor = .abankTextPrimary

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.abankTextPrimary,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )

        let searchItem = UIBarButtonItem(
            image: UIImage.abankAsset("abc_mine_detail_toolbar_search", fallback: "magnifyingglass", renderingMode: .alwaysTemplate, pointSize: 18),
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

    override func refreshBankingData() {
        if followsCurrentMonth {
            query.dateMode = .month(BankingDateContext.system.currentMonth)
        }
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

        emptyLabel.text = "暂无收支记录，可切换月份或筛选条件查看"
        emptyLabel.font = .systemFont(ofSize: 14)
        emptyLabel.textColor = .abankTextTertiary
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.isAccessibilityElement = true
        emptyLabel.accessibilityIdentifier = "incomeExpense.emptyState"
        tableView.backgroundView = emptyLabel

        bindFilterBarActions()
        summaryCard.onAnalysisTapped = { [weak self] in self?.openAnalysis() }

        applyPageData()
    }

    private func bindFilterBarActions() {
        filterBar.onMonthTapped = { [weak self] in
            self?.showDatePicker()
        }
        filterBar.onAccountTapped = { [weak self] in
            self?.showAccountPicker()
        }
        filterBar.onFilterTapped = { [weak self] in
            self?.showAdvancedFilter()
        }
    }

    private func reloadData() {
        pageData = FinanceLedgerStore.shared.incomeExpensePageData(query: query)
        applyPageData()
    }

    private func applyPageData() {
        sections = pageData.dayGroups
        headersShowMonth = IncomeExpenseDayGroup.spansMultipleMonths(sections)
        filterBar.configure(
            month: pageData.month,
            account: pageData.accountFilter,
            filterActive: query.advancedFilter.isActive
        )
        summaryCard.configure(
            monthLabelText: pageData.monthLabel,
            expense: pageData.summary.expense,
            income: pageData.summary.income
        )
        emptyLabel.isHidden = !sections.isEmpty
        tableView.reloadData()
    }

    // MARK: - Panels

    private func hostViewForSheet() -> UIView {
        navigationController?.view ?? view
    }

    private func dismissActiveSheet() {
        activeSheet?.removeFromSuperview()
        activeSheet = nil
    }

    private func showDatePicker() {
        dismissActiveSheet()
        let sheet = IncomeExpenseDatePickerSheet()
        sheet.onConfirm = { [weak self] mode in
            guard let self else { return }
            self.followsCurrentMonth = false
            self.query.dateMode = mode
            self.activeSheet = nil
            self.reloadData()
        }
        sheet.onCancel = { [weak self] in
            self?.activeSheet = nil
        }
        sheet.onLegacyDetailTapped = { [weak self] in
            self?.showToast("跳转至明细")
        }
        sheet.present(in: hostViewForSheet(), mode: query.dateMode)
        activeSheet = sheet
    }

    private func showAccountPicker() {
        dismissActiveSheet()
        let sheet = IncomeExpenseAccountPickerSheet()
        sheet.onSelect = { [weak self] filter in
            guard let self else { return }
            self.query.accountFilter = filter
            self.activeSheet = nil
            self.reloadData()
        }
        sheet.onCancel = { [weak self] in
            self?.activeSheet = nil
        }
        sheet.present(
            in: hostViewForSheet(),
            options: FinanceLedgerStore.shared.accountFilterOptions(),
            selected: query.accountFilter
        )
        activeSheet = sheet
    }

    private func showAdvancedFilter() {
        dismissActiveSheet()
        let controller = IncomeExpenseFilterViewController(filter: query.advancedFilter)
        controller.onConfirm = { [weak self] filter in
            guard let self else { return }
            self.query.advancedFilter = filter
            self.reloadData()
        }
        // 与日期/账户一致：以弹框方式呈现筛选面板
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        nav.navigationBar.tintColor = .abankTextPrimary
        present(nav, animated: true)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    /// 分析页按月统计：自定义区间取结束月份。
    private func openAnalysis() {
        let month: String
        switch query.dateMode {
        case .month(let value): month = value
        case .custom(_, let end): month = String(end.prefix(7))
        }
        let controller = MonthlyBillViewController(month: month, accountFilter: query.accountFilter, title: "收支分析")
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func searchTapped() {
        let controller = TransactionSearchViewController(accountFilter: query.accountFilter)
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func moreTapped() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "月度账单", style: .default) { [weak self] _ in
            self?.navigationController?.pushViewController(MonthlyBillViewController(), animated: true)
        })
        sheet.addAction(UIAlertAction(title: "电子回单", style: .default) { [weak self] _ in
            self?.navigationController?.pushViewController(TransferReceiptListViewController(), animated: true)
        })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        sheet.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItems?.first
        present(sheet, animated: true)
    }
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
        header.configure(title: sections[section].headerTitle(showsMonth: headersShowMonth))
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
        cell.onTap = { [weak self] in self?.openDetail(for: tx) }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let tx = sections[indexPath.section].transactions[indexPath.row]
        openDetail(for: tx)
    }

    private func openDetail(for transaction: LedgerTransaction) {
        let controller = IncomeExpenseDetailViewController(transaction: transaction)
        navigationController?.pushViewController(controller, animated: true)
    }
}
