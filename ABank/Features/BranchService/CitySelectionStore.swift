//
//  CitySelectionStore.swift
//  ABank
//
//  全局当前城市：生活 Tab、网点列表、首页与“我的”网点卡共用。
//  只有写入成功才更新内存并发通知；数据无法识别时回到默认城市。
//

import Foundation

final class CitySelectionStore {
    static let shared = CitySelectionStore()
    static let storageKey = "abank.selectedCity.v1"
    static let didChangeNotification = Notification.Name("ABank.selectedCityDidChange")

    private let defaults: UserDefaults
    private let notificationCenter: NotificationCenter
    private let dataWriter: ((Data) throws -> Void)?
    private(set) var currentCity: BranchCity

    init(defaults: UserDefaults = .standard,
         notificationCenter: NotificationCenter = .default,
         dataWriter: ((Data) throws -> Void)? = nil) {
        self.defaults = defaults
        self.notificationCenter = notificationCenter
        self.dataWriter = dataWriter
        let storedID = defaults.data(forKey: Self.storageKey).flatMap { String(data: $0, encoding: .utf8) }
        currentCity = storedID.flatMap(BranchCatalog.city(id:))
            ?? BranchCatalog.city(id: BranchCatalog.defaultCityID)!
    }

    /// 未知城市返回 false；选择当前城市视为成功且不通知；写入失败返回 false 且保持原城市。
    @discardableResult
    func select(cityID: String) -> Bool {
        guard let city = BranchCatalog.city(id: cityID) else { return false }
        guard city != currentCity else { return true }
        let data = Data(city.id.utf8)
        do {
            if let dataWriter {
                try dataWriter(data)
            } else {
                defaults.set(data, forKey: Self.storageKey)
            }
        } catch {
            return false
        }
        currentCity = city
        notificationCenter.post(name: Self.didChangeNotification, object: self)
        return true
    }
}
