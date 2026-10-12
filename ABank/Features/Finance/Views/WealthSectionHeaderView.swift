//
//  WealthSectionHeaderView.swift
//  ABank
//

import UIKit
import SnapKit

final class WealthSectionHeaderView: UIView {

    var onTap: (() -> Void)?

    private let titleLabel = UILabel()
    private let titleImage = UIImageView()
    private let subtitleLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))

    init(title: String, subtitle: String? = nil) {
        super.init(frame: .zero)
        titleLabel.text = title
        let artwork = ["活钱专区": "abc_wealth_header_spare_money", "稳健增长": "abc_wealth_header_steady_growth", "收益进阶": "abc_wealth_header_income_advance", "热门存款": "abc_wealth_header_deposits", "债券指数": "abc_wealth_header_bonds"]
        titleImage.image = artwork[title].flatMap { UIImage(named: $0) }
        titleImage.contentMode = .scaleAspectFit
        titleImage.isAccessibilityElement = true
        titleImage.accessibilityLabel = title
        subtitleLabel.text = subtitle
        setupUI(showsSubtitle: subtitle != nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(showsSubtitle: Bool) {
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .abankTextPrimary

        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .abankTextTertiary
        subtitleLabel.isHidden = !showsSubtitle

        chevron.tintColor = .abankTextTertiary
        chevron.contentMode = .scaleAspectFit
        chevron.isHidden = !showsSubtitle

        addSubview(titleLabel)
        if titleImage.image != nil {
            titleLabel.isHidden = true
            addSubview(titleImage)
            titleImage.snp.makeConstraints { $0.edges.equalTo(titleLabel) }
        }
        addSubview(subtitleLabel)
        addSubview(chevron)

        titleLabel.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(12)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.trailing.equalTo(chevron.snp.leading).offset(-2)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(Spacing.sm)
        }

        if showsSubtitle {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            addGestureRecognizer(tap)
            isUserInteractionEnabled = true
        }
    }

    @objc private func handleTap() { onTap?() }
}
