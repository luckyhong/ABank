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
        card.backgroundColor = .clear
        card.layer.cornerRadius = CornerRadius.lg
        card.clipsToBounds = true

        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center

        let background = UIImage(named: "abc_mine_stats_background")
        // Trim the shipped canvas gutters and surplus white area; retain the curved lower edge.
        let cropped = background.flatMap { image -> UIImage? in
            guard let cgImage = image.cgImage else { return image }
            let inset = CGFloat(cgImage.width) * 60.0 / 1125.0
            let rect = CGRect(x: inset, y: 0, width: CGFloat(cgImage.width) - 2 * inset, height: CGFloat(cgImage.height) * 256.0 / 326.0)
            guard let trimmed = cgImage.cropping(to: rect) else { return image }
            return UIImage(cgImage: trimmed, scale: image.scale, orientation: image.imageOrientation)
        }
        let artwork = UIImageView(image: cropped)
        artwork.contentMode = .scaleToFill
        artwork.isUserInteractionEnabled = false
        card.addSubview(artwork)
        artwork.snp.makeConstraints { $0.edges.equalToSuperview() }
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
        guard UIImage(named: "abc_mine_stats_background") == nil else { return }
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
        valueLabel.font = .systemFont(ofSize: 28, weight: .regular)
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
