//
//  WealthSteadyGrowthView.swift
//  ABank
//

import UIKit
import SnapKit

final class WealthSteadyGrowthView: UIView {

    var onHeaderTapped: (() -> Void)?
    var onProductTapped: ((Int) -> Void)?

    private let header = WealthSectionHeaderView(title: "稳健增长", subtitle: "中-低风险 稳健理财")
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with products: [WealthProduct]) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        products.enumerated().forEach { index, product in
            stack.addArrangedSubview(makeProductCard(product, index: index))
        }
    }

    private func setupUI() {
        header.onTap = { [weak self] in self?.onHeaderTapped?() }
        stack.axis = .vertical
        stack.spacing = 12

        addSubview(header)
        addSubview(stack)
        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        stack.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func makeProductCard(_ product: WealthProduct, index: Int) -> UIView {
        let card = UIControl()
        card.tag = index
        card.addAction(UIAction { [weak self] _ in self?.onProductTapped?(index) }, for: .touchUpInside)
        card.backgroundColor = .abankCardBackground
        card.layer.cornerRadius = CornerRadius.lg
        card.addShadow(color: .black, opacity: 0.06, offset: CGSize(width: 0, height: 2), radius: 8)

        let nameLabel = UILabel()
        nameLabel.text = product.name
        nameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = .abankTextPrimary
        nameLabel.numberOfLines = 2

        let yieldLabel = UILabel()
        yieldLabel.text = product.rateText
        yieldLabel.font = .systemFont(ofSize: 24, weight: .bold)
        yieldLabel.textColor = .abankHighlight

        let yieldTitle = UILabel()
        yieldTitle.text = WealthProduct.rateLabel
        yieldTitle.font = .systemFont(ofSize: 11)
        yieldTitle.textColor = .abankTextTertiary

        let rateNoteLabel = UILabel()
        rateNoteLabel.text = "按持有天数估算"
        rateNoteLabel.font = .systemFont(ofSize: 11)
        rateNoteLabel.textColor = .abankTextTertiary

        let holdingLabel = UILabel()
        holdingLabel.text = "最低持有\(product.minHoldDays)天"
        holdingLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        holdingLabel.textColor = .abankTextPrimary

        let purchaseLabel = UILabel()
        purchaseLabel.text = "\(wealthPurchaseMinimumText(product.minPurchaseInCents)) · \(product.risk.title)"
        purchaseLabel.font = .systemFont(ofSize: 11)
        purchaseLabel.textColor = .abankTextTertiary

        card.addSubview(nameLabel)
        card.addSubview(yieldLabel)
        card.addSubview(yieldTitle)
        card.addSubview(rateNoteLabel)
        card.addSubview(holdingLabel)
        card.addSubview(purchaseLabel)

        nameLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        yieldLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(Spacing.md)
        }
        yieldTitle.snp.makeConstraints { make in
            make.top.equalTo(yieldLabel.snp.bottom).offset(4)
            make.leading.equalTo(yieldLabel)
        }
        rateNoteLabel.snp.makeConstraints { make in
            make.top.equalTo(yieldTitle.snp.bottom).offset(2)
            make.leading.equalTo(yieldLabel)
        }
        holdingLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(16)
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.leading.greaterThanOrEqualTo(yieldLabel.snp.trailing).offset(16)
        }
        purchaseLabel.snp.makeConstraints { make in
            make.top.equalTo(holdingLabel.snp.bottom).offset(4)
            make.trailing.equalTo(holdingLabel)
        }

        rateNoteLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-Spacing.md)
        }
        return card
    }
}
