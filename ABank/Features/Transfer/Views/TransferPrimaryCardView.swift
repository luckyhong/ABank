//
//  TransferPrimaryCardView.swift
//  ABank
//

import UIKit
import SnapKit

final class TransferPrimaryCardView: UIView {

    var onPrimaryTapped: ((Int) -> Void)?
    var onSecondaryTapped: ((Int) -> Void)?

    private let card = UIView()
    private let topArea = UIView()
    private let gradientLayer = CAGradientLayer()
    private let topDivider = UIView()
    private let bottomArea = UIView()
    private let bottomDivider = UIView()

    private var primaryButtons: [UIControl] = []
    private var secondaryButtons: [UIControl] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = topArea.bounds
        if gradientLayer.superlayer == nil {
            topArea.layer.insertSublayer(gradientLayer, at: 0)
        }
    }

    func configure(
        primary: [TransferPrimaryAction],
        secondary: [TransferSecondaryAction]
    ) {
        primaryButtons.forEach { $0.removeFromSuperview() }
        secondaryButtons.forEach { $0.removeFromSuperview() }
        primaryButtons = []
        secondaryButtons = []

        let primaryControls = primary.enumerated().map { index, item in
            makePrimaryButton(item: item, index: index)
        }
        primaryButtons = primaryControls
        layoutEqual(buttons: primaryControls, in: topArea, divider: topDivider)

        let secondaryControls = secondary.enumerated().map { index, item in
            makeSecondaryButton(item: item, index: index)
        }
        secondaryButtons = secondaryControls
        layoutEqual(buttons: secondaryControls, in: bottomArea, divider: bottomDivider)
    }

    private func setupUI() {
        card.backgroundColor = .white
        card.layer.cornerRadius = CornerRadius.md
        card.clipsToBounds = true

        // 阴影放在外层，避免 clipsToBounds 裁切
        layer.cornerRadius = CornerRadius.md
        addShadow(color: .black, opacity: 0.08, offset: CGSize(width: 0, height: 2), radius: 8)

        topArea.backgroundColor = UIColor(red: 0 / 255, green: 176 / 255, blue: 148 / 255, alpha: 1)
        gradientLayer.colors = [
            UIColor(red: 33 / 255, green: 198 / 255, blue: 172 / 255, alpha: 0.28).cgColor,
            UIColor(red: 0 / 255, green: 160 / 255, blue: 140 / 255, alpha: 0.08).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        topArea.layer.insertSublayer(gradientLayer, at: 0)

        topDivider.backgroundColor = UIColor.white.withAlphaComponent(0.35)
        bottomDivider.backgroundColor = .abankSeparator
        bottomArea.backgroundColor = .white

        addSubview(card)
        card.addSubview(topArea)
        card.addSubview(bottomArea)
        topArea.addSubview(topDivider)
        bottomArea.addSubview(bottomDivider)

        card.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        topArea.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(112)
        }
        bottomArea.snp.makeConstraints { make in
            make.top.equalTo(topArea.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(52)
        }
        topDivider.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(0.5)
            make.height.equalTo(40)
        }
        bottomDivider.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(0.5)
            make.height.equalTo(20)
        }
    }

    private func layoutEqual(buttons: [UIControl], in container: UIView, divider: UIView) {
        guard buttons.count == 2 else { return }
        buttons.forEach { container.addSubview($0) }
        container.bringSubviewToFront(divider)
        buttons[0].snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.equalTo(container.snp.centerX)
        }
        buttons[1].snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
            make.leading.equalTo(container.snp.centerX)
        }
    }

    private func makePrimaryButton(item: TransferPrimaryAction, index: Int) -> UIControl {
        let control = UIControl()
        control.tag = index

        let icon = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 26, weight: .regular)
        icon.image = UIImage(systemName: item.systemIcon, withConfiguration: config)
        icon.tintColor = UIColor.white.withAlphaComponent(0.95)
        icon.contentMode = .scaleAspectFit

        let title = UILabel()
        title.text = item.title
        title.font = .systemFont(ofSize: 16, weight: .medium)
        title.textColor = .white
        title.textAlignment = .center

        control.addSubview(icon)
        control.addSubview(title)
        icon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(20)
            make.size.equalTo(32)
        }
        title.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(icon.snp.bottom).offset(10)
        }

        if let badge = item.badge {
            let badgeLabel = UILabel()
            badgeLabel.text = " \(badge) "
            badgeLabel.font = .systemFont(ofSize: 9, weight: .medium)
            badgeLabel.textColor = .white
            badgeLabel.backgroundColor = UIColor(red: 230 / 255, green: 60 / 255, blue: 50 / 255, alpha: 1)
            badgeLabel.layer.cornerRadius = 7
            badgeLabel.layer.masksToBounds = true
            badgeLabel.textAlignment = .center
            control.addSubview(badgeLabel)
            badgeLabel.snp.makeConstraints { make in
                make.leading.equalTo(icon.snp.trailing).offset(-6)
                make.bottom.equalTo(icon.snp.top).offset(8)
                make.height.equalTo(14)
            }
        }

        control.addTarget(self, action: #selector(primaryTapped(_:)), for: .touchUpInside)
        return control
    }

    private func makeSecondaryButton(item: TransferSecondaryAction, index: Int) -> UIControl {
        let control = UIControl()
        control.tag = index

        let icon = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        icon.image = UIImage(systemName: item.systemIcon, withConfiguration: config)
        icon.tintColor = .abankTeal
        icon.contentMode = .scaleAspectFit

        let title = UILabel()
        title.text = item.title
        title.font = .systemFont(ofSize: 14)
        title.textColor = .abankTextPrimary

        let stack = UIStackView(arrangedSubviews: [icon, title])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 6
        stack.isUserInteractionEnabled = false

        control.addSubview(stack)
        icon.snp.makeConstraints { make in
            make.size.equalTo(16)
        }
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        control.addTarget(self, action: #selector(secondaryTapped(_:)), for: .touchUpInside)
        return control
    }

    @objc private func primaryTapped(_ sender: UIControl) { onPrimaryTapped?(sender.tag) }
    @objc private func secondaryTapped(_ sender: UIControl) { onSecondaryTapped?(sender.tag) }
}
