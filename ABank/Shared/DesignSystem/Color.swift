//
//  Color.swift
//  ABank
//
//  Created by 韩继宏 on 2025/10/27.
//

import UIKit

extension UIColor {
    // MARK: - 主题色（参考农业银行绿色系）
    static let abankPrimary = UIColor(red: 0.0/255.0, green: 136.0/255.0, blue: 102.0/255.0, alpha: 1.0) // 农业银行绿
    static let abankPrimaryDark = UIColor(red: 0.0, green: 0.5, blue: 0.15, alpha: 1.0)
    
    // MARK: - 背景色
    static let abankBackground = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0) // 浅灰背景
    static let abankCardBackground = UIColor.white
    static let abankSectionBackground = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
    
    // MARK: - 文字颜色
    static let abankTextPrimary = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
    static let abankTextSecondary = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
    static let abankTextTertiary = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
    
    // MARK: - 功能色
    static let abankSuccess = UIColor(red: 0.0, green: 0.7, blue: 0.3, alpha: 1.0)
    static let abankWarning = UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)
    static let abankError = UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
    
    // MARK: - 分割线
    static let abankSeparator = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
}

