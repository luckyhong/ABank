//
//  MobileRechargeViewController.swift
//  ABank
//
//  手机充值：输入号码、选择面额，下一步进入确认页。号码校验与运营商仅为本地展示。
//

import UIKit
import SnapKit

final class MobileRechargeViewController: PaymentFlowViewController, RouteHosting {
    private let phoneRow = TransferInputRow("手机号码", placeholder: "请输入 11 位手机号", id: "recharge.phone", keyboard: .numberPad)
    private let carrierLabel = UILabel()
    private var selectedFace: Int64 = 5_000
    private var nextButton: UIButton?

    var hostedRoute: AppRoute? { .mobileRecharge }

    override func setupUI() {
        super.setupUI()
        title = "手机充值"
        phoneRow.field.text = CustomerInfoStore.shared.load().mobile
        phoneRow.field.addAction(UIAction { [weak self] _ in self?.phoneDidChange() }, for: .editingChanged)
        carrierLabel.font = .abankCaption()
        carrierLabel.numberOfLines = 0
        carrierLabel.accessibilityIdentifier = "recharge.carrier"
    }

    override func setupNavigationBar() {
        super.setupNavigationBar()
        let records = UIBarButtonItem(title: "充值记录", style: .plain, target: self, action: #selector(openRecords))
        records.accessibilityIdentifier = "recharge.records"
        navigationItem.rightBarButtonItem = records
    }

    @objc private func openRecords() {
        router.open(.orders, from: self)
    }

    override func refreshBankingData() {
        clearContent()
        addGroup([phoneRow])
        contentStack.addArrangedSubview(carrierLabel)
        addSectionTitle("选择面额")
        contentStack.addArrangedSubview(faceGrid())
        nextButton = addButton("下一步", id: "recharge.next") { [weak self] in self?.nextTapped() }
        addNotice("请核对账户与交易信息后办理")
        phoneDidChange()
    }

    private func faceGrid() -> UIView {
        let columns = 3
        let faces = PaymentCatalog.denominationsInCents
        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = Spacing.sm
        for start in stride(from: 0, to: faces.count, by: columns) {
            let line = UIStackView()
            line.spacing = Spacing.sm
            line.distribution = .fillEqually
            for face in faces[start..<min(start + columns, faces.count)] {
                line.addArrangedSubview(faceButton(face))
            }
            grid.addArrangedSubview(line)
        }
        return grid
    }

    private func faceButton(_ face: Int64) -> UIButton {
        let yuan = face / 100
        let selected = face == selectedFace
        let button = UIButton(type: .system)
        button.setTitle("\(yuan) 元", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.setTitleColor(selected ? .white : .abankTeal, for: .normal)
        button.backgroundColor = selected ? .abankTeal : .white
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.abankTeal.cgColor
        button.accessibilityIdentifier = "recharge.face.\(yuan)"
        button.accessibilityTraits = selected ? [.button, .selected] : .button
        button.snp.makeConstraints { $0.height.equalTo(52) }
        button.addAction(UIAction { [weak self] _ in
            self?.selectedFace = face
            self?.refreshBankingData()
        }, for: .touchUpInside)
        return button
    }

    private var normalizedPhone: String {
        PaymentRules.normalizedPhone(phoneRow.field.text ?? "")
    }

    private func phoneDidChange() {
        let phone = normalizedPhone
        let valid = PaymentRules.isValidPhone(phone)
        if phone.isEmpty {
            carrierLabel.text = "请输入手机号码"
            carrierLabel.textColor = .abankTextSecondary
        } else if valid {
            carrierLabel.text = "运营商：" + PaymentRules.phoneOperator(of: phone).title
            carrierLabel.textColor = .abankTextSecondary
        } else {
            carrierLabel.text = PaymentError.invalidPhone.localizedDescription
            carrierLabel.textColor = .abankError
        }
        nextButton?.isEnabled = valid
        nextButton?.backgroundColor = valid ? .abankTeal : .abankTextTertiary
    }

    private func nextTapped() {
        let phone = normalizedPhone
        guard PaymentRules.isValidPhone(phone) else { return }
        // 只在确认前拦截权限问题；其他校验交给确认页的原有逻辑。
        do { _ = try ledger.validateMobileRecharge(phone: phone, faceInCents: selectedFace, couponID: nil) }
        catch { if presentPermissionBlockedIfNeeded(error, router: router) { return } }
        router.open(.mobileRechargeConfirm(phone: phone, faceInCents: selectedFace), from: self)
    }
}
