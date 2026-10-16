//
//  MyAccountOpenAccountButton.swift
//  ABank
//

import UIKit
import SnapKit

final class MyAccountOpenAccountButton: UIControl {

    private let borderColor = UIColor(red: 245 / 255, green: 173 / 255, blue: 27 / 255, alpha: 1)
    private let dashedBorder = CAShapeLayer()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "+  开通电子账户"
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = UIColor(red: 245 / 255, green: 173 / 255, blue: 27 / 255, alpha: 1)
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        layer.cornerRadius = CornerRadius.sm

        dashedBorder.fillColor = UIColor.clear.cgColor
        dashedBorder.strokeColor = borderColor.cgColor
        dashedBorder.lineWidth = 1
        dashedBorder.lineDashPattern = [3, 3]
        layer.addSublayer(dashedBorder)

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        snp.makeConstraints { make in
            make.height.equalTo(48)
        }

        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = UIBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), cornerRadius: CornerRadius.sm)
        dashedBorder.path = path.cgPath
        dashedBorder.frame = bounds
    }

    @objc private func touchDown() {
        alpha = 0.7
    }

    @objc private func touchUp() {
        alpha = 1
    }
}
