//
//  AccountDetailQueryHeaderView.swift
//  ABank
//

import UIKit
import SnapKit

final class AccountDetailQueryHeaderView: UIView {

    var onCurrencyTapped: (() -> Void)?

    private let logoView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "abc_account_bank_logo"))
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()

    private let cardNumberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = .abankTextPrimary
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private let currencyButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = .abankTextPrimary
        configuration.image = UIImage(systemName: "arrowtriangle.down.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 8, weight: .regular))
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 8
        configuration.contentInsets = .zero
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var result = attributes
            result.font = .systemFont(ofSize: 15)
            return result
        }
        button.configuration = configuration
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
        CGSize(width: UIView.noIntrinsicMetric, height: 44)
    }

    @objc private func currencyTapped() { onCurrencyTapped?() }
}
