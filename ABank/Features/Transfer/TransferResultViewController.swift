import UIKit
import SnapKit

final class TransferResultViewController: TransferFlowViewController {
    private let record: TransferRecord?
    private let retryDraft: TransferDraft?
    private let errorMessage: String?
    private let store: FinanceLedgerStore

    init(record: TransferRecord, store: FinanceLedgerStore? = nil) {
        self.record = record
        self.store = store ?? .shared
        self.retryDraft = nil
        self.errorMessage = nil
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    init(draft: TransferDraft, error: Error, store: FinanceLedgerStore? = nil) {
        self.record = nil
        self.retryDraft = draft
        self.errorMessage = error.localizedDescription
        self.store = store ?? .shared
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "转账结果"
        let succeeded = record?.status == .succeeded
        let icon = UIImageView(image: succeeded
            ? UIImage.abankAsset("abc_transfer_result_success", fallback: "checkmark.circle.fill")
            : UIImage(systemName: "xmark.circle"))
        icon.tintColor = .abankTextTertiary
        icon.contentMode = .scaleAspectFit
        icon.snp.makeConstraints { $0.height.equalTo(68) }
        contentStack.addArrangedSubview(icon)
        let status = UILabel()
        status.text = record?.status.title ?? "模拟转账未完成"
        status.font = .systemFont(ofSize: 21, weight: .medium)
        status.textColor = .abankTextPrimary
        status.textAlignment = .center
        status.accessibilityIdentifier = "transfer.result.status"
        contentStack.addArrangedSubview(status)
        let reason = UILabel()
        reason.text = succeeded ? "本机账本已更新，无真实资金交易" : (record?.failureReason ?? errorMessage)
        reason.font = .systemFont(ofSize: 14)
        reason.textColor = .abankTextSecondary
        reason.numberOfLines = 0
        reason.textAlignment = .center
        contentStack.addArrangedSubview(reason)

        if let record {
            addGroup([
                TransferInfoRow("转账金额", value: "¥ " + TransferMoney.text(record.amountInCents), emphasized: true),
                TransferInfoRow("收款人", value: record.recipientName),
                TransferInfoRow(record.method == .account ? "收款账号" : "收款手机号", value: record.maskedDestination),
                TransferInfoRow("收款银行", value: record.bankName),
                TransferInfoRow("付款账户", value: record.payerLabel),
                TransferInfoRow("交易时间", value: record.createdAt),
                TransferInfoRow("模拟单号", value: String(record.id.suffix(12))),
                TransferInfoRow("附言", value: record.note.isEmpty ? "无" : record.note)
            ])
            if let id = record.transactionID {
                _ = addButton("查看收支明细", id: "transfer.viewTransaction", primary: false) { [weak self] in
                    guard let self, let transaction = self.store.transaction(id: id) else { return }
                    self.navigationController?.pushViewController(IncomeExpenseDetailViewController(transaction: transaction), animated: true)
                }
            }
        }
        if !succeeded {
            _ = addButton("重新填写", id: "transfer.retry") { [weak self] in self?.retry() }
        }
        _ = addButton("转账记录", id: "transfer.viewRecords", primary: false) { [weak self] in
            guard let self else { return }
            if let records = self.navigationController?.viewControllers.first(where: { $0 is TransferRecordsViewController }) {
                self.navigationController?.popToViewController(records, animated: true)
            } else {
                self.navigationController?.pushViewController(TransferRecordsViewController(store: self.store), animated: true)
            }
        }
        _ = addButton("完成", id: "transfer.done", primary: succeeded) { [weak self] in
            guard let self else { return }
            TransferFlowNavigation.finish(self)
        }
    }

    private func retry() {
        let draft: TransferDraft
        if let retryDraft { draft = retryDraft }
        else if let record {
            draft = TransferDraft(payerAccountID: record.payerAccountID, method: record.method,
                                  recipientName: record.recipientName, bankName: record.bankName,
                                  destination: record.maskedDestination,
                                  savedRecipientID: "history:" + record.id,
                                  amountInCents: record.amountInCents, note: record.note)
        } else { return }
        guard let nav = navigationController else { return }
        var stack = nav.viewControllers
        stack.removeLast()
        stack.append(TransferFormViewController(initialDraft: draft, store: store))
        nav.setViewControllers(stack, animated: true)
    }
}
