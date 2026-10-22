//
//  MonthlyBillViewController.swift
//  ABank
//

import UIKit
import SnapKit

/// 月度账单 / 收支分析：月份汇总、分类占比、近 6 月趋势与主要收支，均由共享账本派生。
final class MonthlyBillViewController: BankingDataViewController {

    private let store: FinanceLedgerStore
    private let accountFilter: IncomeExpenseAccountFilter
    private let pageTitle: String
    private var month: String
    private var direction: LedgerTransactionDirection = .expense
    private var hidesAmounts = false
    private var data: MonthlyBillData

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let monthSwitcher = MonthlyBillMonthSwitcher()
    private let summaryView = MonthlyBillSummaryView()
    private let directionControl = UISegmentedControl(items: ["支出", "收入"])
    private let categoryCard = MonthlyBillSectionCard(title: "分类构成")
    private let trendCard = MonthlyBillSectionCard(title: "收支趋势")
    private let trendView = MonthlyBillTrendView()
    private let topCard = MonthlyBillSectionCard(title: "主要支出")
    private let noticeLabel = UILabel()

    init(month: String? = nil, accountFilter: IncomeExpenseAccountFilter = .all,
         title: String = "月度账单", store: FinanceLedgerStore? = nil) {
        let store = store ?? .shared
        self.store = store
        self.accountFilter = accountFilter
        self.pageTitle = title
        let initialMonth = month ?? store.defaultBillMonth
        self.month = initialMonth
        self.data = store.monthlyBill(month: initialMonth, accountFilter: accountFilter)
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = pageTitle
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.tintColor = .abankTextPrimary
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.abankTextPrimary,
                                          .font: UIFont.systemFont(ofSize: 17, weight: .semibold)]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationItem.backButtonTitle = ""
        updateEyeItem()
    }

    override func setupUI() {
        view.backgroundColor = .abankBackground
        scrollView.alwaysBounceVertical = true
        contentStack.axis = .vertical
        contentStack.spacing = 12
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        contentStack.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(UIEdgeInsets(top: 0, left: Spacing.md, bottom: Spacing.lg, right: Spacing.md))
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-Spacing.md * 2)
        }

        directionControl.selectedSegmentIndex = 0
        directionControl.selectedSegmentTintColor = .abankTeal
        directionControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        directionControl.accessibilityIdentifier = "bill.direction"
        directionControl.addTarget(self, action: #selector(directionChanged), for: .valueChanged)
        directionControl.snp.makeConstraints { $0.height.equalTo(34) }

        let legend = MonthlyBillLegendView()
        let legendRow = UIView()
        legendRow.addSubview(legend)
        legend.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(Spacing.md)
        }
        trendCard.accessoryLabel.text = "点击柱状图切换月份"
        trendCard.setRows([legendRow, trendView])

        noticeLabel.text = "统计仅含本机模拟账本中「计入收支」的交易，可在收支详情中调整分类或是否计入收支。数据仅供演示参考。"
        noticeLabel.font = .systemFont(ofSize: 12)
        noticeLabel.textColor = .abankTextTertiary
        noticeLabel.numberOfLines = 0

        [monthSwitcher, summaryView, directionControl, categoryCard, topCard, trendCard, noticeLabel].forEach {
            contentStack.addArrangedSubview($0)
        }

        monthSwitcher.onPrevious = { [weak self] in self?.shiftMonth(-1) }
        monthSwitcher.onNext = { [weak self] in self?.shiftMonth(1) }
        trendView.onSelectMonth = { [weak self] month in self?.select(month: month) }

        applyData()
    }

    override func refreshBankingData() {
        data = store.monthlyBill(month: month, accountFilter: accountFilter)
        applyData()
    }

    // MARK: - 状态

    private func shiftMonth(_ offset: Int) {
        guard let target = store.dates.month(month, offsetBy: offset) else { return }
        select(month: target)
    }

    private func select(month target: String) {
        let range = store.billMonthRange()
        guard target != month, target >= range.earliest, target <= range.latest else { return }
        month = target
        refreshBankingData()
        scrollView.setContentOffset(CGPoint(x: 0, y: -scrollView.adjustedContentInset.top), animated: true)
    }

    @objc private func directionChanged() {
        direction = directionControl.selectedSegmentIndex == 0 ? .expense : .income
        applyData()
    }

    @objc private func eyeTapped() {
        hidesAmounts.toggle()
        updateEyeItem()
        applyData()
    }

    private func updateEyeItem() {
        let item = UIBarButtonItem(
            image: UIImage.abankAsset(hidesAmounts ? "abc_mine_detail_amount_eye_closed" : "abc_mine_detail_amount_eye_open",
                                      fallback: hidesAmounts ? "eye.slash" : "eye", renderingMode: .alwaysTemplate, pointSize: 16),
            style: .plain, target: self, action: #selector(eyeTapped))
        item.accessibilityLabel = hidesAmounts ? "显示金额" : "隐藏金额"
        item.accessibilityIdentifier = "bill.amountVisibility"
        navigationItem.rightBarButtonItem = item
    }

    // MARK: - 展示

    private func applyData() {
        let range = store.billMonthRange()
        monthSwitcher.configure(
            title: store.dates.monthTitle(month),
            subtitle: data.accountTitle,
            canGoPrevious: month > range.earliest,
            canGoNext: month < range.latest
        )
        summaryView.configure(with: data, hidden: hidesAmounts)

        let isExpense = direction == .expense
        let color = isExpense ? MonthlyBillFormat.expenseColor : MonthlyBillFormat.incomeColor
        let total = isExpense ? data.expenseInCents : data.incomeInCents
        categoryCard.titleLabel.text = isExpense ? "支出构成" : "收入构成"
        categoryCard.accessoryLabel.text = "合计 " + MonthlyBillFormat.amount(total, hidden: hidesAmounts)
        let stats = data.categories(for: direction)
        var categoryRows: [UIView] = stats.map { stat -> UIView in
            let row = MonthlyBillCategoryRow(stat: stat, color: color, hidden: hidesAmounts)
            row.addAction(UIAction { [weak self] _ in self?.openCategory(stat.categoryId) }, for: .touchUpInside)
            return row
        }
        if categoryRows.isEmpty {
            categoryRows = [MonthlyBillSectionCard.placeholder(isExpense ? "本月暂无计入收支的支出" : "本月暂无计入收支的收入")]
        }
        categoryCard.setRows(categoryRows)

        topCard.titleLabel.text = isExpense ? "主要支出" : "主要收入"
        topCard.accessoryLabel.text = "按金额排序"
        var topRows: [UIView] = []
        for (index, tx) in data.topTransactions(for: direction).enumerated() {
            let row = MonthlyBillTopRow(rank: index + 1, transaction: tx,
                                        accountLabel: store.accountCardLabel(for: tx.accountId), hidden: hidesAmounts)
            row.accessibilityIdentifier = "bill.top.\(index)"
            row.addAction(UIAction { [weak self] _ in self?.openDetail(tx) }, for: .touchUpInside)
            topRows.append(row)
        }
        topCard.setRows(topRows.isEmpty ? [MonthlyBillSectionCard.placeholder("暂无记录")] : topRows)

        trendView.configure(points: data.trend, selectedMonth: month, hidesAmounts: hidesAmounts)
    }

    // MARK: - 跳转

    /// 进入收支列表并带上月份、账户和分类，列表与账单使用同一筛选口径。
    private func openCategory(_ categoryId: String) {
        var query = IncomeExpenseQuery(dateMode: .month(month), accountFilter: accountFilter)
        query.advancedFilter.selectedCategoryIds = [categoryId]
        navigationController?.pushViewController(IncomeExpenseViewController(query: query), animated: true)
    }

    private func openDetail(_ transaction: LedgerTransaction) {
        navigationController?.pushViewController(IncomeExpenseDetailViewController(transaction: transaction), animated: true)
    }
}
