//
//  SecuritySettingsStore.swift
//  ABank
//
//  安全设置的本地持久化。只有写入成功才更新内存并发通知；数据无法解码时使用默认值，
//  原数据保留到下一次成功保存。
//

import Foundation

nonisolated enum SecuritySettingsError: LocalizedError, Equatable {
    case persistence, deviceNotRemovable, deviceNotFound

    var errorDescription: String? {
        switch self {
        case .persistence: return "保存失败，请稍后重试"
        case .deviceNotRemovable: return "当前使用的设备不可移除"
        case .deviceNotFound: return "设备不存在或已移除"
        }
    }
}

final class SecuritySettingsStore {
    static let shared = SecuritySettingsStore()
    static let storageKey = "abank.securitySettings.v1"
    static let didChangeNotification = Notification.Name("ABank.securitySettingsDidChange")
    static let smallPaymentQuotas: [Int64] = [20_000, 50_000, 100_000]

    private let defaults: UserDefaults
    private let notificationCenter: NotificationCenter
    private let dates: BankingDateContext
    private let dataWriter: ((Data) throws -> Void)?
    private(set) var settings: SecuritySettings

    init(defaults: UserDefaults = .standard,
         notificationCenter: NotificationCenter = .default,
         dates: BankingDateContext = .system,
         dataWriter: ((Data) throws -> Void)? = nil) {
        self.defaults = defaults
        self.notificationCenter = notificationCenter
        self.dates = dates
        self.dataWriter = dataWriter
        if let data = defaults.data(forKey: Self.storageKey),
           let stored = try? JSONDecoder().decode(SecuritySettings.self, from: data) {
            settings = stored
        } else {
            settings = .default
        }
    }

    // MARK: - 读取

    var transferLimits: TransferLimits { settings.transferLimits }
    var hidesAmounts: Bool { settings.hidesAmounts }

    var devices: [LoginDevice] {
        let removed = Set(settings.removedDeviceIDs)
        return LoginDevice.seed(dates: dates).filter { !removed.contains($0.id) }
    }

    func device(id: String) -> LoginDevice? {
        devices.first { $0.id == id }
    }

    /// 安全中心顶部“已开启 N 项保护”。
    var enabledProtectionCount: Int {
        let defaults = SecuritySettings.default
        let limitsLowered = settings.perTransferLimitInCents < defaults.perTransferLimitInCents
            || settings.dailyLimitInCents < defaults.dailyLimitInCents
        return [settings.faceIDLoginEnabled, settings.gestureLoginEnabled, settings.hidesAmounts, limitsLowered]
            .filter { $0 }.count
    }

    // MARK: - 修改

    func setTransferLimits(perTransfer: Int64, daily: Int64) throws {
        try TransferLimitRules.validate(perTransfer: perTransfer, daily: daily)
        var updated = settings
        updated.perTransferLimitInCents = perTransfer
        updated.dailyLimitInCents = daily
        guard commit(updated) else { throw SecuritySettingsError.persistence }
    }

    @discardableResult
    func setHidesAmounts(_ hides: Bool) -> Bool {
        update { $0.hidesAmounts = hides }
    }

    @discardableResult
    func setFaceIDLogin(_ enabled: Bool) -> Bool {
        update { $0.faceIDLoginEnabled = enabled }
    }

    @discardableResult
    func setGestureLogin(_ enabled: Bool) -> Bool {
        update { $0.gestureLoginEnabled = enabled }
    }

    @discardableResult
    func setSmallPayment(enabled: Bool, quotaInCents: Int64) -> Bool {
        guard Self.smallPaymentQuotas.contains(quotaInCents) else { return false }
        return update {
            $0.smallPaymentWithoutPasswordEnabled = enabled
            $0.smallPaymentQuotaInCents = quotaInCents
        }
    }

    func removeDevice(id: String) throws {
        guard let device = device(id: id) else { throw SecuritySettingsError.deviceNotFound }
        guard !device.isCurrent else { throw SecuritySettingsError.deviceNotRemovable }
        var updated = settings
        updated.removedDeviceIDs.append(id)
        guard commit(updated) else { throw SecuritySettingsError.persistence }
    }

    // MARK: - 持久化

    private func update(_ change: (inout SecuritySettings) -> Void) -> Bool {
        var updated = settings
        change(&updated)
        return commit(updated)
    }

    /// 值未变化时视为成功且不写入、不通知；写入失败时内存保持原值。
    private func commit(_ updated: SecuritySettings) -> Bool {
        guard updated != settings else { return true }
        do {
            let data = try JSONEncoder().encode(updated)
            if let dataWriter {
                try dataWriter(data)
            } else {
                defaults.set(data, forKey: Self.storageKey)
            }
        } catch {
            return false
        }
        settings = updated
        notificationCenter.post(name: Self.didChangeNotification, object: self)
        return true
    }
}
