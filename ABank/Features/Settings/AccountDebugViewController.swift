#if DEBUG
import UIKit

final class AccountDebugViewController: UITableViewController {
    private let store = FinanceLedgerStore.shared
    private let operations: [DebugLedgerDraft.Operation] = [.transfer(.income), .transfer(.expense), .targetBalance]
    private var accounts: [LedgerAccount] = []
    private var entries: [LedgerTransaction] = []
    private var selectedID: String?
    private var status: String?
    private var readError: String?

    init() {
        super.init(style: .insetGrouped)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "账户数据调试"
        tableView.accessibilityIdentifier = "accountDebug.dashboard"
        NotificationCenter.default.addObserver(self, selector: #selector(ledgerChanged), name: .financeLedgerDidChange, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadLedger()
    }

    @objc private func ledgerChanged() {
        guard viewIfLoaded?.window != nil else { return }
        reloadLedger()
    }

    private func reloadLedger() {
        do {
            let record = try store.loadForTransfer()
            accounts = record.accounts.filter { $0.currency == "人民币" }
            if !accounts.contains(where: { $0.id == selectedID }) {
                selectedID = accounts.first { $0.id == FinanceLedgerRecord.defaultAccountId }?.id ?? accounts.first?.id
            }
            entries = record.transactions.reversed().filter {
                $0.accountId == selectedID && FinanceLedgerStore.isDebugEntry($0)
            }
            readError = nil
        } catch {
            readError = error.localizedDescription
            selectedID = nil
            accounts = []
            entries = []
        }
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 3 }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        ["人民币账户", "账户操作", "本工具录入的流水"][section]
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0: return status
        case 1: return "模拟流水会改变本地账户余额。通过「前往转账」可测试转账历史与回单。"
        default: return entries.isEmpty ? nil : "点选一笔流水可撤销，余额和统计会重新计算。"
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return max(1, accounts.count)
        case 1: return operations.count + 1
        default: return max(1, entries.count)
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard !accounts.isEmpty else { return debugCell(readError ?? "暂无可调试的人民币账户", enabled: false) }
            let account = accounts[indexPath.row]
            let cell = debugCell(account.cardLabel, detail: "余额 ¥" + account.balance.abankPlainAmountString())
            cell.accessibilityIdentifier = "accountDebug.account." + account.id
            if account.id == selectedID {
                cell.accessoryType = .checkmark
                cell.accessibilityTraits.insert(.selected)
            }
            return cell
        case 1:
            let isTransferLink = indexPath.row == operations.count
            let enabled = selectedID != nil
            let cell = debugCell(isTransferLink ? "前往转账" : operations[indexPath.row].title, enabled: enabled)
            cell.accessoryType = enabled ? .disclosureIndicator : .none
            cell.accessibilityIdentifier = "accountDebug.operation.\(indexPath.row)"
            return cell
        default:
            guard !entries.isEmpty else { return debugCell("暂无调试流水", enabled: false) }
            let entry = entries[indexPath.row]
            let amount = (entry.direction == .income ? "+" : "−") + "¥" + entry.amount.abankPlainAmountString()
            let cell = debugCell(entry.displaySummary + "  " + amount, detail: entry.datetimeText)
            cell.accessoryType = .disclosureIndicator
            cell.accessibilityIdentifier = "accountDebug.entry.\(indexPath.row)"
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0:
            guard !accounts.isEmpty else { return }
            status = nil
            selectedID = accounts[indexPath.row].id
            reloadLedger()
        case 1:
            guard let account = accounts.first(where: { $0.id == selectedID }) else { return }
            if indexPath.row == operations.count {
                AppRouter.shared.open(.transfer(payerAccountID: account.id), from: self)
                return
            }
            let form = DebugLedgerEntryViewController(store: store, account: account, operation: operations[indexPath.row])
            form.onSave = { [weak self] in self?.report("调试流水已保存") }
            navigationController?.pushViewController(form, animated: true)
        default:
            guard !entries.isEmpty else { return }
            confirmRemoval(entries[indexPath.row])
        }
    }

    private func confirmRemoval(_ entry: LedgerTransaction) {
        let alert = UIAlertController(title: "撤销这笔调试流水？",
                                      message: entry.displaySummary + " · " + entry.signedAmountText, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "撤销流水", style: .destructive) { [weak self] _ in
            guard let self else { return }
            do {
                try store.removeDebugEntry(id: entry.id)
                report("调试流水已撤销")
            } catch { report(error.localizedDescription) }
        })
        present(alert, animated: true)
    }

    private func report(_ message: String) {
        status = message
        reloadLedger()
        if viewIfLoaded?.window != nil {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}

private final class DebugLedgerEntryViewController: UITableViewController {
    private let store: FinanceLedgerStore
    private let account: LedgerAccount
    private let operation: DebugLedgerDraft.Operation
    private let requestID = UUID()
    private let amount = UITextField()
    private let summary = UITextField()
    private let counterparty = UITextField()
    private let note = UITextField()
    private let includeInFlow = UISwitch()
    private let useHistoricalTime = UISwitch()
    private let datePicker = UIDatePicker()
    private var status: String?
    private var balance: Double?
    private var balanceError: String?
    private var didSave = false
    var onSave: (() -> Void)?

    init(store: FinanceLedgerStore, account: LedgerAccount, operation: DebugLedgerDraft.Operation) {
        self.store = store
        self.account = account
        self.operation = operation
        super.init(style: .insetGrouped)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var isTarget: Bool {
        if case .targetBalance = operation { return true }
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = operation.title
        tableView.accessibilityIdentifier = "accountDebug.form"
        tableView.keyboardDismissMode = .interactive
        configure(amount, label: isTarget ? "目标余额（元）" : "金额（元）", id: "amount", placeholder: "0.00")
        amount.keyboardType = .decimalPad
        configure(summary, label: "交易摘要", id: "summary", placeholder: operation.title)
        configure(counterparty, label: "对方户名", id: "counterparty", placeholder: "选填")
        configure(note, label: "备注", id: "note", placeholder: "选填")
        includeInFlow.isOn = !isTarget
        includeInFlow.accessibilityLabel = "计入收支统计"
        includeInFlow.accessibilityIdentifier = "accountDebug.includeInFlow"
        useHistoricalTime.accessibilityLabel = "自定义交易时间"
        useHistoricalTime.accessibilityIdentifier = "accountDebug.historicalTime"
        useHistoricalTime.addAction(UIAction { [weak self] _ in self?.toggleHistoricalTime() }, for: .valueChanged)
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.locale = Locale(identifier: "zh_CN")
        datePicker.calendar = store.dates.calendar
        datePicker.timeZone = store.dates.calendar.timeZone
        datePicker.accessibilityLabel = "交易时间，北京时间"
        datePicker.accessibilityIdentifier = "accountDebug.date"
        NotificationCenter.default.addObserver(self, selector: #selector(ledgerChanged), name: .financeLedgerDidChange, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshBalance()
    }

    @objc private func ledgerChanged() {
        guard viewIfLoaded?.window != nil, !didSave else { return }
        refreshBalance()
    }

    private func refreshBalance() {
        do {
            balance = try store.loadForTransfer().accounts.first(where: { $0.id == account.id })?.balance
            balanceError = nil
        } catch {
            balance = nil
            balanceError = error.localizedDescription
        }
        tableView.reloadSections(IndexSet([0, numberOfSections(in: tableView) - 1]), with: .none)
    }

    private func configure(_ field: UITextField, label: String, id: String, placeholder: String) {
        field.font = .preferredFont(forTextStyle: .body)
        field.adjustsFontForContentSizeCategory = true
        field.placeholder = placeholder
        field.accessibilityLabel = label
        field.accessibilityIdentifier = "accountDebug." + id
        field.clearButtonMode = .whileEditing
        field.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        let toolbar = UIToolbar()
        toolbar.items = [UIBarButtonItem(systemItem: .flexibleSpace),
                         UIBarButtonItem(systemItem: .done, primaryAction: UIAction { [weak field] _ in
                             field?.resignFirstResponder()
                         })]
        toolbar.sizeToFit()
        field.inputAccessoryView = toolbar
    }

    private func toggleHistoricalTime() {
        if useHistoricalTime.isOn {
            datePicker.maximumDate = store.dates.now
            datePicker.date = store.dates.now
            tableView.insertRows(at: [IndexPath(row: 1, section: 2)], with: .none)
        } else {
            tableView.deleteRows(at: [IndexPath(row: 1, section: 2)], with: .none)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int { isTarget ? 3 : 4 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return isTarget ? 3 : 5
        case 2 where !isTarget: return useHistoricalTime.isOn ? 2 : 1
        default: return status == nil ? 1 : 2
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: return isTarget ? "余额调整" : "流水信息"
        case 2 where !isTarget: return "交易时间（北京时间）"
        default: return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let detail = balance.map { "当前余额 ¥" + $0.abankPlainAmountString() } ?? balanceError ?? "余额不可用"
            return debugCell(account.cardLabel, detail: detail, enabled: false)
        case 1:
            switch indexPath.row {
            case 0: return inputCell(amount)
            case 1 where isTarget:
                let cell = debugCell("清零")
                cell.textLabel?.textColor = view.tintColor
                return cell
            case 1: return inputCell(summary)
            case 2 where !isTarget: return inputCell(counterparty)
            case 3: return inputCell(note)
            default: return switchCell("计入收支统计", control: includeInFlow)
            }
        case 2 where !isTarget:
            if indexPath.row == 0 { return switchCell("自定义交易时间", control: useHistoricalTime) }
            return controlCell([datePicker])
        default:
            if indexPath.row == 1 { return debugCell(status ?? "", enabled: false) }
            let cell = debugCell("预览并保存", enabled: balance != nil && !didSave)
            cell.textLabel?.textColor = balance == nil ? .secondaryLabel : view.tintColor
            cell.accessibilityIdentifier = "accountDebug.preview"
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if isTarget, indexPath == IndexPath(row: 1, section: 1) { amount.text = "0.00" }
        if indexPath.section == numberOfSections(in: tableView) - 1, indexPath.row == 0 {
            guard balance != nil, !didSave else { return }
            preview()
        }
    }

    private func preview() {
        view.endEditing(true)
        do {
            guard let cents = TransferMoney.parse(amount.text ?? "") else { throw DebugLedgerError.invalidAmount }
            let draft = DebugLedgerDraft(accountID: account.id, operation: operation, amountInCents: cents,
                                         date: useHistoricalTime.isOn ? datePicker.date : nil, summary: summary.text ?? "",
                                         counterparty: counterparty.text ?? "", note: note.text ?? "", includeInFlow: includeInFlow.isOn)
            let expected = try store.previewDebugEntry(draft)
            guard expected.change != 0 else {
                report("目标余额与当前余额相同，无需保存")
                return
            }
            let sign = expected.change > 0 ? "+" : "−"
            let message = [
                account.cardLabel,
                "当前余额  ¥" + TransferMoney.text(expected.currentBalance),
                "余额变动  " + sign + "¥" + TransferMoney.text(abs(expected.change)),
                "预计余额  ¥" + TransferMoney.text(expected.newBalance)
            ].joined(separator: "\n")
            let alert = UIAlertController(title: "确认保存", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "返回修改", style: .cancel))
            alert.addAction(UIAlertAction(title: "保存流水", style: .default) { [weak self] _ in
                self?.save(draft, expected: expected)
            })
            present(alert, animated: true)
        } catch { report(error.localizedDescription) }
    }

    private func save(_ draft: DebugLedgerDraft, expected: DebugLedgerPreview) {
        guard !didSave else { return }
        didSave = true
        do {
            try store.saveDebugEntry(draft, requestID: requestID, expected: expected)
            onSave?()
            navigationController?.popViewController(animated: true)
        } catch {
            didSave = false
            refreshBalance()
            report(error.localizedDescription)
        }
    }

    private func report(_ message: String) {
        status = message
        let section = numberOfSections(in: tableView) - 1
        tableView.reloadSections(IndexSet(integer: section), with: .none)
        tableView.scrollToRow(at: IndexPath(row: 1, section: section), at: .bottom, animated: false)
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    private func inputCell(_ field: UITextField) -> UITableViewCell {
        let label = UILabel()
        label.text = field.accessibilityLabel
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.isAccessibilityElement = false
        return controlCell([label, field])
    }

    private func switchCell(_ title: String, control: UISwitch) -> UITableViewCell {
        let cell = debugCell(title, enabled: false)
        cell.textLabel?.textColor = .label
        cell.textLabel?.isAccessibilityElement = false
        cell.accessoryView = control
        cell.isAccessibilityElement = false
        return cell
    }

    private func controlCell(_ controls: [UIView]) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        let stack = UIStackView(arrangedSubviews: controls)
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(stack)
        let guide = cell.contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: guide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
        ])
        return cell
    }
}

private func debugCell(_ title: String, detail: String? = nil, enabled: Bool = true) -> UITableViewCell {
    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
    cell.textLabel?.text = title
    cell.textLabel?.font = .preferredFont(forTextStyle: .body)
    cell.textLabel?.adjustsFontForContentSizeCategory = true
    cell.textLabel?.textColor = enabled ? .label : .secondaryLabel
    cell.textLabel?.numberOfLines = 0
    cell.detailTextLabel?.text = detail
    cell.detailTextLabel?.font = .preferredFont(forTextStyle: .subheadline)
    cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
    cell.detailTextLabel?.textColor = .secondaryLabel
    cell.detailTextLabel?.numberOfLines = 0
    cell.selectionStyle = enabled ? .default : .none
    return cell
}
#endif
