//
//  AssistantMessageView.swift
//  ABank
//
//  对话气泡：用户在右侧橙色，助手在左侧白色，助手气泡可带功能卡片与快捷问题标签。
//

import UIKit
import SnapKit

final class AssistantMessageView: UIView {
    var onFeatureTapped: ((FeatureID) -> Void)?
    var onQuickTapped: ((String) -> Void)?

    init(text: String, isUser: Bool, features: [FeatureID] = [], quickQuestions: [String] = []) {
        super.init(frame: .zero)

        let bubble = UIView()
        bubble.backgroundColor = isUser ? .abankOrange : .white
        bubble.layer.cornerRadius = 12

        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 15)
        label.textColor = isUser ? .white : .abankTextPrimary
        label.accessibilityIdentifier = isUser ? "assistant.user.text" : "assistant.reply.text"

        let column = UIStackView(arrangedSubviews: [label])
        column.axis = .vertical
        column.spacing = 10
        for id in features { column.addArrangedSubview(featureCard(id)) }
        if !quickQuestions.isEmpty {
            for (index, question) in quickQuestions.enumerated() {
                let chip = UIButton(type: .system)
                chip.setTitle(question, for: .normal)
                chip.setTitleColor(.abankOrange, for: .normal)
                chip.titleLabel?.font = .systemFont(ofSize: 14)
                chip.contentHorizontalAlignment = .leading
                chip.accessibilityIdentifier = "assistant.quick.\(index)"
                chip.addAction(UIAction { [weak self] _ in self?.onQuickTapped?(question) }, for: .touchUpInside)
                column.addArrangedSubview(chip)
            }
        }

        bubble.addSubview(column)
        addSubview(bubble)
        column.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
        bubble.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.8)
            if isUser { make.trailing.equalToSuperview() } else { make.leading.equalToSuperview() }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func featureCard(_ id: FeatureID) -> UIView {
        let descriptor = FeatureCatalog.descriptor(id)
        let button = UIControl()
        button.backgroundColor = UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1)
        button.layer.cornerRadius = 8
        button.accessibilityIdentifier = "assistant.feature.\(id.rawValue)"

        let icon = UIImageView(image: UIImage(systemName: descriptor.systemIcon))
        icon.tintColor = .abankOrange
        icon.contentMode = .scaleAspectFit
        let title = UILabel()
        title.text = descriptor.title
        title.font = .systemFont(ofSize: 14, weight: .medium)
        title.textColor = .abankTextPrimary
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .abankTextTertiary
        [icon, title, chevron].forEach { $0.isUserInteractionEnabled = false; button.addSubview($0) }
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        title.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
        }
        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
            make.width.equalTo(10)
        }
        button.snp.makeConstraints { $0.height.equalTo(40) }
        button.addAction(UIAction { [weak self] _ in self?.onFeatureTapped?(id) }, for: .touchUpInside)
        return button
    }
}
