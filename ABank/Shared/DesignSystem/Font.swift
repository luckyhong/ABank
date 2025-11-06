//
//  Font.swift
//  ABank
//
//  Created by 韩继宏 on 2025/10/27.
//

import UIKit

extension UIFont {
    // MARK: - 标题字体
    static func abankTitle1() -> UIFont {
        return UIFont.systemFont(ofSize: 28, weight: .bold)
    }
    
    static func abankTitle2() -> UIFont {
        return UIFont.systemFont(ofSize: 22, weight: .bold)
    }
    
    static func abankTitle3() -> UIFont {
        return UIFont.systemFont(ofSize: 20, weight: .semibold)
    }
    
    // MARK: - 正文字体
    static func abankHeadline() -> UIFont {
        return UIFont.systemFont(ofSize: 17, weight: .semibold)
    }
    
    static func abankBody() -> UIFont {
        return UIFont.systemFont(ofSize: 17, weight: .regular)
    }
    
    static func abankBodyMedium() -> UIFont {
        return UIFont.systemFont(ofSize: 17, weight: .medium)
    }
    
    // MARK: - 辅助字体
    static func abankSubheadline() -> UIFont {
        return UIFont.systemFont(ofSize: 15, weight: .regular)
    }
    
    static func abankCaption() -> UIFont {
        return UIFont.systemFont(ofSize: 13, weight: .regular)
    }
    
    static func abankCaptionMedium() -> UIFont {
        return UIFont.systemFont(ofSize: 13, weight: .medium)
    }
}

