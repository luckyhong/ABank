//
//  MyLoanViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class MyLoanViewController: BaseViewController {

    private var pageData: MyLoanPageData
    private let security: SecuritySettingsStore

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let summaryView = MyLoanSummaryView()
    private let actionGrid = MyLoanActionGridView()
    private let contractSection = MyLoanContractSectionView()
    private let tipLabel = UILabel()

    init(security: SecuritySettingsStore = .shared) {
        self.pageData = FinanceLedgerStore.shared.myLoanPageData()
        self.security = security
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
        NotificationCenter.default.addObserver(self, selector: #selector(securitySettingsDidChange),
                                               name: SecuritySettingsStore.didChangeNotification, object: security)
    }

    @objc private func securitySettingsDidChange() {
        guard isViewLoaded else { return }
        applyAmountVisibility()
    }

    private func applyAmountVisibility() {
        summaryView.setAmountVisible(!security.hidesAmounts)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "我的贷款"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.abankBackIndicator,
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "历史贷款",
            style: .plain,
            target: self,
            action: #selector(historyTapped)
        )
        navigationItem.rightBarButtonItem?.setTitleTextAttributes(
            [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.abankTextSecondary],
            for: .normal
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    override func setupUI() {
        view.backgroundColor = .abankBackground

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true

        tipLabel.font = .systemFont(ofSize: 12)
        tipLabel.textColor = .abankTextTertiary
        tipLabel.numberOfLines = 0

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        [summaryView, actionGrid, contractSection, tipLabel].forEach { contentView.addSubview($0) }

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        summaryView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        actionGrid.snp.makeConstraints { make in
            make.top.equalTo(summaryView.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }
        contractSection.snp.makeConstraints { make in
            make.top.equalTo(actionGrid.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
        }
        tipLabel.snp.makeConstraints { make in
            make.top.equalTo(contractSection.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.bottom.equalToSuperview().offset(-Spacing.pageBottom - 24)
        }

        summaryView.onRepaymentDetailTapped = { [weak self] in
            let controller = LoanDueViewController(period: .thisMonth)
            self?.navigationController?.pushViewController(controller, animated: true)
        }
        summaryView.onEyeTapped = { [weak self] in
            guard let self else { return }
            // 全局隐私设置：失败时保持原状态并提示
            if !self.security.setHidesAmounts(!self.security.hidesAmounts) {
                self.showToast(SecuritySettingsError.persistence.localizedDescription)
            }
            self.applyAmountVisibility()
        }
        actionGrid.onItemTapped = { [weak self] index in
            let titles = ["待办任务", "进度查询", "贷款续贷", "结清证明"]
            let controller: UIViewController
            switch index {
            case 0: controller = LoanTasksViewController()
            case 1: controller = LoanProgressListViewController()
            default:
                self?.showToast(titles[safe: index] ?? "功能")
                return
            }
            self?.navigationController?.pushViewController(controller, animated: true)
        }
        contractSection.onContractTapped = { [weak self] id in
            guard let self,
                  let contract = FinanceLedgerStore.shared.loanContract(id: id) else { return }
            let controller = LoanDetailViewController(contract: contract)
            self.navigationController?.pushViewController(controller, animated: true)
        }
        contractSection.onToggleDetail = { [weak self] id in
            FinanceLedgerStore.shared.toggleLoanDetailExpanded(id: id)
            self?.reloadData()
        }
        contractSection.onTaxInfoTapped = { [weak self] in
            self?.showToast("报税信息")
        }

        applyPageData()
    }

    private func reloadData() {
        pageData = FinanceLedgerStore.shared.myLoanPageData()
        applyPageData()
    }

    private func applyPageData() {
        summaryView.configure(
            monthlyDue: pageData.monthlyDue,
            unpaidPrincipal: pageData.totalUnpaidPrincipal,
            availableLimit: pageData.availableLimit
        )
        applyAmountVisibility()
        contractSection.configure(contracts: pageData.contracts)
        tipLabel.text = pageData.tip
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func historyTapped() { showToast("历史贷款") }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
