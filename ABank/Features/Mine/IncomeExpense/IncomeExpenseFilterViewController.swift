//
//  IncomeExpenseFilterViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class IncomeExpenseFilterViewController: BaseViewController {

    var onConfirm: ((IncomeExpenseAdvancedFilter) -> Void)?

    private var filter: IncomeExpenseAdvancedFilter

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let footerView = UIView()
    private let resetButton = UIButton(type: .system)
    private let confirmButton = UIButton(type: .system)

    private let amountTitleLabel = UILabel()
    private let minAmountField = UITextField()
    private let maxAmountField = UITextField()
    private let amountDashLabel = UILabel()

    private let categoryTitleLabel = UILabel()
    private var groupViews: [IncomeExpenseCategoryGroupView] = []

    private let tagSelectedBackground = UIColor(red: 255 / 255, green: 243 / 255, blue: 224 / 255, alpha: 1)
    private let tagNormalBackground = UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1)
    private let confirmOrange = UIColor(red: 255 / 255, green: 149 / 255, blue: 0 / 255, alpha: 1)

    init(filter: IncomeExpenseAdvancedFilter) {
        self.filter = filter
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "筛选"
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

        scrollView.keyboardDismissMode = .onDrag
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false

        amountTitleLabel.text = "金额"
        amountTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        amountTitleLabel.textColor = .abankTextPrimary

        configureAmountField(minAmountField, placeholder: "最小金额")
        configureAmountField(maxAmountField, placeholder: "最大金额")
        if let min = filter.minAmount {
            minAmountField.text = Self.amountText(min)
        }
        if let max = filter.maxAmount {
            maxAmountField.text = Self.amountText(max)
        }

        amountDashLabel.text = "—"
        amountDashLabel.font = .systemFont(ofSize: 14)
        amountDashLabel.textColor = .abankTextTertiary
        amountDashLabel.textAlignment = .center

        categoryTitleLabel.text = "分类"
        categoryTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        categoryTitleLabel.textColor = .abankTextPrimary

        footerView.backgroundColor = .white
        footerView.layer.shadowColor = UIColor.black.cgColor
        footerView.layer.shadowOpacity = 0.06
        footerView.layer.shadowOffset = CGSize(width: 0, height: -2)
        footerView.layer.shadowRadius = 4

        resetButton.setTitle("重置", for: .normal)
        resetButton.setTitleColor(confirmOrange, for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        resetButton.backgroundColor = .white
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)

        confirmButton.setTitle("确定", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        confirmButton.backgroundColor = confirmOrange
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        let footerDivider = UIView()
        footerDivider.backgroundColor = .abankSeparator
        let midDivider = UIView()
        midDivider.backgroundColor = .abankSeparator

        view.addSubview(scrollView)
        view.addSubview(footerView)
        scrollView.addSubview(contentView)
        footerView.addSubview(resetButton)
        footerView.addSubview(confirmButton)
        footerView.addSubview(footerDivider)
        footerView.addSubview(midDivider)

        contentView.addSubview(amountTitleLabel)
        contentView.addSubview(minAmountField)
        contentView.addSubview(amountDashLabel)
        contentView.addSubview(maxAmountField)
        contentView.addSubview(categoryTitleLabel)

        groupViews = IncomeExpenseFilterCatalog.allGroups.map { group in
            let view = IncomeExpenseCategoryGroupView(
                group: group,
                selectedBackground: tagSelectedBackground,
                normalBackground: tagNormalBackground,
                accent: confirmOrange
            )
            view.selectedIds = filter.selectedCategoryIds
            view.onSelectionChanged = { [weak self] ids in
                self?.filter.selectedCategoryIds = ids
                self?.syncGroupSelections()
            }
            contentView.addSubview(view)
            return view
        }

        footerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        resetButton.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
            make.height.equalTo(50)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        confirmButton.snp.makeConstraints { make in
            make.trailing.top.equalToSuperview()
            make.leading.equalTo(resetButton.snp.trailing)
            make.height.equalTo(50)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        footerDivider.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(0.5)
        }
        midDivider.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalTo(resetButton)
            make.centerX.equalToSuperview()
            make.width.equalTo(0.5)
        }

        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(footerView.snp.top)
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        amountTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(16)
        }
        minAmountField.snp.makeConstraints { make in
            make.top.equalTo(amountTitleLabel.snp.bottom).offset(14)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(40)
        }
        amountDashLabel.snp.makeConstraints { make in
            make.centerY.equalTo(minAmountField)
            make.leading.equalTo(minAmountField.snp.trailing).offset(10)
            make.width.equalTo(16)
        }
        maxAmountField.snp.makeConstraints { make in
            make.centerY.height.equalTo(minAmountField)
            make.leading.equalTo(amountDashLabel.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-16)
            make.width.equalTo(minAmountField)
        }

        categoryTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(minAmountField.snp.bottom).offset(28)
            make.leading.equalToSuperview().offset(16)
        }

        var previous: UIView = categoryTitleLabel
        for (index, groupView) in groupViews.enumerated() {
            groupView.snp.makeConstraints { make in
                make.top.equalTo(previous.snp.bottom).offset(index == 0 ? 16 : 22)
                make.leading.trailing.equalToSuperview().inset(16)
                if index == groupViews.count - 1 {
                    make.bottom.equalToSuperview().offset(-24)
                }
            }
            previous = groupView
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingTap))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func configureAmountField(_ field: UITextField, placeholder: String) {
        field.placeholder = placeholder
        field.font = .systemFont(ofSize: 14)
        field.textColor = .abankTextPrimary
        field.keyboardType = .decimalPad
        field.backgroundColor = tagNormalBackground
        field.layer.cornerRadius = 4
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        field.leftViewMode = .always
        field.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        field.rightViewMode = .always
        field.delegate = self
    }

    private func syncGroupSelections() {
        groupViews.forEach { $0.selectedIds = filter.selectedCategoryIds }
    }

    private func readAmountFields() {
        filter.minAmount = Self.parseAmount(minAmountField.text)
        filter.maxAmount = Self.parseAmount(maxAmountField.text)
        if let min = filter.minAmount, let max = filter.maxAmount, min > max {
            swap(&filter.minAmount, &filter.maxAmount)
            minAmountField.text = filter.minAmount.map { Self.amountText($0) }
            maxAmountField.text = filter.maxAmount.map { Self.amountText($0) }
        }
    }

    private static func parseAmount(_ text: String?) -> Double? {
        guard let raw = text?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        return Double(raw)
    }

    private static func amountText(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }

    @objc private func backTapped() {
        dismissFilter()
    }

    @objc private func resetTapped() {
        filter = .empty
        minAmountField.text = nil
        maxAmountField.text = nil
        syncGroupSelections()
    }

    @objc private func confirmTapped() {
        view.endEditing(true)
        readAmountFields()
        let callback = onConfirm
        dismissFilter {
            callback?(self.filter)
        }
    }

    private func dismissFilter(completion: (() -> Void)? = nil) {
        if presentingViewController != nil || navigationController?.presentingViewController != nil {
            dismiss(animated: true, completion: completion)
        } else {
            navigationController?.popViewController(animated: true)
            completion?()
        }
    }

    @objc private func endEditingTap() {
        view.endEditing(true)
    }
}

extension IncomeExpenseFilterViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty { return true }
        let allowed = CharacterSet(charactersIn: "0123456789.")
        guard string.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return false }
        let current = textField.text ?? ""
        let next = (current as NSString).replacingCharacters(in: range, with: string)
        if next.filter({ $0 == "." }).count > 1 { return false }
        if let dot = next.firstIndex(of: ".") {
            let decimals = next[next.index(after: dot)...]
            if decimals.count > 2 { return false }
        }
        return next.count <= 12
    }
}

// MARK: - Category group

private final class IncomeExpenseCategoryGroupView: UIView {

    var onSelectionChanged: ((Set<String>) -> Void)?

    var selectedIds: Set<String> = [] {
        didSet { refreshTags() }
    }

    private let group: IncomeExpenseCategoryGroup
    private let titleLabel = UILabel()
    private let flowView = IncomeExpenseTagFlowView()
    private let selectedBackground: UIColor
    private let normalBackground: UIColor
    private let accent: UIColor

    init(
        group: IncomeExpenseCategoryGroup,
        selectedBackground: UIColor,
        normalBackground: UIColor,
        accent: UIColor
    ) {
        self.group = group
        self.selectedBackground = selectedBackground
        self.normalBackground = normalBackground
        self.accent = accent
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        titleLabel.text = group.title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .abankTextPrimary

        flowView.onTagTapped = { [weak self] id in
            self?.toggle(id: id)
        }

        addSubview(titleLabel)
        addSubview(flowView)
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }
        flowView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }
        refreshTags()
    }

    private func refreshTags() {
        let items = group.options.map { option -> IncomeExpenseTagFlowView.Item in
            let selected = isOptionSelected(option)
            return .init(
                id: option.id,
                title: option.title,
                selected: selected,
                selectedBackground: selectedBackground,
                normalBackground: normalBackground,
                selectedTextColor: accent,
                normalTextColor: .abankTextPrimary
            )
        }
        flowView.configure(items: items)
    }

    private func isOptionSelected(_ option: IncomeExpenseCategoryOption) -> Bool {
        if option.isAll {
            let concrete = Set(group.options.filter { !$0.isAll }.map(\.id))
            return selectedIds.contains(option.id)
                || (!concrete.isEmpty && concrete.isSubset(of: selectedIds))
        }
        return selectedIds.contains(option.id)
    }

    private func toggle(id: String) {
        guard let option = group.options.first(where: { $0.id == id }) else { return }
        var next = selectedIds
        let concreteIds = Set(group.options.filter { !$0.isAll }.map(\.id))
        let allId = group.options.first(where: \.isAll)?.id

        if option.isAll {
            if concreteIds.isSubset(of: next) || next.contains(option.id) {
                next.subtract(concreteIds)
                if let allId { next.remove(allId) }
            } else {
                next.formUnion(concreteIds)
                if let allId { next.insert(allId) }
            }
        } else {
            if next.contains(option.id) {
                next.remove(option.id)
            } else {
                next.insert(option.id)
            }
            if let allId {
                if concreteIds.isSubset(of: next) {
                    next.insert(allId)
                } else {
                    next.remove(allId)
                }
            }
        }

        selectedIds = next
        onSelectionChanged?(next)
    }
}

// MARK: - Tag flow layout

private final class IncomeExpenseTagFlowView: UIView {

    struct Item {
        let id: String
        let title: String
        let selected: Bool
        let selectedBackground: UIColor
        let normalBackground: UIColor
        let selectedTextColor: UIColor
        let normalTextColor: UIColor
    }

    var onTagTapped: ((String) -> Void)?

    private var buttons: [UIButton] = []
    private var items: [Item] = []
    private var heightConstraint: Constraint?

    private let rowHeight: CGFloat = 34
    private let spacing: CGFloat = 10
    private let horizontalSpacing: CGFloat = 10

    override init(frame: CGRect) {
        super.init(frame: frame)
        snp.makeConstraints { make in
            heightConstraint = make.height.equalTo(rowHeight).constraint
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(items: [Item]) {
        self.items = items
        buttons.forEach { $0.removeFromSuperview() }
        buttons = items.enumerated().map { index, item in
            let button = UIButton(type: .system)
            button.setTitle(item.title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13)
            button.setTitleColor(item.selected ? item.selectedTextColor : item.normalTextColor, for: .normal)
            button.backgroundColor = item.selected ? item.selectedBackground : item.normalBackground
            button.layer.cornerRadius = 4
            button.layer.borderWidth = item.selected ? 0.5 : 0
            button.layer.borderColor = item.selected ? item.selectedTextColor.cgColor : UIColor.clear.cgColor
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
            button.tag = index
            button.addTarget(self, action: #selector(tagTapped(_:)), for: .touchUpInside)
            addSubview(button)
            return button
        }
        setNeedsLayout()
        layoutIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !buttons.isEmpty else { return }

        var x: CGFloat = 0
        var y: CGFloat = 0
        let maxWidth = bounds.width

        for button in buttons {
            let title = button.title(for: .normal) ?? ""
            let textWidth = (title as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 13)]).width
            let width = ceil(textWidth + 24)
            if x > 0, x + width > maxWidth {
                x = 0
                y += rowHeight + spacing
            }
            button.frame = CGRect(x: x, y: y, width: width, height: rowHeight)
            x += width + horizontalSpacing
        }

        let totalHeight = y + rowHeight
        heightConstraint?.update(offset: totalHeight)
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: heightConstraint?.layoutConstraints.first?.constant ?? rowHeight)
    }

    @objc private func tagTapped(_ sender: UIButton) {
        guard items.indices.contains(sender.tag) else { return }
        onTagTapped?(items[sender.tag].id)
    }
}
