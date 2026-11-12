//
//  AccountShareViewController.swift
//  ABank
//
//  查看/分享账户信息：户名脱敏、卡号可切换显示，可复制卡号或调起系统分享（标注模拟数据）。
//

import UIKit
import SnapKit

final class AccountShareViewController: TransferFlowViewController, RouteHosting {
    static let openingBranch = "农行西安东关正街支行"

    private let accountID: String
    private let ledger: FinanceLedgerStore
    private let card: MyAccountDebitCard?
    private let holderName: String
    private let numberLabel = UILabel()
    private let eyeButton = UIButton(type: .system)
    private var showsFullNumber = false

    var hostedRoute: AppRoute? { .accountShare(accountID: accountID) }

    init(accountID: String, ledger: FinanceLedgerStore = .shared,
         card: MyAccountDebitCard? = nil, holderName: String? = nil) {
        self.accountID = accountID
        self.ledger = ledger
        self.card = card ?? MockDataProvider.shared.getMyAccountPageData().debitCards.first { $0.accountId == accountID }
        self.holderName = AccountHolderName.masked(holderName ?? CustomerInfoStore.shared.load().name)
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "查看/分享"
        guard let card else {
            addNotice(AccountSettingsError.accountNotFound.localizedDescription)
            return
        }
        eyeButton.accessibilityIdentifier = "share.eye"
        eyeButton.tintColor = .abankTextSecondary
        eyeButton.addAction(UIAction { [weak self] _ in self?.toggleNumber() }, for: .touchUpInside)
        addGroup([
            TransferInfoRow("户名", value: holderName),
            makeNumberRow(),
            TransferInfoRow("开户行", value: ledger.account(id: accountID)?.openingBranch ?? "—"),
            TransferInfoRow("账户类型", value: card.accountClass)
        ])
        _ = addButton("复制卡号", id: "share.copy", primary: false) { [weak self] in self?.copyNumber() }
        _ = addButton("分享", id: "share.share") { [weak self] in self?.share() }
        addNotice("请妥善保管账户信息，仅向可信任的人分享")
        renderNumber()
    }

    private var plainNumber: String { (card?.fullNumber ?? "").filter { !$0.isWhitespace } }

    private func renderNumber() {
        guard let card else { return }
        numberLabel.text = showsFullNumber ? card.fullNumber : card.maskedNumber
        let symbol = showsFullNumber ? "eye" : "eye.slash"
        eyeButton.setImage(UIImage(systemName: symbol), for: .normal)
        eyeButton.accessibilityLabel = showsFullNumber ? "隐藏卡号" : "显示完整卡号"
    }

    /// 卡号行：标题、卡号、显示/隐藏按钮。
    private func makeNumberRow() -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = "卡号"
        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.textColor = .abankTextSecondary
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        numberLabel.font = .systemFont(ofSize: 16)
        numberLabel.textColor = .abankTextPrimary
        numberLabel.textAlignment = .right
        numberLabel.adjustsFontSizeToFitWidth = true
        numberLabel.accessibilityIdentifier = "share.number"
        eyeButton.setContentHuggingPriority(.required, for: .horizontal)
        eyeButton.snp.makeConstraints { $0.size.equalTo(44) }
        let stack = UIStackView(arrangedSubviews: [titleLabel, numberLabel, eyeButton])
        stack.spacing = 8
        stack.alignment = .center
        let row = UIView()
        row.addSubview(stack)
        stack.snp.makeConstraints { $0.leading.equalToSuperview().inset(16); $0.trailing.equalToSuperview().inset(8); $0.top.bottom.equalToSuperview().inset(13) }
        row.snp.makeConstraints { $0.height.greaterThanOrEqualTo(58) }
        let line = UIView()
        line.backgroundColor = .abankSeparator.withAlphaComponent(0.5)
        row.addSubview(line)
        line.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(16); $0.bottom.equalToSuperview(); $0.height.equalTo(0.5) }
        return row
    }

    private func toggleNumber() {
        showsFullNumber.toggle()
        renderNumber()
    }

    private func copyNumber() {
        guard plainNumber.allSatisfy(\.isNumber) else { showToast("该账户暂未提供完整卡号"); return }
        UIPasteboard.general.string = plainNumber
        showToast("已复制")
    }

    private func share() {
        guard let card else { return }
        let text = "户名：\(holderName)\n卡号：\(card.fullNumber)\n开户行：\(ledger.account(id: accountID)?.openingBranch ?? "—")"
        let controller = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = view
        controller.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 80, width: 1, height: 1)
        present(controller, animated: true)
    }
}
