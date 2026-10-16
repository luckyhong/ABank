import UIKit
import SnapKit

final class TransferFormViewController: TransferFlowViewController {
    private let store: FinanceLedgerStore
    private var draft: TransferDraft
    private let recipientRow = TransferInputRow("收款人", placeholder: "请输入演示姓名", id: "transfer.recipientName")
    private let destinationRow: TransferInputRow
    private let amountRow = TransferInputRow("转账金额", placeholder: "0.00", id: "transfer.amount", keyboard: .decimalPad)
    private let noteRow = TransferInputRow("附言", placeholder: "选填，最多60字", id: "transfer.note")
    private let bankRow = TransferInfoRow("收款银行", value: "")
    private var manualButton: UIButton?
    private let payerRow = TransferInfoRow("付款账户", value: "", image: "abc_account_bank_logo")

    init(method: TransferMethod = .account, payerAccountID: String? = nil,
         recipient: TransferRecipient? = nil, initialDraft: TransferDraft? = nil,
         store: FinanceLedgerStore? = nil) {
        let store = store ?? .shared
        self.store = store
        self.draft = initialDraft ?? TransferDraft(payerAccountID: payerAccountID ?? store.load().accounts.first?.id ?? "", method: recipient?.method ?? method)
        destinationRow = TransferInputRow(self.draft.method == .account ? "收款账号" : "手机号",
            placeholder: self.draft.method == .account ? "16至19位演示账号" : "11位演示手机号", id: "transfer.destination", keyboard: .numberPad)
        if let recipient { draft.savedRecipientID = recipient.id }
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = draft.method.title
        addNotice()
        _ = addButton("选择转账伙伴  ›", id: "transfer.chooseRecipient", primary: false) { [weak self] in self?.chooseRecipient() }
        if draft.method == .account { addGroup([recipientRow, destinationRow, bankRow]) }
        else { addGroup([recipientRow, destinationRow]) }
        addGroup([payerRow])
        addGroup([amountRow, noteRow])
        let bankTap = UITapGestureRecognizer(target: self, action: #selector(chooseBank))
        bankRow.addGestureRecognizer(bankTap)
        payerRow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(choosePayer)))
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [UIBarButtonItem(systemItem: .flexibleSpace), UIBarButtonItem(title: "完成", style: .done, target: self, action: #selector(endInput))]
        for field in [recipientRow.field, destinationRow.field, amountRow.field, noteRow.field] {
            field.inputAccessoryView = toolbar
            field.addAction(UIAction { [weak self, weak field] _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self, weak field] in
                    guard let self, let field, field.isFirstResponder else { return }
                    self.view.layoutIfNeeded()
                    self.scrollView.scrollRectToVisible(field.convert(field.bounds, to: self.scrollView).insetBy(dx: 0, dy: -20), animated: true)
                }
            }, for: .editingDidBegin)
        }
        _ = addButton("下一步", id: "transfer.next") { [weak self] in self?.nextTapped() }
        manualButton = addButton("手动填写收款人", id: "transfer.manual", primary: false) { [weak self] in
            self?.captureFields()
            self?.draft.savedRecipientID = nil
            self?.draft.destination = ""
            self?.draft.recipientName = ""
            self?.applyDraft()
        }
        addNotice("确认前请核对收款人。手续费：0.00元（模拟）。")
        applyDraft()
    }

    override func refreshBankingData() { refreshPayer() }

    private func applyDraft() {
        if draft.savedRecipientID != nil, let recipient = try? store.recipient(for: draft) {
            draft.recipientName = recipient.name
            draft.destination = recipient.maskedDestination
            draft.bankName = recipient.bankName
        }
        recipientRow.field.text = draft.recipientName
        destinationRow.field.text = draft.destination
        let editable = draft.savedRecipientID == nil
        bankRow.valueLabel.text = draft.bankName + (editable ? "  ›" : "")
        manualButton?.isHidden = editable
        recipientRow.field.isEnabled = editable
        destinationRow.field.isEnabled = editable
        bankRow.isUserInteractionEnabled = editable
        amountRow.field.text = draft.amountInCents > 0 ? TransferMoney.text(draft.amountInCents) : ""
        noteRow.field.text = draft.note
        refreshPayer()
    }

    private func refreshPayer() {
        let accounts = store.load().accounts
        if !accounts.contains(where: { $0.id == draft.payerAccountID }) { draft.payerAccountID = accounts.first?.id ?? "" }
        if let account = accounts.first(where: { $0.id == draft.payerAccountID }) {
            payerRow.valueLabel.text = account.cardLabel + "  ›\n可用余额 ¥ " + account.balance.abankPlainAmountString()
        } else { payerRow.valueLabel.text = "暂无可用账户" }
    }

    private func captureFields() {
        draft.recipientName = recipientRow.field.text ?? ""
        draft.destination = destinationRow.field.text ?? ""
        draft.note = noteRow.field.text ?? ""
        draft.amountInCents = TransferMoney.parse(amountRow.field.text ?? "") ?? 0
    }

    private func nextTapped() {
        view.endEditing(true)
        captureFields()
        do {
            try store.validateTransfer(draft)
            navigationController?.pushViewController(TransferConfirmViewController(draft: draft, store: store), animated: true)
        } catch { addError(error) }
    }

    private func chooseRecipient() {
        captureFields()
        let controller = TransferRecipientsViewController(method: draft.method, store: store)
        controller.onSelect = { [weak self] recipient in
            guard let self else { return }
            self.draft.savedRecipientID = recipient.id
            self.navigationController?.popViewController(animated: true)
            self.applyDraft()
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func chooseBank() {
        let alert = UIAlertController(title: "收款银行", message: nil, preferredStyle: .actionSheet)
        for name in ["中国农业银行", "中国工商银行", "中国建设银行", "中国银行", "招商银行", "交通银行"] {
            alert.addAction(UIAlertAction(title: name, style: .default) { [weak self] _ in
                self?.draft.bankName = name
                self?.bankRow.valueLabel.text = name + "  ›"
            })
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.popoverPresentationController?.sourceView = bankRow
        alert.popoverPresentationController?.sourceRect = bankRow.bounds
        present(alert, animated: true)
    }

    @objc private func choosePayer() {
        let alert = UIAlertController(title: "付款账户", message: nil, preferredStyle: .actionSheet)
        for account in store.load().accounts where account.currency == "人民币" {
            alert.addAction(UIAlertAction(title: "\(account.cardLabel)  ¥ \(account.balance.abankPlainAmountString())", style: .default) { [weak self] _ in
                self?.draft.payerAccountID = account.id
                self?.refreshPayer()
            })
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.popoverPresentationController?.sourceView = payerRow
        alert.popoverPresentationController?.sourceRect = payerRow.bounds
        present(alert, animated: true)
    }
    @objc private func endInput() { view.endEditing(true) }
}
