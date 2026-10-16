import Foundation

@main struct TransferDataChecks {
    @MainActor static func main() async throws {
        let suite = "ABank.TransferChecks." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var now = ISO8601DateFormatter().date(from: "2026-10-16T04:00:00Z")!
        let dates = BankingDateContext(now: { now })
        let store = FinanceLedgerStore(defaults: defaults, dates: dates)
        let key = "abank.financeLedger.record.v8"
        let account = LedgerAccount(id: "acct_8472", tailNumber: "8472", currency: "人民币", balance: 300_000, openingBalance: 300_000)
        let other = LedgerAccount(id: "acct_second", tailNumber: "0999", currency: "人民币", balance: 1000, openingBalance: 1000)
        let fixture = FinanceLedgerRecord(accounts: [account, other], transactions: [], loanContracts: [], assetLiabilityAnnouncement: "演示", dataTimestamp: "2026-10-15 12:00:00")
        func reset() { precondition(store.save(fixture)) }
        func expect(_ error: TransferError, _ operation: () throws -> Void) {
            do { try operation(); fatalError("Expected \(error)") }
            catch let actual as TransferError { precondition(actual == error, "\(actual) != \(error)") }
            catch { fatalError("Unexpected \(error)") }
        }
        reset()
        var legacy = try JSONSerialization.jsonObject(with: JSONEncoder().encode(fixture)) as! [String: Any]
        legacy.removeValue(forKey: "transferRecords")
        defaults.set(try JSONSerialization.data(withJSONObject: legacy), forKey: key)
        precondition(store.load().transferRecords.isEmpty && store.load().accounts == fixture.accounts)
        let legacyBytes = defaults.data(forKey: key)
        _ = store.transferRecords()
        precondition(defaults.data(forKey: key) == legacyBytes)
        for (input, cents) in [("0.01", Int64(1)), ("100.10", 10010), (" 50 ", 5000), ("50000.00", 5_000_000)] {
            precondition(TransferMoney.parse(input) == cents)
        }
        for input in ["", "-1", "1.001", "1e3", "nan", "1,000", "1.", ".1", "99999999999999999999"] {
            precondition(TransferMoney.parse(input) == nil, input)
        }
        precondition(TransferMoney.cents(from: .nan) == nil)
        var draft = TransferDraft(payerAccountID: account.id, method: .account,
                                  recipientName: "演示客户", bankName: "中国建设银行", destination: "6217000000000593",
                                  amountInCents: 10_001, note: "模拟附言")
        let first = try store.submitTransfer(draft: draft, requestID: "first")
        precondition(first.status == .succeeded)
        precondition(first.maskedDestination == "6217****0593" && first.note == "模拟附言")
        precondition(store.load().transferRecords.count == 1 && store.load().transactions.count == 1)
        precondition(store.totalAssets() == 300_899.99)
        precondition(store.transaction(id: first.transactionID!)?.counterpartyAccount == first.maskedDestination)
        precondition(store.transaction(id: first.transactionID!)?.balanceAfter == 299_899.99)
        precondition(store.mineMonthlyFlow().expense == 100.01)
        precondition(store.assetLiabilityPageData().totalAssets == store.totalAssets())
        precondition(store.assetLiabilityPageData().assetCategories.first?.totalAmount == store.totalAssets())
        let encodedText = String(data: defaults.data(forKey: key)!, encoding: .utf8)!
        precondition(!encodedText.contains(draft.destination), "Do not persist raw recipient card input")
        let duplicate = try store.submitTransfer(draft: draft, requestID: "first")
        precondition(duplicate == first)
        let restored = FinanceLedgerStore(defaults: defaults, dates: dates)
        let restarted = try restored.submitTransfer(draft: draft, requestID: "first")
        precondition(restarted == first)
        precondition(restored.load().transactions.count == 1)
        print("PASS v8 migration, money parsing, masked persistence, atomic record/ledger projections and restart idempotency")

        // Repeated taps from independent tasks are serialized on the main actor.
        let repeatedDraft = draft
        let records = try await withThrowingTaskGroup(of: TransferRecord.self) { group in
            for _ in 0..<20 { group.addTask { @MainActor in try store.submitTransfer(draft: repeatedDraft, requestID: "parallel") } }
            var results: [TransferRecord] = []
            for try await value in group { results.append(value) }
            return results
        }
        precondition(Set(records.map(\.id)).count == 1)
        precondition(store.load().transactions.count == 2)
        precondition(store.transferRecords().first?.requestID == "parallel", "Same-second history is ordered by insertion")
        let allQuery = AccountDetailQueryFilter.default(referenceDate: now)
        precondition(store.accountDetailQueryPageData(accountId: account.id, filter: allQuery).transactions.first?.id == records[0].transactionID)

        var bad = draft
        bad.amountInCents = 0
        expect(.invalidAmount) { _ = try store.submitTransfer(draft: bad, requestID: "zero") }
        bad.amountInCents = -1
        expect(.invalidAmount) { try store.validateTransfer(bad) }
        bad = draft; bad.destination = "123"
        expect(.invalidDestination) { try store.validateTransfer(bad) }
        bad = draft; bad.note = String(repeating: "字", count: 61)
        expect(.invalidRecipient) { try store.validateTransfer(bad) }
        bad = draft; bad.payerAccountID = "missing"
        expect(.missingAccount) { try store.validateTransfer(bad) }
        bad = draft; bad.savedRecipientID = "invalid"
        expect(.invalidRecipient) { try store.validateTransfer(bad) }
        bad = draft; bad.savedRecipientID = "a1"
        expect(.sameAccount) { try store.validateTransfer(bad) }
        bad = draft; bad.destination = "6230480012348472"
        expect(.sameAccount) { try store.validateTransfer(bad) }
        bad = draft; bad.amountInCents = 5_000_001
        expect(.singleLimit) { try store.validateTransfer(bad) }
        bad = draft; bad.payerAccountID = other.id; bad.amountInCents = 100_001
        expect(.insufficientBalance) { try store.validateTransfer(bad) }
        precondition(store.load().transactions.count == 2)
        expect(.invalidRequest) { _ = try store.submitTransfer(draft: draft, requestID: "") }
        reset()
        var exact = draft
        exact.payerAccountID = other.id
        exact.amountInCents = 100_000
        _ = try store.submitTransfer(draft: exact, requestID: "exact-balance")
        precondition(store.load().accounts.first(where: { $0.id == other.id })?.balance == 0)
        precondition(store.load().accounts.first(where: { $0.id == account.id })?.balance == account.balance)
        print("PASS serialized repeated submit, invalid inputs, missing/self account, exact balance, payer selection and single limits")

        reset()
        draft.amountInCents = 5_000_000
        for i in 0..<4 { _ = try store.submitTransfer(draft: draft, requestID: "limit-\(i)") }
        draft.amountInCents = 1
        expect(.dailyLimit) { _ = try store.submitTransfer(draft: draft, requestID: "over-daily") }
        precondition(store.load().transactions.count == 4)
        now = ISO8601DateFormatter().date(from: "2026-10-16T16:00:00Z")! // Beijing midnight, still the same UTC day
        _ = try store.submitTransfer(draft: draft, requestID: "next-day")
        precondition(store.load().transactions.count == 5)
        // Validation and submission read separately: the second must reject a balance changed after confirmation.
        reset()
        draft.payerAccountID = other.id; draft.amountInCents = 100_000
        try store.validateTransfer(draft)
        var changed = fixture
        changed.accounts[1].openingBalance = 1
        changed.accounts[1].balance = 1
        precondition(store.save(changed))
        expect(.insufficientBalance) { _ = try store.submitTransfer(draft: draft, requestID: "stale-balance") }
        precondition(store.load().transactions.isEmpty)
        print("PASS exact daily limit, next Beijing day reset and submission revalidation")

        reset()
        draft.payerAccountID = account.id; draft.amountInCents = 100
        let failure = FinanceLedgerStore(defaults: defaults, dates: dates, simulationSucceeds: { _ in false })
        let failed = try failure.submitTransfer(draft: draft, requestID: "failure")
        precondition(failed.status == .failed && failed.transactionID == nil)
        precondition(failure.totalAssets() == 301_000 && failure.load().transactions.isEmpty)
        let repeatedFailure = try failure.submitTransfer(draft: draft, requestID: "failure")
        precondition(repeatedFailure == failed)
        let retried = try store.submitTransfer(draft: draft, requestID: "retry")
        precondition(retried.status == .succeeded && store.load().transactions.count == 1)
        var phone = TransferDraft(payerAccountID: account.id, method: .phone,
                                  recipientName: "手机号演示客户", destination: "13800008000", amountInCents: 1)
        let phoneRecord = try store.submitTransfer(draft: phone, requestID: "phone")
        precondition(phoneRecord.maskedDestination == "138****8000")
        phone.destination = "12345678901"
        expect(.invalidDestination) { try store.validateTransfer(phone) }
        let history = phoneRecord.reusableRecipient
        phone.savedRecipientID = history.id
        let repeated = try store.submitTransfer(draft: phone, requestID: "saved-phone")
        precondition(repeated.maskedDestination == phoneRecord.maskedDestination)
        precondition(!String(data: defaults.data(forKey: key)!, encoding: .utf8)!.contains("13800008000"))
        print("PASS deterministic failure without debit, retry, phone transfer, saved recipient reuse and masked phone persistence")

        let before = defaults.data(forKey: key)
        let writerFailure = FinanceLedgerStore(defaults: defaults, dates: dates, dataWriter: { _ in throw TransferError.persistence })
        let alreadySaved = try writerFailure.submitTransfer(draft: draft, requestID: "retry")
        precondition(alreadySaved.id == retried.id, "A committed retry must not attempt another write")
        expect(.persistence) { _ = try writerFailure.submitTransfer(draft: draft, requestID: "write-failure") }
        precondition(defaults.data(forKey: key) == before)
        defaults.set(Data("broken".utf8), forKey: key)
        _ = store.load()
        expect(.corruptLedger) { _ = try store.submitTransfer(draft: draft, requestID: "broken") }
        precondition(defaults.data(forKey: key) == Data("broken".utf8))
        reset()
        let untouched = defaults.data(forKey: key)
        try store.validateTransfer(draft) // cancelling after confirmation does not call submit
        precondition(defaults.data(forKey: key) == untouched)
        var nonFinite = fixture
        nonFinite.accounts[0].balance = .infinity
        precondition(!store.save(nonFinite))
        precondition(defaults.data(forKey: key) == untouched)
        print("PASS write/encoding failure and cancellation preserve bytes; corrupt records never reset on transfer")
    }
}
