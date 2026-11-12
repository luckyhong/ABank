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

    @discardableResult
    func openElectronicAccount() throws -> LedgerAccount {
        var root = try loadForTransfer()
        // One electronic account per local customer; repeated taps return the same account.
        if let account = root.accounts.first(where: { $0.id.hasPrefix("electronic_") }) { return account }
        let number = "623048" + (0..<10).map { _ in String(Int.random(in: 0...9)) }.joined()
        var account = LedgerAccount(id: "electronic_" + UUID().uuidString, tailNumber: String(number.suffix(4)),
            currency: "人民币", balance: 0, openingBalance: 0, alias: "电子账户", accountNumber: number,
            openedOn: dates.string(from: dates.now), branchName: "手机银行")
        account.kind = .electronic
        root.accounts.append(account)
        root.dataTimestamp = dates.string(from: dates.now, format: "yyyy-MM-dd HH:mm:ss")
        do { try persist(root) } catch { throw AccountSettingsError.persistence }
        return account
    }

    func setReportedLost(_ lost: Bool, accountID: String) throws {
        try modifyAccount(id: accountID) { $0.isReportedLost = lost }
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

extension LedgerAccount {
    var fullCardNumber: String? {
        accountNumber ?? (id == FinanceLedgerRecord.defaultAccountId ? "6230 4800 1234 8472" : nil)
    }
    var maskedCardNumber: String { fullCardNumber.map { String($0.filter { !$0.isWhitespace }.prefix(4)) + " **** " + tailNumber } ?? "**** **** " + tailNumber }
    var openingBranch: String { branchName ?? (id == FinanceLedgerRecord.defaultAccountId ? "农行西安东关正街支行" : "—") }
    var debitCard: MyAccountDebitCard {
        MyAccountDebitCard(accountClass: effectiveKind == .electronic ? "II类" : (id == FinanceLedgerRecord.defaultAccountId ? "I类" : "借记卡"),
            maskedNumber: maskedCardNumber, fullNumber: fullCardNumber ?? maskedCardNumber, availableBalance: balance,
            actions: [.init(title: "查询明细", badge: nil), .init(title: "我要转账", badge: nil), .init(title: "活钱理财", badge: "时时付")],
            accountId: id, alias: alias, statusText: isReportedLost ? "已挂失" : "正常", accountTypeTitle: effectiveKind.title)
    }
}
