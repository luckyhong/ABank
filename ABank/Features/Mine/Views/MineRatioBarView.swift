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
    private let divider = CAShapeLayer()
    private var displayedRatio: CGFloat = 0.5

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(leftRatio: CGFloat, leftColor: UIColor = .abankTeal, rightColor: UIColor = UIColor(red: 1, green: 0.75, blue: 0.30, alpha: 1)) {
        let clamped = min(max(leftRatio, 0.05), 0.95)
        displayedRatio = clamped
        setNeedsLayout()
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

    override func layoutSubviews() {
        super.layoutSubviews()
        let x = bounds.width * displayedRatio
        let path = UIBezierPath()
        path.move(to: CGPoint(x: x + 1, y: 0))
        path.addLine(to: CGPoint(x: x - 1, y: bounds.height))
        divider.path = path.cgPath
    }

    private func setupUI() {
        layer.cornerRadius = 3
        clipsToBounds = true
        addSubview(leftBar)
        addSubview(rightBar)
        divider.strokeColor = UIColor.white.cgColor
        divider.lineWidth = 2
        layer.addSublayer(divider)
        snp.makeConstraints { make in
            make.height.equalTo(6)
        }
    }
}
