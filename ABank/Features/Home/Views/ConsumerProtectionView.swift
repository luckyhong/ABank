//
//  ConsumerProtectionView.swift
//  ABank
//

import UIKit
import SnapKit

final class ConsumerProtectionView: UIView {

    var onItemTapped: ((HomeConsumerProtectionItem) -> Void)?

    private let header = SectionHeaderView(title: "消保专区", showsChevron: false)
    private let grid = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with items: [HomeConsumerProtectionItem]) {
        grid.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let rows = stride(from: 0, to: items.count, by: 2).map { start -> UIStackView in
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 8
            row.distribution = .fillEqually
            let end = min(start + 2, items.count)
            for index in start..<end {
                row.addArrangedSubview(makeCard(item: items[index]))
            }
            if end - start == 1 {
                row.addArrangedSubview(UIView())
            }
            return row
        }
        rows.forEach { grid.addArrangedSubview($0) }
    }

    private func setupUI() {
        grid.axis = .vertical
        grid.spacing = 8
        addSubview(header)
        addSubview(grid)
        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(24)
        }
        grid.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func makeCard(item: HomeConsumerProtectionItem) -> UIView {
        let card = UIControl()
        card.backgroundColor = item.backgroundColor
        card.layer.cornerRadius = CornerRadius.md
        card.addAction(UIAction { [weak self] _ in
            self?.onItemTapped?(item)
        }, for: .touchUpInside)

        let title = UILabel()
        title.text = item.title
        title.font = .systemFont(ofSize: 15, weight: .semibold)
        title.textColor = .abankTextPrimary
        title.isUserInteractionEnabled = false

        let subtitle = UILabel()
        subtitle.text = item.subtitle
        subtitle.font = .systemFont(ofSize: 12)
        subtitle.textColor = .abankTextSecondary
        subtitle.isUserInteractionEnabled = false

        card.addSubview(title)
        card.addSubview(subtitle)
        title.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-14)
        }
        subtitle.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(8)
            make.leading.trailing.equalTo(title)
            make.bottom.equalToSuperview().offset(-16)
        }
        card.snp.makeConstraints { make in
            make.height.equalTo(78)
        }
        return card
    }
}
