//
//  PromoBannerCell.swift
//  ABank
//
//  Created by 韩继宏 on 2025/11/07.
//

import UIKit
import SnapKit

final class PromoBannerCell: UICollectionViewCell {
    static let reuseIdentifier = "PromoBannerCell"

    private let gradientLayer = CAGradientLayer()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let artStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.insertSublayer(gradientLayer, at: 0)

        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = UIColor(red: 0.45, green: 0.28, blue: 0.12, alpha: 1)
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        subtitleLabel.textColor = UIColor(red: 0.55, green: 0.35, blue: 0.15, alpha: 1)

        artStack.axis = .horizontal
        artStack.spacing = 6
        artStack.alignment = .center

        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(artStack)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(28)
            make.trailing.lessThanOrEqualTo(artStack.snp.leading).offset(-8)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
        }
        artStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = contentView.bounds
    }

    func configure(with item: HomePromoBannerItem) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        switch item.tone {
        case .gold:
            gradientLayer.colors = [
                UIColor(red: 0.96, green: 0.90, blue: 0.76, alpha: 1).cgColor,
                UIColor(red: 0.93, green: 0.84, blue: 0.66, alpha: 1).cgColor
            ]
        case .peach:
            gradientLayer.colors = [
                UIColor(red: 1.0, green: 0.93, blue: 0.88, alpha: 1).cgColor,
                UIColor(red: 1.0, green: 0.86, blue: 0.78, alpha: 1).cgColor
            ]
        case .mint:
            gradientLayer.colors = [
                UIColor(red: 0.88, green: 0.96, blue: 0.93, alpha: 1).cgColor,
                UIColor(red: 0.78, green: 0.92, blue: 0.88, alpha: 1).cgColor
            ]
        }

        artStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for size in [36, 44, 36] as [CGFloat] {
            let coin = UIView()
            coin.backgroundColor = UIColor(red: 0.85, green: 0.70, blue: 0.28, alpha: 1)
            coin.layer.cornerRadius = size / 2
            coin.layer.borderWidth = 2
            coin.layer.borderColor = UIColor(red: 0.95, green: 0.85, blue: 0.45, alpha: 1).cgColor
            coin.snp.makeConstraints { make in
                make.size.equalTo(size)
            }
            artStack.addArrangedSubview(coin)
        }
    }
}
