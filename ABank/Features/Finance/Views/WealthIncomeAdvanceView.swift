//
//  WealthIncomeAdvanceView.swift
//  ABank
//

import UIKit
import SnapKit

final class WealthIncomeAdvanceView: UIView {

    var onHeaderTapped: (() -> Void)?
    var onItemTapped: ((Int) -> Void)?

    private let header = WealthSectionHeaderView(title: "收益进阶", subtitle: "专业投研 优选基金")
    private let card = UIView()
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with items: [WealthFundItem]) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        items.enumerated().forEach { index, item in
            if index > 0 {
                let sep = UIView()
                sep.backgroundColor = .abankSeparator
                sep.snp.makeConstraints { make in make.height.equalTo(0.5) }
                stack.addArrangedSubview(sep)
            }
            stack.addArrangedSubview(makeRow(item, index: index))
        }
    }

    private func setupUI() {
        header.onTap = { [weak self] in self?.onHeaderTapped?() }
        card.backgroundColor = .abankCardBackground
        card.layer.cornerRadius = CornerRadius.lg
        card.addShadow(color: .black, opacity: 0.06, offset: CGSize(width: 0, height: 2), radius: 8)
        stack.axis = .vertical

        addSubview(header)
        addSubview(card)
        card.addSubview(stack)

        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        card.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func makeRow(_ item: WealthFundItem, index: Int) -> UIView {
        let row = UIControl()
        row.tag = index
        row.addAction(UIAction { [weak self] _ in self?.onItemTapped?(index) }, for: .touchUpInside)

        let nameLabel = UILabel()
        nameLabel.text = item.name
        nameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = .abankTextPrimary

        let yieldLabel = UILabel()
        yieldLabel.text = item.yieldRate
        yieldLabel.font = .systemFont(ofSize: 22, weight: .bold)
        yieldLabel.textColor = .abankHighlight

        let yieldTitle = UILabel()
        yieldTitle.text = item.yieldLabel
        yieldTitle.font = .systemFont(ofSize: 11)
        yieldTitle.textColor = .abankTextTertiary

        let categoryLabel = UILabel()
        categoryLabel.text = item.category
        categoryLabel.font = .systemFont(ofSize: 14)
        categoryLabel.textColor = .abankTextPrimary

        row.addSubview(nameLabel)
        row.addSubview(yieldLabel)
        row.addSubview(yieldTitle)
        row.addSubview(categoryLabel)

        nameLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        yieldLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(Spacing.md)
            make.bottom.equalToSuperview().offset(-Spacing.md)
        }
        yieldTitle.snp.makeConstraints { make in
            make.leading.equalTo(yieldLabel.snp.trailing).offset(8)
            make.bottom.equalTo(yieldLabel).offset(-2)
        }
        categoryLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.centerY.equalTo(yieldLabel)
        }

        if item.isSelected {
            let ribbon = UILabel()
            ribbon.text = "优选"
            ribbon.font = .systemFont(ofSize: 9, weight: .bold)
            ribbon.textColor = .white
            ribbon.textAlignment = .center
            ribbon.backgroundColor = .abankHighlight
            row.addSubview(ribbon)
            ribbon.snp.makeConstraints { make in
                make.top.trailing.equalToSuperview()
                make.width.equalTo(36)
                make.height.equalTo(36)
            }
            ribbon.transform = CGAffineTransform(rotationAngle: .pi / 4)
                .translatedBy(x: 8, y: -4)
        }
        return row
    }
}
