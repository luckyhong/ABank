//
//  LoanRepaymentDetailViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class LoanRepaymentDetailViewController: BaseViewController {

    private let contractId: String
    private var selectedTab: LoanRepaymentTab = .detail
    private var filter = LoanRepaymentFilter.default()
    private var pageData = LoanRepaymentPageData(planItems: [], detailItems: [])

    private let tabBar = LoanRepaymentTabBarView()
    private let filterBar = LoanRepaymentFilterBarView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()

    init(contractId: String) {
        self.contractId = contractId
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "还款详情"
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.tintColor = .abankTextPrimary
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
    }

    override func setupUI() {
        view.backgroundColor = .white

        filter.applyQuickRange(.threeMonths, referenceDate: Self.referenceDate)

        tabBar.configure(tab: selectedTab)
        tabBar.onTabChanged = { [weak self] tab in
            self?.selectedTab = tab
            self?.tableView.reloadData()
            self?.updateEmptyState()
        }

        filterBar.onThreeMonthsTapped = { [weak self] in self?.selectQuickRange(.threeMonths) }
        filterBar.onOneYearTapped = { [weak self] in self?.selectQuickRange(.oneYear) }
        filterBar.onFilterTapped = { [weak self] in self?.openFilter() }

        tableView.backgroundColor = UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1)
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(LoanRepaymentInfoCell.self, forCellReuseIdentifier: LoanRepaymentInfoCell.reuseId)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 220
        tableView.showsVerticalScrollIndicator = false

        emptyLabel.text = "暂无记录"
        emptyLabel.font = .systemFont(ofSize: 14)
        emptyLabel.textColor = .abankTextTertiary
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true

        view.addSubview(tabBar)
        view.addSubview(filterBar)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        tabBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        filterBar.snp.makeConstraints { make in
            make.top.equalTo(tabBar.snp.bottom)
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

        reloadData()
    }

    private func selectQuickRange(_ range: LoanRepaymentQuickRange) {
        filter.applyQuickRange(range, referenceDate: Self.referenceDate)
        reloadData()
    }

    private func openFilter() {
        let draft: LoanRepaymentFilter
        if filter.quickRange == .custom {
            draft = filter
        } else {
            // 打开筛选页时给出与设计稿一致的默认区间
            var custom = filter
            custom.applyCustom(
                start: Self.defaultCustomStart,
                end: Self.defaultCustomEnd,
                sortOrder: filter.sortOrder
            )
            draft = custom
        }

        let controller = LoanRepaymentFilterViewController(filter: draft)
        controller.onConfirm = { [weak self] confirmed in
            guard let self else { return }
            self.filter = confirmed
            self.reloadData()
        }
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        nav.navigationBar.tintColor = .abankTextPrimary
        present(nav, animated: true)
    }

    private func reloadData() {
        pageData = FinanceLedgerStore.shared.loanRepaymentPageData(
            contractId: contractId,
            filter: filter
        )
        filterBar.configure(range: filter.quickRange)
        tableView.reloadData()
        updateEmptyState()
    }

    private func updateEmptyState() {
        let isEmpty: Bool
        switch selectedTab {
        case .plan: isEmpty = pageData.planItems.isEmpty
        case .detail: isEmpty = pageData.detailItems.isEmpty
        }
        emptyLabel.isHidden = !isEmpty
    }

    /// 设计稿参考日，保证「近三月」能覆盖截图中的计划/明细
    private static var referenceDate: Date {
        LoanRepaymentFilter.date(from: "2026-08-20") ?? Date()
    }

    private static let defaultCustomStart = "2025-08-20"
    private static let defaultCustomEnd = "2026-08-20"

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
            cell.configure(plan: item, isLast: indexPath.row == pageData.planItems.count - 1)
        case .detail:
            let item = pageData.detailItems[indexPath.row]
            cell.configure(detail: item, isLast: indexPath.row == pageData.detailItems.count - 1)
        }
        return cell
    }
}
