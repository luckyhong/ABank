import UIKit
import SnapKit

final class LedgerAnalysisViewController: TransferFlowViewController {
    private var query: IncomeExpenseQuery
    private let store = FinanceLedgerStore.shared
    init(query: IncomeExpenseQuery = IncomeExpenseQuery(dateMode: .month(BankingDateContext.system.previousMonth))) {
        self.query = query
        super.init(nibName: nil, bundle: nil); hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func setupUI() { super.setupUI(); title = "月度账单" }
    override func setupNavigationBar() {
        super.setupNavigationBar()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "导出", style: .plain, target: self, action: #selector(exportStatement))
    }
    override func refreshBankingData() {
        guard isViewLoaded else { return }
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let page = store.incomeExpensePageData(query: query)
        let result = store.analysis(query: query)
        let month = UIButton(type: .system)
        month.setTitle(query.filterBarMonthText + "  ", for: .normal)
        month.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        month.semanticContentAttribute = .forceRightToLeft
        month.titleLabel?.font = .preferredFont(forTextStyle: .headline); month.tintColor = .abankTextPrimary
        month.contentHorizontalAlignment = .leading; month.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44) }
        month.accessibilityIdentifier = "analysis.month"
        month.addAction(UIAction { [weak self] _ in self?.chooseMonth() }, for: .touchUpInside)
        contentStack.addArrangedSubview(month)
        addNotice(page.accountFilter + " · " + (LedgerBookCatalog.title(for: query.ledgerID) ?? "全部账本"))
        let income = metric("收入（元）", value: result.summary.income, color: .abankIncomeAmount)
        let expense = metric("支出（元）", value: result.summary.expense, color: .abankExpenseAmount)
        let metrics = UIStackView(arrangedSubviews: [income, expense]); metrics.distribution = .fillEqually; metrics.spacing = 16
        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory { metrics.axis = .vertical }
        let balance = BankingPageStyle.text("本期结余  " + (result.summary.income - result.summary.expense).abankPlainAmountString(), style: .subheadline, color: .abankTextSecondary)
        contentStack.addArrangedSubview(BankingPageStyle.surface([metrics, balance]))
        if result.categories.isEmpty {
            contentStack.addArrangedSubview(BankingPageStyle.empty("本期暂无计入收支的记录", detail: "可切换月份，或查看最近一笔交易所在月份。", actionTitle: "查看最近账单") { [weak self] in self?.showLatestMonth() })
        }
        addTrend()
        for direction in [LedgerTransactionDirection.expense, .income] {
            let categories = result.categories.filter { $0.direction == direction }
            guard !categories.isEmpty else { continue }
            contentStack.addArrangedSubview(BankingPageStyle.section(direction == .expense ? "支出去向" : "收入来源"))
            for category in categories {
                let row = LedgerCategoryRow(category: category)
                row.addAction(UIAction { [weak self] _ in
                    guard let self else { return }
                    var filter = self.query; filter.advancedFilter.selectedCategoryIds = [category.categoryID]
                    self.navigationController?.pushViewController(LedgerSearchViewController(query: filter), animated: true)
                }, for: .touchUpInside)
                contentStack.addArrangedSubview(row)
            }
        }
        if !result.majorTransactions.isEmpty {
            contentStack.addArrangedSubview(BankingPageStyle.section("主要收支"))
            for transaction in result.majorTransactions {
                let row = BenefitsRow(title: transaction.title, subtitle: transaction.datetimeText + " · " + transaction.signedAmountText, id: "analysis.transaction." + transaction.id, showsChevron: true)
                row.onTap = { [weak self] in self?.navigationController?.pushViewController(IncomeExpenseDetailViewController(transaction: transaction), animated: true) }
                contentStack.addArrangedSubview(row)
            }
        }
        addNotice("不计入收支的交易不参与统计；分类占比按各自收入或支出计算。")
        _ = addButton("查看本期明细", id: "analysis.search", primary: false) { [weak self] in
            guard let self else { return }; self.navigationController?.pushViewController(LedgerSearchViewController(query: self.query), animated: true)
        }
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory { refreshBankingData() }
    }
    private func metric(_ title: String, value: Double, color: UIColor) -> UIView {
        let amount = BankingPageStyle.text(value.abankPlainAmountString(), style: .title1, color: color)
        amount.font = UIFontMetrics(forTextStyle: .title1).scaledFont(for: .monospacedDigitSystemFont(ofSize: 27, weight: .medium))
        amount.numberOfLines = 1; amount.adjustsFontSizeToFitWidth = true; amount.minimumScaleFactor = 0.7
        let stack = UIStackView(arrangedSubviews: [BankingPageStyle.text(title, style: .subheadline, color: .abankTextSecondary), amount]); stack.axis = .vertical; stack.spacing = 8
        return stack
    }
    private func addTrend() {
        guard case .month(let month) = query.dateMode, let date = store.dates.date(from: month + "-01") else { return }
        let values: [(String, MonthlyFlowSummary)] = (-5...0).map { offset in
            let label = store.dates.string(from: store.dates.calendar.date(byAdding: .month, value: offset, to: date)!, format: "yyyy-MM")
            var filter = query; filter.dateMode = .month(label)
            return (label, store.analysis(query: filter).summary)
        }
        let trend = LedgerTrendView(values: values)
        trend.onSelect = { [weak self] month in self?.query.dateMode = .month(month); self?.refreshBankingData() }
        contentStack.addArrangedSubview(BankingPageStyle.surface([BankingPageStyle.section("近六个月收支"), trend]))
    }
    @objc private func exportStatement() { LedgerStatementSharing.present(query: query, from: self) }
    private func chooseMonth() {
        let sheet = IncomeExpenseDatePickerSheet()
        sheet.onConfirm = { [weak self] mode in self?.query.dateMode = mode; self?.refreshBankingData() }
        sheet.present(in: navigationController?.view ?? view, mode: query.dateMode)
    }
    private func showLatestMonth() {
        let latest = store.load().transactions.filter { $0.includeInFlow }.map(\.date).max()
        if let latest { query.dateMode = .month(String(latest.prefix(7))); refreshBankingData() }
    }
}

private final class LedgerCategoryRow: UIControl {
    private let line = UIStackView()
    init(category: LedgerCategoryTotal) {
        super.init(frame: .zero)
        backgroundColor = .white; layer.cornerRadius = 10
        let title = BankingPageStyle.text(IncomeExpenseFilterCatalog.title(for: category.categoryID) ?? "其他", style: .subheadline)
        let value = BankingPageStyle.text(category.amount.abankPlainAmountString() + "　" + String(Int((category.share * 100).rounded())) + "%", style: .subheadline)
        value.setContentCompressionResistancePriority(.required, for: .horizontal)
        line.addArrangedSubview(title); line.addArrangedSubview(value); line.spacing = 12
        let bar = UIProgressView(progressViewStyle: .bar); bar.progress = Float(category.share)
        bar.progressTintColor = category.direction == .income ? .abankIncomeAmount : .abankPrimaryDark; bar.trackTintColor = .abankBackground
        let stack = UIStackView(arrangedSubviews: [line, bar]); stack.axis = .vertical; stack.spacing = 12; stack.isUserInteractionEnabled = false
        addSubview(stack); stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        isAccessibilityElement = true; accessibilityTraits = .button; accessibilityLabel = (title.text ?? "") + "，" + (value.text ?? "")
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        line.axis = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
        line.alignment = line.axis == .vertical ? .leading : .fill
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

private final class LedgerTrendView: UIView {
    var onSelect: ((String) -> Void)?
    init(values: [(String, MonthlyFlowSummary)]) {
        super.init(frame: .zero)
        let maximum = max(1, values.flatMap { [$0.1.income, $0.1.expense] }.max() ?? 1)
        let columns = UIStackView(); columns.distribution = .fillEqually; columns.spacing = 8; columns.alignment = .bottom
        for (month, value) in values {
            let button = UIButton(type: .custom)
            button.accessibilityLabel = "\(month)，收入\(value.income.abankPlainAmountString())元，支出\(value.expense.abankPlainAmountString())元"
            button.addAction(UIAction { [weak self] _ in self?.onSelect?(month) }, for: .touchUpInside)
            let bars = UIStackView(); bars.spacing = 3; bars.alignment = .bottom; bars.distribution = .fillEqually; bars.isUserInteractionEnabled = false
            for (amount, color) in [(value.income, UIColor.abankIncomeAmount), (value.expense, UIColor.abankPrimaryDark)] {
                let bar = UIView(); bar.backgroundColor = color; bar.layer.cornerRadius = 2
                bar.snp.makeConstraints { $0.height.equalTo(amount == 0 ? 1 : max(3, 82 * amount / maximum)) }
                bars.addArrangedSubview(bar)
            }
            let label = BankingPageStyle.text(String(month.suffix(2)) + "月", style: .caption1, color: .abankTextSecondary); label.textAlignment = .center
            label.font = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: .systemFont(ofSize: 12), maximumPointSize: 18)
            label.numberOfLines = 1; label.adjustsFontSizeToFitWidth = true; label.minimumScaleFactor = 0.7
            button.addSubview(bars); button.addSubview(label)
            bars.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(6); $0.bottom.equalTo(label.snp.top).offset(-8); $0.height.equalTo(82) }
            label.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview() }
            button.snp.makeConstraints { $0.height.equalTo(112) }
            columns.addArrangedSubview(button)
        }
        let legend = BankingPageStyle.text("橙色：收入　绿色：支出 · 点击月份查看", style: .caption1, color: .abankTextSecondary)
        addSubview(columns); addSubview(legend)
        columns.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }
        legend.snp.makeConstraints { $0.top.equalTo(columns.snp.bottom).offset(14); $0.leading.trailing.bottom.equalToSuperview() }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
