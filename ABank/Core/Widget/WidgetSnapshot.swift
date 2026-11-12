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

    /// 快照月份不是当前月份时，“本月”收支视为 0，避免跨月后仍显示上月数字。
    func monthlyFlow(inMonth currentMonth: String) -> (income: Int64, expense: Int64) {
        month == currentMonth ? (monthIncomeInCents, monthExpenseInCents) : (0, 0)
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

    func clear() { defaults?.removeObject(forKey: WidgetSnapshot.storageKey) }

    func load() -> WidgetSnapshot? {
        WidgetSnapshot.decode(defaults?.data(forKey: WidgetSnapshot.storageKey))
    }
}

/// 写入去重：快照为 nil 不写；与上次内容相同（忽略更新时间）不写、不刷新。
struct WidgetSnapshotSync {
    private let store: WidgetSnapshotStore
    private let reload: () -> Void
    private var last: WidgetSnapshot?

    init(store: WidgetSnapshotStore, reload: @escaping () -> Void) {
        self.store = store
        self.reload = reload
        self.last = store.load()
    }

    mutating func clear() {
        guard last != nil else { return }
        store.clear(); last = nil; reload()
    }

    mutating func sync(_ snapshot: WidgetSnapshot?) {
        guard let snapshot, !Self.sameContent(snapshot, last) else { return }
        store.save(snapshot)
        last = snapshot
        reload()
    }

    private static func sameContent(_ a: WidgetSnapshot, _ b: WidgetSnapshot?) -> Bool {
        guard let b else { return false }
        return a.balanceInCents == b.balanceInCents && a.monthIncomeInCents == b.monthIncomeInCents
            && a.monthExpenseInCents == b.monthExpenseInCents && a.month == b.month
    }
}
