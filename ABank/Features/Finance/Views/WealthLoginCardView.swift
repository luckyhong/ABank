//
//  WealthLoginCardView.swift
//  ABank
//

import UIKit
import SnapKit

final class WealthLoginCardView: UIView {

    var onLoginTapped: (() -> Void)?

    private let card = UIView()
    private let gradientLayer = CAGradientLayer()
    private let messageLabel = UILabel()
    private let loginButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = card.bounds
    }

    func configure(with greeting: WealthGreeting) {
        messageLabel.text = greeting.message
        loginButton.setTitle(greeting.loginTitle, for: .normal)
    }

    private func setupUI() {
        card.layer.cornerRadius = CornerRadius.lg
        card.clipsToBounds = true
        gradientLayer.colors = [
            UIColor(red: 1.0, green: 0.94, blue: 0.88, alpha: 1).cgColor,
            UIColor.white.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        card.layer.insertSublayer(gradientLayer, at: 0)

        messageLabel.font = .systemFont(ofSize: 16, weight: .medium)
        messageLabel.textColor = .abankTextPrimary

        loginButton.setTitleColor(.abankTextPrimary, for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 14)
        loginButton.layer.cornerRadius = 16
        loginButton.layer.borderWidth = 0.8
        loginButton.layer.borderColor = UIColor.abankTextTertiary.cgColor
        loginButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 20, bottom: 6, right: 20)
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)

        addSubview(card)
        card.addSubview(messageLabel)
        card.addSubview(loginButton)

        card.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(56)
        }
        messageLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.centerY.equalToSuperview()
        }
        loginButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.centerY.equalToSuperview()
        }
    }

    @objc private func loginTapped() { onLoginTapped?() }
}
