//
//  MineCardHeaderView.swift
//  ABank
//

import UIKit
import SnapKit

final class MineCardHeaderView: UIView {

    var onTap: (() -> Void)?
    var onEyeTapped: (() -> Void)?
    var onRefreshTapped: (() -> Void)?

    private let titleLabel = UILabel()
    private let eyeButton = UIButton(type: .system)
    private let refreshButton = UIButton(type: .system)
    private let chevronView = UIImageView(image: UIImage(systemName: "chevron.right"))

    private var isAmountVisible = true

    init(title: String, showsEye: Bool = false, showsRefresh: Bool = false) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupUI(showsEye: showsEye, showsRefresh: showsRefresh)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setAmountVisible(_ visible: Bool) {
        isAmountVisible = visible
        let icon = visible ? "eye" : "eye.slash"
        eyeButton.setImage(UIImage(systemName: icon), for: .normal)
    }

    private func setupUI(showsEye: Bool, showsRefresh: Bool) {
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .abankTextPrimary

        eyeButton.setImage(UIImage(systemName: "eye"), for: .normal)
        eyeButton.tintColor = .abankTextTertiary
        eyeButton.isHidden = !showsEye
        eyeButton.addTarget(self, action: #selector(eyeTapped), for: .touchUpInside)

        refreshButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        refreshButton.tintColor = .abankPrimary
        refreshButton.isHidden = !showsRefresh
        refreshButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)

        chevronView.tintColor = .abankTextTertiary
        chevronView.contentMode = .scaleAspectFit

        addSubview(titleLabel)
        addSubview(eyeButton)
        addSubview(refreshButton)
        addSubview(chevronView)

        titleLabel.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        eyeButton.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(6)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        refreshButton.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(6)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        chevronView.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(12)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    @objc private func handleTap() { onTap?() }
    @objc private func eyeTapped() { onEyeTapped?() }
    @objc private func refreshTapped() { onRefreshTapped?() }
}
