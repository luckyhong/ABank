//
//  BenefitsPresentation.swift
//  ABank
//
//  权益订单枚举的界面表现：主题色与状态标签是否高亮。
//

import UIKit

extension RewardCurrency {
    var tint: UIColor { self == .points ? .abankOrange : .abankSuccess }
    var unit: String { self == .points ? "积分" : "小豆" }
}

extension CouponStatus {
    var tagActive: Bool { self == .unused }
}

extension OrderStatus {
    var tagActive: Bool { self == .pendingUse }
}

func formattedAmount(_ value: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.groupingSeparator = ","
    formatter.locale = Locale(identifier: "en_US")
    return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
}
