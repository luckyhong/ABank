//
//  String+Extensions.swift
//  ABank
//
//  Created by 韩继宏 on 2025/10/27.
//

import Foundation

extension String {
    /// 格式化金额显示（添加千分位分隔符）
    func formatAmount() -> String {
        guard let amount = Double(self) else { return self }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? self
    }
    
    /// 隐藏银行卡号中间部分
    func maskBankCard() -> String {
        guard count >= 8 else { return self }
        let prefix = String(prefix(4))
        let suffix = String(suffix(4))
        let middle = String(repeating: "*", count: count - 8)
        return prefix + middle + suffix
    }
}

