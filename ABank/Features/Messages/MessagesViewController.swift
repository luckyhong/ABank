import UIKit
import SnapKit

final class MessagesViewController: BankingDataViewController, UITableViewDataSource, UITableViewDelegate {
    private let table = UITableView(frame: .zero, style: .insetGrouped)
    private let filter = UISegmentedControl(items: ["全部", "未读", "交易", "账户/财富"])
    private let emptyTitle = MessageTypography.label(font: .abankHeadline(), style: .headline)
    private let emptyBody = MessageTypography.label(font: .abankSubheadline(), style: .subheadline, color: .abankTextSecondary)
    private var rows: [BankMessage] = []
    private let messages = BankMessageStore.shared

    override func setupUI() {
        title = "消息中心"
        view.backgroundColor = .abankBackground

        filter.selectedSegmentIndex = 0
        filter.backgroundColor = .abankCardBackground
        filter.selectedSegmentTintColor = .abankMintSurface
        filter.setTitleTextAttributes([.foregroundColor: UIColor.abankTextSecondary, .font: UIFont.abankCaptionMedium()], for: .normal)
        filter.setTitleTextAttributes([.foregroundColor: UIColor.abankMintInk, .font: UIFont.abankCaptionMedium()], for: .selected)
        filter.addAction(UIAction { [weak self] _ in self?.refreshBankingData() }, for: .valueChanged)
        filter.accessibilityIdentifier = "messages.filter"

        table.dataSource = self
        table.delegate = self
        table.backgroundColor = .abankBackground
        table.separatorColor = .abankSeparator
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 102
        table.register(BankMessageCell.self, forCellReuseIdentifier: BankMessageCell.reuseID)
        view.addSubview(filter)
        view.addSubview(table)

        filter.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        table.snp.makeConstraints { make in
            make.top.equalTo(filter.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview()
        }

        let readAllButton = UIBarButtonItem(title: "全部已读", style: .plain, target: self, action: #selector(readAll))
        readAllButton.tintColor = .abankMintInk
        navigationItem.rightBarButtonItem = readAllButton
    }

    override func refreshBankingData() {
        let all = messages.messages()
        let unread = all.filter { !messages.isRead($0) }
        navigationItem.rightBarButtonItem?.isEnabled = !unread.isEmpty
        switch filter.selectedSegmentIndex {
        case 1:
            rows = unread
            emptyTitle.text = "没有未读消息"
            emptyBody.text = "已读通知可在「全部」中查看"
        case 2:
            rows = all.filter { $0.category == "交易通知" }
            emptyTitle.text = "暂无交易通知"
            emptyBody.text = "转账、缴费等通知将显示在这里"
        case 3:
            rows = all.filter { $0.category != "交易通知" }
            emptyTitle.text = "暂无账户或财富通知"
            emptyBody.text = "账单、还款和财富通知将显示在这里"
        default:
            rows = all
            emptyTitle.text = "暂无消息"
            emptyBody.text = "交易和账单通知将显示在这里"
        }
        table.backgroundView = rows.isEmpty ? makeEmptyView() : nil
        table.reloadData()
    }

    private func makeEmptyView() -> UIView {
        let container = UIView()
        emptyTitle.textAlignment = .center
        emptyBody.textAlignment = .center
        let copy = UIStackView(arrangedSubviews: [emptyTitle, emptyBody])
        copy.axis = .vertical
        copy.spacing = 8
        container.addSubview(copy)
        copy.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.centerY.equalToSuperview().offset(-32)
        }
        return container
    }

    @objc private func readAll() {
        messages.markRead(messages.messages())
        refreshBankingData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: BankMessageCell.reuseID, for: indexPath) as! BankMessageCell
        cell.configure(item, isRead: messages.isRead(item))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = rows[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        messages.markRead([item])
        navigationController?.pushViewController(BankMessageDetailViewController(message: item), animated: true)
    }
}

private final class BankMessageCell: UITableViewCell {
    static let reuseID = "BankMessageCell"
    private let headline = MessageTypography.label(font: .abankHeadline(), style: .headline)
    private let body = MessageTypography.label(font: .abankSubheadline(), style: .subheadline, color: .abankTextSecondary)
    private let metadata = MessageTypography.label(font: .abankCaption(), style: .footnote, color: .abankTextSecondary)
    private let icon = UIImageView()
    private let iconBackground = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .abankCardBackground
        accessoryType = .disclosureIndicator
        let selection = UIView()
        selection.backgroundColor = .abankSectionBackground
        selectedBackgroundView = selection

        icon.contentMode = .scaleAspectFit
        iconBackground.layer.cornerRadius = 10
        iconBackground.addSubview(icon)

        let text = UIStackView(arrangedSubviews: [headline, body, metadata])
        text.axis = .vertical
        text.spacing = 5
        text.setCustomSpacing(8, after: body)

        contentView.addSubview(iconBackground)
        contentView.addSubview(text)
        iconBackground.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(14)
            make.size.equalTo(36)
        }
        icon.snp.makeConstraints { $0.edges.equalToSuperview().inset(9) }
        text.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(14)
            make.leading.equalTo(iconBackground.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(8)
        }
        separatorInset.left = 62
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ item: BankMessage, isRead: Bool) {
        headline.text = item.title
        body.text = item.body
        metadata.text = "\(item.category)  ·  \(item.date)"
        icon.image = UIImage(systemName: isRead ? "envelope.open" : "envelope.badge")
        icon.tintColor = isRead ? .abankTextSecondary : .abankMintInk
        iconBackground.backgroundColor = isRead ? .abankSectionBackground : .abankMintSurface
        accessibilityLabel = "\(item.title)，\(item.body)，\(item.category)，\(item.date)"
        accessibilityValue = isRead ? "已读" : "未读"
    }
}

final class BankMessageDetailViewController: TransferFlowViewController {
    private let message: BankMessage

    init(message: BankMessage) {
        self.message = message
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupUI() {
        super.setupUI()
        title = "通知详情"

        let headline = MessageTypography.label(font: .abankTitle2(), style: .title2)
        headline.text = message.title
        headline.accessibilityTraits = .header
        let metadata = MessageTypography.label(font: .abankCaption(), style: .footnote, color: .abankTextSecondary)
        metadata.text = "\(message.category)  ·  \(message.date)"
        let body = MessageTypography.label(font: .abankBody(), style: .body)
        body.text = message.body

        let notice = UIStackView(arrangedSubviews: [headline, metadata, body])
        notice.axis = .vertical
        notice.spacing = 8
        notice.setCustomSpacing(16, after: metadata)
        notice.backgroundColor = .abankCardBackground
        notice.layer.cornerRadius = 12
        notice.isLayoutMarginsRelativeArrangement = true
        notice.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 18, leading: 16, bottom: 18, trailing: 16)
        contentStack.addArrangedSubview(notice)

        let button = addButton("查看详情", id: "message.open", primary: false) { [weak self] in
            guard let self else { return }
            self.router.open(self.message.route, from: self)
        }
        button.backgroundColor = .abankMintSurface
        button.setTitleColor(.abankMintInk, for: .normal)
    }
}

private enum MessageTypography {
    static func label(font: UIFont, style: UIFont.TextStyle, color: UIColor = .abankTextPrimary) -> UILabel {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: style).scaledFont(for: font)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        label.numberOfLines = 0
        return label
    }
}
