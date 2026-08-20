//
//  MineRatioBarView.swift
//  ABank
//

import UIKit
import SnapKit

/// 收支比例条
final class MineRatioBarView: UIView {

    private let leftBar = UIView()
    private let rightBar = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(leftRatio: CGFloat, leftColor: UIColor = .abankTeal, rightColor: UIColor = .abankOrange) {
        let clamped = min(max(leftRatio, 0.05), 0.95)
        leftBar.backgroundColor = leftColor
        rightBar.backgroundColor = rightColor
        leftBar.snp.remakeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(clamped)
        }
        rightBar.snp.remakeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
            make.leading.equalTo(leftBar.snp.trailing)
        }
    }

    private func setupUI() {
        layer.cornerRadius = 3
        clipsToBounds = true
        addSubview(leftBar)
        addSubview(rightBar)
        snp.makeConstraints { make in
            make.height.equalTo(6)
        }
    }
}
