//
//  WealthProductTagView.swift
//  ABank
//

import UIKit
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
