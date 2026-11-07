//
//  BranchSketchMapView.swift
//  ABank
//
//  网点示意图：用图层绘制街道网格与河道，按网点归一化坐标放置标记。不接地图 SDK。
//

import UIKit
import SnapKit

final class BranchSketchMapView: UIView {
    var onPinTapped: ((String) -> Void)?

    private let roadLayer = CAShapeLayer()
    private let mainRoadLayer = CAShapeLayer()
    private let riverLayer = CAShapeLayer()
    private let noteLabel = UILabel()
    private var pins: [(branch: Branch, button: UIButton)] = []
    private var highlightedID: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 0.92, green: 0.95, blue: 0.93, alpha: 1)
        layer.cornerRadius = 10
        clipsToBounds = true
        accessibilityIdentifier = "branch.sketchMap"

        riverLayer.strokeColor = UIColor(red: 0.70, green: 0.85, blue: 0.95, alpha: 1).cgColor
        riverLayer.fillColor = UIColor.clear.cgColor
        riverLayer.lineWidth = 14
        roadLayer.strokeColor = UIColor.white.cgColor
        roadLayer.lineWidth = 5
        mainRoadLayer.strokeColor = UIColor(red: 1.0, green: 0.92, blue: 0.75, alpha: 1).cgColor
        mainRoadLayer.lineWidth = 9
        [riverLayer, roadLayer, mainRoadLayer].forEach(layer.addSublayer)

        noteLabel.text = "示意图，非实际位置"
        noteLabel.font = .systemFont(ofSize: 10)
        noteLabel.textColor = .abankTextTertiary
        addSubview(noteLabel)
        noteLabel.snp.makeConstraints { $0.leading.bottom.equalToSuperview().inset(Spacing.sm) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(branches: [Branch], highlightedID: String?) {
        pins.forEach { $0.button.removeFromSuperview() }
        self.highlightedID = highlightedID
        pins = branches.map { branch in
            let isHighlighted = branch.id == highlightedID
            let size: CGFloat = isHighlighted ? 36 : 26
            let button = UIButton(type: .custom)
            let image = UIImage(systemName: "mappin.circle.fill",
                                withConfiguration: UIImage.SymbolConfiguration(pointSize: size))
            button.setImage(image, for: .normal)
            button.tintColor = isHighlighted ? .abankPrimary : (branch.kind == .selfService ? .abankTextTertiary : .abankTeal)
            button.accessibilityIdentifier = "branch.sketchMap.pin.\(branch.id)"
            button.accessibilityLabel = branch.name
            button.addAction(UIAction { [weak self] _ in self?.onPinTapped?(branch.id) }, for: .touchUpInside)
            addSubview(button)
            return (branch, button)
        }
        if let highlighted = pins.first(where: { $0.branch.id == highlightedID }) {
            bringSubviewToFront(highlighted.button)
        }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width, h = bounds.height
        guard w > 0, h > 0 else { return }

        let roads = UIBezierPath()
        for fraction in stride(from: 0.15, through: 0.9, by: 0.18) {
            roads.move(to: CGPoint(x: 0, y: h * fraction))
            roads.addLine(to: CGPoint(x: w, y: h * fraction))
            roads.move(to: CGPoint(x: w * fraction, y: 0))
            roads.addLine(to: CGPoint(x: w * fraction, y: h))
        }
        roadLayer.path = roads.cgPath

        let main = UIBezierPath()
        main.move(to: CGPoint(x: 0, y: h * 0.52))
        main.addLine(to: CGPoint(x: w, y: h * 0.44))
        main.move(to: CGPoint(x: w * 0.47, y: 0))
        main.addLine(to: CGPoint(x: w * 0.53, y: h))
        mainRoadLayer.path = main.cgPath

        let river = UIBezierPath()
        river.move(to: CGPoint(x: -10, y: h * 0.86))
        river.addCurve(to: CGPoint(x: w + 10, y: h * 0.70),
                       controlPoint1: CGPoint(x: w * 0.3, y: h * 0.62),
                       controlPoint2: CGPoint(x: w * 0.6, y: h * 1.0))
        riverLayer.path = river.cgPath

        let inset: CGFloat = 20
        for pin in pins {
            let size: CGFloat = pin.branch.id == highlightedID ? 44 : 34
            let x = inset + (w - inset * 2) * pin.branch.mapX
            let y = inset + (h - inset * 2) * pin.branch.mapY
            pin.button.frame = CGRect(x: x - size / 2, y: y - size / 2, width: size, height: size)
        }
    }
}
