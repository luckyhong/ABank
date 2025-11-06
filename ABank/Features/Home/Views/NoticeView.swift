//
//  NoticeView.swift
//  ABank
//
//  Created by 韩继宏 on 2025/10/27.
//

import UIKit
import SnapKit

class NoticeView: UIView {
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .abankCardBackground
        view.addCornerRadius(12)
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "megaphone.fill"))
        imageView.tintColor = .abankWarning
        return imageView
    }()
    
    private let noticeLabel: UILabel = {
        let label = UILabel()
        label.text = "【重要通知】农业银行推出新用户专享理财活动，年化收益高达4.5%"
        label.font = .abankSubheadline()
        label.textColor = .abankTextPrimary
        label.numberOfLines = 2
        return label
    }()
    
    private let arrowImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.tintColor = .abankTextTertiary
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(noticeLabel)
        containerView.addSubview(arrowImageView)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(60)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        
        noticeLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(Spacing.md)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(arrowImageView.snp.leading).offset(-Spacing.md)
        }
        
        arrowImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(noticeTapped))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true
    }
    
    @objc private func noticeTapped() {
        print("点击了公告")
        // TODO: 跳转到公告详情
    }
}

