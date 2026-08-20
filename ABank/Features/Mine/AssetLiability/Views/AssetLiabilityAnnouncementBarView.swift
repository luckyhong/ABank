//
//  AssetLiabilityAnnouncementBarView.swift
//  ABank
//

import UIKit
import SnapKit

final class AssetLiabilityAnnouncementBarView: UIControl {

    var onTap: (() -> Void)?

    private let speakerIcon = UIImageView()
    private let messageLabel = UILabel()
    private let arrowIcon = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(message: String) {
        messageLabel.text = message
    }

    private func setupUI() {
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        speakerIcon.image = UIImage(systemName: "speaker.wave.2.fill", withConfiguration: iconConfig)
        speakerIcon.tintColor = UIColor(red: 175 / 255, green: 125 / 255, blue: 60 / 255, alpha: 1)
        speakerIcon.contentMode = .scaleAspectFit

        messageLabel.font = .systemFont(ofSize: 13)
        messageLabel.textColor = UIColor(red: 155 / 255, green: 105 / 255, blue: 50 / 255, alpha: 1)
        messageLabel.lineBreakMode = .byTruncatingTail

        let arrowConfig = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        arrowIcon.image = UIImage(systemName: "chevron.right", withConfiguration: arrowConfig)
        arrowIcon.tintColor = UIColor(red: 175 / 255, green: 130 / 255, blue: 75 / 255, alpha: 1)
        arrowIcon.contentMode = .scaleAspectFit

        addSubview(speakerIcon)
        addSubview(messageLabel)
        addSubview(arrowIcon)

        speakerIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(15)
        }
        messageLabel.snp.makeConstraints { make in
            make.leading.equalTo(speakerIcon.snp.trailing).offset(6)
            make.centerY.equalToSuperview()
        }
        arrowIcon.snp.makeConstraints { make in
            make.leading.equalTo(messageLabel.snp.trailing).offset(4)
            make.trailing.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(12)
        }
        snp.makeConstraints { make in
            make.height.equalTo(32)
        }
    }

    @objc private func tapped() { onTap?() }
}
