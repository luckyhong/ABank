//
//  WealthHotspotView.swift
//  ABank
//

import UIKit
import SnapKit

final class WealthHotspotView: UIView {

    var onTap: (() -> Void)?

    private let tagLabel = UILabel()
    private let headlineLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with hotspot: WealthHotspot) {
        tagLabel.text = hotspot.tag
        headlineLabel.text = hotspot.headline
    }

    private func setupUI() {
        tagLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        tagLabel.textColor = .abankTextPrimary

        headlineLabel.font = .systemFont(ofSize: 13)
        headlineLabel.textColor = .abankTextSecondary
        headlineLabel.numberOfLines = 1
        headlineLabel.lineBreakMode = .byTruncatingTail

        addSubview(tagLabel)
        addSubview(headlineLabel)

        tagLabel.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        headlineLabel.snp.makeConstraints { make in
            make.leading.equalTo(tagLabel.snp.trailing).offset(Spacing.sm)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    @objc private func handleTap() { onTap?() }
}
