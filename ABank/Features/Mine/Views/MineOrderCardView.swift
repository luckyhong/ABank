//
//  MineOrderCardView.swift
//  ABank
//

import UIKit
import SnapKit

final class MineOrderCardView: UIView {

    var onTap: (() -> Void)?

    private let card = UIControl()
    private let titleLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        card.backgroundColor = .abankCardBackground
        card.layer.cornerRadius = CornerRadius.lg
        card.addShadow(color: .black, opacity: 0.06, offset: CGSize(width: 0, height: 2), radius: 8)
        card.addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        titleLabel.text = "我的订单"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .abankTextPrimary
        chevron.tintColor = .abankTextTertiary
        chevron.contentMode = .scaleAspectFit

        addSubview(card)
        card.addSubview(titleLabel)
        card.addSubview(chevron)

        card.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(52)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.centerY.equalToSuperview()
        }
        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.centerY.equalToSuperview()
            make.size.equalTo(12)
        }
    }

    @objc private func handleTap() { onTap?() }
}
