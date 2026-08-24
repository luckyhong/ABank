//
//  AccountDetailQueryHeaderView.swift
//  ABank
//

import UIKit
import SnapKit

final class AccountDetailQueryHeaderView: UIView {

    var onCurrencyTapped: (() -> Void)?

    private let logoView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "abc_bank_logo"))
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()

    private let cardNumberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .abankTextPrimary
        return label
    }()

    private let currencyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.abankTextPrimary, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        let config = UIImage.SymbolConfiguration(pointSize: 9, weight: .semibold)
        button.setImage(UIImage(systemName: "chevron.down", withConfiguration: config), for: .normal)
        button.tintColor = UIColor(red: 170 / 255, green: 170 / 255, blue: 170 / 255, alpha: 1)
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 1, left: 4, bottom: -1, right: -4)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(maskedNumber: String, currencyTitle: String = "人民币 | 本币", showsCurrency: Bool = true) {
        cardNumberLabel.text = maskedNumber
        currencyButton.isHidden = !showsCurrency
        currencyButton.isEnabled = showsCurrency
        if showsCurrency {
            currencyButton.setTitle(currencyTitle, for: .normal)
        }
    }

    private func setupUI() {
        backgroundColor = .white

        addSubview(logoView)
        addSubview(cardNumberLabel)
        addSubview(currencyButton)

        logoView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        cardNumberLabel.snp.makeConstraints { make in
            make.leading.equalTo(logoView.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
        }
        currencyButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(cardNumberLabel.snp.trailing).offset(12)
        }

        currencyButton.addTarget(self, action: #selector(currencyTapped), for: .touchUpInside)
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 48)
    }

    @objc private func currencyTapped() { onCurrencyTapped?() }
}
