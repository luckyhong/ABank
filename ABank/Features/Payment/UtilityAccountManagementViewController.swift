import UIKit

final class UtilityAccountManagementViewController: PaymentFlowViewController {
    override var maximumContentWidth: CGFloat? { 560 }

    private let kind: PaymentKind

    init(kind: PaymentKind, ledger: FinanceLedgerStore) {
        self.kind = kind
        super.init(ledger: ledger)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func refreshBankingData() {
        clearContent()
        title = kind.title + "户号管理"
        let accounts = ledger.utilityAccounts(kind: kind)
        if accounts.active.isEmpty {
            addEmptyState("暂无已添加户号", id: "payment.manage.empty")
        }
        if !accounts.active.isEmpty { addSectionTitle("我的户号") }
        for account in accounts.active {
            let tag = account.id == accounts.defaultID ? BranchStatusTagView(text: "默认", active: true) : nil
            let row = BenefitsRow(title: account.name, subtitle: account.accountNo,
                                  trailing: tag,
                                  id: "payment.manage." + account.id, showsChevron: true, scalesType: true)
            row.accessibilityHint = account.id == accounts.defaultID ? "默认户号，打开管理选项" : "打开管理选项"
            row.onTap = { [weak self, weak row] in
                guard let row else { return }
                self?.showActions(for: account, from: row)
            }
            contentStack.addArrangedSubview(row)
        }
        if !accounts.available.isEmpty {
            if let previous = contentStack.arrangedSubviews.last { contentStack.setCustomSpacing(Spacing.lg, after: previous) }
            addSectionTitle("可添加的模拟户号")
        }
        for account in accounts.available {
            let row = BenefitsRow(title: account.name, subtitle: account.accountNo, trailing: nil,
                                  id: "payment.add." + account.id, showsChevron: true, scalesType: true)
            row.accessibilityHint = "添加此户号"
            row.onTap = { [weak self] in self?.apply(.add, to: account.id) }
            contentStack.addArrangedSubview(row)
        }
    }

    private func showActions(for account: BillAccount, from source: UIView) {
        let sheet = UIAlertController(title: account.name, message: account.accountNo, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "修改名称", style: .default) { [weak self] _ in self?.rename(account) })
        sheet.addAction(UIAlertAction(title: "设为默认户号", style: .default) { [weak self] _ in
            self?.apply(.makeDefault, to: account.id)
        })
        sheet.addAction(UIAlertAction(title: "移除户号", style: .destructive) { [weak self] _ in
            self?.confirm("移除后仍可在缴费记录中查看历史订单。", confirmTitle: "确认移除") { [weak self] in
                self?.apply(.remove, to: account.id)
            }
        })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        sheet.popoverPresentationController?.sourceView = source
        sheet.popoverPresentationController?.sourceRect = source.bounds
        present(sheet, animated: true)
    }

    private func rename(_ account: BillAccount) {
        let alert = UIAlertController(title: "修改户号名称", message: "请输入 1–24 个字符。", preferredStyle: .alert)
        alert.addTextField { $0.text = account.name; $0.accessibilityLabel = "户号名称" }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "保存", style: .default) { [weak self, weak alert] _ in
            self?.apply(.rename(alert?.textFields?.first?.text ?? ""), to: account.id)
        })
        present(alert, animated: true)
    }

    private func apply(_ edit: UtilityAccountEdit, to id: String) {
        do { try ledger.editUtilityAccount(id: id, edit: edit) }
        catch { showError(error) }
    }
}
