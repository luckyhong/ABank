import UIKit
import SnapKit

final class MyAccountDebitCardView: UIView {
    var onAction: ((MyAccountAction) -> Void)?

    private let sectionTitleLabel = UILabel()
    private let cardView = UIView()
    private let classBadge = UILabel()
    private let cardNumberLabel = UILabel()
    private let viewShareButton = UIButton(type: .system)
    private let aliasButton = UIButton(type: .system)
    private let balanceCaptionLabel = UILabel()
    private let balanceLabel = UILabel()
    private let detailsButton = UIButton(type: .system)
    private let actionDivider = UIView()
    private let actionBar = UIStackView()
    private let flexibleHighlight = CAGradientLayer()
    private let flexibleBadge = UILabel()
    private var actions: [MyAccountDebitAction] = []
    private weak var wealthButton: UIButton?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with card: MyAccountDebitCard) {
        classBadge.text = card.accountClass
        cardNumberLabel.text = card.maskedNumber
        balanceLabel.text = card.availableBalance.abankPlainAmountString()
        actions = card.actions
        actionBar.arrangedSubviews.forEach { $0.removeFromSuperview() }
        flexibleHighlight.removeFromSuperlayer()
        wealthButton = nil
        flexibleBadge.isHidden = true
        for (index, action) in actions.enumerated() {
            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle(action.title, for: .normal)
            button.setTitleColor(.abankTextPrimary, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16)
            button.addTarget(self, action: #selector(actionTapped(_:)), for: .touchUpInside)
            actionBar.addArrangedSubview(button)
            if index > 0 {
                let divider = UIView()
                divider.backgroundColor = UIColor(white: 0.92, alpha: 1)
                button.addSubview(divider)
                divider.snp.makeConstraints { make in
                    make.leading.top.bottom.equalToSuperview()
                    make.width.equalTo(0.5)
                }
            }
            if let badge = action.badge {
                button.layer.insertSublayer(flexibleHighlight, at: 0)
                flexibleBadge.text = " \(badge) "
                flexibleBadge.isHidden = false
                wealthButton = button
            }
        }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        actionBar.layoutIfNeeded()
        flexibleHighlight.frame = wealthButton?.bounds ?? .zero
    }

    private func setupUI() {
        sectionTitleLabel.text = "借记卡"
        sectionTitleLabel.font = .systemFont(ofSize: 20, weight: .medium)
        sectionTitleLabel.textColor = .black
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 9
        cardView.addShadow(color: .black, opacity: 0.035, offset: CGSize(width: 0, height: 3), radius: 7)
        classBadge.font = .systemFont(ofSize: 11)
        classBadge.textColor = .white
        classBadge.textAlignment = .center
        classBadge.backgroundColor = UIColor(red: 1, green: 0.47, blue: 0.48, alpha: 1)
        classBadge.layer.cornerRadius = 15
        classBadge.clipsToBounds = true
        cardNumberLabel.font = .systemFont(ofSize: 19)
        cardNumberLabel.textColor = .abankTextPrimary
        cardNumberLabel.adjustsFontSizeToFitWidth = true
        cardNumberLabel.minimumScaleFactor = 0.8
        cardNumberLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        viewShareButton.setTitle("查看/分享", for: .normal)
        viewShareButton.setTitleColor(.abankTeal, for: .normal)
        viewShareButton.titleLabel?.font = .systemFont(ofSize: 10)
        viewShareButton.layer.borderColor = UIColor.abankTeal.cgColor
        viewShareButton.layer.borderWidth = 0.5
        viewShareButton.layer.cornerRadius = 1
        var aliasConfiguration = UIButton.Configuration.plain()
        aliasConfiguration.title = "设置别名"
        aliasConfiguration.image = UIImage.abankAsset("abc_account_alias", fallback: "square.and.pencil", pointSize: 16)
        aliasConfiguration.imagePlacement = .trailing
        aliasConfiguration.imagePadding = 4
        aliasConfiguration.contentInsets = .zero
        aliasConfiguration.baseForegroundColor = .abankTextPrimary
        aliasConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var result = attributes
            result.font = .systemFont(ofSize: 14)
            return result
        }
        aliasButton.configuration = aliasConfiguration

        balanceCaptionLabel.text = "人民币可用余额："
        balanceCaptionLabel.font = .systemFont(ofSize: 17)
        balanceCaptionLabel.textColor = .abankTextPrimary
        balanceCaptionLabel.setContentHuggingPriority(.required, for: .horizontal)
        balanceLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        balanceCaptionLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        balanceLabel.font = .systemFont(ofSize: 26, weight: .medium)
        balanceLabel.textColor = .abankTextPrimary
        balanceLabel.adjustsFontSizeToFitWidth = true
        balanceLabel.minimumScaleFactor = 0.65
        var detailConfiguration = UIButton.Configuration.plain()
        detailConfiguration.title = "详情"
        detailConfiguration.image = UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .regular))
        detailConfiguration.imagePlacement = .trailing
        detailConfiguration.imagePadding = 6
        detailConfiguration.baseForegroundColor = UIColor(white: 0.43, alpha: 1)
        detailConfiguration.contentInsets = .zero
        detailConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var result = attributes
            result.font = .systemFont(ofSize: 14)
            return result
        }
        detailsButton.configuration = detailConfiguration
        detailsButton.backgroundColor = UIColor(red: 0.88, green: 0.95, blue: 0.92, alpha: 1)
        detailsButton.layer.cornerRadius = 13
        detailsButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        detailsButton.addShadow(color: .abankTeal, opacity: 0.12, offset: CGSize(width: 0, height: 2), radius: 2)

        flexibleHighlight.colors = [UIColor.white.cgColor, UIColor(red: 1, green: 0.9, blue: 0.8, alpha: 1).cgColor]
        flexibleHighlight.startPoint = CGPoint(x: 0, y: 0)
        flexibleHighlight.endPoint = CGPoint(x: 1, y: 1)
        flexibleHighlight.cornerRadius = 9
        flexibleHighlight.maskedCorners = [.layerMaxXMaxYCorner]
        flexibleBadge.font = .systemFont(ofSize: 9)
        flexibleBadge.textColor = .white
        flexibleBadge.backgroundColor = UIColor(red: 1, green: 0.48, blue: 0.49, alpha: 1)
        flexibleBadge.layer.cornerRadius = 4
        flexibleBadge.clipsToBounds = true
        flexibleBadge.isUserInteractionEnabled = false
        actionDivider.backgroundColor = UIColor(white: 0.92, alpha: 1)
        actionBar.distribution = .fillEqually

        addSubview(sectionTitleLabel)
        addSubview(cardView)
        let topRow = UIStackView(arrangedSubviews: [classBadge, cardNumberLabel, viewShareButton, aliasButton])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = 6
        let balanceRow = UIStackView(arrangedSubviews: [balanceCaptionLabel, balanceLabel])
        balanceRow.axis = .horizontal
        balanceRow.alignment = .center
        balanceRow.spacing = 4
        [topRow, balanceRow, detailsButton, actionDivider, actionBar, flexibleBadge].forEach { cardView.addSubview($0) }
        sectionTitleLabel.snp.makeConstraints { $0.top.leading.equalToSuperview() }
        cardView.snp.makeConstraints { make in
            make.top.equalTo(sectionTitleLabel.snp.bottom).offset(32)
            make.leading.trailing.bottom.equalToSuperview()
        }
        topRow.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(30)
        }
        classBadge.snp.makeConstraints { $0.size.equalTo(30) }
        viewShareButton.snp.makeConstraints { $0.width.equalTo(56); $0.height.equalTo(16) }
        aliasButton.snp.makeConstraints { $0.width.equalTo(80) }
        balanceRow.snp.makeConstraints { make in
            make.top.equalTo(topRow.snp.bottom).offset(22)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(32)
        }
        detailsButton.snp.makeConstraints { make in
            make.top.equalTo(balanceRow.snp.bottom).offset(2)
            make.trailing.equalToSuperview().offset(3)
            make.width.equalTo(64)
            make.height.equalTo(26)
        }
        actionDivider.snp.makeConstraints { make in
            make.top.equalTo(detailsButton.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
        actionBar.snp.makeConstraints { make in
            make.top.equalTo(actionDivider.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(44)
        }
        flexibleBadge.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.top.equalTo(actionBar).offset(2)
            make.height.equalTo(13)
        }
        viewShareButton.addTarget(self, action: #selector(viewShareTapped), for: .touchUpInside)
        aliasButton.addTarget(self, action: #selector(aliasTapped), for: .touchUpInside)
        detailsButton.addTarget(self, action: #selector(detailsTapped), for: .touchUpInside)
    }

    @objc private func viewShareTapped() { onAction?(.viewShare) }
    @objc private func aliasTapped() { onAction?(.setAlias) }
    @objc private func detailsTapped() { onAction?(.details) }
    @objc private func actionTapped(_ sender: UIButton) {
        guard actions.indices.contains(sender.tag) else { return }
        switch actions[sender.tag].title {
        case MyAccountAction.queryDetail.rawValue: onAction?(.queryDetail)
        case MyAccountAction.transfer.rawValue: onAction?(.transfer)
        case MyAccountAction.flexibleWealth.rawValue: onAction?(.flexibleWealth)
        default: break
        }
    }
}
