//
//  BannerView.swift
//  ABank
//
//  Created by 韩继宏 on 2025/11/06.
//

import UIKit
import SnapKit

final class BannerView: UIView {
    
    private let imageView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(140)
        }
        imageView.layer.cornerRadius = 12
        imageView.layer.masksToBounds = true
        
        // 简单的渐变占位（可替换为实际图片资源）
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.orange.cgColor, UIColor(red: 1.0, green: 0.85, blue: 0.7, alpha: 1).cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = bounds
        imageView.layer.addSublayer(gradient)
        imageView.layoutIfNeeded()
    }
}


