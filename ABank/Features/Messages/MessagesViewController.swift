import UIKit
import SnapKit

final class MessagesViewController: BankingDataViewController, UITableViewDataSource, UITableViewDelegate {
    private let table = UITableView(frame: .zero, style: .insetGrouped)
    private let filter = UISegmentedControl(items: ["全部", "未读", "交易", "账户/财富"])
    private var rows: [BankMessage] = []
    private let messages = BankMessageStore.shared
    override func setupUI() {
        title = "消息中心"
        view.backgroundColor = .abankBackground
        filter.selectedSegmentIndex = 0
        filter.selectedSegmentTintColor = .abankPrimaryDark
        filter.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        filter.addAction(UIAction { [weak self] _ in self?.refreshBankingData() }, for: .valueChanged)
        filter.accessibilityIdentifier = "messages.filter"
        table.dataSource = self; table.delegate = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 96
        view.addSubview(filter); view.addSubview(table)
        filter.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(12); $0.leading.trailing.equalToSuperview().inset(16); $0.height.equalTo(36) }
        table.snp.makeConstraints { $0.top.equalTo(filter.snp.bottom).offset(8); $0.leading.trailing.bottom.equalToSuperview() }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "全部已读", style: .plain, target: self, action: #selector(readAll))
    }
    override func refreshBankingData() {
        rows = messages.messages().filter { item in
            switch filter.selectedSegmentIndex {
            case 1: return !messages.isRead(item)
            case 2: return item.category == "交易通知"
            case 3: return item.category != "交易通知"
            default: return true
            }
        }
        let empty = UILabel()
        empty.text = "暂无消息，交易和账单通知将显示在这里"
        empty.numberOfLines = 0; empty.textAlignment = .center; empty.textColor = .abankTextSecondary
        table.backgroundView = rows.isEmpty ? empty : nil
        table.reloadData()
    }
    @objc private func readAll() { messages.markRead(messages.messages()); refreshBankingData() }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = rows[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = item.title
        cell.textLabel?.numberOfLines = 0
        cell.imageView?.image = UIImage(systemName: messages.isRead(item) ? "envelope.open" : "envelope.badge.fill")
        cell.imageView?.tintColor = messages.isRead(item) ? .abankTextSecondary : .abankPrimaryDark
        cell.accessibilityValue = messages.isRead(item) ? "已读" : "未读"
        cell.textLabel?.font = .preferredFont(forTextStyle: .headline)
        cell.detailTextLabel?.text = item.body + "\n" + item.date
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.font = .preferredFont(forTextStyle: .subheadline)
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = rows[indexPath.row]
        messages.markRead([item])
        navigationController?.pushViewController(BankMessageDetailViewController(message: item), animated: true)
    }
}

final class BankMessageDetailViewController: TransferFlowViewController {
    private let message: BankMessage
    init(message: BankMessage) { self.message = message; super.init(nibName: nil, bundle: nil); hidesBottomBarWhenPushed = true }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func setupUI() {
        super.setupUI(); title = "通知详情"
        let headline = UILabel(); headline.text = message.title; headline.font = .preferredFont(forTextStyle: .title2); headline.numberOfLines = 0
        let body = UILabel(); body.text = message.body; body.font = .preferredFont(forTextStyle: .body); body.numberOfLines = 0
        [headline, body].forEach { contentStack.addArrangedSubview($0) }
        addNotice(message.date)
        _ = addButton("查看详情", id: "message.open") { [weak self] in guard let self else { return }; self.router.open(self.message.route, from: self) }
    }
}
