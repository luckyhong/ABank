//
//  MineAssetStatsCardView.swift
//  ABank
//

import UIKit
import SnapKit

final class MineAssetStatsCardView: UIView {

    private let card = UIView()
    private let stack = UIStackView()
    private let patternLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        drawPattern()
    }

    func configure(with stats: [MineAssetStat]) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stats.forEach { stack.addArrangedSubview(makeStatCell(stat: $0)) }
    }

    private func setupUI() {
        card.backgroundColor = UIColor(red: 0.18, green: 0.20, blue: 0.22, alpha: 1)
        card.layer.cornerRadius = CornerRadius.lg
        card.clipsToBounds = true

        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center

        card.addSubview(stack)
        addSubview(card)

        card.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(88)
        }
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.centerY.equalToSuperview()
        }
    }

    private func drawPattern() {
        patternLayer.removeFromSuperlayer()
        let path = UIBezierPath()
        let w = card.bounds.width
        let h = card.bounds.height
        guard w > 0, h > 0 else { return }

        for i in stride(from: 0, through: Int(w + h), by: 18) {
            path.move(to: CGPoint(x: CGFloat(i), y: h))
            path.addLine(to: CGPoint(x: CGFloat(i) - h, y: 0))
        }
        patternLayer.path = path.cgPath
        patternLayer.strokeColor = UIColor.white.withAlphaComponent(0.04).cgColor
        patternLayer.lineWidth = 1
        card.layer.addSublayer(patternLayer)
    }

    private func makeStatCell(stat: MineAssetStat) -> UIView {
        let wrap = UIView()
        let valueLabel = UILabel()
        valueLabel.text = "\(stat.value)"
        valueLabel.font = .systemFont(ofSize: 28, weight: .bold)
        valueLabel.textColor = UIColor(red: 0.95, green: 0.82, blue: 0.55, alpha: 1)
        valueLabel.textAlignment = .center

        let titleLabel = UILabel()
        titleLabel.text = stat.label
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        titleLabel.textAlignment = .center

        wrap.addSubview(valueLabel)
        wrap.addSubview(titleLabel)
        valueLabel.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(valueLabel.snp.bottom).offset(4)
            make.centerX.bottom.equalToSuperview()
        }
        return wrap
    }
}
