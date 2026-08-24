//
//  MyAccountModels.swift
//  ABank
//

import Foundation

struct MyAccountPageData {
    let debitCards: [MyAccountDebitCard]
    let creditAdImageName: String
    let creditAdTitle: String
}

struct MyAccountDebitCard {
    let accountClass: String
    let maskedNumber: String
    let availableBalance: Double
    let actions: [MyAccountDebitAction]
}

struct MyAccountDebitAction {
    let title: String
    let badge: String?
}

enum MyAccountAction: String {
    case viewShare = "查看/分享"
    case setAlias = "设置别名"
    case details = "详情"
    case queryDetail = "查询明细"
    case transfer = "我要转账"
    case flexibleWealth = "活钱理财"
    case openElectronic = "开通电子账户"
    case creditAd = "信用卡广告"
    case more = "更多"
}
