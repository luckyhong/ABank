//
//  MineSecurityCenterCardView.swift
//  ABank
//

import UIKit
import SnapKit

final class MineSecurityCenterCardView: UIView {

    var onTap: (() -> Void)?
    var onItemTapped: ((Int) -> Void)?

    private let card = UIView()
    private let header = MineCardHeaderView(title: "安全中心")
    private let grid = MineActionGridView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with items: [MineGridItem]) {
        grid.configure(with: items)
    }

    private func setupUI() {
        card.backgroundColor = .abankCardBackground
        card.layer.cornerRadius = CornerRadius.lg
        card.addShadow(color: .black, opacity: 0.06, offset: CGSize(width: 0, height: 2), radius: 8)

        header.onTap = { [weak self] in self?.onTap?() }
        grid.onItemTapped = { [weak self] index in self?.onItemTapped?(index) }

        addSubview(card)
        card.addSubview(header)
        card.addSubview(grid)

        card.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        grid.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(Spacing.md)
            make.leading.trailing.equalToSuperview().inset(Spacing.sm)
            make.bottom.equalToSuperview().offset(-Spacing.md)
        }
    }
}
