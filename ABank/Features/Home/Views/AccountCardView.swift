//
//  AccountCardView.swift
//  ABank
//
//  Created by 韩继宏 on 2025/10/27.
//

import UIKit
import SnapKit

class AccountCardView: UIView {
    
    private let cardBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .abankPrimary
        view.addCornerRadius(16)
        return view
    }()
    
    private let bankNameLabel: UILabel = {
        let label = UILabel()
        label.text = "中国农业银行"
        label.textColor = .white
        label.font = .abankHeadline()
        return label
    }()
    
    private let cardNumberLabel: UILabel = {
        let label = UILabel()
        label.text = "6228 **** **** 1234"
        label.textColor = .white
        label.font = .abankBody()
        return label
    }()
    
    private let balanceTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "账户余额（元）"
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        label.font = .abankCaption()
        return label
    }()
    
    private let balanceLabel: UILabel = {
        let label = UILabel()
        label.text = "¥ 12,345.67"
        label.textColor = .white
        label.font = .abankTitle1()
        return label
    }()
    
    private let eyeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "eye.fill"), for: .normal)
        button.setImage(UIImage(systemName: "eye.slash.fill"), for: .selected)
        button.tintColor = .white
        return button
    }()
    
    private var isBalanceHidden = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(cardBackgroundView)
        cardBackgroundView.addSubview(bankNameLabel)
        cardBackgroundView.addSubview(cardNumberLabel)
        cardBackgroundView.addSubview(balanceTitleLabel)
        cardBackgroundView.addSubview(balanceLabel)
        cardBackgroundView.addSubview(eyeButton)
        
        cardBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(200)
        }
        
        bankNameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Spacing.lg)
            make.leading.equalToSuperview().offset(Spacing.lg)
        }
        
        eyeButton.snp.makeConstraints { make in
            make.centerY.equalTo(bankNameLabel)
            make.trailing.equalToSuperview().offset(-Spacing.lg)
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        
        cardNumberLabel.snp.makeConstraints { make in
            make.top.equalTo(bankNameLabel.snp.bottom).offset(Spacing.xl)
            make.leading.equalToSuperview().offset(Spacing.lg)
        }
        
        balanceTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(cardNumberLabel.snp.bottom).offset(Spacing.xl)
            make.leading.equalToSuperview().offset(Spacing.lg)
        }
        
        balanceLabel.snp.makeConstraints { make in
            make.top.equalTo(balanceTitleLabel.snp.bottom).offset(Spacing.sm)
            make.leading.equalToSuperview().offset(Spacing.lg)
            make.bottom.equalToSuperview().offset(-Spacing.lg)
        }
        
        eyeButton.addTarget(self, action: #selector(eyeButtonTapped), for: .touchUpInside)
    }
    
    @objc private func eyeButtonTapped() {
        isBalanceHidden.toggle()
        eyeButton.isSelected = isBalanceHidden
        balanceLabel.text = isBalanceHidden ? "¥ ****.**" : "¥ 12,345.67"
    }
    
    func updateBalance(_ balance: String) {
        balanceLabel.text = "¥ \(balance)"
    }
}

