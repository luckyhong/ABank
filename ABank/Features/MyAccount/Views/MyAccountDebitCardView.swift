//
//  MyAccountDebitCardView.swift
//  ABank
//

import UIKit
import SnapKit

final class MyAccountDebitCardView: UIView {

    var onAction: ((MyAccountAction) -> Void)?

    private let sectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "借记卡"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .abankTextPrimary
        return label
    }()

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .abankCardBackground
        view.layer.cornerRadius = CornerRadius.md
        view.addShadow(color: .black, opacity: 0.06, offset: CGSize(width: 0, height: 1), radius: 6)
        return view
    }()

    private let classBadge: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = UIColor(red: 232 / 255, green: 90 / 255, blue: 90 / 255, alpha: 1)
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        return label
    }()

    private let cardNumberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .abankTextPrimary
        return label
    }()

    private let viewShareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("查看/分享", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 11, weight: .regular)
        button.setTitleColor(UIColor(red: 64 / 255, green: 168 / 255, blue: 158 / 255, alpha: 1), for: .normal)
        button.backgroundColor = UIColor(red: 232 / 255, green: 245 / 255, blue: 243 / 255, alpha: 1)
        button.layer.cornerRadius = 11
        button.contentEdgeInsets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
        return button
    }()

    private let aliasButton: UIButton = {
        let button = UIButton(type: .system)
        let color = UIColor(red: 64 / 255, green: 168 / 255, blue: 158 / 255, alpha: 1)
        button.setTitle("设置别名", for: .normal)
        button.setTitleColor(color, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .regular)
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        button.setImage(UIImage(systemName: "square.and.pencil", withConfiguration: config), for: .normal)
        button.tintColor = color
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: -3)
        return button
    }()

    private let balanceCaptionLabel: UILabel = {
        let label = UILabel()
        label.text = "人民币可用余额："
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .abankTextSecondary
        return label
    }()

    private let balanceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 26, weight: .semibold)
        label.textColor = .abankTextPrimary
        return label
    }()

    private let detailsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("详情 >", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        button.setTitleColor(UIColor(red: 90 / 255, green: 110 / 255, blue: 110 / 255, alpha: 1), for: .normal)
        button.backgroundColor = UIColor(red: 232 / 255, green: 242 / 255, blue: 240 / 255, alpha: 1)
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        return button
    }()

    private let actionDivider = UIView()
    private let actionBar = UIView()
    private var actionButtons: [UIButton] = []
    private let flexibleHighlight = CAGradientLayer()

    private let flexibleBadge: PaddingBadgeLabel = {
        let label = PaddingBadgeLabel()
        label.text = "时时付"
        label.font = .systemFont(ofSize: 9, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = UIColor(red: 232 / 255, green: 72 / 255, blue: 62 / 255, alpha: 1)
        label.layer.cornerRadius = 3
        label.layer.masksToBounds = true
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with card: MyAccountDebitCard) {
        classBadge.text = card.accountClass
        cardNumberLabel.text = card.maskedNumber
        balanceLabel.text = card.availableBalance.abankPlainAmountString()

        actionBar.subviews.forEach { $0.removeFromSuperview() }
        actionButtons.removeAll()
        flexibleHighlight.removeFromSuperlayer()

        let buttons = card.actions.map { action -> UIButton in
            let button = UIButton(type: .system)
            button.setTitle(action.title, for: .normal)
            button.setTitleColor(.abankTextPrimary, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
            button.addTarget(self, action: #selector(actionTapped(_:)), for: .touchUpInside)
            return button
        }
        actionButtons = buttons
        buttons.forEach { actionBar.addSubview($0) }

        guard !buttons.isEmpty else { return }

        buttons.first?.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        buttons.last?.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
        }

        for index in 0..<buttons.count {
            if index > 0 {
                buttons[index].snp.makeConstraints { make in
                    make.leading.equalTo(buttons[index - 1].snp.trailing)
                    make.width.equalTo(buttons[0])
                    make.top.bottom.equalToSuperview()
                }
                let separator = UIView()
                separator.backgroundColor = .abankSeparator
                actionBar.addSubview(separator)
                separator.snp.makeConstraints { make in
                    make.centerY.equalToSuperview()
                    make.leading.equalTo(buttons[index])
                    make.width.equalTo(1.0 / UIScreen.main.scale)
                    make.height.equalTo(18)
                }
            }
        }

        if card.actions.last?.badge != nil {
            buttons.last?.layer.insertSublayer(flexibleHighlight, at: 0)
            flexibleBadge.text = card.actions.last?.badge
            flexibleBadge.isHidden = false
        } else {
            flexibleBadge.isHidden = true
        }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let lastButton = actionButtons.last else { return }
        flexibleHighlight.frame = lastButton.bounds
        flexibleHighlight.colors = [
            UIColor(red: 1, green: 0.95, blue: 0.92, alpha: 0).cgColor,
            UIColor(red: 1, green: 0.88, blue: 0.82, alpha: 0.55).cgColor
        ]
        flexibleHighlight.startPoint = CGPoint(x: 0.35, y: 0.5)
        flexibleHighlight.endPoint = CGPoint(x: 1, y: 0.5)
    }

    private func setupUI() {
        addSubview(sectionTitleLabel)
        addSubview(cardView)
        cardView.clipsToBounds = false

        let topRow = UIStackView(arrangedSubviews: [classBadge, cardNumberLabel, UIView(), viewShareButton, aliasButton])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = 6

        let balanceRow = UIStackView(arrangedSubviews: [balanceCaptionLabel, balanceLabel, UIView(), detailsButton])
        balanceRow.axis = .horizontal
        balanceRow.alignment = .center
        balanceRow.spacing = 2

        actionDivider.backgroundColor = .abankSeparator

        [topRow, balanceRow, actionDivider, actionBar, flexibleBadge].forEach { cardView.addSubview($0) }

        sectionTitleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }
        cardView.snp.makeConstraints { make in
            make.top.equalTo(sectionTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }
        classBadge.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 28, height: 20))
        }
        topRow.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(14)
        }
        balanceRow.snp.makeConstraints { make in
            make.top.equalTo(topRow.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(14)
        }
        actionDivider.snp.makeConstraints { make in
            make.top.equalTo(balanceRow.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }
        actionBar.snp.makeConstraints { make in
            make.top.equalTo(actionDivider.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(46)
        }
        flexibleBadge.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-6)
            make.bottom.equalTo(actionBar.snp.top).offset(8)
            make.height.equalTo(15)
        }

        viewShareButton.addTarget(self, action: #selector(viewShareTapped), for: .touchUpInside)
        aliasButton.addTarget(self, action: #selector(aliasTapped), for: .touchUpInside)
        detailsButton.addTarget(self, action: #selector(detailsTapped), for: .touchUpInside)
    }

    @objc private func viewShareTapped() { onAction?(.viewShare) }
    @objc private func aliasTapped() { onAction?(.setAlias) }
    @objc private func detailsTapped() { onAction?(.details) }

    @objc private func actionTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        switch title {
        case MyAccountAction.queryDetail.rawValue: onAction?(.queryDetail)
        case MyAccountAction.transfer.rawValue: onAction?(.transfer)
        case MyAccountAction.flexibleWealth.rawValue: onAction?(.flexibleWealth)
        default: break
        }
    }
}

private final class PaddingBadgeLabel: UILabel {
    private let insets = UIEdgeInsets(top: 1, left: 4, bottom: 1, right: 4)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right,
                      height: size.height + insets.top + insets.bottom)
    }
}
