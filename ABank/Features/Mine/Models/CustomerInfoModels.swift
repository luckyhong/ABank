//
//  CustomerInfoModels.swift
//  ABank
//

import Foundation

struct CustomerInfoRecord: Codable, Equatable {
    var name: String
    var gender: String
    var nationality: String
    var idType: String
    var idNumber: String
    var idValidFrom: String
    var idValidTo: String
    var mobile: String
    var email: String
    var landlineAreaCode: String
    var landlineNumber: String
    var province: String
    var city: String
    var district: String
    var detailAddress: String
    var postalCode: String
    var occupationLevel1: String
    var occupationLevel2: String
    var taxIdentity: String

    var regionDisplay: String {
        [province, city, district].filter { !$0.isEmpty }.joined(separator: "/")
    }

    var idValidityDisplay: String {
        "\(Self.maskDate(idValidFrom))-\(Self.maskDate(idValidTo))"
    }

    var maskedName: String { Self.maskName(name) }
    var maskedIdNumber: String { Self.maskIdNumber(idNumber) }
    var maskedMobile: String { Self.maskMobile(mobile) }

    static func maskName(_ value: String) -> String {
        guard value.count >= 2 else { return value.isEmpty ? "" : "*" }
        return "*" + String(value.suffix(value.count - 1))
    }

    static func maskIdNumber(_ value: String) -> String {
        guard value.count >= 8 else { return value }
        let prefix = String(value.prefix(6))
        let suffix = String(value.suffix(2))
        return prefix + String(repeating: "*", count: value.count - 8) + suffix
    }

    static func maskMobile(_ value: String) -> String {
        guard value.count >= 7 else { return value }
        let prefix = String(value.prefix(3))
        let suffix = String(value.suffix(3))
        return prefix + String(repeating: "*", count: value.count - 6) + suffix
    }

    static func maskDate(_ value: String) -> String {
        let parts = value.split(separator: "/").map(String.init)
        guard parts.count == 3 else { return value }
        return "\(parts[0])/**/\(parts[2])"
    }
}

struct RegionNode {
    let name: String
    let postalCode: String?
    let children: [RegionNode]
}

enum CustomerInfoCatalog {
    static let genders = ["男", "女"]

    static let occupations: [(String, [String])] = [
        ("专业技术人员", [
            "信息科技及工程技术人员",
            "卫生专业技术人员",
            "经济、金融专业人员",
            "法律专业人员",
            "教学人员",
            "文学艺术、体育专业人员"
        ]),
        ("国家机关、党群组织、企事业单位负责人", [
            "中国共产党机关负责人",
            "国家机关负责人",
            "民主党派和工商联负责人",
            "事业单位负责人",
            "企业负责人"
        ]),
        ("办事人员和有关人员", [
            "行政办公人员",
            "安全保卫和消防人员",
            "邮政和电信业务人员"
        ]),
        ("商业、服务业人员", [
            "购销人员",
            "仓储人员",
            "餐饮服务人员",
            "饭店、旅游及健身娱乐场所服务人员"
        ]),
        ("农、林、牧、渔、水利业生产人员", [
            "种植业生产人员",
            "林业生产及野生动植物保护人员",
            "畜牧业生产人员"
        ]),
        ("生产、运输设备操作人员及有关人员", [
            "机械制造加工人员",
            "运输设备操作人员",
            "电力设备安装运行检修人员"
        ]),
        ("学生", ["在校学生"]),
        ("军人", ["现役军人"]),
        ("无业", ["无固定职业"]),
        ("不便分类的其他从业人员", ["其他从业人员"])
    ]

    static func level2Options(for level1: String) -> [String] {
        occupations.first { $0.0 == level1 }?.1 ?? []
    }

    static let taxIdentities = [
        "仅为中国税收居民",
        "仅为非居民",
        "既是中国税收居民又是其他国家（地区）税收居民"
    ]

    static let regions: [RegionNode] = [
        RegionNode(name: "陕西省", postalCode: nil, children: [
            RegionNode(name: "西安市", postalCode: nil, children: [
                RegionNode(name: "灞桥区", postalCode: "710038", children: []),
                RegionNode(name: "雁塔区", postalCode: "710061", children: []),
                RegionNode(name: "未央区", postalCode: "710016", children: []),
                RegionNode(name: "碑林区", postalCode: "710001", children: []),
                RegionNode(name: "莲湖区", postalCode: "710003", children: [])
            ]),
            RegionNode(name: "延安市", postalCode: nil, children: [
                RegionNode(name: "宝塔区", postalCode: "716000", children: []),
                RegionNode(name: "安塞区", postalCode: "717400", children: []),
                RegionNode(name: "子长市", postalCode: "717300", children: []),
                RegionNode(name: "延川县", postalCode: "717200", children: [])
            ])
        ]),
        RegionNode(name: "北京市", postalCode: nil, children: [
            RegionNode(name: "北京市", postalCode: nil, children: [
                RegionNode(name: "朝阳区", postalCode: "100020", children: []),
                RegionNode(name: "海淀区", postalCode: "100080", children: []),
                RegionNode(name: "东城区", postalCode: "100010", children: [])
            ])
        ]),
        RegionNode(name: "上海市", postalCode: nil, children: [
            RegionNode(name: "上海市", postalCode: nil, children: [
                RegionNode(name: "浦东新区", postalCode: "200120", children: []),
                RegionNode(name: "徐汇区", postalCode: "200030", children: [])
            ])
        ]),
        RegionNode(name: "广东省", postalCode: nil, children: [
            RegionNode(name: "广州市", postalCode: nil, children: [
                RegionNode(name: "天河区", postalCode: "510630", children: []),
                RegionNode(name: "越秀区", postalCode: "510030", children: [])
            ]),
            RegionNode(name: "深圳市", postalCode: nil, children: [
                RegionNode(name: "南山区", postalCode: "518000", children: []),
                RegionNode(name: "福田区", postalCode: "518000", children: [])
            ])
        ])
    ]
}
