import Foundation

@main struct AccountSettingsChecks {
    @MainActor static func main() throws {
        try legacyDecode()
        try aliasRules()
        cardLabel()
        try storeRoundTrip()
        writeFailure()
        holderName()
        try transferBlocked()
        try paymentBlocked()
        try permissionFirst()
        try idempotentReplayAfterDisable()
        try wealthUnaffected()
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

    // MARK: - 权限拦截

    static let now = ISO8601DateFormatter().date(from: "2026-11-06T02:00:00Z")!
    static let phone = "15288888684"

    final class RiskBox { var state = RiskAssessmentState.valid(.c2, expiresOn: "2027-11-05") }

    static func fixture(balance: Double) -> FinanceLedgerRecord {
        let account = LedgerAccount(id: accountID, tailNumber: "8472", currency: "人民币", balance: balance, openingBalance: balance)
        return FinanceLedgerRecord(accounts: [account], transactions: [], loanContracts: [],
                                   assetLiabilityAnnouncement: "演示", dataTimestamp: "2026-11-05 12:00:00")
    }

    @MainActor static func makeStores(_ defaults: UserDefaults, balance: Double = 5000) -> (FinanceLedgerStore, BenefitsStore) {
        let dates = BankingDateContext(now: { now })
        let benefits = BenefitsStore(defaults: defaults, notificationCenter: NotificationCenter(), dates: dates)
        let risk = RiskBox()
        let store = FinanceLedgerStore(defaults: defaults, dates: dates,
                                       transferLimitsProvider: { TransferLimits() },
                                       riskStateProvider: { risk.state }, benefitsProvider: { benefits })
        precondition(store.save(fixture(balance: balance)), "seed")
        return (store, benefits)
    }

    static func draft(_ cents: Int64 = 10_000) -> TransferDraft {
        TransferDraft(payerAccountID: accountID, method: .account, recipientName: "演示客户", bankName: "中国建设银行",
                      destination: "6217000000000593", amountInCents: cents, note: "")
    }

    struct Snapshot: Equatable {
        let balance: Double, transactions: Int, transfers: Int, orders: Int
        @MainActor init(_ store: FinanceLedgerStore) {
            let record = store.load()
            balance = record.accounts[0].balance
            transactions = record.transactions.count
            transfers = record.transferRecords.count
            orders = record.paymentOrders.count
        }
    }

    @MainActor static func disable(_ store: FinanceLedgerStore, transfer: Bool = false, payment: Bool = false) throws {
        try store.setPermissions(AccountPermissions(mobileTransfer: !transfer, onlinePayment: !payment), accountID: accountID)
    }

    @MainActor static func transferBlocked() throws {
        try withSuite { defaults in
            let (store, _) = makeStores(defaults)
            try disable(store, transfer: true)
            let before = Snapshot(store)
            expect(TransferError.transferPermissionDisabled, { try store.validateTransfer(draft()) }, "validate transfer")
            expect(TransferError.transferPermissionDisabled, { _ = try store.submitTransfer(draft: draft(), requestID: "r1") }, "submit transfer")
            precondition(Snapshot(store) == before, "transfer blocked leaves ledger unchanged")
            precondition(TransferError.transferPermissionDisabled.localizedDescription == "手机银行转账已关闭，请先在交易权限中开启")
            try store.setPermissions(.allEnabled, accountID: accountID)
            let record = try store.submitTransfer(draft: draft(), requestID: "r2")
            precondition(record.status == .succeeded)
        }
    }

    @MainActor static func paymentBlocked() throws {
        try withSuite { defaults in
            let (store, benefits) = makeStores(defaults)
            let couponID = try benefits.redeem(goodsID: "g.phone5").couponID
            try disable(store, payment: true)
            let before = Snapshot(store)
            let bill = "bill.water.home"
            expect(PaymentError.onlinePaymentDisabled, { _ = try store.validateMobileRecharge(phone: phone, faceInCents: 1000, couponID: couponID) }, "validate recharge")
            expect(PaymentError.onlinePaymentDisabled, { _ = try store.submitMobileRecharge(phone: phone, faceInCents: 1000, couponID: couponID, requestID: "p1") }, "submit recharge")
            expect(PaymentError.onlinePaymentDisabled, { try store.validateUtilityPayment(billAccountID: bill) }, "validate bill")
            expect(PaymentError.onlinePaymentDisabled, { _ = try store.submitUtilityPayment(billAccountID: bill, requestID: "p2") }, "submit bill")
            precondition(Snapshot(store) == before, "payment blocked leaves ledger unchanged")
            precondition(benefits.coupon(id: couponID).map(benefits.status) == .unused, "coupon untouched")
            precondition(PaymentError.onlinePaymentDisabled.localizedDescription == "网上支付已关闭，请先在交易权限中开启")
            try store.setPermissions(.allEnabled, accountID: accountID)
            try store.validateUtilityPayment(billAccountID: bill)
            _ = try store.submitUtilityPayment(billAccountID: bill, requestID: "p3")
            expect(PaymentError.alreadyPaid, { try store.validateUtilityPayment(billAccountID: bill) }, "validate paid bill")
        }
    }

    @MainActor static func permissionFirst() throws {
        try withSuite { defaults in
            let (store, _) = makeStores(defaults, balance: 0)
            try disable(store, transfer: true, payment: true)
            expect(TransferError.transferPermissionDisabled, { try store.validateTransfer(draft()) }, "transfer before balance")
            expect(PaymentError.onlinePaymentDisabled, { _ = try store.validateMobileRecharge(phone: phone, faceInCents: 1000, couponID: "nope") }, "recharge before coupon")
            expect(PaymentError.onlinePaymentDisabled, { _ = try store.submitUtilityPayment(billAccountID: "bill.water.home", requestID: "x",
                                                                                          expectedAmountInCents: 1) }, "bill before amount")
        }
    }

    @MainActor static func idempotentReplayAfterDisable() throws {
        try withSuite { defaults in
            let (store, _) = makeStores(defaults)
            let order = try store.submitMobileRecharge(phone: phone, faceInCents: 2000, couponID: nil, requestID: "same")
            let transfer = try store.submitTransfer(draft: draft(), requestID: "same-transfer")
            try disable(store, transfer: true, payment: true)
            let replayOrder = try store.submitMobileRecharge(phone: phone, faceInCents: 2000, couponID: nil, requestID: "same")
            let replayTransfer = try store.submitTransfer(draft: draft(), requestID: "same-transfer")
            precondition(replayOrder.id == order.id && replayTransfer.id == transfer.id, "idempotent replay")
        }
    }

    @MainActor static func wealthUnaffected() throws {
        try withSuite { defaults in
            let (store, _) = makeStores(defaults)
            try disable(store, transfer: true, payment: true)
            let order = try store.submitWealthPurchase(productID: "w.tiantianli2", amountInCents: 50_000, requestID: "w")
            precondition(order.principalInCents == 50_000)
        }
    }
}
