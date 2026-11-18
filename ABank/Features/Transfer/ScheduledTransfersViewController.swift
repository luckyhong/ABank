import UIKit

final class ScheduledTransfersViewController: TransferFlowViewController, RouteHosting {
    override var maximumContentWidth: CGFloat? { 560 }

    private let ledger: FinanceLedgerStore
    private let cancellationOnly: Bool
    var hostedRoute: AppRoute? { .scheduledTransfers(cancellationOnly: cancellationOnly) }

    init(ledger: FinanceLedgerStore, cancellationOnly: Bool) {
        self.ledger = ledger
        self.cancellationOnly = cancellationOnly
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func refreshBankingData() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        title = cancellationOnly ? "转账撤销" : "预约转账"
        if !cancellationOnly {
            _ = addButton("新建预约", id: "scheduled.new") { [weak self] in
                guard let self else { return }
                self.navigationController?.pushViewController(ScheduledTransferFormViewController(ledger: self.ledger), animated: true)
            }
            addNotice("到期后可在本页确认执行。")
        }
        let orders = ledger.load().scheduledTransfers.reversed().filter { !cancellationOnly || $0.isPending }
        if orders.isEmpty {
            contentStack.addArrangedSubview(BankingPageStyle.empty(
                cancellationOnly ? "暂无可撤销的预约" : "暂无预约转账", detail: cancellationOnly ? "待执行的预约可从这里撤销。" : "新建预约后，记录会显示在这里。"))
        }
        let today = ledger.dates.string(from: ledger.dates.now)
        for order in orders {
            let status = order.isPending && order.dueDate <= today ? "可执行" : order.status
            let row = BenefitsRow(title: order.recipientName,
                                  subtitle: order.dueDate + " · " + TransferMoney.text(order.amount) + " 元",
                                  trailing: BranchStatusTagView(text: status, active: order.isPending),
                                  id: "scheduled.row." + order.id, showsChevron: true, scalesType: true)
            row.accessibilityHint = status
            row.onTap = { [weak self] in
                guard let self else { return }
                self.router.open(.scheduledTransferDetail(id: order.id, cancellationOnly: self.cancellationOnly), from: self)
            }
            contentStack.addArrangedSubview(row)
        }
    }
}

final class ScheduledTransferFormViewController: TransferFlowViewController {
    override var maximumContentWidth: CGFloat? { 560 }

    private let ledger: FinanceLedgerStore
    private var payerID = FinanceLedgerRecord.defaultAccountId
    private var recipient: TransferRecipient?
    private let requestID = UUID().uuidString
    private let amount = TransferInputRow("转账金额", placeholder: "请输入金额（元）", id: "scheduled.amount", keyboard: .decimalPad)
    private let datePicker = UIDatePicker()

    init(ledger: FinanceLedgerStore) {
        self.ledger = ledger
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        let dates = ledger.dates
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.calendar = dates.calendar
        datePicker.timeZone = dates.calendar.timeZone
        datePicker.locale = Locale(identifier: "zh_CN")
        datePicker.accessibilityLabel = "预约日期"
        datePicker.accessibilityIdentifier = "scheduled.date"
        if let tomorrow = dates.calendar.dateInterval(of: .day, for: dates.now)?.end {
            datePicker.minimumDate = tomorrow
            datePicker.date = tomorrow
        }
    }

    override func refreshBankingData() {
        title = "新建预约"
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let row = BenefitsRow(title: recipient?.name ?? "选择收款人", subtitle: recipient?.maskedDestination,
                              id: "scheduled.recipient", showsChevron: true, scalesType: true)
        row.onTap = { [weak self] in self?.chooseRecipient() }
        let dateRow = UIStackView(arrangedSubviews: [
            BankingPageStyle.text("预约日期（北京时间）", style: .body), datePicker
        ])
        dateRow.axis = .vertical
        dateRow.alignment = .leading
        dateRow.spacing = 6
        addGroup([
            BankingAccountPickerRow(account: ledger.account(id: payerID), id: "scheduled.payer") { [weak self] in
                guard let self else { return }
                BankingAccountPickerRow.choose(from: self, ledger: self.ledger, selected: self.payerID) { [weak self] in
                    self?.payerID = $0
                    self?.refreshBankingData()
                }
            },
            row, amount
        ])
        contentStack.addArrangedSubview(BankingPageStyle.surface([dateRow]))
        _ = addButton("保存预约", id: "scheduled.create") { [weak self] in self?.save() }
        addNotice("保存预约后，到期仍需手动确认转账。")
    }

    private func chooseRecipient() {
        let picker = TransferRecipientsViewController(store: ledger, savedOnly: true)
        picker.onSelect = { [weak self] recipient in
            self?.recipient = recipient
            self?.navigationController?.popViewController(animated: true)
        }
        navigationController?.pushViewController(picker, animated: true)
    }

    private func save() {
        guard let recipient else { return showToast("请选择收款人") }
        guard let value = TransferMoney.parse(amount.field.text ?? ""), value > 0 else {
            return showToast(TransferError.invalidAmount.localizedDescription)
        }
        view.endEditing(true)
        do {
            let order = try ledger.createScheduledTransfer(payerID: payerID, recipientID: recipient.id, method: recipient.method,
                amount: value, dueDate: ledger.dates.string(from: datePicker.date), requestID: requestID)
            guard let navigationController else { return }
            let detail = ScheduledTransferDetailViewController(id: order.id, ledger: ledger, cancellationOnly: false)
            navigationController.setViewControllers(Array(navigationController.viewControllers.dropLast()) + [detail], animated: true)
        } catch { showToast(error.localizedDescription) }
    }
}

final class ScheduledTransferDetailViewController: TransferFlowViewController, RouteHosting {
    override var maximumContentWidth: CGFloat? { 560 }

    private let ledger: FinanceLedgerStore
    private let id: String
    private let cancellationOnly: Bool
    var hostedRoute: AppRoute? { .scheduledTransferDetail(id: id, cancellationOnly: cancellationOnly) }

    init(id: String, ledger: FinanceLedgerStore, cancellationOnly: Bool) {
        self.id = id
        self.cancellationOnly = cancellationOnly
        self.ledger = ledger
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func refreshBankingData() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        title = "预约详情"
        let root = ledger.load()
        guard let order = root.scheduledTransfers.first(where: { $0.id == id }) else {
            return addNotice("预约单不存在")
        }
        let canExecute = order.isPending && order.dueDate <= ledger.dates.string(from: ledger.dates.now)
        contentStack.addArrangedSubview(BankingPageStyle.amountSummary("¥ " + TransferMoney.text(order.amount),
            label: "预约金额", status: canExecute ? "可执行" : order.status, detail: "预约日期 " + order.dueDate,
            statusColor: canExecute || order.transferID != nil ? .abankMintInk : .abankTextSecondary))
        addGroup([
            TransferInfoRow("收款人", value: order.recipientName),
            TransferInfoRow("收款银行", value: order.bankName),
            TransferInfoRow(order.method == .phone ? "收款手机号" : "收款账号", value: order.maskedDestination),
            TransferInfoRow("付款账户", value: ledger.account(id: order.payerAccountID)?.cardLabel ?? "—")
        ])
        if let transfer = root.transferRecords.first(where: { $0.id == order.transferID }) {
            _ = addButton("查看转账结果", id: "scheduled.result") { [weak self] in self?.openResult(transfer) }
        }
        guard order.isPending else { return }
        if !cancellationOnly, canExecute {
            _ = addButton("确认执行", id: "scheduled.execute") { [weak self] in
                self?.confirm("确认向\(order.recipientName)转账 \(TransferMoney.text(order.amount)) 元？", confirmTitle: "确认转账") { [weak self] in
                    guard let self else { return }
                    do { self.openResult(try self.ledger.executeScheduledTransfer(id: self.id)) }
                    catch { self.addError(error) }
                }
            }
        }
        _ = addButton("撤销预约", id: "scheduled.cancel", primary: false) { [weak self] in
            self?.confirm("撤销后这笔预约将不能执行。", confirmTitle: "确认撤销", destructive: true) { [weak self] in
                guard let self else { return }
                do { try self.ledger.cancelScheduledTransfer(id: self.id) }
                catch { self.addError(error) }
            }
        }
    }

    private func confirm(_ message: String, confirmTitle: String, destructive: Bool = false, action: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: confirmTitle, style: destructive ? .destructive : .default) { _ in action() })
        present(alert, animated: true)
    }

    private func openResult(_ result: TransferRecord) {
        navigationController?.pushViewController(TransferResultViewController(record: result, store: ledger), animated: true)
    }
}
