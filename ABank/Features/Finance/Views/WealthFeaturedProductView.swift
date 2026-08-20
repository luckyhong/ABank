//
//  WealthFeaturedProductView.swift
//  ABank
//

import UIKit
import SnapKit

final class WealthFeaturedProductView: UIView {

    var onTabSelected: ((Int) -> Void)?
    var onBuyTapped: (() -> Void)?

    private let card = UIView()
    private let tabStack = UIStackView()
    private let nameLabel = UILabel()
    private let yieldLabel = UILabel()
    private let yieldTitleLabel = UILabel()
    private let dateRangeLabel = UILabel()
    private let riskLabel = UILabel()
    private let riskTitleLabel = UILabel()
    private let holdingLabel = UILabel()
    private let holdingTitleLabel = UILabel()
    private let buyButton = UIButton(type: .system)
    private let disclaimerLabel = UILabel()
    private let adTag = UILabel()

    private var tabs: [WealthProductTab] = []
    private var selectedIndex = 0
    private var tabButtons: [UIButton] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with tabs: [WealthProductTab]) {
        self.tabs = tabs
        tabStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        tabButtons.removeAll()

        tabs.enumerated().forEach { index, tab in
            let button = UIButton(type: .system)
            button.setTitle(tab.title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: index == 0 ? .semibold : .regular)
            button.tag = index
            button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            tabButtons.append(button)
            tabStack.addArrangedSubview(button)
        }
        selectTab(at: 0)
    }

    private func selectTab(at index: Int) {
        selectedIndex = index
        tabButtons.enumerated().forEach { i, button in
            let active = i == index
            button.setTitleColor(active ? .abankTextPrimary : .abankTextTertiary, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: active ? .semibold : .regular)
            button.backgroundColor = active
                ? UIColor(red: 1.0, green: 0.96, blue: 0.88, alpha: 1)
                : .clear
            button.layer.cornerRadius = active ? 8 : 0
        }
        guard let product = tabs[safe: index]?.product else { return }
        nameLabel.text = product.name
        yieldLabel.text = product.yieldRate
        yieldTitleLabel.text = product.yieldLabel
        dateRangeLabel.text = product.yieldDateRange
        riskLabel.text = product.riskLevel
        riskTitleLabel.text = product.riskLabel
        holdingLabel.text = product.holdingPeriod
        holdingTitleLabel.text = product.holdingLabel
        buyButton.setTitle(product.actionTitle, for: .normal)
        disclaimerLabel.text = product.disclaimer
        adTag.isHidden = !product.isAd
    }

    private func setupUI() {
        card.backgroundColor = .abankCardBackground
        card.layer.cornerRadius = CornerRadius.lg
        card.addShadow(color: .black, opacity: 0.06, offset: CGSize(width: 0, height: 2), radius: 8)

        tabStack.axis = .horizontal
        tabStack.distribution = .fillEqually
        tabStack.spacing = 4

        nameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = .abankTextPrimary
        nameLabel.numberOfLines = 2

        yieldLabel.font = .systemFont(ofSize: 26, weight: .bold)
        yieldLabel.textColor = .abankHighlight
        yieldTitleLabel.font = .systemFont(ofSize: 11)
        yieldTitleLabel.textColor = .abankTextTertiary
        dateRangeLabel.font = .systemFont(ofSize: 10)
        dateRangeLabel.textColor = .abankTextTertiary

        riskLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        riskLabel.textColor = .abankTextPrimary
        riskTitleLabel.font = .systemFont(ofSize: 11)
        riskTitleLabel.textColor = .abankTextTertiary

        holdingLabel.font = .systemFont(ofSize: 14, weight: .medium)
        holdingLabel.textColor = .abankTextPrimary
        holdingTitleLabel.font = .systemFont(ofSize: 11)
        holdingTitleLabel.textColor = .abankTextTertiary

        buyButton.backgroundColor = .abankOrange
        buyButton.setTitleColor(.white, for: .normal)
        buyButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        buyButton.layer.cornerRadius = 22
        buyButton.addTarget(self, action: #selector(buyTapped), for: .touchUpInside)

        disclaimerLabel.font = .systemFont(ofSize: 10)
        disclaimerLabel.textColor = .abankTextTertiary
        disclaimerLabel.numberOfLines = 2

        adTag.text = "【广告】"
        adTag.font = .systemFont(ofSize: 9)
        adTag.textColor = .abankTextTertiary

        addSubview(card)
        [tabStack, nameLabel, yieldLabel, yieldTitleLabel, dateRangeLabel,
         riskLabel, riskTitleLabel, holdingLabel, holdingTitleLabel,
         buyButton, disclaimerLabel, adTag].forEach { card.addSubview($0) }

        card.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tabStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(36)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(tabStack.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }

        let col1 = makeMetricColumn(value: yieldLabel, title: yieldTitleLabel, extra: dateRangeLabel)
        let col2 = makeMetricColumn(value: riskLabel, title: riskTitleLabel, extra: nil)
        let col3 = makeMetricColumn(value: holdingLabel, title: holdingTitleLabel, extra: nil)
        let metricsRow = UIStackView(arrangedSubviews: [col1, col2, col3])
        metricsRow.axis = .horizontal
        metricsRow.distribution = .fillEqually
        metricsRow.alignment = .top
        card.addSubview(metricsRow)
        metricsRow.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }

        buyButton.snp.makeConstraints { make in
            make.top.equalTo(metricsRow.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.height.equalTo(44)
        }
        disclaimerLabel.snp.makeConstraints { make in
            make.top.equalTo(buyButton.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(Spacing.md)
            make.trailing.equalTo(adTag.snp.leading).offset(-8)
            make.bottom.equalToSuperview().offset(-12)
        }
        adTag.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.bottom.equalTo(disclaimerLabel)
        }
    }

    private func makeMetricColumn(value: UILabel, title: UILabel, extra: UILabel?) -> UIView {
        let col = UIView()
        col.addSubview(value)
        col.addSubview(title)
        value.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        title.snp.makeConstraints { make in
            make.top.equalTo(value.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
        }
        if let extra {
            col.addSubview(extra)
            extra.snp.makeConstraints { make in
                make.top.equalTo(title.snp.bottom).offset(2)
                make.leading.trailing.bottom.equalToSuperview()
            }
        } else {
            title.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
            }
        }
        return col
    }

    @objc private func tabTapped(_ sender: UIButton) {
        selectTab(at: sender.tag)
        onTabSelected?(sender.tag)
    }

    @objc private func buyTapped() { onBuyTapped?() }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
