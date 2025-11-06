//
//  QuickActionsView.swift
//  ABank
//
//  Created by 韩继宏 on 2025/10/27.
//

import UIKit
import SnapKit

struct QuickAction {
    let title: String
    let icon: String
    let action: () -> Void
}

class QuickActionsView: UIView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "快捷功能"
        label.font = .abankHeadline()
        label.textColor = .abankTextPrimary
        return label
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .abankCardBackground
        view.addCornerRadius(12)
        return view
    }()
    
    private var actions: [QuickAction] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(titleLabel)
        addSubview(containerView)
        
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }
        
        containerView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Spacing.md)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func setupActions() {
        actions = [
            QuickAction(title: "转账", icon: "arrow.left.arrow.right", action: { [weak self] in
                self?.handleAction("转账")
            }),
            QuickAction(title: "收款", icon: "qrcode", action: { [weak self] in
                self?.handleAction("收款")
            }),
            QuickAction(title: "缴费", icon: "creditcard.fill", action: { [weak self] in
                self?.handleAction("缴费")
            }),
            QuickAction(title: "理财", icon: "chart.line.uptrend.xyaxis", action: { [weak self] in
                self?.handleAction("理财")
            }),
            QuickAction(title: "贷款", icon: "banknote.fill", action: { [weak self] in
                self?.handleAction("贷款")
            }),
            QuickAction(title: "信用卡", icon: "creditcard", action: { [weak self] in
                self?.handleAction("信用卡")
            }),
            QuickAction(title: "生活", icon: "house.fill", action: { [weak self] in
                self?.handleAction("生活")
            }),
            QuickAction(title: "更多", icon: "ellipsis", action: { [weak self] in
                self?.handleAction("更多")
            })
        ]
        
        setupActionButtons()
    }
    
    private func setupActionButtons() {
        let columns = 4
        let rows = 2
        let buttonSize: CGFloat = 60
        let spacing: CGFloat = (UIScreen.main.bounds.width - Spacing.md * 2 - buttonSize * CGFloat(columns)) / CGFloat(columns + 1)
        
        for (index, action) in actions.enumerated() {
            let row = index / columns
            let col = index % columns
            
            let button = createActionButton(action: action)
            containerView.addSubview(button)
            
            button.snp.makeConstraints { make in
                make.size.equalTo(buttonSize)
                make.leading.equalToSuperview().offset(spacing + CGFloat(col) * (buttonSize + spacing))
                make.top.equalToSuperview().offset(Spacing.lg + CGFloat(row) * (buttonSize + Spacing.md))
            }
        }
        
        containerView.snp.makeConstraints { make in
            make.height.equalTo(Spacing.lg * 2 + buttonSize * CGFloat(rows) + Spacing.md * CGFloat(rows - 1))
        }
    }
    
    private func createActionButton(action: QuickAction) -> UIButton {
        let button = UIButton(type: .custom)
        
        let iconView = UIImageView(image: UIImage(systemName: action.icon))
        iconView.tintColor = .abankPrimary
        iconView.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.text = action.title
        titleLabel.font = .abankCaption()
        titleLabel.textColor = .abankTextPrimary
        titleLabel.textAlignment = .center
        
        let stackView = UIStackView(arrangedSubviews: [iconView, titleLabel])
        stackView.axis = .vertical
        stackView.spacing = Spacing.xs
        stackView.alignment = .center
        
        button.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        iconView.snp.makeConstraints { make in
            make.size.equalTo(32)
        }
        
        button.addTarget(self, action: #selector(actionButtonTapped(_:)), for: .touchUpInside)
        button.tag = actions.firstIndex(where: { $0.title == action.title }) ?? 0
        
        return button
    }
    
    @objc private func actionButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < actions.count else { return }
        actions[index].action()
    }
    
    private func handleAction(_ title: String) {
        print("点击了: \(title)")
        // TODO: 实现具体跳转逻辑
    }
}

