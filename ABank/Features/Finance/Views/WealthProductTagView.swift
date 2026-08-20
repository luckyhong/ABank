//
//  WealthProductTagView.swift
//  ABank
//

import UIKit
import SnapKit

enum WealthRibbonStyle {
    case hot
    case selected
}

final class WealthProductTagView: UILabel {
    init(text: String) {
        super.init(frame: .zero)
        self.text = text
        font = .systemFont(ofSize: 10, weight: .medium)
        textColor = .abankGold
        layer.borderColor = UIColor.abankGold.cgColor
        layer.borderWidth = 0.5
        layer.cornerRadius = 3
        textAlignment = .center
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class WealthRibbonBadgeView: UIView {
    private let label = UILabel()

    init(text: String, style: WealthRibbonStyle) {
        super.init(frame: .zero)
        label.text = text
        label.font = .systemFont(ofSize: 9, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        backgroundColor = style == .hot ? .abankHighlight : .abankHighlight
        clipsToBounds = true
        addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6))
        }
        transform = CGAffineTransform(rotationAngle: .pi / 4)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
