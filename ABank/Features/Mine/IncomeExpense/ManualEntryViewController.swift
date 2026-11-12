import UIKit
import SnapKit

final class ManualEntryViewController: TransferFlowViewController {
    private let entryID: String
    private let existing: LedgerTransaction?
    private let name = TransferInputRow("名称", placeholder: "例如：午餐、交通", id: "entry.title")
    private let amount = TransferInputRow("金额", placeholder: "0.00", id: "entry.amount", keyboard: .decimalPad)
    private let note = TransferInputRow("备注", placeholder: "选填，最多200字", id: "entry.note")
    private let direction = UISegmentedControl(items: ["支出", "收入"])
    private let datePicker = UIDatePicker()
    private let categoryButton = UIButton(type: .system)
    private let bookButton = UIButton(type: .system)
    private let purposeButton = UIButton(type: .system)
    private var purposeID: String?
    private let errorLabel = UILabel()
    private var categoryID: String
    private var bookID: String?
    var onSave: ((LedgerTransaction) -> Void)?

    init(transaction: LedgerTransaction? = nil) {
        existing = transaction
        purposeID = transaction?.purposeCategoryID
        entryID = transaction?.id ?? "manual_" + UUID().uuidString
        categoryID = transaction?.categoryId ?? "other_expense"
        bookID = transaction?.ledgerId
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = existing == nil ? "记一笔" : "编辑账单"
        addNotice("记录现金或其他账户收支，不影响银行卡余额")
        direction.selectedSegmentIndex = existing?.direction == .income ? 1 : 0
        direction.accessibilityIdentifier = "entry.direction"
        direction.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.categoryID = self.direction.selectedSegmentIndex == 1 ? "transfer_in" : "other_expense"
            self.renderOptions()
        }, for: .valueChanged)
        direction.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44) }
        contentStack.addArrangedSubview(direction)
        name.field.text = existing?.title
        amount.field.text = existing.map { TransferMoney.text(TransferMoney.cents(from: $0.amount) ?? 0) }
        note.field.text = existing?.note
        addGroup([name, amount, note])
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.locale = Locale(identifier: "zh_CN")
        datePicker.calendar = BankingDateContext.system.calendar
        datePicker.timeZone = BankingDateContext.system.calendar.timeZone
        datePicker.maximumDate = Date()
        datePicker.date = existing.flatMap { BankingDateContext.system.date(from: $0.date) } ?? Date()
        datePicker.accessibilityIdentifier = "entry.date"
        let dateRow = TransferInfoRow("日期", value: "")
        dateRow.valueLabel.isHidden = true
        dateRow.addSubview(datePicker)
        datePicker.snp.makeConstraints { $0.trailing.equalToSuperview().inset(16); $0.centerY.equalToSuperview() }
        addGroup([dateRow])
        for (button, action) in [(categoryButton, #selector(chooseCategory)), (bookButton, #selector(chooseBook)), (purposeButton, #selector(choosePurpose))] {
            button.tintColor = .abankTeal
            button.titleLabel?.font = .systemFont(ofSize: 16)
            button.contentHorizontalAlignment = .leading
            button.backgroundColor = .white
            button.contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
            button.snp.makeConstraints { $0.height.greaterThanOrEqualTo(52) }
            button.addTarget(self, action: action, for: .touchUpInside)
            contentStack.addArrangedSubview(button)
        }
        errorLabel.textColor = .abankOrangeDeep
        errorLabel.font = .systemFont(ofSize: 14)
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        errorLabel.accessibilityIdentifier = "entry.error"
        contentStack.addArrangedSubview(errorLabel)
        _ = addButton("保存账单", id: "entry.save") { [weak self] in self?.saveEntry() }
        renderOptions()
    }

    private func renderOptions() {
        purposeButton.setTitle("用途　\(LedgerPurpose.title(purposeID) ?? "未设置")", for: .normal)
        categoryButton.setTitle("分类　\(IncomeExpenseFilterCatalog.title(for: categoryID) ?? "请选择")　›", for: .normal)
        bookButton.setTitle("账本　\(LedgerBookCatalog.title(for: bookID) ?? "未归属")　›", for: .normal)
    }
    @objc private func chooseCategory() {
        let sheet = IncomeExpenseOptionPickerSheet()
        let direction: LedgerTransactionDirection = direction.selectedSegmentIndex == 1 ? .income : .expense
        sheet.onSelect = { [weak self] id in self?.categoryID = id; self?.renderOptions() }
        sheet.present(in: navigationController?.view ?? view, title: "选择分类",
                      options: IncomeExpenseFilterCatalog.selectableOptions(for: direction).map { ($0.id, $0.title) }, selectedId: categoryID)
    }
    @objc private func choosePurpose() {
        let sheet = IncomeExpenseOptionPickerSheet()
        sheet.onSelect = { [weak self] id in self?.purposeID = id.isEmpty ? nil : id; self?.renderOptions() }
        sheet.present(in: navigationController?.view ?? view, title: "选择用途", options: [("", "未设置")] + LedgerPurpose.options, selectedId: purposeID ?? "")
    }
    @objc private func chooseBook() {
        let sheet = IncomeExpenseOptionPickerSheet()
        sheet.onSelect = { [weak self] id in self?.bookID = id.isEmpty ? nil : id; self?.renderOptions() }
        sheet.present(in: navigationController?.view ?? view, title: "归属账本",
                      options: [("", "未归属")] + LedgerBookCatalog.options.map { ($0.id, $0.title) }, selectedId: bookID ?? "")
    }
    private func saveEntry() {
        view.endEditing(true)
        do {
            guard let cents = TransferMoney.parse(amount.field.text ?? "") else { throw LedgerEditError.invalidAmount }
            let draft = ManualEntryDraft(title: name.field.text ?? "", amountInCents: cents,
                direction: direction.selectedSegmentIndex == 1 ? .income : .expense,
                date: BankingDateContext.system.string(from: datePicker.date), categoryID: categoryID,
                ledgerID: bookID, note: note.field.text ?? "", purposeID: purposeID)
            let saved = try FinanceLedgerStore.shared.saveManualEntry(draft, id: entryID)
            onSave?(saved)
            navigationController?.popViewController(animated: true)
        } catch {
            errorLabel.text = error.localizedDescription
            errorLabel.isHidden = false
            UIAccessibility.post(notification: .announcement, argument: error.localizedDescription)
        }
    }
}

/// Shares a snapshot of precisely the visible query, including excluded rows marked as such.
enum LedgerStatementSharing {
    static func present(query: IncomeExpenseQuery, from controller: UIViewController) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("收支明细-\(UUID().uuidString).csv")
        do {
            try FinanceLedgerStore.shared.statementCSV(query: query).write(to: url, atomically: true, encoding: .utf8)
            let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activity.popoverPresentationController?.sourceView = controller.view
            activity.popoverPresentationController?.sourceRect = CGRect(x: controller.view.bounds.midX, y: controller.view.bounds.midY, width: 1, height: 1)
            activity.completionWithItemsHandler = { _, _, _, _ in try? FileManager.default.removeItem(at: url) }
            controller.present(activity, animated: true)
        } catch {
            let alert = UIAlertController(title: "账单导出失败", message: "请稍后重试", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "知道了", style: .default))
            controller.present(alert, animated: true)
        }
    }
}
