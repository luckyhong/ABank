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

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "收支"


        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.abankBackIndicator,
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
        let addItem = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(addEntry))
        addItem.accessibilityLabel = "记一笔"
        navigationItem.rightBarButtonItems = [moreItem, addItem, searchItem]
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
        summaryCard.onAnalysisTapped = { [weak self] in self?.navigationController?.pushViewController(LedgerAnalysisViewController(query: self?.query ?? IncomeExpenseQuery()), animated: true) }

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
        title = LedgerBookCatalog.title(for: query.ledgerID).map { "收支 · " + $0 } ?? "收支"
        sections = pageData.dayGroups
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
            guard let self else { return }
            self.router.open(.accountDetail(accountID: nil, maskedNumber: nil), from: self)
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
        let nav = ABankNavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func searchTapped() { navigationController?.pushViewController(LedgerSearchViewController(query: query), animated: true) }
    @objc private func addEntry() { navigationController?.pushViewController(ManualEntryViewController(), animated: true) }

    @objc private func moreTapped() {
        let alert = UIAlertController(title: "账单管理", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "记一笔", style: .default) { [weak self] _ in
            let editor = ManualEntryViewController()
            editor.onSave = { [weak self] transaction in
                self?.followsCurrentMonth = false
                self?.query = IncomeExpenseQuery(dateMode: .month(String(transaction.date.prefix(7))), accountFilter: .manual)
                self?.reloadData()
            }
            self?.navigationController?.pushViewController(editor, animated: true)
        })
        alert.addAction(UIAlertAction(title: "导出当前明细", style: .default) { [weak self] _ in
            guard let self else { return }
            LedgerStatementSharing.present(query: self.query, from: self)
        })
        alert.addAction(UIAlertAction(title: "选择账本", style: .default) { [weak self] _ in self?.showBookPicker() })
        alert.addAction(UIAlertAction(title: "重置筛选", style: .default) { [weak self] _ in
            self?.query = IncomeExpenseQuery()
            self?.followsCurrentMonth = true
            self?.reloadData()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItems?.first
        present(alert, animated: true)
    }

    private func showBookPicker() {
        dismissActiveSheet()
        let sheet = IncomeExpenseOptionPickerSheet()
        sheet.onSelect = { [weak self] id in
            self?.query.ledgerID = id.isEmpty ? nil : id
            self?.activeSheet = nil
            self?.reloadData()
        }
        sheet.present(in: hostViewForSheet(), title: "选择账本", options: [("", "全部账本")] + LedgerBookCatalog.options.map { ($0.id, $0.title) }, selectedId: query.ledgerID ?? "")
        activeSheet = sheet
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
        header.configure(date: sections[section].date)
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
