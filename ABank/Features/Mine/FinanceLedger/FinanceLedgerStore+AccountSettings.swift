//
//  FinanceLedgerStore+AccountSettings.swift
//  ABank
//
//  借记卡别名与交易权限的读写：严格读取账本，修改后整份写回，失败不改变任何数据。
//

import Foundation

extension FinanceLedgerStore {
    func account(id: String) -> LedgerAccount? {
        load().accounts.first { $0.id == id }
    }

    func setAlias(_ raw: String, accountID: String) throws {
        let alias = try AccountAliasRules.normalized(raw)
        try modifyAccount(id: accountID) { $0.alias = alias }
    }

    func setPermissions(_ permissions: AccountPermissions, accountID: String) throws {
        try modifyAccount(id: accountID) { $0.permissions = permissions }
    }

    private func modifyAccount(id: String, _ change: (inout LedgerAccount) -> Void) throws {
        var root: FinanceLedgerRecord
        do { root = try loadForTransfer() } catch { throw AccountSettingsError.persistence }
        guard let index = root.accounts.firstIndex(where: { $0.id == id }) else { throw AccountSettingsError.accountNotFound }
        change(&root.accounts[index])
        do { try persist(root) } catch { throw AccountSettingsError.persistence }
    }
}
