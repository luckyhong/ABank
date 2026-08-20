//
//  IncomeExpenseDatePickerSheet.swift
//  ABank
//

import UIKit
import SnapKit

final class IncomeExpenseDatePickerSheet: UIView, UIPickerViewDataSource, UIPickerViewDelegate {

    var onConfirm: ((IncomeExpenseDateMode) -> Void)?
    var onCancel: (() -> Void)?
    var onLegacyDetailTapped: (() -> Void)?

    private let dimView = UIView()
    private let panel = UIView()
    private let cancelButton = UIButton(type: .system)
    private let confirmButton = UIButton(type: .system)
    private let tipBar = UIView()
    private let tipLabel = UILabel()
    private let tipLinkButton = UIButton(type: .system)

    private let monthTabButton = UIButton(type: .system)
    private let customTabButton = UIButton(type: .system)
    private let tabUnderline = UIView()

    private let monthPicker = UIPickerView()
    private let customContainer = UIView()
    private let startDateRow = IncomeExpenseDateRowView(title: "开始日期")
    private let endDateRow = IncomeExpenseDateRowView(title: "结束日期")
    private let customPicker = UIDatePicker()

    private var years: [Int] = []
    private var isMonthMode = true
    private var editingCustomStart = true
    private var customStartDate = Date()
    private var customEndDate = Date()
    private var pendingYear = 2026
    private var pendingMonth = 8

    private let accent = UIColor.abankOrange
    private let tipBackground = UIColor(red: 255 / 255, green: 250 / 255, blue: 235 / 255, alpha: 1)
    private let tipLinkColor = UIColor(red: 210 / 255, green: 140 / 255, blue: 40 / 255, alpha: 1)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupYears()
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func present(in host: UIView, mode: IncomeExpenseDateMode) {
        apply(mode: mode)
        frame = host.bounds
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.addSubview(self)

        layoutIfNeeded()
        panel.transform = CGAffineTransform(translationX: 0, y: panel.bounds.height + 40)
        dimView.alpha = 0
        UIView.animate(withDuration: 0.28, delay: 0, options: .curveEaseOut) {
            self.panel.transform = .identity
            self.dimView.alpha = 1
        }
    }

    // MARK: - Setup

    private func setupYears() {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        years = Array(2021...max(currentYear, 2026))
    }

    private func setupUI() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancelTapped)))

        panel.backgroundColor = .white
        panel.layer.cornerRadius = 12
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        panel.clipsToBounds = true

        cancelButton.setTitle("取消", for: .normal)
        cancelButton.setTitleColor(.abankTextPrimary, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        confirmButton.setTitle("确定", for: .normal)
        confirmButton.setTitleColor(accent, for: .normal)
        confirmButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        tipBar.backgroundColor = tipBackground
        tipLabel.font = .systemFont(ofSize: 12)
        tipLabel.textColor = .abankTextSecondary
        tipLabel.numberOfLines = 1
        tipLabel.text = "若查询时间为2021年1月之前，请"
        tipLinkButton.setTitle("点击此处", for: .normal)
        tipLinkButton.setTitleColor(tipLinkColor, for: .normal)
        tipLinkButton.titleLabel?.font = .systemFont(ofSize: 12)
        tipLinkButton.addTarget(self, action: #selector(legacyTapped), for: .touchUpInside)
        let underlineAttr: [NSAttributedString.Key: Any] = [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .foregroundColor: tipLinkColor,
            .font: UIFont.systemFont(ofSize: 12)
        ]
        tipLinkButton.setAttributedTitle(NSAttributedString(string: "点击此处", attributes: underlineAttr), for: .normal)

        let tipSuffix = UILabel()
        tipSuffix.font = .systemFont(ofSize: 12)
        tipSuffix.textColor = .abankTextSecondary
        tipSuffix.text = "跳转至明细"

        configureTab(monthTabButton, title: "月份选择", selected: true)
        configureTab(customTabButton, title: "自定义", selected: false)
        monthTabButton.addTarget(self, action: #selector(monthTabTapped), for: .touchUpInside)
        customTabButton.addTarget(self, action: #selector(customTabTapped), for: .touchUpInside)
        tabUnderline.backgroundColor = accent
        tabUnderline.layer.cornerRadius = 1

        monthPicker.dataSource = self
        monthPicker.delegate = self

        customPicker.datePickerMode = .date
        if #available(iOS 13.4, *) {
            customPicker.preferredDatePickerStyle = .wheels
        }
        customPicker.locale = Locale(identifier: "zh_CN")
        customPicker.minimumDate = date(year: 2021, month: 1, day: 1)
        customPicker.maximumDate = date(year: max(years.last ?? 2026, 2026), month: 12, day: 31)
        customPicker.addTarget(self, action: #selector(customPickerChanged), for: .valueChanged)

        startDateRow.onTapped = { [weak self] in self?.selectCustomField(isStart: true) }
        endDateRow.onTapped = { [weak self] in self?.selectCustomField(isStart: false) }

        addSubview(dimView)
        addSubview(panel)
        [cancelButton, confirmButton, tipBar, monthTabButton, customTabButton, tabUnderline,
         monthPicker, customContainer].forEach { panel.addSubview($0) }
        tipBar.addSubview(tipLabel)
        tipBar.addSubview(tipLinkButton)
        tipBar.addSubview(tipSuffix)
        customContainer.addSubview(startDateRow)
        customContainer.addSubview(endDateRow)
        customContainer.addSubview(customPicker)
        customContainer.isHidden = true

        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        panel.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        cancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(14)
            make.height.equalTo(28)
        }
        confirmButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(cancelButton)
        }
        tipBar.snp.makeConstraints { make in
            make.top.equalTo(cancelButton.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(32)
        }
        tipLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        tipLinkButton.snp.makeConstraints { make in
            make.leading.equalTo(tipLabel.snp.trailing).offset(2)
            make.centerY.equalToSuperview()
        }
        tipSuffix.snp.makeConstraints { make in
            make.leading.equalTo(tipLinkButton.snp.trailing).offset(2)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }

        monthTabButton.snp.makeConstraints { make in
            make.top.equalTo(tipBar.snp.bottom).offset(8)
            make.trailing.equalTo(panel.snp.centerX).offset(-20)
            make.height.equalTo(40)
        }
        customTabButton.snp.makeConstraints { make in
            make.centerY.equalTo(monthTabButton)
            make.leading.equalTo(panel.snp.centerX).offset(20)
            make.height.equalTo(40)
        }
        tabUnderline.snp.makeConstraints { make in
            make.top.equalTo(monthTabButton.snp.bottom)
            make.centerX.equalTo(monthTabButton)
            make.width.equalTo(56)
            make.height.equalTo(2)
        }

        monthPicker.snp.makeConstraints { make in
            make.top.equalTo(tabUnderline.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(216)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
        }
        customContainer.snp.makeConstraints { make in
            make.top.equalTo(tabUnderline.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
        }
        startDateRow.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        endDateRow.snp.makeConstraints { make in
            make.top.equalTo(startDateRow.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        customPicker.snp.makeConstraints { make in
            make.top.equalTo(endDateRow.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(180)
            make.bottom.equalToSuperview().offset(-8)
        }
    }

    private func configureTab(_ button: UIButton, title: String, selected: Bool) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: selected ? .medium : .regular)
        button.setTitleColor(selected ? .abankTextPrimary : .abankTextSecondary, for: .normal)
    }

    // MARK: - Apply / State

    private func apply(mode: IncomeExpenseDateMode) {
        switch mode {
        case .month(let month):
            isMonthMode = true
            let parts = month.split(separator: "-")
            pendingYear = Int(parts.first.map(String.init) ?? "2026") ?? 2026
            pendingMonth = Int(parts.last.map(String.init) ?? "8") ?? 8
            if let start = date(year: pendingYear, month: pendingMonth, day: 1) {
                customStartDate = start
                customEndDate = endOfMonth(for: start)
            }
        case .custom(let start, let end):
            isMonthMode = false
            customStartDate = parseDate(start) ?? Date()
            customEndDate = parseDate(end) ?? Date()
            pendingYear = Calendar.current.component(.year, from: customStartDate)
            pendingMonth = Calendar.current.component(.month, from: customStartDate)
        }
        refreshTabUI()
        reloadMonthPickerSelection()
        refreshCustomRows()
        selectCustomField(isStart: true, animated: false)
    }

    private func refreshTabUI() {
        configureTab(monthTabButton, title: "月份选择", selected: isMonthMode)
        configureTab(customTabButton, title: "自定义", selected: !isMonthMode)
        monthPicker.isHidden = !isMonthMode
        customContainer.isHidden = isMonthMode
        tabUnderline.snp.remakeConstraints { make in
            make.top.equalTo((isMonthMode ? monthTabButton : customTabButton).snp.bottom)
            make.centerX.equalTo(isMonthMode ? monthTabButton : customTabButton)
            make.width.equalTo(56)
            make.height.equalTo(2)
        }
        UIView.animate(withDuration: 0.2) { self.layoutIfNeeded() }
    }

    private func reloadMonthPickerSelection() {
        monthPicker.reloadAllComponents()
        let yearIndex = years.firstIndex(of: pendingYear) ?? (years.count - 1)
        monthPicker.selectRow(yearIndex, inComponent: 0, animated: false)
        monthPicker.selectRow(max(0, min(11, pendingMonth - 1)), inComponent: 1, animated: false)
    }

    private func refreshCustomRows() {
        startDateRow.configure(dateText: formatDate(customStartDate), selected: editingCustomStart)
        endDateRow.configure(dateText: formatDate(customEndDate), selected: !editingCustomStart)
    }

    private func selectCustomField(isStart: Bool, animated: Bool = true) {
        editingCustomStart = isStart
        customPicker.date = isStart ? customStartDate : customEndDate
        refreshCustomRows()
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismiss()
        onCancel?()
    }

    @objc private func confirmTapped() {
        let mode: IncomeExpenseDateMode
        if isMonthMode {
            let yearRow = monthPicker.selectedRow(inComponent: 0)
            let monthRow = monthPicker.selectedRow(inComponent: 1)
            let year = years[safe: yearRow] ?? pendingYear
            let month = monthRow + 1
            mode = .month(String(format: "%04d-%02d", year, month))
        } else {
            if customStartDate > customEndDate {
                swap(&customStartDate, &customEndDate)
            }
            mode = .custom(start: formatDate(customStartDate), end: formatDate(customEndDate))
        }
        let callback = onConfirm
        dismiss {
            callback?(mode)
        }
    }

    @objc private func monthTabTapped() {
        isMonthMode = true
        refreshTabUI()
    }

    @objc private func customTabTapped() {
        isMonthMode = false
        refreshTabUI()
    }

    @objc private func customPickerChanged() {
        if editingCustomStart {
            customStartDate = customPicker.date
        } else {
            customEndDate = customPicker.date
        }
        refreshCustomRows()
    }

    @objc private func legacyTapped() {
        onLegacyDetailTapped?()
    }

    private func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.22, animations: {
            self.panel.transform = CGAffineTransform(translationX: 0, y: self.panel.bounds.height + 40)
            self.dimView.alpha = 0
        }, completion: { _ in
            self.removeFromSuperview()
            completion?()
        })
    }

    // MARK: - Helpers

    private func date(year: Int, month: Int, day: Int) -> Date? {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))
    }

    private func endOfMonth(for date: Date) -> Date {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date))
        else { return date }
        return calendar.date(byAdding: .day, value: range.count - 1, to: start) ?? date
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func parseDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }

    // MARK: - UIPickerView

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 2 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        component == 0 ? years.count : 12
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 20)
        label.textColor = .abankTextPrimary
        if component == 0 {
            label.text = "\(years[safe: row] ?? 2026)"
        } else {
            label.text = "\(row + 1)"
        }
        return label
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { 40 }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            pendingYear = years[safe: row] ?? pendingYear
        } else {
            pendingMonth = row + 1
        }
    }
}

// MARK: - Custom date row

private final class IncomeExpenseDateRowView: UIControl {
    var onTapped: (() -> Void)?

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let bottomLine = UIView()

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.textColor = .abankTextPrimary

        valueLabel.font = .systemFont(ofSize: 15)
        valueLabel.textColor = .abankTextSecondary
        valueLabel.textAlignment = .right

        bottomLine.backgroundColor = .abankSeparator

        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(bottomLine)
        titleLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        valueLabel.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(12)
        }
        bottomLine.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(dateText: String, selected: Bool) {
        valueLabel.text = dateText
        valueLabel.textColor = selected ? .abankOrange : .abankTextSecondary
        titleLabel.textColor = selected ? .abankTextPrimary : .abankTextSecondary
    }

    @objc private func tapped() { onTapped?() }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
