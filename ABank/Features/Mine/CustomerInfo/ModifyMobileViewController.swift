//
//  ModifyMobileViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class ModifyMobileViewController: BaseViewController {

    private let currentMobile: String
    private var countdown = 0
    private var timer: Timer?
    private let presetCode = "123456"

    private let currentRow = CustomerInfoFormRowView(title: "原手机号")
    private let mobileField = UITextField()
    private let codeField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let confirmButton = UIButton(type: .system)
    private let tipLabel = UILabel()

    init(currentMobile: String = CustomerInfoStore.shared.load().mobile) {
        self.currentMobile = currentMobile
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "修改手机号码"
        navigationController?.navigationBar.tintColor = .abankTextPrimary
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
    }

    override func setupUI() {
        view.backgroundColor = .abankBackground

        let card = UIView()
        card.backgroundColor = .white
        view.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }

        currentRow.setValue(CustomerInfoRecord.maskMobile(currentMobile))

        let newRow = makeInputRow(title: "新手机号", field: mobileField, placeholder: "请输入新手机号码")
        mobileField.keyboardType = .numberPad

        let codeRow = UIView()
        codeRow.backgroundColor = .white
        let codeTitle = UILabel()
        codeTitle.text = "验证码"
        codeTitle.font = .systemFont(ofSize: 16)
        codeTitle.textColor = .abankTextPrimary
        codeField.placeholder = "请输入验证码"
        codeField.font = .systemFont(ofSize: 16)
        codeField.textAlignment = .right
        codeField.keyboardType = .numberPad
        codeField.textColor = .abankTextPrimary

        sendButton.setTitle("获取验证码", for: .normal)
        sendButton.setTitleColor(.abankTeal, for: .normal)
        sendButton.titleLabel?.font = .systemFont(ofSize: 14)
        sendButton.addTarget(self, action: #selector(sendCode), for: .touchUpInside)

        let separator = UIView()
        separator.backgroundColor = .abankSeparator

        codeRow.addSubview(codeTitle)
        codeRow.addSubview(codeField)
        codeRow.addSubview(sendButton)
        codeRow.addSubview(separator)
        codeTitle.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(88)
        }
        sendButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        codeField.snp.makeConstraints { make in
            make.leading.equalTo(codeTitle.snp.trailing)
            make.trailing.equalTo(sendButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
        separator.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.bottom.equalToSuperview()
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }
        codeRow.snp.makeConstraints { make in
            make.height.equalTo(50)
        }

        card.addSubview(currentRow)
        card.addSubview(newRow)
        card.addSubview(codeRow)
        currentRow.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        newRow.snp.makeConstraints { make in
            make.top.equalTo(currentRow.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }
        codeRow.snp.makeConstraints { make in
            make.top.equalTo(newRow.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        tipLabel.text = "验证码将发送至新手机号，本地演示验证码为 \(presetCode)"
        tipLabel.font = .systemFont(ofSize: 13)
        tipLabel.textColor = .abankTextTertiary
        tipLabel.numberOfLines = 0
        view.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { make in
            make.top.equalTo(card.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        confirmButton.setTitle("确定", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        confirmButton.backgroundColor = UIColor(red: 1.0, green: 0.48, blue: 0.16, alpha: 1)
        confirmButton.layer.cornerRadius = 4
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        view.addSubview(confirmButton)
        confirmButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12)
        }
    }

    private func makeInputRow(title: String, field: UITextField, placeholder: String) -> UIView {
        let row = UIView()
        row.backgroundColor = .white
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .abankTextPrimary
        field.placeholder = placeholder
        field.font = .systemFont(ofSize: 16)
        field.textAlignment = .right
        field.textColor = .abankTeal
        let separator = UIView()
        separator.backgroundColor = .abankSeparator
        row.addSubview(titleLabel)
        row.addSubview(field)
        row.addSubview(separator)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(88)
        }
        field.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        separator.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.bottom.equalToSuperview()
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }
        row.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        return row
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func sendCode() {
        let mobile = mobileField.text ?? ""
        guard mobile.count == 11, mobile.hasPrefix("1") else {
            showToast("请输入11位新手机号码")
            return
        }
        guard mobile != currentMobile else {
            showToast("新手机号不能与原号码相同")
            return
        }
        countdown = 60
        sendButton.isEnabled = false
        updateCountdownTitle()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        showToast("验证码已发送（\(presetCode)）")
    }

    private func tick() {
        countdown -= 1
        if countdown <= 0 {
            timer?.invalidate()
            sendButton.isEnabled = true
            sendButton.setTitle("获取验证码", for: .normal)
        } else {
            updateCountdownTitle()
        }
    }

    private func updateCountdownTitle() {
        sendButton.setTitle("重新获取(\(countdown)s)", for: .normal)
    }

    @objc private func confirmTapped() {
        view.endEditing(true)
        let mobile = mobileField.text ?? ""
        let code = codeField.text ?? ""
        guard mobile.count == 11, mobile.hasPrefix("1") else {
            showToast("请输入11位新手机号码")
            return
        }
        guard mobile != currentMobile else {
            showToast("新手机号不能与原号码相同")
            return
        }
        guard code == presetCode else {
            showToast("验证码不正确")
            return
        }
        CustomerInfoStore.shared.update { $0.mobile = mobile }
        showToast("手机号码修改成功")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }

    deinit {
        timer?.invalidate()
    }
}
