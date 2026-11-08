import Foundation

@main struct AccountSettingsChecks {
    @MainActor static func main() throws {
        try legacyDecode()
        try aliasRules()
        cardLabel()
        try storeRoundTrip()
        writeFailure()
        holderName()
        print("Account settings checks passed")
    }

    struct WriteFailure: Error {}

    static let accountID = FinanceLedgerRecord.defaultAccountId

    @MainActor static func withSuite(_ body: (UserDefaults) throws -> Void) rethrows {
        let suite = "ABank.AccountSettingsChecks." + UUID().uuidString
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

    static func legacyDecode() throws {
        let json = #"{"id":"acct_8472","tailNumber":"8472","currency":"人民币","balance":100,"openingBalance":100}"#
        let account = try JSONDecoder().decode(LedgerAccount.self, from: Data(json.utf8))
        precondition(account.alias == nil)
        precondition(account.permissions == .allEnabled)
        precondition(account.balance == 100 && account.openingBalance == 100)
        let encoded = try JSONEncoder().encode(account)
        let again = try JSONDecoder().decode(LedgerAccount.self, from: encoded)
        precondition(again == account)
    }

    static func aliasRules() throws {
        precondition(AccountAliasRules.maxLength == 10)
        let n = AccountAliasRules.normalized
        let trimmed = try n("  工资卡 "), blank = try n("   "), empty = try n("")
        let ten = try n(String(repeating: "字", count: 10)), emoji = try n(String(repeating: "😀", count: 10))
        precondition(trimmed == "工资卡" && blank == nil && empty == nil)
        precondition(ten == String(repeating: "字", count: 10))
        precondition(emoji == String(repeating: "😀", count: 10))
        expect(AccountSettingsError.aliasTooLong, { _ = try AccountAliasRules.normalized(String(repeating: "字", count: 11)) }, "11 chars")
        expect(AccountSettingsError.aliasInvalidCharacter, { _ = try AccountAliasRules.normalized("工资\n卡") }, "newline")
        precondition(AccountSettingsError.aliasTooLong.localizedDescription == "别名最多 10 个字")
        precondition(AccountSettingsError.aliasInvalidCharacter.localizedDescription == "别名不能包含换行")
        precondition(AccountSettingsError.accountNotFound.localizedDescription == "账户不存在或暂不可用")
        precondition(AccountSettingsError.persistence.localizedDescription == "本地保存失败，请重试")
    }

    static func cardLabel() {
        var account = LedgerAccount(id: "a", tailNumber: "8472", currency: "人民币", balance: 1, openingBalance: 1)
        precondition(account.cardLabel == "借记卡8472", account.cardLabel)
        account.alias = "工资卡"
        precondition(account.cardLabel == "工资卡（8472）", account.cardLabel)
    }

    @MainActor static func storeRoundTrip() throws {
        try withSuite { defaults in
            let store = FinanceLedgerStore(defaults: defaults)
            try store.setAlias("工资卡", accountID: accountID)
            precondition(FinanceLedgerStore(defaults: defaults).account(id: accountID)?.alias == "工资卡")
            try store.setAlias("", accountID: accountID)
            precondition(FinanceLedgerStore(defaults: defaults).account(id: accountID)?.alias == nil)
            try store.setPermissions(AccountPermissions(mobileTransfer: false, onlinePayment: true), accountID: accountID)
            let read = FinanceLedgerStore(defaults: defaults).account(id: accountID)?.permissions
            precondition(read == AccountPermissions(mobileTransfer: false, onlinePayment: true))
            expect(AccountSettingsError.accountNotFound, { try store.setAlias("x", accountID: "missing") }, "missing alias")
            expect(AccountSettingsError.accountNotFound, { try store.setPermissions(.allEnabled, accountID: "missing") }, "missing perms")
            expect(AccountSettingsError.aliasTooLong, { try store.setAlias(String(repeating: "字", count: 11), accountID: accountID) }, "store long")
        }
    }

    @MainActor static func writeFailure() {
        withSuite { defaults in
            let seed = FinanceLedgerStore(defaults: defaults)
            try! seed.setAlias("旧名", accountID: accountID)
            let failing = FinanceLedgerStore(defaults: defaults, dataWriter: { _ in throw WriteFailure() })
            expect(AccountSettingsError.persistence, { try failing.setAlias("新名", accountID: accountID) }, "alias write")
            expect(AccountSettingsError.persistence, {
                try failing.setPermissions(AccountPermissions(mobileTransfer: false, onlinePayment: false), accountID: accountID)
            }, "perms write")
            let account = FinanceLedgerStore(defaults: defaults).account(id: accountID)
            precondition(account?.alias == "旧名")
            precondition(account?.permissions == .allEnabled)
        }
    }

    static func holderName() {
        precondition(AccountHolderName.masked("韩继宏") == "韩*宏")
        precondition(AccountHolderName.masked("张三") == "张*")
        precondition(AccountHolderName.masked("欧阳明月") == "欧**月")
        precondition(AccountHolderName.masked("李") == "李")
    }
}
