//
//  GridMenuView.swift
//  ABank
//
//  Created by 韩继宏 on 2025/11/06.
//

import UIKit
import SnapKit

struct GridMenuItem {
    let title: String
    let systemIcon: String
}

final class GridMenuView: UIView {
    
    private let items: [GridMenuItem]
    private let columns = 4
    
    init(items: [GridMenuItem]) {
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
        }
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = Spacing.md
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: Spacing.md, left: Spacing.lg, bottom: Spacing.md, right: Spacing.lg)
        container.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let rows = Int(ceil(Double(items.count) / Double(columns)))
        for row in 0..<rows {
            let hStack = UIStackView()
            hStack.axis = .horizontal
            hStack.alignment = .fill
            hStack.distribution = .fillEqually
            hStack.spacing = 0
            stack.addArrangedSubview(hStack)
            
            let start = row * columns
            let end = min(start + columns, items.count)
            let rowItems = items[start..<end]
            for item in rowItems {
                hStack.addArrangedSubview(cellView(title: item.title, icon: item.systemIcon))
            }
            if rowItems.count < columns {
                // 填充占位，保持等宽
                for _ in 0..<(columns - rowItems.count) {
                    hStack.addArrangedSubview(UIView())
                }
            }
        }
    }
    
    private func cellView(title: String, icon: String) -> UIView {
        let wrap = UIView()
        let iconContainer = UIView()
        iconContainer.backgroundColor = UIColor.abankPrimary.withAlphaComponent(0.08)
        iconContainer.layer.cornerRadius = 18
        
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .abankPrimary
        iconView.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .abankSubheadline()
        titleLabel.textColor = .abankTextPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        
        wrap.addSubview(iconContainer)
        wrap.addSubview(titleLabel)
        iconContainer.addSubview(iconView)
        
        iconContainer.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 48, height: 48))
        }
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(24)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconContainer.snp.bottom).offset(Spacing.sm)
            make.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
        return wrap
    }
}


