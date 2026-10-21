import UIKit
import SnapKit

/// 回单查询：列出本机已成功的模拟转账回单，可限定付款账户。
final class TransferReceiptListViewController: BankingDataViewController, UITableViewDataSource, UITableViewDelegate {
    private let store: FinanceLedgerStore
    private let accountID: String?
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let noticeLabel = UILabel()
    private let emptyLabel = UILabel()
    private var receipts: [TransferReceipt] = []

    init(accountID: String? = nil, store: FinanceLedgerStore? = nil) {
        self.accountID = accountID
        self.store = store ?? .shared
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "电子回单"
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.tintColor = .abankTextPrimary
        navigationItem.backButtonTitle = ""
    }

    override func setupUI() {
        view.backgroundColor = .white
        let scope = accountID.map { store.accountCardLabel(for: $0) } ?? "全部付款账户"
        noticeLabel.text = "\(scope) · 仅含本机成功的模拟转账，回单不具备凭证效力"
        noticeLabel.font = .systemFont(ofSize: 13)
        noticeLabel.textColor = .abankTextSecondary
        noticeLabel.numberOfLines = 0
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88
        tableView.register(TransferReceiptCell.self, forCellReuseIdentifier: TransferReceiptCell.reuseId)
        tableView.accessibilityIdentifier = "receipt.list.table"
        emptyLabel.text = "暂无电子回单\n完成模拟转账后可在此查看"
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.font = .systemFont(ofSize: 14)
        emptyLabel.textColor = .abankTextTertiary
        emptyLabel.accessibilityIdentifier = "receipt.list.emptyState"
        tableView.backgroundView = emptyLabel
        [noticeLabel, tableView].forEach { view.addSubview($0) }
        noticeLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(noticeLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func refreshBankingData() {
        receipts = store.transferReceipts(accountID: accountID)
        emptyLabel.isHidden = !receipts.isEmpty
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { receipts.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TransferReceiptCell.reuseId, for: indexPath) as! TransferReceiptCell
        cell.configure(receipts[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController(TransferReceiptViewController(receipt: receipts[indexPath.row], store: store), animated: true)
    }
}

final class TransferReceiptCell: UITableViewCell {
    static let reuseId = "TransferReceiptCell"
    private let nameLabel = UILabel()
    private let amountLabel = UILabel()
    private let detailLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        let icon = UIImageView(image: UIImage.abankAsset("abc_transfer_record", fallback: "doc.text"))
        icon.contentMode = .scaleAspectFit
        nameLabel.font = .systemFont(ofSize: 17)
        nameLabel.textColor = .abankTextPrimary
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        amountLabel.font = .systemFont(ofSize: 17, weight: .medium)
        amountLabel.textColor = .abankTextPrimary
        amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)
        detailLabel.font = .systemFont(ofSize: 13)
        detailLabel.textColor = .abankTextSecondary
        detailLabel.numberOfLines = 0
        [icon, nameLabel, amountLabel, detailLabel].forEach { contentView.addSubview($0) }
        icon.snp.makeConstraints { $0.leading.equalToSuperview().offset(16); $0.centerY.equalToSuperview(); $0.size.equalTo(26) }
        nameLabel.snp.makeConstraints { $0.leading.equalTo(icon.snp.trailing).offset(12); $0.top.equalToSuperview().offset(12); $0.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-8) }
        amountLabel.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-8); $0.centerY.equalTo(nameLabel) }
        detailLabel.snp.makeConstraints { $0.leading.equalTo(nameLabel); $0.top.equalTo(nameLabel.snp.bottom).offset(5); $0.trailing.equalTo(amountLabel); $0.bottom.equalToSuperview().offset(-12) }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(_ receipt: TransferReceipt) {
        nameLabel.text = receipt.payeeName
        amountLabel.text = receipt.amountText
        detailLabel.text = "\(receipt.createdAt) · \(receipt.payerLabel)\n回单编号 \(receipt.receiptNumber)"
        accessibilityIdentifier = "receipt.cell.\(receipt.receiptNumber)"
    }
}
