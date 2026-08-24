//
//  AccountDetailQueryViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class AccountDetailQueryViewController: BaseViewController {

    private let accountId: String
    private let maskedNumber: String
    private var filter: AccountDetailQueryFilter
    private var transactions: [LedgerTransaction] = []

    private let headerView = AccountDetailQueryHeaderView()
    private let filterBar = AccountDetailQueryFilterBarView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()

    init(
        accountId: String = FinanceLedgerRecord.defaultAccountId,
        maskedNumber: String = "6230 **** 8472"
    ) {
        self.accountId = accountId
        self.maskedNumber = maskedNumber
        self.filter = .default()
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "明细查询"
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

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        let serviceItem = UIBarButtonItem(
            image: UIImage(systemName: "headphones", withConfiguration: iconConfig),
            style: .plain,
            target: self,
            action: #selector(serviceTapped)
        )
        let statementItem = UIBarButtonItem(
            image: UIImage(systemName: "doc.text.magnifyingglass", withConfiguration: iconConfig),
            style: .plain,
            target: self,
            action: #selector(statementTapped)
        )
        navigationItem.rightBarButtonItems = [statementItem, serviceItem]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        reloadData()
    }

    override func setupUI() {
        view.backgroundColor = .white

        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            AccountDetailQueryTransactionCell.self,
            forCellReuseIdentifier: AccountDetailQueryTransactionCell.reuseId
        )
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.showsVerticalScrollIndicator = false

        emptyLabel.text = "暂无交易明细"
        emptyLabel.font = .systemFont(ofSize: 14)
        emptyLabel.textColor = .abankTextTertiary
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true

        view.addSubview(headerView)
        view.addSubview(filterBar)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        headerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(48)
        }
        filterBar.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(52)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(filterBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        emptyLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(filterBar.snp.bottom).offset(80)
        }

        headerView.onCurrencyTapped = { [weak self] in self?.showCurrencyPicker() }
        filterBar.onWeekTapped = { [weak self] in self?.selectQuickRange(.week) }
        filterBar.onMonthTapped = { [weak self] in self?.selectQuickRange(.month) }
        filterBar.onThreeMonthsTapped = { [weak self] in self?.selectQuickRange(.threeMonths) }
        filterBar.onFilterTapped = { [weak self] in self?.openAdvancedFilter() }

        reloadData()
    }

    // MARK: - Data

    private func reloadData() {
        let pageData = FinanceLedgerStore.shared.accountDetailQueryPageData(
            accountId: accountId,
            filter: filter,
            maskedNumber: maskedNumber
        )
        transactions = pageData.transactions
        headerView.configure(
            maskedNumber: pageData.maskedNumber,
            currencyTitle: pageData.currencyTitle
        )
        filterBar.configure(range: filter.quickRange, filterActive: filter.isAdvancedActive)
        tableView.reloadData()
        emptyLabel.isHidden = !transactions.isEmpty
    }

    private func selectQuickRange(_ range: AccountDetailQuickRange) {
        filter.applyQuickRange(range)
        reloadData()
    }

    // MARK: - Actions

    private func showCurrencyPicker() {
        let alert = UIAlertController(title: "选择币种", message: nil, preferredStyle: .actionSheet)
        for currency in AccountDetailCurrency.allCases {
            let title = currency.title + (currency == filter.currency ? " ✓" : "")
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                guard let self else { return }
                self.filter.currency = currency
                self.reloadData()
            })
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = headerView
            popover.sourceRect = headerView.bounds
        }
        present(alert, animated: true)
    }

    private func openAdvancedFilter() {
        let controller = IncomeExpenseFilterViewController(filter: filter.advancedFilter)
        controller.onConfirm = { [weak self] confirmed in
            guard let self else { return }
            self.filter.advancedFilter = confirmed
            self.reloadData()
        }
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        nav.navigationBar.tintColor = .abankTextPrimary
        present(nav, animated: true)
    }

    private func openDetail(for transaction: LedgerTransaction) {
        let controller = AccountDetailQueryDetailViewController(
            transaction: transaction,
            maskedNumber: maskedNumber
        )
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func serviceTapped() {
        showToast("正在为您接入在线客服")
    }

    @objc private func statementTapped() {
        showToast("回单查询")
    }
}

extension AccountDetailQueryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        transactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: AccountDetailQueryTransactionCell.reuseId,
            for: indexPath
        ) as? AccountDetailQueryTransactionCell else {
            return UITableViewCell()
        }
        let tx = transactions[indexPath.row]
        cell.configure(transaction: tx, isLast: indexPath.row == transactions.count - 1)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        openDetail(for: transactions[indexPath.row])
    }
}
