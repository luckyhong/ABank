//
//  CustomerInfoStore.swift
//  ABank
//

import Foundation

final class CustomerInfoStore {
    static let shared = CustomerInfoStore()

    private let defaultsKey = "abank.customerInfo.record"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    func load() -> CustomerInfoRecord {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let record = try? decoder.decode(CustomerInfoRecord.self, from: data) {
            return record
        }
        return Self.defaultRecord
    }

    func save(_ record: CustomerInfoRecord) {
        guard let data = try? encoder.encode(record) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    func update(_ transform: (inout CustomerInfoRecord) -> Void) {
        var record = load()
        transform(&record)
        save(record)
    }

    static let defaultRecord = CustomerInfoRecord(
        name: "韩继宏",
        gender: "男",
        nationality: "中国",
        idType: "居民身份证",
        idNumber: "610626198808081012",
        idValidFrom: "2018/08/08",
        idValidTo: "2038/08/08",
        mobile: "15288888684",
        email: "",
        landlineAreaCode: "",
        landlineNumber: "",
        province: "陕西省",
        city: "西安市",
        district: "灞桥区",
        detailAddress: "西铁浐灞生态苑住宅小区西区",
        postalCode: "717600",
        occupationLevel1: "专业技术人员",
        occupationLevel2: "信息科技及工程技术人员",
        taxIdentity: "仅为中国税收居民"
    )
}
