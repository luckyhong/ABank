import UIKit

final class TransferConfirmViewController: TransferFlowViewController {
    private let draft: TransferDraft
    private let store: FinanceLedgerStore
    private let requestID = UUID().uuidString
    private var isSubmitting = false
    private var submitButton: UIButton!
    private var previousGestureEnabled = true

    init(draft: TransferDraft, store: FinanceLedgerStore? = nil) {
        self.draft = draft
        self.store = store ?? .shared
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "转账确认"
        addNotice("请确认以下模拟转账信息")
        let recipient = try? store.recipient(for: draft)
        addGroup([
            TransferInfoRow("转账金额", value: "¥ " + TransferMoney.text(draft.amountInCents), emphasized: true),
            TransferInfoRow("收款人", value: recipient?.name ?? draft.recipientName),
            TransferInfoRow(draft.method == .account ? "收款账号" : "收款手机号", value: recipient?.maskedDestination ?? ""),
            TransferInfoRow("收款银行", value: recipient?.bankName ?? ""),
            TransferInfoRow("付款账户", value: store.load().accounts.first(where: { $0.id == draft.payerAccountID })?.cardLabel ?? "不可用"),
            TransferInfoRow("手续费", value: "¥ 0.00"),
            TransferInfoRow("附言", value: draft.note.isEmpty ? "无" : draft.note)
        ])
        addNotice()
        submitButton = addButton("确认模拟转账", id: "transfer.confirm") { [weak self] in self?.submit() }
        _ = addButton("返回修改", id: "transfer.edit", primary: false) { [weak self] in
            guard self?.isSubmitting == false else { return }
            self?.navigationController?.popViewController(animated: true)
        }
    }

    private func submit() {
        guard !isSubmitting else { return }
        isSubmitting = true
        submitButton.isEnabled = false
        submitButton.setTitle("正在处理模拟转账…", for: .normal)
        navigationItem.hidesBackButton = true
        previousGestureEnabled = navigationController?.interactivePopGestureRecognizer?.isEnabled ?? true
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        // A short, deterministic presentation state; no network and no random financial outcome.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self, let nav = self.navigationController, nav.topViewController === self else { return }
            let result: TransferResultViewController
            do {
                let record = try self.store.submitTransfer(draft: self.draft, requestID: self.requestID)
                result = TransferResultViewController(record: record, store: self.store)
            } catch {
                result = TransferResultViewController(draft: self.draft, error: error, store: self.store)
            }
            nav.interactivePopGestureRecognizer?.isEnabled = self.previousGestureEnabled
            // Remove both the editable draft and its submitted confirmation from the back stack.
            var stack = nav.viewControllers
            stack.removeLast()
            if stack.last is TransferFormViewController { stack.removeLast() }
            stack.append(result)
            nav.setViewControllers(stack, animated: true)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isSubmitting { navigationController?.interactivePopGestureRecognizer?.isEnabled = previousGestureEnabled }
    }
}
