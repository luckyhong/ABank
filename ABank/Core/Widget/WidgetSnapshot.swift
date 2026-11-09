//
//  WidgetSnapshot.swift
//  ABank
//
//  模拟余额 Widget 的共享快照：App 写入 App Group，Widget 只读。
//  App 与 Widget 扩展共用本文件，只依赖 Foundation；快照不含卡号、姓名。
//

import Foundation

struct WidgetSnapshot: Codable, Equatable {
    var balanceInCents: Int64
    var monthIncomeInCents: Int64
    var monthExpenseInCents: Int64
    /// yyyy-MM
    var month: String
    /// yyyy-MM-dd HH:mm:ss 北京时间
    var updatedAt: String

    static let groupID = "group.com.axdxa.AtlasBarKit.ABank"
    static let storageKey = "abank.widget.snapshot.v1"

    /// nil、空数据或损坏数据都返回 nil。
    static func decode(_ data: Data?) -> WidgetSnapshot? {
        guard let data, !data.isEmpty else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func encoded() -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return (try? encoder.encode(self)) ?? Data()
    }
}

struct WidgetSnapshotStore {
    private let defaults: UserDefaults?

    init(defaults: UserDefaults? = UserDefaults(suiteName: WidgetSnapshot.groupID)) {
        self.defaults = defaults
    }

    func save(_ snapshot: WidgetSnapshot) {
        defaults?.set(snapshot.encoded(), forKey: WidgetSnapshot.storageKey)
    }

    func load() -> WidgetSnapshot? {
        WidgetSnapshot.decode(defaults?.data(forKey: WidgetSnapshot.storageKey))
    }
}
