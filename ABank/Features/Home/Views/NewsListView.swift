//
//  NewsListView.swift
//  ABank
//
//  Created by 韩继宏 on 2025/11/06.
//

import UIKit
import SnapKit

final class NewsListView: UIView {
    
    private let stack = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupUI() {
        stack.axis = .vertical
        stack.spacing = Spacing.sm
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        stack.addArrangedSubview(itemView(badge: "待办", text: "快来试试智能提醒吧~"))
        stack.addArrangedSubview(itemView(badge: "头条", text: "国务院领导人出席第八届中国国际进..."))
    }
    
    private func itemView(badge: String, text: String) -> UIView {
        let wrap = UIView()
        let badgeLabel = UILabel()
        badgeLabel.text = badge
        badgeLabel.font = .abankCaptionMedium()
        badgeLabel.textColor = .abankWarning
        
        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = .abankBody()
        textLabel.textColor = .abankTextPrimary
        textLabel.numberOfLines = 1
        
        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = .abankTextTertiary
        
        wrap.addSubview(badgeLabel)
        wrap.addSubview(textLabel)
        wrap.addSubview(arrow)
        
        arrow.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(14)
        }
        badgeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        textLabel.snp.makeConstraints { make in
            make.leading.equalTo(badgeLabel.snp.trailing).offset(Spacing.sm)
            make.trailing.lessThanOrEqualTo(arrow.snp.leading).offset(-Spacing.sm)
            make.centerY.equalToSuperview()
        }
        
        wrap.snp.makeConstraints { make in
            make.height.equalTo(24)
        }
        return wrap
    }
}


