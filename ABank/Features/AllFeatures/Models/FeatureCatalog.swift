//
//  FeatureCatalog.swift
//  ABank
//
//  全部功能目录：稳定 ID、分类、可用状态与默认常用。
//  仅依赖 Foundation，便于数据检查脚本在 macOS 上编译。
//

import Foundation

/// 稳定功能 ID。持久化只保存 rawValue，改名需兼容旧值。
enum FeatureID: String, Codable, CaseIterable {
    // 账户
    case myAccount, accountDetail, debitCard, incomeExpense, monthlyBill, ledgerSearch
    case assetLiability, customerInfo, openCard, sameNumberReplace
    // 转账
    case transfer, accountTransfer, phoneTransfer, transferRecords, transferLimits, receipts
    case creditCardRepay, scheduledTransfer, multiTransfer, otherBankIn, crossBorder
    case donation, mobileCollection, transferCancel
    // 财富
    case deposit, wealthProduct, fund, preciousMetals, bonds, insurance, securities, forex, personalPension
    // 贷款信用卡
    case loan, creditCard, inclusiveFinance
    // 生活
    case lifePayment, mobileRecharge, beans, pointsMall, government, socialInsurance
    case campus, cafeteria, partyFee, carService, abcMall, hospital, providentFund, transport
    case takeout, movies, hotelTravel, express, charity, pensionCommunity, hotActivities, cityZone
    // 网点与安全
    case branchQuery, branchQueue, coinReservation
    case securityCenter, loginSettings, paymentSettings, loginDevices
    case benefits, customerLevel, orders, scan
}

enum FeatureCategory: String, CaseIterable {
    case account, transfer, wealth, credit, life, service

    var title: String {
        switch self {
        case .account: return "账户"
        case .transfer: return "转账"
        case .wealth: return "财富"
        case .credit: return "贷款信用卡"
        case .life: return "生活"
        case .service: return "网点与安全"
        }
    }
}

struct FeatureDescriptor {
    enum Availability: Equatable {
        case available(AppRoute)
        /// stage 为 nil 表示尚未排入开发计划。
        case planned(stage: String?)
    }

    let id: FeatureID
    let title: String
    let keywords: [String]
    let imageName: String?
    let systemIcon: String
    let category: FeatureCategory
    let availability: Availability

    var isAvailable: Bool {
        if case .available = availability { return true }
        return false
    }

    var plannedStageText: String {
        if case .planned(let stage?) = availability { return "计划阶段：\(stage)" }
        return "后续规划"
    }
}

enum FeatureCatalog {
    static let defaultFavorites: [FeatureID] = [
        .creditCard, .pensionCommunity, .inclusiveFinance, .deposit, .wealthProduct,
        .loan, .lifePayment, .hotActivities, .cityZone
    ]

    static func descriptor(_ id: FeatureID) -> FeatureDescriptor {
        guard let descriptor = byID[id] else {
            preconditionFailure("FeatureCatalog 缺少 \(id.rawValue)")
        }
        return descriptor
    }

    static func features(in category: FeatureCategory) -> [FeatureDescriptor] {
        all.filter { $0.category == category }
    }

    private static let byID: [FeatureID: FeatureDescriptor] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    private static let branchStage = "M5 网点服务"
    private static let securityStage = "M4 安全中心"
    private static let benefitsStage = "M6 权益订单"
    private static let wealthStage = "M7 财富产品"
    private static let paymentStage = "M8 充值缴费"

    private static func item(
        _ id: FeatureID, _ title: String, _ category: FeatureCategory,
        image: String? = nil, icon: String, keywords: [String] = [],
        _ availability: FeatureDescriptor.Availability
    ) -> FeatureDescriptor {
        FeatureDescriptor(id: id, title: title, keywords: keywords, imageName: image,
                          systemIcon: icon, category: category, availability: availability)
    }

    static let all: [FeatureDescriptor] = [
        // MARK: 账户
        item(.myAccount, "我的账户", .account, image: "abc_home_account", icon: "person.fill",
             keywords: ["账户", "银行卡", "余额"], .available(.myAccount)),
        item(.accountDetail, "明细查询", .account, icon: "doc.text.magnifyingglass",
             keywords: ["明细", "流水", "交易记录"], .available(.accountDetail(accountID: nil, maskedNumber: nil))),
        item(.debitCard, "借记卡", .account, icon: "creditcard.fill",
             keywords: ["卡片", "银行卡", "余额"], .available(.debitCardDetail)),
        item(.incomeExpense, "收支", .account, image: "abc_home_income", icon: "list.bullet.rectangle",
             keywords: ["账单", "流水", "收入", "支出"], .available(.incomeExpense(accountID: nil))),
        item(.monthlyBill, "月度账单", .account, icon: "chart.pie.fill",
             keywords: ["账单", "分析", "统计"], .available(.ledgerAnalysis)),
        item(.ledgerSearch, "交易搜索", .account, icon: "magnifyingglass",
             keywords: ["流水", "查询"], .available(.ledgerSearch)),
        item(.assetLiability, "资产负债", .account, icon: "chart.bar.doc.horizontal",
             keywords: ["资产", "负债", "总资产"], .available(.assetLiability)),
        item(.customerInfo, "客户资料", .account, icon: "person.text.rectangle",
             keywords: ["个人信息", "手机号", "税收"], .available(.customerInfo)),
        item(.openCard, "我要开卡", .account, image: "abc_mine_branch_open", icon: "creditcard.and.123",
             keywords: ["开户", "办卡"], .planned(stage: branchStage)),
        item(.sameNumberReplace, "同号换卡", .account, image: "abc_mine_branch_replace", icon: "arrow.triangle.2.circlepath",
             keywords: ["换卡"], .planned(stage: branchStage)),

        // MARK: 转账
        item(.transfer, "转账", .transfer, image: "abc_home_transfer", icon: "arrow.left.arrow.right",
             keywords: ["汇款", "付款"], .available(.transfer(payerAccountID: nil))),
        item(.accountTransfer, "账号转账", .transfer, icon: "creditcard",
             keywords: ["汇款", "卡号"], .available(.transferForm(method: .account))),
        item(.phoneTransfer, "手机号转账", .transfer, icon: "iphone",
             keywords: ["汇款", "手机号"], .available(.transferForm(method: .phone))),
        item(.transferRecords, "转账记录", .transfer, icon: "clock.arrow.circlepath",
             keywords: ["历史", "汇款记录"], .available(.transferRecords)),
        item(.transferLimits, "转账限额", .transfer, image: "abc_mine_security_transfer", icon: "shield.lefthalf.filled",
             keywords: ["限额", "转账设置"], .available(.transferLimits)),
        item(.receipts, "电子回单", .transfer, icon: "doc.richtext",
             keywords: ["回单", "凭证"], .available(.transferReceipts)),
        item(.creditCardRepay, "信用卡还款", .transfer, image: "abc_transfer_repay", icon: "creditcard",
             keywords: ["还款"], .planned(stage: nil)),
        item(.scheduledTransfer, "预约转账", .transfer, image: "abc_transfer_schedule", icon: "clock",
             keywords: ["定时"], .planned(stage: nil)),
        item(.multiTransfer, "向多人转账", .transfer, image: "abc_transfer_multiple", icon: "person.3",
             keywords: ["批量"], .planned(stage: nil)),
        item(.otherBankIn, "他行卡转入", .transfer, image: "abc_transfer_other_bank", icon: "arrow.uturn.left",
             keywords: ["他行", "归集"], .planned(stage: nil)),
        item(.crossBorder, "跨境服务", .transfer, image: "abc_transfer_crossborder", icon: "airplane",
             keywords: ["境外", "汇款"], .planned(stage: nil)),
        item(.donation, "公益捐款", .transfer, image: "abc_transfer_donation", icon: "heart",
             keywords: ["捐赠"], .planned(stage: nil)),
        item(.mobileCollection, "手机号收款", .transfer, image: "abc_transfer_mobile_collection", icon: "iphone.gen1",
             keywords: ["收款"], .planned(stage: nil)),
        item(.transferCancel, "转账撤销", .transfer, image: "abc_transfer_cancel", icon: "arrow.uturn.backward",
             keywords: ["撤回"], .planned(stage: nil)),

        // MARK: 财富
        item(.deposit, "存款", .wealth, image: "abc_home_deposit", icon: "banknote",
             keywords: ["定期", "储蓄"], .planned(stage: wealthStage)),
        item(.wealthProduct, "理财产品", .wealth, image: "abc_home_wealth", icon: "chart.line.uptrend.xyaxis",
             keywords: ["理财", "收益", "农银快e宝"], .planned(stage: wealthStage)),
        item(.fund, "基金", .wealth, image: "abc_wealth_menu_fund", icon: "chart.line.uptrend.xyaxis",
             keywords: ["定投"], .planned(stage: wealthStage)),
        item(.preciousMetals, "贵金属", .wealth, image: "abc_wealth_menu_metals", icon: "square.stack.3d.up.fill",
             keywords: ["黄金", "白银", "存金通"], .planned(stage: nil)),
        item(.bonds, "债券", .wealth, image: "abc_wealth_menu_bonds", icon: "chart.bar.fill",
             keywords: ["国债"], .planned(stage: nil)),
        item(.insurance, "保险", .wealth, image: "abc_wealth_menu_insurance", icon: "shield.fill",
             keywords: ["保障"], .planned(stage: nil)),
        item(.securities, "证券期货", .wealth, image: "abc_wealth_menu_securities", icon: "doc.text.fill",
             keywords: ["股票", "银证"], .planned(stage: nil)),
        item(.forex, "外汇", .wealth, image: "abc_wealth_menu_forex", icon: "dollarsign.arrow.circlepath",
             keywords: ["购汇", "结汇"], .planned(stage: nil)),
        item(.personalPension, "个人养老金", .wealth, image: "abc_wealth_menu_pension", icon: "house.and.flag.fill",
             keywords: ["养老"], .planned(stage: nil)),

        // MARK: 贷款信用卡
        item(.loan, "贷款", .credit, image: "abc_home_loan", icon: "bag.fill",
             keywords: ["借款", "还款", "合同", "分期借钱"], .available(.myLoan)),
        item(.creditCard, "信用卡", .credit, image: "abc_home_credit", icon: "creditcard",
             keywords: ["账单", "分期"], .planned(stage: nil)),
        item(.inclusiveFinance, "普惠金融", .credit, image: "abc_home_inclusive", icon: "yensign.circle",
             keywords: ["小微", "贷款"], .planned(stage: nil)),

        // MARK: 生活
        item(.lifePayment, "生活缴费", .life, image: "abc_home_payment", icon: "bolt.fill",
             keywords: ["水费", "电费", "燃气"], .planned(stage: paymentStage)),
        item(.mobileRecharge, "手机充值", .life, image: "abc_life_menu_mobile", icon: "iphone",
             keywords: ["话费", "流量"], .planned(stage: paymentStage)),
        item(.beans, "小豆乐园", .life, image: "abc_life_menu_beans", icon: "leaf.fill",
             keywords: ["小豆", "签到"], .planned(stage: benefitsStage)),
        item(.pointsMall, "积分商城", .life, image: "abc_life_menu_points", icon: "star.fill",
             keywords: ["积分", "兑换"], .planned(stage: benefitsStage)),
        item(.government, "政务民生", .life, image: "abc_life_menu_government", icon: "person.fill",
             .planned(stage: nil)),
        item(.socialInsurance, "社保医保", .life, image: "abc_life_menu_social", icon: "person.text.rectangle",
             keywords: ["社保", "医保"], .planned(stage: nil)),
        item(.campus, "校园", .life, image: "abc_life_menu_campus", icon: "graduationcap.fill",
             keywords: ["学费"], .planned(stage: nil)),
        item(.cafeteria, "食堂", .life, image: "abc_life_menu_cafeteria", icon: "fork.knife",
             .planned(stage: nil)),
        item(.partyFee, "党费", .life, image: "abc_life_menu_party", icon: "flag.fill",
             .planned(stage: nil)),
        item(.carService, "车主服务", .life, image: "abc_life_menu_car", icon: "car.fill",
             keywords: ["ETC", "违章"], .planned(stage: nil)),
        item(.abcMall, "农银商城", .life, image: "abc_life_menu_market", icon: "storefront.fill",
             keywords: ["购物"], .planned(stage: nil)),
        item(.hospital, "医疗挂号", .life, image: "abc_life_menu_hospital", icon: "cross.case.fill",
             keywords: ["医院", "挂号"], .planned(stage: nil)),
        item(.providentFund, "公积金", .life, image: "abc_life_menu_provident", icon: "building.columns.fill",
             .planned(stage: nil)),
        item(.transport, "交通出行", .life, image: "abc_life_menu_transport", icon: "bus.fill",
             keywords: ["乘车码", "公交"], .planned(stage: nil)),
        item(.takeout, "美团外卖", .life, icon: "bag.fill",
             keywords: ["外卖"], .planned(stage: nil)),
        item(.movies, "电影演出", .life, icon: "film.fill",
             keywords: ["电影票"], .planned(stage: nil)),
        item(.hotelTravel, "酒店旅行", .life, icon: "airplane",
             keywords: ["酒店", "机票"], .planned(stage: nil)),
        item(.express, "快递寄件", .life, icon: "shippingbox.fill",
             keywords: ["快递"], .planned(stage: nil)),
        item(.charity, "爱心公益", .life, icon: "heart.fill",
             keywords: ["公益"], .planned(stage: nil)),
        item(.pensionCommunity, "养老社区", .life, image: "abc_home_pension_community", icon: "house",
             keywords: ["养老"], .planned(stage: nil)),
        item(.hotActivities, "热门活动", .life, image: "abc_home_activity", icon: "megaphone.fill",
             keywords: ["活动", "优惠"], .planned(stage: nil)),
        item(.cityZone, "城市专区", .life, image: "abc_home_city", icon: "building.2.fill",
             keywords: ["城市"], .planned(stage: nil)),

        // MARK: 网点与安全
        item(.branchQuery, "网点查询", .service, image: "abc_mine_branch_find", icon: "building.columns",
             keywords: ["网点", "附近", "营业时间"], .planned(stage: branchStage)),
        item(.branchQueue, "网点取号", .service, icon: "number.circle",
             keywords: ["排队", "取号", "网点"], .planned(stage: branchStage)),
        item(.coinReservation, "纪念币预约", .service, image: "abc_mine_branch_coin", icon: "bitcoinsign.circle",
             keywords: ["纪念币", "预约"], .planned(stage: branchStage)),
        item(.securityCenter, "安全中心", .service, icon: "lock.shield.fill",
             keywords: ["安全", "设置"], .planned(stage: securityStage)),
        item(.loginSettings, "登录设置", .service, image: "abc_mine_security_login", icon: "door.left.hand.open",
             keywords: ["密码", "指纹", "面容"], .planned(stage: securityStage)),
        item(.paymentSettings, "支付设置", .service, image: "abc_mine_security_payment", icon: "lock.shield",
             keywords: ["免密", "支付"], .planned(stage: securityStage)),
        item(.loginDevices, "登录设备", .service, image: "abc_mine_security_devices", icon: "iphone",
             keywords: ["设备"], .planned(stage: securityStage)),
        item(.benefits, "权益中心", .service, icon: "gift.fill",
             keywords: ["权益", "卡券"], .planned(stage: benefitsStage)),
        item(.customerLevel, "客户等级", .service, icon: "crown.fill",
             keywords: ["等级", "VIP"], .planned(stage: benefitsStage)),
        item(.orders, "我的订单", .service, icon: "doc.plaintext",
             keywords: ["订单"], .planned(stage: benefitsStage)),
        item(.scan, "扫一扫", .service, image: "abc_home_scan", icon: "qrcode.viewfinder",
             keywords: ["二维码", "付款码"], .planned(stage: "M10 快捷与扫码"))
    ]
}
