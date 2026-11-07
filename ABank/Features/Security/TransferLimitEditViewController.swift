//
//  TransferLimitEditViewController.swift
//  ABank
//
//  修改转账限额：实时校验，出错时行内提示并禁用保存；Store 保存时再次校验。
//

import UIKit

final class TransferLimitEditViewController: SecurityFlowViewController {
    private let perTransferInput = TransferInputRow("单笔限额", placeholder: "1 至 500000 元", id: "limitEdit.perTransfer",
                                                    keyboard: .decimalPad)
    private let dailyInput = TransferInputRow("日累计限额", placeholder: "1 至 1000000 元", id: "limitEdit.daily",
                                              keyboard: .decimalPad)
    private let errorLabel = UILabel()
    private var saveButton: UIButton?

    override func setupUI() {
        super.setupUI()
        title = "修改限额"
        addNotice("单位：元。单笔限额不能高于日累计限额")
        let limits = security.transferLimits
        perTransferInput.field.text = TransferMoney.text(limits.perTransferInCents)
        dailyInput.field.text = TransferMoney.text(limits.dailyInCents)
        for input in [perTransferInput, dailyInput] {
            input.field.addAction(UIAction { [weak self] _ in self?.validateInput() }, for: .editingChanged)
        }
        addGroup([perTransferInput, dailyInput])

        errorLabel.font = .abankCaption()
        errorLabel.textColor = .abankError
        errorLabel.numberOfLines = 0
        errorLabel.accessibilityIdentifier = "limitEdit.error"
        contentStack.addArrangedSubview(errorLabel)

        saveButton = addButton("保存", id: "limitEdit.save") { [weak self] in self?.save() }
        validateInput()
    }

    /// 返回解析后的限额；不合法时显示第一条错误并禁用保存。
    @discardableResult
    private func validateInput() -> (perTransfer: Int64, daily: Int64)? {
        do {
            let perTransfer = try TransferLimitRules.parse(perTransferInput.field.text ?? "")
            let daily = try TransferLimitRules.parse(dailyInput.field.text ?? "")
            try TransferLimitRules.validate(perTransfer: perTransfer, daily: daily)
            setError(nil)
            return (perTransfer, daily)
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
        guard let limits = validateInput() else { return }
        view.endEditing(true)
        do {
            try security.setTransferLimits(perTransfer: limits.perTransfer, daily: limits.daily)
        } catch let error as TransferLimitError {
            setError(error.localizedDescription)
            return
        } catch {
            showToast(SecuritySettingsError.persistence.localizedDescription)
            return
        }
        let previous = navigationController.flatMap { $0.viewControllers.dropLast().last } as? BaseViewController
        navigationController?.popViewController(animated: true)
        previous?.showToast("限额已更新")
    }
}
