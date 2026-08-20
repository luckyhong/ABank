//
//  TaxIdentityViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class TaxIdentityViewController: BaseViewController {

    private var selected: String
    private var optionButtons: [UIButton] = []

    init(selected: String = CustomerInfoStore.shared.load().taxIdentity) {
        self.selected = selected
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "税收身份声明"
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

        let intro = UILabel()
        intro.text = "根据《非居民金融账户涉税信息尽职调查管理办法》，请确认并声明您的税收居民身份。"
        intro.font = .systemFont(ofSize: 13)
        intro.textColor = .abankTextSecondary
        intro.numberOfLines = 0
        view.addSubview(intro)
        intro.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.backgroundColor = .white
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(intro.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
        }

        for (index, title) in CustomerInfoCatalog.taxIdentities.enumerated() {
            let button = makeOption(title: title, tag: index)
            optionButtons.append(button)
            stack.addArrangedSubview(button)
        }
        refreshSelection()

        let confirmButton = UIButton(type: .system)
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

    private func makeOption(title: String, tag: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = tag
        button.backgroundColor = .white
        button.addTarget(self, action: #selector(optionTapped(_:)), for: .touchUpInside)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .abankTextPrimary
        titleLabel.numberOfLines = 2
        titleLabel.tag = 100

        let check = UIImageView()
        check.tag = 101
        check.contentMode = .scaleAspectFit
        check.tintColor = .abankTeal

        let separator = UIView()
        separator.backgroundColor = .abankSeparator

        button.addSubview(titleLabel)
        button.addSubview(check)
        button.addSubview(separator)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalTo(check.snp.leading).offset(-12)
            make.top.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
        check.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        separator.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.bottom.equalToSuperview()
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }
        button.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(56)
        }
        return button
    }

    private func refreshSelection() {
        for button in optionButtons {
            let title = CustomerInfoCatalog.taxIdentities[button.tag]
            let check = button.viewWithTag(101) as? UIImageView
            let isOn = title == self.selected
            check?.image = UIImage(systemName: isOn ? "checkmark.circle.fill" : "circle")
            check?.tintColor = isOn ? .abankTeal : .abankTextTertiary
        }
    }

    @objc private func optionTapped(_ sender: UIButton) {
        selected = CustomerInfoCatalog.taxIdentities[sender.tag]
        refreshSelection()
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func confirmTapped() {
        CustomerInfoStore.shared.update { $0.taxIdentity = selected }
        showToast("税收身份已声明")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }
}
