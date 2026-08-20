//
//  WealthPopularDepositView.swift
//  ABank
//

import UIKit
import SnapKit

final class WealthPopularDepositView: UIView {

    var onHeaderTapped: (() -> Void)?
    var onItemTapped: ((Int) -> Void)?

    private let header = WealthSectionHeaderView(title: "热门存款", subtitle: "托底保障 安心选择")
    private let card = UIView()
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with items: [WealthDepositItem]) {
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

    private func makeRow(_ item: WealthDepositItem, index: Int) -> UIView {
        let row = UIControl()
        row.tag = index
        row.addAction(UIAction { [weak self] _ in self?.onItemTapped?(index) }, for: .touchUpInside)

        let nameLabel = UILabel()
        nameLabel.text = item.name
        nameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = .abankTextPrimary
        nameLabel.numberOfLines = 2

        let rateLabel = UILabel()
        rateLabel.text = item.rate
        rateLabel.font = .systemFont(ofSize: 22, weight: .bold)
        rateLabel.textColor = .abankHighlight

        let rateTitle = UILabel()
        rateTitle.text = item.rateLabel
        rateTitle.font = .systemFont(ofSize: 11)
        rateTitle.textColor = .abankTextTertiary

        let termLabel = UILabel()
        termLabel.text = item.term
        termLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        termLabel.textColor = .abankTextPrimary

        let minLabel = UILabel()
        minLabel.text = item.minPurchase
        minLabel.font = .systemFont(ofSize: 11)
        minLabel.textColor = .abankTextTertiary

        row.addSubview(nameLabel)
        row.addSubview(rateLabel)
        row.addSubview(rateTitle)
        row.addSubview(termLabel)
        row.addSubview(minLabel)

        nameLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        rateLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(Spacing.md)
            make.bottom.equalToSuperview().offset(-Spacing.md)
        }
        rateTitle.snp.makeConstraints { make in
            make.leading.equalTo(rateLabel.snp.trailing).offset(8)
            make.bottom.equalTo(rateLabel).offset(-2)
        }
        termLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.centerY.equalTo(rateLabel)
        }
        minLabel.snp.makeConstraints { make in
            make.trailing.equalTo(termLabel)
            make.top.equalTo(termLabel.snp.bottom).offset(4)
        }
        return row
    }
}
