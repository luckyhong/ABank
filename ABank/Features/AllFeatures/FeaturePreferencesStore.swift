//
//  FeaturePreferencesStore.swift
//  ABank
//
//  常用功能与最近使用的本地持久化，只保存功能 ID。
//

import Foundation

final class FeaturePreferencesStore {
    static let shared = FeaturePreferencesStore()
    static let didChangeNotification = Notification.Name("ABank.featurePreferencesDidChange")
    static let storageKey = "abank.featurePreferences.v1"
    static let maxFavorites = 9
    static let maxRecents = 8

    private struct Stored: Codable {
        var favorites: [String]
        var recents: [String]
    }

    private let defaults: UserDefaults
    private let notificationCenter: NotificationCenter
    private(set) var favorites: [FeatureID]
    private(set) var recents: [FeatureID]

    init(defaults: UserDefaults = .standard, notificationCenter: NotificationCenter = .default) {
        self.defaults = defaults
        self.notificationCenter = notificationCenter
        if let data = defaults.data(forKey: Self.storageKey),
           let stored = try? JSONDecoder().decode(Stored.self, from: data) {
            favorites = Self.sanitize(stored.favorites.compactMap(FeatureID.init(rawValue:)), limit: Self.maxFavorites)
            recents = Self.sanitize(stored.recents.compactMap(FeatureID.init(rawValue:)), limit: Self.maxRecents)
        } else {
            favorites = FeatureCatalog.defaultFavorites
            recents = []
        }
    }

    /// 去重保序并截断到上限后保存；返回实际保存的常用列表。
    @discardableResult
    func setFavorites(_ ids: [FeatureID]) -> [FeatureID] {
        let sanitized = Self.sanitize(ids, limit: Self.maxFavorites)
        if persist(favorites: sanitized, recents: recents) {
            favorites = sanitized
            notifyChange()
        }
        return favorites
    }

    /// 记录一次已完成功能的使用；待上线功能不记录。
    func recordUse(_ id: FeatureID) {
        guard FeatureCatalog.descriptor(id).isAvailable else { return }
        let updated = Self.sanitize([id] + recents.filter { $0 != id }, limit: Self.maxRecents)
        if persist(favorites: favorites, recents: updated) {
            recents = updated
            notifyChange()
        }
    }

    private func persist(favorites: [FeatureID], recents: [FeatureID]) -> Bool {
        let stored = Stored(favorites: favorites.map(\.rawValue), recents: recents.map(\.rawValue))
        guard let data = try? JSONEncoder().encode(stored) else { return false }
        defaults.set(data, forKey: Self.storageKey)
        return true
    }

    private func notifyChange() {
        notificationCenter.post(name: Self.didChangeNotification, object: self)
    }

    private static func sanitize(_ ids: [FeatureID], limit: Int) -> [FeatureID] {
        var seen = Set<FeatureID>()
        return Array(ids.filter { seen.insert($0).inserted }.prefix(limit))
    }
}

/// 编辑常用页的草稿：点击“完成”前不写入 Store。
struct FavoritesDraft: Equatable {
    enum AddResult: Equatable { case added, duplicate, full }

    private(set) var ids: [FeatureID]

    init(ids: [FeatureID]) {
        var seen = Set<FeatureID>()
        self.ids = Array(ids.filter { seen.insert($0).inserted }.prefix(FeaturePreferencesStore.maxFavorites))
    }

    mutating func add(_ id: FeatureID) -> AddResult {
        if ids.contains(id) { return .duplicate }
        guard ids.count < FeaturePreferencesStore.maxFavorites else { return .full }
        ids.append(id)
        return .added
    }

    mutating func remove(_ id: FeatureID) {
        ids.removeAll { $0 == id }
    }

    /// 越界下标夹取到有效范围；源下标无效时忽略。
    mutating func move(from source: Int, to destination: Int) {
        guard ids.indices.contains(source) else { return }
        let id = ids.remove(at: source)
        ids.insert(id, at: min(max(destination, 0), ids.count))
    }
}
