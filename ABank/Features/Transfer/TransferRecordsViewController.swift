import UIKit
import SnapKit

final class TransferRecordsViewController: BankingDataViewController, UITableViewDataSource, UITableViewDelegate {
    private let store: FinanceLedgerStore
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let filter = UISegmentedControl(items: ["全部", "成功", "失败"])
    private let emptyLabel = UILabel()
    private var records: [TransferRecord] = []

    init(store: FinanceLedgerStore? = nil) {
        self.store = store ?? .shared
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        title = "转账记录"
        view.backgroundColor = .white
        filter.selectedSegmentIndex = 0
        filter.selectedSegmentTintColor = .abankTeal
        filter.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        filter.accessibilityIdentifier = "transfer.records.filter"
        filter.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        let notice = UILabel()
        notice.text = "仅显示本机发起的模拟转账"
        notice.font = .systemFont(ofSize: 13)
        notice.textColor = .abankTextSecondary
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 88
        tableView.register(TransferHistoryCell.self, forCellReuseIdentifier: "transfer")
        tableView.accessibilityIdentifier = "transfer.records.table"
        emptyLabel.text = "暂无符合条件的模拟转账"
        emptyLabel.textAlignment = .center
        emptyLabel.font = .systemFont(ofSize: 14)
        emptyLabel.textColor = .abankTextTertiary
        tableView.backgroundView = emptyLabel
        [filter, notice, tableView].forEach { view.addSubview($0) }
        filter.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(12); $0.leading.trailing.equalToSuperview().inset(16); $0.height.equalTo(34) }
        notice.snp.makeConstraints { $0.top.equalTo(filter.snp.bottom).offset(12); $0.leading.trailing.equalTo(filter) }
        tableView.snp.makeConstraints { $0.top.equalTo(notice.snp.bottom).offset(8); $0.leading.trailing.bottom.equalToSuperview() }
        refreshBankingData()
    }
    override func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.tintColor = .abankTextPrimary
    }
    override func refreshBankingData() {
        records = store.transferRecords().filter { record in
            filter.selectedSegmentIndex == 0 || (filter.selectedSegmentIndex == 1 ? record.status == .succeeded : record.status == .failed)
        }
        emptyLabel.isHidden = !records.isEmpty
        tableView.reloadData()
    }
    @objc private func filterChanged() { refreshBankingData() }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { records.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "transfer", for: indexPath) as! TransferHistoryCell
        cell.configure(records[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController(TransferResultViewController(record: records[indexPath.row], store: store), animated: true)
    }
}

final class TransferRecipientsViewController: TransferFlowViewController {
    private let method: TransferMethod?
    private let store: FinanceLedgerStore
    var onSelect: ((TransferRecipient) -> Void)?
    init(method: TransferMethod? = nil, store: FinanceLedgerStore? = nil) {
        self.method = method
        self.store = store ?? .shared
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func setupUI() {
        super.setupUI()
        title = "转账伙伴"
        addNotice("选择本机演示伙伴，或返回手动填写")
        let recipients = store.transferRecipients().filter { method == nil || $0.method == method }
        for recipient in recipients {
            let row = TransferInfoRow(recipient.name, value: recipient.bankName + "\n" + recipient.maskedDestination,
                                      image: recipient.bankName == "中国农业银行" ? "abc_account_bank_logo" : nil)
            row.isUserInteractionEnabled = true
            let button = UIButton(type: .custom)
            row.addSubview(button)
            button.snp.makeConstraints { $0.edges.equalToSuperview() }
            button.accessibilityLabel = recipient.name + " " + recipient.maskedDestination
            button.addAction(UIAction { [weak self] _ in self?.onSelect?(recipient) }, for: .touchUpInside)
            addGroup([row])
        }
        if recipients.isEmpty { addNotice("暂无该类型的转账伙伴，请返回手动填写") }
    }
}

final class TransferLimitsViewController: TransferFlowViewController {
    private let store: FinanceLedgerStore
    init(store: FinanceLedgerStore? = nil) {
        self.store = store ?? .shared
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func setupUI() {
        super.setupUI()
        title = "转账设置"
        addNotice("本机模拟规则，当前仅供查看")
        addGroup([
            TransferInfoRow("单笔限额", value: "¥ " + TransferMoney.text(store.transferLimits.perTransferInCents)),
            TransferInfoRow("每日累计限额", value: "¥ " + TransferMoney.text(store.transferLimits.dailyInCents)),
            TransferInfoRow("手续费", value: "¥ 0.00")
        ])
        addNotice("金额和限额在确认前及提交时均会校验。设备管理与限额编辑将在安全中心阶段完善。")
    }
}
