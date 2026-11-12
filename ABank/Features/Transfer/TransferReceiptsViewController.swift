import UIKit
import SnapKit

final class TransferReceiptsViewController: BankingDataViewController, UITableViewDataSource, UITableViewDelegate {
    private let accountID: String?
    private let store: FinanceLedgerStore
    private let table = UITableView(frame: .zero, style: .insetGrouped)
    private var records: [TransferRecord] = []
    init(accountID: String? = nil, store: FinanceLedgerStore? = nil) {
        self.accountID = accountID; self.store = store ?? .shared
        super.init(nibName: nil, bundle: nil); hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func setupUI() {
        title = "电子回单"; view.backgroundColor = .abankBackground
        table.dataSource = self; table.delegate = self; table.rowHeight = UITableView.automaticDimension; table.estimatedRowHeight = 92
        view.addSubview(table); table.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
    }
    override func refreshBankingData() {
        records = store.receiptRecords(accountID: accountID)
        table.backgroundView = records.isEmpty ? BankingPageStyle.empty("暂无电子回单", detail: "成功办理的转账可在这里查询和分享回单。") : nil
        table.reloadData()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { records.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let record = records[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = record.recipientName + "　¥" + TransferMoney.text(record.amountInCents)
        cell.textLabel?.font = .preferredFont(forTextStyle: .body); cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = record.createdAt + "\n" + record.payerLabel
        cell.detailTextLabel?.font = .preferredFont(forTextStyle: .caption1); cell.detailTextLabel?.numberOfLines = 0
        cell.imageView?.image = UIImage.abankAsset("abc_statement_receipt", fallback: "doc.text")
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.pushViewController(TransferReceiptDetailViewController(recordID: records[indexPath.row].id, store: store), animated: true)
    }
}

final class TransferReceiptDetailViewController: TransferFlowViewController {
    private let recordID: String
    private let store: FinanceLedgerStore
    init(recordID: String, store: FinanceLedgerStore? = nil) {
        self.recordID = recordID; self.store = store ?? .shared
        super.init(nibName: nil, bundle: nil); hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func setupUI() { super.setupUI(); title = "交易回单" }
    override func refreshBankingData() {
        guard isViewLoaded else { return }
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard let record = store.receiptRecords().first(where: { $0.id == recordID }) else {
            contentStack.addArrangedSubview(BankingPageStyle.empty("回单暂不可用", detail: "请返回确认原交易是否存在。")); return
        }
        contentStack.addArrangedSubview(BankReceiptView(record: record))
        _ = addButton("分享PDF回单", id: "receipt.share") { [weak self] in self?.shareReceipt() }
        _ = addButton("复制回单文字", id: "receipt.copy", primary: false) { [weak self] in
            UIPasteboard.general.string = record.receiptText; self?.showToast("回单文字已复制")
        }
        _ = addButton("查看关联流水", id: "receipt.transaction", primary: false) { [weak self] in
            guard let self, let id = record.transactionID, let tx = self.store.transaction(id: id) else { return }
            self.navigationController?.pushViewController(IncomeExpenseDetailViewController(transaction: tx), animated: true)
        }
    }
    private func shareReceipt() {
        guard let record = store.receiptRecords().first(where: { $0.id == recordID }) else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("交易回单-" + record.businessReference + ".pdf")
        do {
            try BankReceiptView.pdf(record: record).write(to: url, options: .atomic)
            let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activity.popoverPresentationController?.sourceView = view
            activity.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
            activity.completionWithItemsHandler = { _, _, _, _ in try? FileManager.default.removeItem(at: url) }
            present(activity, animated: true)
        } catch { showToast("回单导出失败，请稍后重试") }
    }
}

final class BankReceiptView: UIView {
    init(record: TransferRecord) {
        super.init(frame: .zero)
        backgroundColor = .white; layer.cornerRadius = 12
        let logo = UIImageView(image: UIImage.abankAsset("abc_account_bank_logo", fallback: "building.columns")); logo.contentMode = .scaleAspectFit
        logo.snp.makeConstraints { $0.size.equalTo(28) }
        let brand = UIStackView(arrangedSubviews: [logo, BankingPageStyle.text("ABank　电子回单", style: .headline), UIView()]); brand.spacing = 10; brand.alignment = .center
        let amount = BankingPageStyle.text("¥ " + TransferMoney.text(record.amountInCents), style: .largeTitle); amount.textAlignment = .center
        amount.numberOfLines = 1; amount.adjustsFontSizeToFitWidth = true; amount.minimumScaleFactor = 0.6
        amount.accessibilityIdentifier = "receipt.amount"
        let status = BankingPageStyle.text(record.status.title, style: .subheadline, color: .abankPrimaryDark); status.textAlignment = .center
        let line = UIView(); line.backgroundColor = .abankSeparator; line.snp.makeConstraints { $0.height.equalTo(1) }
        let rows: [(String, String)] = [("付款账户", record.payerLabel), ("收款人", record.recipientName),
            ("收款账号", record.maskedDestination), ("收款银行", record.bankName), ("交易时间", record.createdAt),
            ("业务编号", record.businessReference), ("附言", record.note.isEmpty ? "无" : record.note)]
        var views: [UIView] = [brand, amount, status, line]
        for (title, value) in rows {
            let label = BankingPageStyle.text(title, style: .subheadline, color: .abankTextSecondary)
            label.setContentCompressionResistancePriority(.required, for: .horizontal)
            let text = BankingPageStyle.text(value, style: .subheadline); text.textAlignment = .right
            if title == "业务编号" { text.numberOfLines = 1; text.adjustsFontSizeToFitWidth = true; text.minimumScaleFactor = 0.65 }
            let row = UIStackView(arrangedSubviews: [label, text]); row.spacing = 18; row.alignment = .top
            views.append(row)
        }
        views.append(BankingPageStyle.text("请妥善保管回单，交易详情以关联流水为准。", style: .caption1, color: .abankTextSecondary))
        let stack = UIStackView(arrangedSubviews: views); stack.axis = .vertical; stack.spacing = 20
        addSubview(stack); stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(20) }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    static func pdf(record: TransferRecord) -> Data {
        let receipt = BankReceiptView(record: record)
        let width: CGFloat = 555
        let fit = receipt.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        receipt.frame = CGRect(x: 0, y: 0, width: width, height: fit.height); receipt.layoutIfNeeded()
        return UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842)).pdfData { context in
            context.beginPage()
            context.cgContext.translateBy(x: 20, y: 20)
            let scale = min(1, 802 / max(1, fit.height)); context.cgContext.scaleBy(x: scale, y: scale)
            receipt.layer.render(in: context.cgContext)
        }
    }
}
