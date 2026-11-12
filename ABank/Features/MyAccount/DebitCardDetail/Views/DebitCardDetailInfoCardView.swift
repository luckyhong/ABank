//
//  DebitCardDetailInfoCardView.swift
//  ABank
//

import UIKit
import SnapKit

final class DebitCardDetailInfoCardView: UIView {

    var onToggleNumberVisibility: (() -> Void)?
    var onAction: ((String) -> Void)?

    private let classBadge = UILabel()
    private let cardNumberLabel = UILabel()
    /// 卡号上方的别名行；未设置别名时隐藏。
    private let aliasLabel = UILabel()
    private let eyeButton = UIButton(type: .system)
    private let infoStack = UIStackView()
    private let actionStack = UIStackView()

    private var infoRows: [DebitCardDetailKeyValueRow] = []
    private var isNumberVisible = false
    private var maskedNumber = ""
    private var fullNumber = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with data: DebitCardDetailPageData) {
        classBadge.text = data.accountClass
        maskedNumber = data.maskedNumber
        fullNumber = data.fullNumber
        applyCardNumber()

        infoStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        infoRows = data.infoItems.map { item in
            let row = DebitCardDetailKeyValueRow(style: .card)
            row.configure(title: item.title, value: item.value)
            return row
        }
        infoRows.forEach { infoStack.addArrangedSubview($0) }

        actionStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        data.actions.forEach { title in
            let button = makeActionButton(title: title)
            actionStack.addArrangedSubview(button)
        }
    }

    func setAlias(_ alias: String?) {
        aliasLabel.text = alias
        aliasLabel.isHidden = alias == nil
    }

    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = CornerRadius.md
        addShadow(color: .black, opacity: 0.06, offset: CGSize(width: 0, height: 1), radius: 6)

        classBadge.font = .systemFont(ofSize: 10, weight: .semibold)
        classBadge.textColor = .white
        classBadge.textAlignment = .center
        classBadge.backgroundColor = UIColor(red: 64 / 255, green: 168 / 255, blue: 158 / 255, alpha: 1)
        classBadge.layer.cornerRadius = 4
        classBadge.layer.masksToBounds = true

        cardNumberLabel.font = .systemFont(ofSize: 16, weight: .medium)
        cardNumberLabel.textColor = .abankTextPrimary

        eyeButton.setImage(Self.eyeImage(visible: isNumberVisible), for: .normal)
        eyeButton.tintColor = .abankTextTertiary
        eyeButton.addTarget(self, action: #selector(eyeTapped), for: .touchUpInside)

        infoStack.axis = .vertical
        infoStack.alignment = .fill
        infoStack.spacing = 0

        actionStack.axis = .horizontal
        actionStack.alignment = .fill
        actionStack.distribution = .fillEqually
        actionStack.spacing = 10

        let headerRow = UIStackView(arrangedSubviews: [classBadge, cardNumberLabel, eyeButton, UIView()])
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.spacing = 8

        aliasLabel.font = .systemFont(ofSize: 15, weight: .medium)
        aliasLabel.textColor = .abankTextPrimary
        aliasLabel.accessibilityIdentifier = "debitDetail.alias"
        aliasLabel.isHidden = true
        let headerStack = UIStackView(arrangedSubviews: [aliasLabel, headerRow])
        headerStack.axis = .vertical
        headerStack.spacing = 6

        addSubview(headerStack)
        addSubview(infoStack)
        addSubview(actionStack)

        classBadge.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 28, height: 18))
        }
        eyeButton.snp.makeConstraints { make in
            make.size.equalTo(44)
        }
        headerStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(14)
        }
        infoStack.snp.makeConstraints { make in
            make.top.equalTo(headerStack.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(14)
        }
        actionStack.snp.makeConstraints { make in
            make.top.equalTo(infoStack.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(14)
            make.bottom.equalToSuperview().offset(-16)
            make.height.equalTo(32)
        }
    }

    private func makeActionButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.abankTextPrimary, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13)
        button.backgroundColor = .white
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor(red: 210 / 255, green: 210 / 255, blue: 210 / 255, alpha: 1).cgColor
        button.addTarget(self, action: #selector(actionTapped(_:)), for: .touchUpInside)
        return button
    }

    private func applyCardNumber() {
        cardNumberLabel.text = isNumberVisible ? fullNumber : maskedNumber
        eyeButton.setImage(Self.eyeImage(visible: isNumberVisible), for: .normal)
    }

    /// 与“我的”“我的贷款”一致：图标表示当前状态（睁眼 = 已显示）。
    private static func eyeImage(visible: Bool) -> UIImage? {
        UIImage.abankAsset(visible ? "abc_mine_detail_amount_eye_open" : "abc_mine_detail_amount_eye_closed",
                           fallback: visible ? "eye" : "eye.slash", renderingMode: .alwaysTemplate, pointSize: 14)
    }

    @objc private func eyeTapped() {
        isNumberVisible.toggle()
        applyCardNumber()
        onToggleNumberVisibility?()
    }

    @objc private func actionTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        onAction?(title)
    }
}
