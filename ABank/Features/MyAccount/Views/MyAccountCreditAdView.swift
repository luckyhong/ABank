//
//  MyAccountCreditAdView.swift
//  ABank
//

import UIKit
import SnapKit

final class MyAccountCreditAdView: UIView {

    var onAdTapped: (() -> Void)?

    private let sectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "信用卡"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .abankTextPrimary
        return label
    }()

    private let bannerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = CornerRadius.sm
        imageView.backgroundColor = UIColor(red: 180 / 255, green: 30 / 255, blue: 35 / 255, alpha: 1)
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private let adTag = AdTagLabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(imageName: String) {
        bannerImageView.image = UIImage(named: imageName)
    }

    private func setupUI() {
        addSubview(sectionTitleLabel)
        addSubview(bannerImageView)
        bannerImageView.addSubview(adTag)

        sectionTitleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }
        bannerImageView.snp.makeConstraints { make in
            make.top.equalTo(sectionTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(bannerImageView.snp.width).multipliedBy(120.0 / 440.0)
        }
        adTag.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.bottom.equalToSuperview().offset(-6)
        }
        adTag.textColor = UIColor.white.withAlphaComponent(0.85)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        bannerImageView.addGestureRecognizer(tap)
    }

    @objc private func handleTap() {
        onAdTapped?()
    }
}
