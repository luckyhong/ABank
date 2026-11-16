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
        configuration.image = UIImage(named: "abc_account_currency_chevron")?.withRenderingMode(.alwaysTemplate)
        configuration.imageColorTransformer = UIConfigurationColorTransformer { _ in .abankTextSecondary }
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 6
        configuration.contentInsets = .zero
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var result = attributes
            result.font = .systemFont(ofSize: 15)
            return result
        }
        button.configuration = configuration
        button.accessibilityIdentifier = "accountQuery.currency"
        button.accessibilityHint = "选择查询币种"
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(maskedNumber: String, currencyTitle: String = "人民币 | 本币", showsCurrency: Bool = true) {
        cardNumberLabel.text = maskedNumber
        cardNumberLabel.adjustsFontForContentSizeCategory = true
        logoView.snp.updateConstraints { $0.size.equalTo(showsCurrency ? 20 : 22) }
        currencyButton.isHidden = !showsCurrency
        currencyButton.isEnabled = showsCurrency
        updateTypography()
        if showsCurrency {
            var configuration = currencyButton.configuration
            configuration?.title = currencyTitle
            currencyButton.configuration = configuration
            currencyButton.accessibilityLabel = "币种，" + currencyTitle.replacingOccurrences(of: " | ", with: "，")
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
            make.height.greaterThanOrEqualTo(44)
            make.leading.greaterThanOrEqualTo(cardNumberLabel.snp.trailing).offset(12)
        }

        currencyButton.addTarget(self, action: #selector(currencyTapped), for: .touchUpInside)
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: max(currencyButton.isHidden ? 36 : 44, cardNumberLabel.font.lineHeight + 8))
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection); updateTypography()
    }
    private func updateTypography() {
        cardNumberLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: currencyButton.isHidden ? 18 : 17), compatibleWith: traitCollection)
        invalidateIntrinsicContentSize()
    }

    @objc private func currencyTapped() { onCurrencyTapped?() }
}
