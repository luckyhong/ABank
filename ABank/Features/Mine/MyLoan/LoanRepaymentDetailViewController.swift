//
//  LoanRepaymentDetailViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class LoanRepaymentDetailViewController: BankingDataViewController {

    private let contractId: String
    private var selectedTab: LoanRepaymentTab
    private var filter: LoanRepaymentFilter
    private let store = FinanceLedgerStore.shared
    private var pageData = LoanRepaymentPageData(planItems: [], detailItems: [])

    private let tabBar = LoanRepaymentTabBarView()
    private let filterBar = LoanRepaymentFilterBarView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()

    init(contractId: String, initialTab: LoanRepaymentTab = .plan) {
        self.contractId = contractId
        selectedTab = initialTab
        filter = LoanRepaymentFilter.default(tab: initialTab, dates: FinanceLedgerStore.shared.dates)
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "还款详情"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.abankBackIndicator,
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
    }

    override func setupUI() {
        view.backgroundColor = .abankBackground

        tabBar.configure(tab: selectedTab)
        tabBar.onTabChanged = { [weak self] tab in
            self?.selectedTab = tab
            self?.reloadData(resetScroll: true)
        }

        filterBar.onThreeMonthsTapped = { [weak self] in self?.selectQuickRange(.threeMonths) }
        filterBar.onOneYearTapped = { [weak self] in self?.selectQuickRange(.oneYear) }
        filterBar.onFilterTapped = { [weak self] in self?.openFilter() }

        tableView.backgroundColor = .abankBackground
        tableView.accessibilityIdentifier = "loan.repayment.table"
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(LoanRepaymentInfoCell.self, forCellReuseIdentifier: LoanRepaymentInfoCell.reuseId)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 220
        tableView.showsVerticalScrollIndicator = false

        emptyLabel.text = "暂无记录"
        emptyLabel.font = .preferredFont(forTextStyle: .subheadline)
        emptyLabel.adjustsFontForContentSizeCategory = true
        emptyLabel.numberOfLines = 0
        emptyLabel.textColor = .abankTextSecondary
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true

        view.addSubview(tabBar)
        view.addSubview(filterBar)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        tabBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
            make.width.equalTo(640).priority(999)
            make.height.greaterThanOrEqualTo(50)
        }
        filterBar.snp.makeConstraints { make in
            make.top.equalTo(tabBar.snp.bottom)
            make.leading.trailing.equalTo(tabBar)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(filterBar.snp.bottom)
            make.leading.trailing.equalTo(tabBar)
            make.bottom.equalToSuperview()
        }
        emptyLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.top.equalTo(filterBar.snp.bottom).offset(56)
        }

        reloadData()
    }

    private func selectQuickRange(_ range: LoanRepaymentQuickRange) {
        filter.applyQuickRange(range, tab: selectedTab, dates: store.dates)
        reloadData(resetScroll: true)
    }

    private func openFilter() {
        var defaults = LoanRepaymentFilter.default(tab: selectedTab, dates: store.dates)
        defaults.applyQuickRange(.oneYear, tab: selectedTab, dates: store.dates)
        let draft = filter.quickRange == .custom ? filter : defaults
        let controller = LoanRepaymentFilterViewController(filter: draft, resetFilter: defaults)
        controller.onConfirm = { [weak self] confirmed in
            guard let self else { return }
            self.filter = confirmed
            self.reloadData(resetScroll: true)
        }
        let nav = ABankNavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    override func refreshBankingData() { reloadData() }

    private func reloadData(resetScroll: Bool = false) {
        guard isViewLoaded else { return }
        filter.applyQuickRange(filter.quickRange, tab: selectedTab, dates: store.dates)
        pageData = store.loanRepaymentPageData(
            contractId: contractId,
            filter: filter
        )
        filterBar.configure(range: filter.quickRange, tab: selectedTab)
        tableView.reloadData()
        updateEmptyState()
        if resetScroll {
            tableView.setContentOffset(CGPoint(x: 0, y: -tableView.adjustedContentInset.top), animated: false)
        }
    }

    private func updateEmptyState() {
        let isEmpty: Bool
        switch selectedTab {
        case .plan: isEmpty = pageData.planItems.isEmpty
        case .detail: isEmpty = pageData.detailItems.isEmpty
        }
        emptyLabel.text = selectedTab == .plan ? "所选时段暂无待还计划" : "所选时段暂无已还记录"
        emptyLabel.isHidden = !isEmpty
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}

extension LoanRepaymentDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch selectedTab {
        case .plan: return pageData.planItems.count
        case .detail: return pageData.detailItems.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: LoanRepaymentInfoCell.reuseId,
            for: indexPath
        ) as! LoanRepaymentInfoCell

        switch selectedTab {
        case .plan:
            let item = pageData.planItems[indexPath.row]
            cell.configure(plan: item)
        case .detail:
            let item = pageData.detailItems[indexPath.row]
            cell.configure(detail: item)
        }
        return cell
    }
}
