//
//  ShortcutRowView.swift
//  ABank
//
//  Created by 韩继宏 on 2025/11/06.
//

import UIKit
import SnapKit

struct ShortcutItem {
    let title: String
    let systemIcon: String
}

final class ShortcutRowView: UIView {
    
    private let items: [ShortcutItem]
    
    init(items: [ShortcutItem]) {
        self.items = items
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupUI() {
        let container = UIView()
        container.backgroundColor = .abankCardBackground
        container.layer.cornerRadius = 14
        container.layer.masksToBounds = true
        addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(108)
        }
        
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fillEqually
        stack.spacing = 0
        container.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Spacing.lg)
        }
        
        for item in items {
            let v = verticalIcon(title: item.title, icon: item.systemIcon)
            stack.addArrangedSubview(v)
        }
    }
    
    private func verticalIcon(title: String, icon: String) -> UIView {
        let wrap = UIView()
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .abankPrimary
        iconView.contentMode = .scaleAspectFit
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .abankBodyMedium()
        titleLabel.textColor = .abankTextPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        
        wrap.addSubview(iconView)
        wrap.addSubview(titleLabel)
        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.size.equalTo(36)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(Spacing.sm)
            make.centerX.equalToSuperview()
            make.height.greaterThanOrEqualTo(24)
            make.bottom.equalToSuperview()
        }
        return wrap
    }
}


