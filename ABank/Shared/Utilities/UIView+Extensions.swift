//
//  UIView+Extensions.swift
//  ABank
//
//  Created by 韩继宏 on 2025/10/27.
//

import UIKit

extension UIView {
    /// 添加圆角
    func addCornerRadius(_ radius: CGFloat) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }
    
    /// 添加阴影
    func addShadow(color: UIColor = .black, opacity: Float = 0.1, offset: CGSize = CGSize(width: 0, height: 2), radius: CGFloat = 4) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.masksToBounds = false
    }
    
    /// 添加边框
    func addBorder(color: UIColor, width: CGFloat) {
        layer.borderColor = color.cgColor
        layer.borderWidth = width
    }
}

