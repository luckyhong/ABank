//
//  MineBranchCardView.swift
//  ABank
//

import UIKit
import SnapKit

final class MineBranchCardView: UIView {

    var onTap: (() -> Void)?
    var onRefreshTapped: (() -> Void)?
    var onItemTapped: ((Int) -> Void)?

    private let card = UIView()
    private let header = MineCardHeaderView(title: "我的网点", showsRefresh: true)
    private let subtitleLabel = UILabel()
    private let grid = MineActionGridView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with branch: MineBranchInfo) {
        subtitleLabel.text = "\(branch.name)，距您 \(branch.distance)"
        grid.configure(with: branch.services)
    }

    private func setupUI() {
        card.backgroundColor = .abankCardBackground
        card.layer.cornerRadius = CornerRadius.lg
        card.addShadow(color: .black, opacity: 0.06, offset: CGSize(width: 0, height: 2), radius: 8)

        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .abankTextTertiary

        header.onTap = { [weak self] in self?.onTap?() }
        header.onRefreshTapped = { [weak self] in self?.onRefreshTapped?() }
        grid.onItemTapped = { [weak self] index in self?.onItemTapped?(index) }

        addSubview(card)
        [header, subtitleLabel, grid].forEach { card.addSubview($0) }

        card.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        grid.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(Spacing.md)
            make.leading.trailing.equalToSuperview().inset(Spacing.sm)
            make.bottom.equalToSuperview().offset(-Spacing.md)
        }
    }
}
