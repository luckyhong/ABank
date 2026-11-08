//
//  LoanInfoRowView.swift
//  ABank
//

import UIKit
import SnapKit

/// 贷款页通用的“标题 — 值”信息行（可选说明按钮与分隔线）。
final class LoanInfoRowView: UIView {

    var onInfoTapped: (() -> Void)?

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let infoButton = UIButton(type: .system)
    private let separator = UIView()

    init(title: String, value: String, showsInfo: Bool = false, showsSeparator: Bool = true) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.textColor = .abankTextPrimary

        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 15)
        valueLabel.textColor = .abankTextSecondary
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 0

        infoButton.setImage(UIImage.abankAsset("abc_mine_detail_info_reference", fallback: "info.circle", renderingMode: .alwaysTemplate, pointSize: 13), for: .normal)
        infoButton.tintColor = UIColor(red: 190 / 255, green: 190 / 255, blue: 190 / 255, alpha: 1)
        infoButton.isHidden = !showsInfo
        infoButton.addTarget(self, action: #selector(infoTapped), for: .touchUpInside)

        separator.backgroundColor = .abankSeparator
        separator.isHidden = !showsSeparator

        addSubview(titleLabel)
        addSubview(infoButton)
        addSubview(valueLabel)
        addSubview(separator)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
        infoButton.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(4)
            make.centerY.equalTo(titleLabel)
            make.size.equalTo(18)
        }
        valueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(titleLabel)
            make.leading.greaterThanOrEqualTo(infoButton.snp.trailing).offset(12)
        }
        separator.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(52)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func infoTapped() { onInfoTapped?() }
}
