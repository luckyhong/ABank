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
        isNumberVisible = false
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

        let eyeConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        eyeButton.setImage(UIImage(systemName: "eye", withConfiguration: eyeConfig), for: .normal)
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

        addSubview(headerRow)
        addSubview(infoStack)
        addSubview(actionStack)

        classBadge.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 28, height: 18))
        }
        eyeButton.snp.makeConstraints { make in
            make.size.equalTo(28)
        }
        headerRow.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(14)
        }
        infoStack.snp.makeConstraints { make in
            make.top.equalTo(headerRow.snp.bottom).offset(10)
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
        let symbol = isNumberVisible ? "eye.slash" : "eye"
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        eyeButton.setImage(UIImage(systemName: symbol, withConfiguration: config), for: .normal)
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
