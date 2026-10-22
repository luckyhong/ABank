import UIKit
import SnapKit

/// 电子回单详情：展示带模拟标记的回单，可通过系统分享面板分享或保存图片。
final class TransferReceiptViewController: TransferFlowViewController {
    private let recordID: String
    private let store: FinanceLedgerStore
    private var cardView: TransferReceiptCardView?
    private var receipt: TransferReceipt?

    init(receipt: TransferReceipt, store: FinanceLedgerStore? = nil) {
        self.recordID = receipt.id
        self.receipt = receipt
        self.store = store ?? .shared
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "电子回单"
        guard let receipt else { return }
        let card = TransferReceiptCardView(receipt: receipt)
        contentStack.addArrangedSubview(card)
        cardView = card
        _ = addButton("分享回单", id: "receipt.share") { [weak self] in self?.share() }
        if let transaction = store.transaction(id: receipt.transactionID) {
            _ = addButton("查看收支明细", id: "receipt.viewTransaction", primary: false) { [weak self] in
                self?.navigationController?.pushViewController(IncomeExpenseDetailViewController(transaction: transaction), animated: true)
            }
        }
        addNotice("分享的图片和文字均带有“模拟交易”标记，仅用于学习演示。")
    }

    /// 回单只读派生；对应记录不再可用时返回上一页。
    override func refreshBankingData() {
        guard isViewLoaded, store.transferReceipt(recordID: recordID) == nil else { return }
        navigationController?.popViewController(animated: true)
    }

    private func share() {
        guard let receipt, let cardView else { return }
        let activity = UIActivityViewController(activityItems: [cardView.renderImage(), receipt.shareText],
                                                applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = cardView
        activity.popoverPresentationController?.sourceRect = cardView.bounds
        present(activity, animated: true)
    }
}
