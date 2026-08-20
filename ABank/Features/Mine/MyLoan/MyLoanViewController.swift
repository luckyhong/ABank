//
//  MyLoanViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class MyLoanViewController: BaseViewController {

    private var pageData: MyLoanPageData
    private var isAmountVisible = true

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let summaryView = MyLoanSummaryView()
    private let actionGrid = MyLoanActionGridView()
    private let contractSection = MyLoanContractSectionView()
    private let tipLabel = UILabel()

    init() {
        self.pageData = FinanceLedgerStore.shared.myLoanPageData()
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "我的贷款"
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.tintColor = .abankTextPrimary

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
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

        summaryView.onRepaymentDetailTapped = { [weak self] in self?.showToast("应还详情") }
        summaryView.onEyeTapped = { [weak self] in
            // summaryView 内部已切换；此处同步 VC 状态，供 reload 后恢复
            self?.isAmountVisible.toggle()
        }
        actionGrid.onItemTapped = { [weak self] index in
            let titles = ["待办任务", "进度查询", "贷款续贷", "结清证明"]
            self?.showToast(titles[safe: index] ?? "功能")
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
        summaryView.setAmountVisible(isAmountVisible)
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
