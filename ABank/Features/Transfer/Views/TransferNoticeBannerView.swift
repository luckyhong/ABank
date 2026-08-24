//
//  TransferNoticeBannerView.swift
//  ABank
//

import UIKit
import SnapKit

final class TransferNoticeBannerView: UIView {

    var onClose: (() -> Void)?
    var onTapped: (() -> Void)?

    private let speakerIcon = UIImageView()
    private let textLabel = UILabel()
    private let closeButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(text: String) {
        textLabel.text = text
    }

    private func setupUI() {
        backgroundColor = UIColor(red: 255 / 255, green: 248 / 255, blue: 230 / 255, alpha: 1)

        let speakerConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        speakerIcon.image = UIImage(systemName: "speaker.wave.2.fill", withConfiguration: speakerConfig)
        speakerIcon.tintColor = UIColor(red: 230 / 255, green: 160 / 255, blue: 40 / 255, alpha: 1)
        speakerIcon.contentMode = .scaleAspectFit

        textLabel.font = .systemFont(ofSize: 13)
        textLabel.textColor = .abankTextPrimary

        let closeConfig = UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: closeConfig), for: .normal)
        closeButton.tintColor = .abankTextTertiary
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        addSubview(speakerIcon)
        addSubview(textLabel)
        addSubview(closeButton)

        speakerIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
            make.size.equalTo(28)
        }
        textLabel.snp.makeConstraints { make in
            make.leading.equalTo(speakerIcon.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualTo(closeButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(bannerTapped))
        addGestureRecognizer(tap)

        snp.makeConstraints { make in
            make.height.equalTo(36)
        }
    }

    @objc private func closeTapped() { onClose?() }
    @objc private func bannerTapped() { onTapped?() }
}
