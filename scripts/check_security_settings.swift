import Foundation

@main struct SecuritySettingsChecks {
    @MainActor static func main() throws {
        defaults()
        try limitRules()
        try roundTrip()
        corruptAndMissingFields()
        writeFailure()
        devicesRules()
        try notifications()
        smallPayment()
        try ledgerUsesLiveLimits()
        print("Security settings checks passed")
    }

    struct WriteFailure: Error {}

    @MainActor static func withSuite(_ body: (UserDefaults) throws -> Void) rethrows {
        let suite = "ABank.SecurityChecks." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        try body(defaults)
    }

    static func expect<E: Error & Equatable>(_ expected: E, _ body: () throws -> Void, _ label: String) {
        do {
            try body()
            preconditionFailure("\(label): expected \(expected), got success")
        } catch let error as E {
            precondition(error == expected, "\(label): expected \(expected), got \(error)")
        } catch {
            preconditionFailure("\(label): unexpected \(error)")
        }
    }

    @MainActor static func defaults() {
        precondition(SecuritySettingsStore.storageKey == "abank.securitySettings.v1")
        withSuite { defaults in
            let store = SecuritySettingsStore(defaults: defaults)
            precondition(store.transferLimits.perTransferInCents == 5_000_000)
            precondition(store.transferLimits.dailyInCents == 20_000_000)
            precondition(!store.hidesAmounts)
            precondition(store.settings.faceIDLoginEnabled && !store.settings.gestureLoginEnabled)
            precondition(!store.settings.smallPaymentWithoutPasswordEnabled && store.settings.smallPaymentQuotaInCents == 50_000)
            precondition(store.devices.map(\.id) == ["current-iphone", "ipad-air", "iphone-12"], "\(store.devices.map(\.id))")
            precondition(store.devices.filter(\.isCurrent).map(\.id) == ["current-iphone"])
            precondition(store.enabledProtectionCount == 1, "\(store.enabledProtectionCount)")
        }
    }

    @MainActor static func limitRules() throws {
        try TransferLimitRules.validate(perTransfer: 100, daily: 100)
        try TransferLimitRules.validate(perTransfer: 50_000_000, daily: 100_000_000)
        expect(TransferLimitError.perTransferOutOfRange, { try TransferLimitRules.validate(perTransfer: 99, daily: 1000) }, "single low")
        expect(TransferLimitError.perTransferOutOfRange, { try TransferLimitRules.validate(perTransfer: 50_000_001, daily: 100_000_000) }, "single high")
        expect(TransferLimitError.dailyOutOfRange, { try TransferLimitRules.validate(perTransfer: 100, daily: 100_000_001) }, "daily high")
        expect(TransferLimitError.dailyOutOfRange, { try TransferLimitRules.validate(perTransfer: 100, daily: 99) }, "daily low")
        expect(TransferLimitError.perTransferAboveDaily, { try TransferLimitRules.validate(perTransfer: 2000, daily: 1000) }, "above daily")
        for bad in ["1.234", "0", "abc", "", "-5"] {
            expect(TransferLimitError.invalidAmount, { _ = try TransferLimitRules.parse(bad) }, "parse \(bad)")
        }
        let half = try TransferLimitRules.parse("0.5")
        let fiftyThousand = try TransferLimitRules.parse("50000")
        precondition(half == 50 && fiftyThousand == 5_000_000)
        precondition(TransferLimitError.perTransferOutOfRange.errorDescription == "单笔限额需在 1 元至 50 万元之间")
        precondition(TransferLimitError.dailyOutOfRange.errorDescription == "日累计限额需在 1 元至 100 万元之间")
        precondition(TransferLimitError.perTransferAboveDaily.errorDescription == "单笔限额不能高于日累计限额")
        precondition(TransferLimitError.invalidAmount.errorDescription == "请输入正确金额")
    }

    @MainActor static func roundTrip() throws {
        try withSuite { defaults in
            let store = SecuritySettingsStore(defaults: defaults)
            try store.setTransferLimits(perTransfer: 1_000_000, daily: 3_000_000)
            precondition(store.setHidesAmounts(true))
            precondition(store.setGestureLogin(true))
            try store.removeDevice(id: "ipad-air")
            let reloaded = SecuritySettingsStore(defaults: defaults)
            precondition(reloaded.settings == store.settings)
            precondition(reloaded.transferLimits.perTransferInCents == 1_000_000 && reloaded.transferLimits.dailyInCents == 3_000_000)
            precondition(reloaded.hidesAmounts && reloaded.devices.count == 2)
            // faceID + gesture + hidesAmounts + lowered limits
            precondition(reloaded.enabledProtectionCount == 4, "\(reloaded.enabledProtectionCount)")
        }
    }

    @MainActor static func corruptAndMissingFields() {
        withSuite { defaults in
            let corrupt = Data("{".utf8)
            defaults.set(corrupt, forKey: SecuritySettingsStore.storageKey)
            let store = SecuritySettingsStore(defaults: defaults)
            precondition(store.settings == .default)
            precondition(defaults.data(forKey: SecuritySettingsStore.storageKey) == corrupt)
        }
        withSuite { defaults in
            defaults.set(Data(#"{"hidesAmounts":true}"#.utf8), forKey: SecuritySettingsStore.storageKey)
            let store = SecuritySettingsStore(defaults: defaults)
            precondition(store.hidesAmounts)
            var expected = SecuritySettings.default
            expected.hidesAmounts = true
            precondition(store.settings == expected)
        }
    }

    @MainActor static func writeFailure() {
        withSuite { defaults in
            let center = NotificationCenter()
            var count = 0
            let token = center.addObserver(forName: SecuritySettingsStore.didChangeNotification, object: nil, queue: nil) { _ in count += 1 }
            defer { center.removeObserver(token) }
            let store = SecuritySettingsStore(defaults: defaults, notificationCenter: center, dataWriter: { _ in throw WriteFailure() })
            precondition(store.setHidesAmounts(true) == false)
            precondition(!store.hidesAmounts)
            expect(SecuritySettingsError.persistence, { try store.setTransferLimits(perTransfer: 100, daily: 100) }, "write failure limits")
            precondition(store.transferLimits.perTransferInCents == 5_000_000)
            expect(SecuritySettingsError.persistence, { try store.removeDevice(id: "ipad-air") }, "write failure device")
            precondition(store.devices.count == 3)
            precondition(count == 0)
        }
    }

    @MainActor static func devicesRules() {
        withSuite { defaults in
            let store = SecuritySettingsStore(defaults: defaults)
            expect(SecuritySettingsError.deviceNotRemovable, { try store.removeDevice(id: "current-iphone") }, "remove current")
            expect(SecuritySettingsError.deviceNotFound, { try store.removeDevice(id: "nope") }, "remove missing")
            precondition(store.device(id: "ipad-air") != nil)
            try? store.removeDevice(id: "ipad-air")
            precondition(store.device(id: "ipad-air") == nil)
            expect(SecuritySettingsError.deviceNotFound, { try store.removeDevice(id: "ipad-air") }, "remove twice")
        }
    }

    @MainActor static func notifications() throws {
        try withSuite { defaults in
            let center = NotificationCenter()
            var count = 0
            let token = center.addObserver(forName: SecuritySettingsStore.didChangeNotification, object: nil, queue: nil) { _ in count += 1 }
            defer { center.removeObserver(token) }
            let store = SecuritySettingsStore(defaults: defaults, notificationCenter: center)
            precondition(store.setHidesAmounts(true) && count == 1)
            precondition(store.setHidesAmounts(true) && count == 1)
            try store.setTransferLimits(perTransfer: 5_000_000, daily: 20_000_000)
            precondition(count == 1, "unchanged limits must not notify")
            expect(TransferLimitError.perTransferAboveDaily, { try store.setTransferLimits(perTransfer: 300, daily: 200) }, "invalid limits")
            precondition(count == 1)
        }
    }

    @MainActor static func smallPayment() {
        withSuite { defaults in
            let store = SecuritySettingsStore(defaults: defaults)
            precondition(store.setSmallPayment(enabled: true, quotaInCents: 30_000) == false)
            precondition(!store.settings.smallPaymentWithoutPasswordEnabled)
            precondition(store.setSmallPayment(enabled: true, quotaInCents: 100_000))
            precondition(store.settings.smallPaymentWithoutPasswordEnabled && store.settings.smallPaymentQuotaInCents == 100_000)
            precondition(SecuritySettingsStore.smallPaymentQuotas == [20_000, 50_000, 100_000])
        }
    }

    @MainActor static func ledgerUsesLiveLimits() throws {
        try withSuite { defaults in
            let now = ISO8601DateFormatter().date(from: "2026-10-16T04:00:00Z")!
            let dates = BankingDateContext(now: { now })
            let security = SecuritySettingsStore(defaults: defaults, dates: dates)
            let ledger = FinanceLedgerStore(defaults: defaults, dates: dates, transferLimitsProvider: { security.transferLimits })
            let account = LedgerAccount(id: "acct_8472", tailNumber: "8472", currency: "人民币", balance: 300_000, openingBalance: 300_000)
            let fixture = FinanceLedgerRecord(accounts: [account], transactions: [], loanContracts: [],
                                              assetLiabilityAnnouncement: "演示", dataTimestamp: "2026-10-15 12:00:00")
            precondition(ledger.save(fixture))
            let draft = TransferDraft(payerAccountID: account.id, method: .account, recipientName: "演示客户",
                                      bankName: "中国建设银行", destination: "6217000000000593", amountInCents: 100_000, note: "")
            @MainActor func expectTransfer(_ error: TransferError, _ label: String) {
                expect(error, { try ledger.validateTransfer(draft) }, label)
            }
            try ledger.validateTransfer(draft)
            precondition(ledger.transferLimits.perTransferInCents == 5_000_000)

            try security.setTransferLimits(perTransfer: 50_000, daily: 20_000_000)
            precondition(ledger.transferLimits.perTransferInCents == 50_000)
            expectTransfer(.singleLimit, "lowered single limit")

            try security.setTransferLimits(perTransfer: 5_000_000, daily: 20_000_000)
            precondition(ledger.transferredTodayInCents() == 0)
            _ = try ledger.submitTransfer(draft: draft, requestID: "live-limit-1")
            precondition(ledger.transferredTodayInCents() == 100_000, "\(ledger.transferredTodayInCents())")

            // 日累计低于今日已转仍可保存，此后今日转账被拦截。
            try security.setTransferLimits(perTransfer: 100, daily: 100)
            expectTransfer(.singleLimit, "below spent single")
            try security.setTransferLimits(perTransfer: 100_000, daily: 150_000)
            expectTransfer(.dailyLimit, "daily exhausted")

            try security.setTransferLimits(perTransfer: 5_000_000, daily: 20_000_000)
            try ledger.validateTransfer(draft)
        }
    }
}
