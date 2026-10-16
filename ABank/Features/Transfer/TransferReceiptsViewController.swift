import UIKit

final class TransferReceiptsViewController: TransferFlowViewController {
    private let accountID: String?
    private let store: FinanceLedgerStore
    init(accountID: String? = nil, store: FinanceLedgerStore? = nil) {
        self.accountID = accountID
        self.store = store ?? .shared
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func setupUI() {
        super.setupUI()
        title = "模拟电子回单"
        refreshBankingData()
    }
    override func refreshBankingData() {
        guard isViewLoaded else { return }
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        addNotice("模拟交易 · 仅展示本机成功转账，不作为银行凭证")
        let records = store.receiptRecords(accountID: accountID)
        if records.isEmpty { addNotice("暂无成功模拟转账回单") }
        for record in records {
            _ = addButton("\(record.recipientName)  ¥\(TransferMoney.text(record.amountInCents))\n\(record.createdAt) · 模拟交易", id: "receipt.\(record.id)", primary: false) { [weak self] in
                guard let self else { return }
                self.navigationController?.pushViewController(TransferReceiptDetailViewController(recordID: record.id, store: self.store), animated: true)
            }
        }
    }
}

final class TransferReceiptDetailViewController: TransferFlowViewController {
    private let recordID: String
    private let store: FinanceLedgerStore
    init(recordID: String, store: FinanceLedgerStore? = nil) {
        self.recordID = recordID
        self.store = store ?? .shared
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func setupUI() {
        super.setupUI()
        title = "模拟交易回单"
        refreshBankingData()
    }
    override func refreshBankingData() {
        guard isViewLoaded else { return }
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard let record = store.receiptRecords().first(where: { $0.id == recordID }) else {
            addNotice("该模拟回单不可用")
            return
        }
        addNotice("模拟交易 · 无真实资金交易 · 非银行凭证")
        let label = UILabel()
        label.text = record.receiptText
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.textColor = .abankTextPrimary
        contentStack.addArrangedSubview(label)
        _ = addButton("分享模拟回单", id: "receipt.share") { [weak self] in self?.shareReceipt() }
        _ = addButton("查看关联流水", id: "receipt.transaction", primary: false) { [weak self] in
            guard let self, let id = record.transactionID, let transaction = self.store.transaction(id: id) else { return }
            self.navigationController?.pushViewController(IncomeExpenseDetailViewController(transaction: transaction), animated: true)
        }
    }
    private func shareReceipt() {
        guard let record = store.receiptRecords().first(where: { $0.id == recordID }) else { return }
        // A text document supports Save to Files without copying any raw destination input.
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("模拟交易回单-\(UUID().uuidString).txt")
        do {
            try record.receiptText.write(to: url, atomically: true, encoding: .utf8)
            let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activity.popoverPresentationController?.sourceView = view
            activity.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
            activity.completionWithItemsHandler = { _, _, _, _ in try? FileManager.default.removeItem(at: url) }
            present(activity, animated: true)
        } catch {
            let alert = UIAlertController(title: "回单导出失败", message: "请稍后重试", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "知道了", style: .default))
            present(alert, animated: true)
        }
    }
}
