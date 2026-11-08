//
//  AccountAliasViewController.swift
//  ABank
//
//  设置借记卡别名：实时校验，不合规时行内提示并禁用保存；账本保存时再次校验。
//

import UIKit

final class AccountAliasViewController: TransferFlowViewController, RouteHosting {
    private let accountID: String
    private let ledger: FinanceLedgerStore
    private let input = TransferInputRow("别名", placeholder: "最多 \(AccountAliasRules.maxLength) 个字，留空恢复默认",
                                         id: "alias.field")
    private let errorLabel = UILabel()
    private let remainingLabel = UILabel()
    private var saveButton: UIButton?

    var hostedRoute: AppRoute? { .accountAlias(accountID: accountID) }

    init(accountID: String, ledger: FinanceLedgerStore = .shared) {
        self.accountID = accountID
        self.ledger = ledger
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "账户别名"
        guard let account = ledger.account(id: accountID) else {
            addNotice(AccountSettingsError.accountNotFound.localizedDescription)
            return
        }
        addNotice("为 尾号\(account.tailNumber) 的借记卡设置别名，设置后各页面统一显示“别名（尾号）”")
        input.field.text = account.alias
        input.field.clearButtonMode = .whileEditing
        input.field.addAction(UIAction { [weak self] _ in self?.validateInput() }, for: .editingChanged)
        addGroup([input])

        remainingLabel.font = .abankCaption()
        remainingLabel.textColor = .abankTextSecondary
        remainingLabel.accessibilityIdentifier = "alias.remaining"
        errorLabel.font = .abankCaption()
        errorLabel.textColor = .abankError
        errorLabel.numberOfLines = 0
        errorLabel.accessibilityIdentifier = "alias.error"
        contentStack.addArrangedSubview(remainingLabel)
        contentStack.addArrangedSubview(errorLabel)

        saveButton = addButton("保存", id: "alias.save") { [weak self] in self?.save() }
        addNotice("本机模拟数据，仅保存在本机")
        validateInput()
    }

    /// 返回规范化结果（.some(nil) 表示清除）；不合规时显示原因并禁用保存。
    @discardableResult
    private func validateInput() -> String?? {
        let raw = input.field.text ?? ""
        let count = raw.trimmingCharacters(in: .whitespacesAndNewlines).count
        remainingLabel.text = "还可输入 \(max(0, AccountAliasRules.maxLength - count)) 字"
        do {
            let alias = try AccountAliasRules.normalized(raw)
            setError(nil)
            return .some(alias)
        } catch {
            setError(error.localizedDescription)
            return nil
        }
    }

    private func setError(_ message: String?) {
        errorLabel.text = message
        errorLabel.isHidden = message == nil
        saveButton?.isEnabled = message == nil
        saveButton?.alpha = message == nil ? 1 : 0.4
    }

    private func save() {
        guard let alias = validateInput() else { return }
        view.endEditing(true)
        do {
            try ledger.setAlias(input.field.text ?? "", accountID: accountID)
        } catch let error as AccountSettingsError where error != .persistence && error != .accountNotFound {
            setError(error.localizedDescription)
            return
        } catch {
            showToast(error.localizedDescription)
            return
        }
        let previous = navigationController.flatMap { $0.viewControllers.dropLast().last } as? BaseViewController
        navigationController?.popViewController(animated: true)
        previous?.showToast(alias == nil ? "已恢复默认名称" : "别名已更新")
    }
}
