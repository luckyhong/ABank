//
//  PaymentCatalog.swift
//  ABank
//
//  充值缴费静态目录：面额档位、预置模拟户号与运营商号段。
//

import Foundation

nonisolated enum PaymentCatalog {
    static let denominationsInCents: [Int64] = [1_000, 2_000, 3_000, 5_000, 10_000, 20_000]

    static let billAccounts: [BillAccount] = [
        BillAccount(id: "bill.water.home", kind: .water, name: "家庭住宅", accountNo: "0301 2288 6401",
                    address: "西安市碑林区幸福路 8 号 1 栋 1201", provider: "自来水公司"),
        BillAccount(id: "bill.water.parents", kind: .water, name: "父母住宅", accountNo: "0301 5567 1023",
                    address: "西安市碑林区安居路 26 号 3 栋 402", provider: "自来水公司"),
        BillAccount(id: "bill.electric.home", kind: .electric, name: "家庭住宅", accountNo: "8802 1094 7735",
                    address: "西安市碑林区幸福路 8 号 1 栋 1201", provider: "供电公司"),
        BillAccount(id: "bill.electric.office", kind: .electric, name: "工作室", accountNo: "8802 3351 0286",
                    address: "西安市高新区科技路 18 号 5 层", provider: "供电公司"),
        BillAccount(id: "bill.gas.home", kind: .gas, name: "家庭住宅", accountNo: "6609 4417 2058",
                    address: "西安市碑林区幸福路 8 号 1 栋 1201", provider: "燃气公司"),
        BillAccount(id: "bill.gas.parents", kind: .gas, name: "父母住宅", accountNo: "6609 7782 1304",
                    address: "西安市碑林区安居路 26 号 3 栋 402", provider: "燃气公司")
    ]

    static func billAccount(id: String) -> BillAccount? {
        billAccounts.first { $0.id == id }
    }

    static func billAccounts(of kind: PaymentKind) -> [BillAccount] {
        billAccounts.filter { $0.kind == kind }
    }

    private static let mobilePrefixes: Set<String> = [
        "134", "135", "136", "137", "138", "139", "147", "150", "151", "152", "157", "158", "159",
        "172", "178", "182", "183", "184", "187", "188", "195", "197", "198"
    ]
    private static let unicomPrefixes: Set<String> = [
        "130", "131", "132", "145", "155", "156", "166", "175", "176", "185", "186", "196"
    ]
    private static let telecomPrefixes: Set<String> = [
        "133", "149", "153", "173", "177", "180", "181", "189", "191", "199"
    ]

    /// `prefix` 为手机号前 3 位；仅用于界面展示。
    static func phoneOperator(prefix: String) -> PhoneOperator {
        if mobilePrefixes.contains(prefix) { return .mobile }
        if unicomPrefixes.contains(prefix) { return .unicom }
        if telecomPrefixes.contains(prefix) { return .telecom }
        return .other
    }
}
