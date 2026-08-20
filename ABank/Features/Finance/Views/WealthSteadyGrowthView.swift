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

    func configure(with products: [WealthSteadyProduct]) {
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

    private func makeProductCard(_ product: WealthSteadyProduct, index: Int) -> UIView {
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
        yieldLabel.text = product.yieldRate
        yieldLabel.font = .systemFont(ofSize: 24, weight: .bold)
        yieldLabel.textColor = .abankHighlight

        let yieldTitle = UILabel()
        yieldTitle.text = product.yieldLabel
        yieldTitle.font = .systemFont(ofSize: 11)
        yieldTitle.textColor = .abankTextTertiary

        let dateLabel = UILabel()
        dateLabel.text = product.yieldDateRange
        dateLabel.font = .systemFont(ofSize: 10)
        dateLabel.textColor = .abankTextTertiary

        let holdingLabel = UILabel()
        holdingLabel.text = product.holdingPeriod
        holdingLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        holdingLabel.textColor = .abankTextPrimary

        let purchaseLabel = UILabel()
        purchaseLabel.text = product.purchaseInfo
        purchaseLabel.font = .systemFont(ofSize: 11)
        purchaseLabel.textColor = .abankTextTertiary

        card.addSubview(nameLabel)
        card.addSubview(yieldLabel)
        card.addSubview(yieldTitle)
        card.addSubview(dateLabel)
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
        dateLabel.snp.makeConstraints { make in
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

        if product.isHot {
            let ribbon = UILabel()
            ribbon.text = "热销"
            ribbon.font = .systemFont(ofSize: 9, weight: .bold)
            ribbon.textColor = .white
            ribbon.textAlignment = .center
            ribbon.backgroundColor = .abankHighlight
            card.addSubview(ribbon)
            ribbon.snp.makeConstraints { make in
                make.top.trailing.equalToSuperview()
                make.width.equalTo(36)
                make.height.equalTo(36)
            }
            ribbon.transform = CGAffineTransform(rotationAngle: .pi / 4)
                .translatedBy(x: 8, y: -4)
        }

        if let disclaimer = product.disclaimer {
            let footer = UIView()
            footer.backgroundColor = UIColor(white: 0.97, alpha: 1)
            let disclaimerLabel = UILabel()
            disclaimerLabel.text = disclaimer
            disclaimerLabel.font = .systemFont(ofSize: 10)
            disclaimerLabel.textColor = .abankTextTertiary
            disclaimerLabel.numberOfLines = 1
            let arrow = UIImageView(image: UIImage(systemName: "chevron.down"))
            arrow.tintColor = .abankTextTertiary
            arrow.contentMode = .scaleAspectFit
            footer.addSubview(disclaimerLabel)
            footer.addSubview(arrow)
            card.addSubview(footer)

            footer.snp.makeConstraints { make in
                make.top.equalTo(dateLabel.snp.bottom).offset(12)
                make.leading.trailing.bottom.equalToSuperview()
                make.height.equalTo(32)
            }
            disclaimerLabel.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(Spacing.md)
                make.centerY.equalToSuperview()
                make.trailing.lessThanOrEqualTo(arrow.snp.leading).offset(-8)
            }
            arrow.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-Spacing.md)
                make.centerY.equalToSuperview()
                make.size.equalTo(12)
            }
        } else {
            dateLabel.snp.makeConstraints { make in
                make.bottom.equalToSuperview().offset(-Spacing.md)
            }
        }
        return card
    }
}
