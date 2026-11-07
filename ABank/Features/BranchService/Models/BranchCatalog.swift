//
//  BranchCatalog.swift
//  ABank
//
//  6 个城市的模拟网点。名称、地址、电话均为虚构，不对应真实网点。
//

import Foundation

nonisolated enum BranchCatalog {
    static let defaultCityID = "xian"

    static let cities: [BranchCity] = [
        BranchCity(id: "xian", name: "西安市"),
        BranchCity(id: "beijing", name: "北京市"),
        BranchCity(id: "shanghai", name: "上海市"),
        BranchCity(id: "guangzhou", name: "广州市"),
        BranchCity(id: "chengdu", name: "成都市"),
        BranchCity(id: "wuhan", name: "武汉市")
    ]

    private static let allBusinesses: Set<BranchBusiness> = Set(BranchBusiness.allCases)
    private static let personalOnly: Set<BranchBusiness> = [.personalCash, .personalNonCash, .openCard, .sameNumberReplace]
    private static let noCoin: Set<BranchBusiness> = [.personalCash, .personalNonCash, .corporate, .openCard, .sameNumberReplace]

    private static func full(_ id: String, _ city: String, _ name: String, _ address: String, _ phone: String,
                             _ distance: Int, _ hours: BusinessHours, _ businesses: Set<BranchBusiness>,
                             _ x: Double, _ y: Double) -> Branch {
        Branch(id: id, cityID: city, name: name, address: address, phone: phone, distanceMeters: distance,
               kind: .full, hours: hours, businesses: businesses, mapX: x, mapY: y)
    }

    private static func selfService(_ id: String, _ city: String, _ name: String, _ address: String,
                                    _ distance: Int, _ x: Double, _ y: Double) -> Branch {
        Branch(id: id, cityID: city, name: name, address: address, phone: "95599", distanceMeters: distance,
               kind: .selfService, hours: .allDaySelfService, businesses: [], mapX: x, mapY: y)
    }

    static let branches: [Branch] = [
        // 西安
        full("xa-fengdong", "xian", "西安沣东新城支行", "陕西省西安市沣东新城大明宫·沣东一路88号", "029-8001-2201",
             2552, .weekdayAndWeekend, allBusinesses, 0.32, 0.46),
        full("xa-xingqing", "xian", "西安兴庆路支行营业室", "陕西省西安市碑林区兴庆路模拟大厦1层", "029-8001-2202",
             3870, .weekdayWithLunchWeekendClosed, noCoin, 0.70, 0.38),
        full("xa-gaoxin", "xian", "西安高新科技路支行", "陕西省西安市雁塔区科技路示例广场A座", "029-8001-2203",
             5120, .everyDayLong, allBusinesses, 0.55, 0.72),
        selfService("xa-self-dongguan", "xian", "西安东关正街自助银行", "陕西省西安市碑林区东关正街示例街区12号",
                    6230, 0.82, 0.18),
        // 北京
        full("bj-chaoyang", "beijing", "北京朝阳门支行", "北京市朝阳区朝阳门外大街示例中心1层", "010-6001-3301",
             1280, .everyDayLong, allBusinesses, 0.62, 0.40),
        full("bj-haidian", "beijing", "北京海淀黄庄支行", "北京市海淀区中关村大街模拟大厦2层", "010-6001-3302",
             2960, .weekdayWithLunchWeekendClosed, personalOnly, 0.22, 0.30),
        full("bj-xicheng", "beijing", "北京金融街支行", "北京市西城区金融大街示例楼1层", "010-6001-3303",
             4410, .weekdayAndWeekend, noCoin, 0.38, 0.58),
        selfService("bj-self-wangjing", "beijing", "北京望京自助银行", "北京市朝阳区望京街示例商场B1层",
                    7050, 0.80, 0.15),
        // 上海
        full("sh-lujiazui", "shanghai", "上海陆家嘴支行", "上海市浦东新区陆家嘴环路示例大厦1层", "021-5001-4401",
             1850, .weekdayAndWeekend, allBusinesses, 0.68, 0.45),
        full("sh-xujiahui", "shanghai", "上海徐家汇支行", "上海市徐汇区漕溪北路模拟广场1层", "021-5001-4402",
             3340, .weekdayWithLunchWeekendClosed, noCoin, 0.30, 0.70),
        full("sh-jingan", "shanghai", "上海静安寺支行", "上海市静安区南京西路示例中心2层", "021-5001-4403",
             4780, .everyDayLong, personalOnly, 0.40, 0.32),
        selfService("sh-self-hongqiao", "shanghai", "上海虹桥自助银行", "上海市闵行区申长路示例枢纽B2层",
                    9120, 0.12, 0.55),
        // 广州
        full("gz-tianhe", "guangzhou", "广州天河路支行", "广东省广州市天河区天河路示例大厦1层", "020-3001-5501",
             2100, .everyDayLong, allBusinesses, 0.58, 0.42),
        full("gz-yuexiu", "guangzhou", "广州越秀北京路支行", "广东省广州市越秀区北京路模拟街区8号", "020-3001-5502",
             3650, .weekdayWithLunchWeekendClosed, noCoin, 0.30, 0.62),
        full("gz-pazhou", "guangzhou", "广州琶洲支行", "广东省广州市海珠区阅江路示例中心1层", "020-3001-5503",
             5880, .weekdayAndWeekend, personalOnly, 0.78, 0.74),
        // 成都
        full("cd-chunxi", "chengdu", "成都春熙路支行", "四川省成都市锦江区春熙路示例广场1层", "028-8601-6601",
             1640, .weekdayAndWeekend, allBusinesses, 0.50, 0.44),
        full("cd-tianfu", "chengdu", "成都天府新区支行", "四川省成都市天府新区天府大道示例大厦1层", "028-8601-6602",
             4320, .weekdayWithLunchWeekendClosed, noCoin, 0.46, 0.80),
        full("cd-wuhou", "chengdu", "成都武侯祠支行", "四川省成都市武侯区武侯祠大街模拟街区3号", "028-8601-6603",
             2870, .everyDayLong, personalOnly, 0.24, 0.52),
        // 武汉
        full("wh-jianghan", "wuhan", "武汉江汉路支行", "湖北省武汉市江汉区江汉路示例大厦1层", "027-8501-7701",
             1930, .everyDayLong, allBusinesses, 0.40, 0.36),
        full("wh-guanggu", "wuhan", "武汉光谷支行", "湖北省武汉市洪山区珞喻路示例广场1层", "027-8501-7702",
             5260, .weekdayWithLunchWeekendClosed, noCoin, 0.78, 0.66),
        full("wh-wuchang", "wuhan", "武汉武昌中南路支行", "湖北省武汉市武昌区中南路模拟中心2层", "027-8501-7703",
             3480, .weekdayAndWeekend, personalOnly, 0.56, 0.58)
    ]

    static func city(id: String) -> BranchCity? {
        cities.first { $0.id == id }
    }

    /// 城市内网点，按距离由近到远。
    static func branches(inCity cityID: String) -> [Branch] {
        branches.filter { $0.cityID == cityID }.sorted { $0.distanceMeters < $1.distanceMeters }
    }

    static func branch(id: String) -> Branch? {
        branches.first { $0.id == id }
    }

    /// 城市默认网点（最近的网点）；未知城市回落到默认城市。
    static func defaultBranch(inCity cityID: String) -> Branch {
        branches(inCity: cityID).first ?? branches(inCity: defaultCityID)[0]
    }

    static func displayName(branchID: String) -> String {
        branch(id: branchID)?.name ?? "网点已停用"
    }
}
