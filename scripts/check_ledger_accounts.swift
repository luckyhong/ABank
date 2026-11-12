import Foundation

@main struct LedgerAccountChecks {
    @MainActor static func main() throws {
        let suite = "ABank.LedgerAccountChecks." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let date = BankingDateContext.system.date(from: "2026-11-12")!
        let dates = BankingDateContext(now: { date })
        let store = FinanceLedgerStore(defaults: defaults, dates: dates, riskStateProvider: { .valid(.c5, expiresOn: "2027-11-12") })
        let key = "abank.financeLedger.record.v8"
        let seed = store.load()
        precondition(seed.transactions.count == 37 && TransferMoney.cents(from: seed.accounts[0].balance) == 826_923)
        let balance = seed.accounts[0].balance
        let flow = store.monthlyFlow(for: "2026-11")
        var draft = ManualEntryDraft(title: " 午餐,咖啡 ", amountInCents: 2_035, direction: .expense,
                                    date: "2026-11-11", categoryID: "other_expense", ledgerID: "daily", note: "=1+1")
        let saved = try store.saveManualEntry(draft, id: "manual_one")
        precondition(saved.title == "午餐,咖啡" && saved.isManual)
        _ = try store.saveManualEntry(draft, id: saved.id)
        precondition(store.load().transactions.count == 38 && store.load().accounts[0].balance == balance)
        precondition(TransferMoney.cents(from: store.monthlyFlow(for: "2026-11").expense) == TransferMoney.cents(from: flow.expense)! + 2_035)
        let manualQuery = IncomeExpenseQuery(dateMode: .month("2026-11"), accountFilter: .manual, ledgerID: "daily")
        precondition(store.incomeExpensePageData(query: manualQuery).dayGroups.flatMap(\.transactions).map(\.id) == [saved.id])
        let csv = store.statementCSV(query: manualQuery)
        precondition(csv.hasPrefix("\u{FEFF}") && csv.contains("\"午餐,咖啡\"") && csv.contains("\"'=1+1\"") && csv.contains("\"20.35\""))
        precondition(!csv.contains("8269.23"), "Manual entries must not imply a bank balance")
        draft.direction = .income; draft.categoryID = "transfer_in"; draft.amountInCents = 101
        _ = try store.saveManualEntry(draft, id: saved.id)
        precondition(store.load().transactions.count == 38 && store.monthlyFlow(for: "2026-11").expense == flow.expense)
        precondition(store.incomeExpensePageData(query: manualQuery).summary.income == 1.01)
        let before = defaults.data(forKey: key)
        func rejected(_ action: () throws -> Void) {
            do { try action(); preconditionFailure("Expected rejection") } catch {}
            precondition(defaults.data(forKey: key) == before, "Rejected changes must preserve original bytes")
        }
        var invalid = draft; invalid.date = "2026-11-13"
        rejected { _ = try store.saveManualEntry(invalid, id: "future") }
        invalid.date = "2026-02-30"
        rejected { _ = try store.saveManualEntry(invalid, id: "bad_date") }
        invalid = draft; invalid.amountInCents = 0
        rejected { _ = try store.saveManualEntry(invalid, id: "zero") }
        invalid = draft; invalid.categoryID = "salary"; invalid.direction = .expense
        rejected { _ = try store.saveManualEntry(invalid, id: "category") }
        rejected { try store.deleteManualEntry(id: seed.transactions[0].id) }
        rejected { _ = try store.saveManualEntry(draft, id: seed.transactions[0].id) }
        precondition(!store.updateTransactionDetail(id: "missing", note: "x"))
        precondition(!store.updateTransactionDetail(id: saved.id, categoryId: "other_expense"))
        precondition(!store.updateTransactionLedger(id: saved.id, ledgerId: "missing"))
        precondition(store.updateTransactionLedger(id: saved.id, ledgerId: nil))
        try store.deleteManualEntry(id: saved.id)
        precondition(store.load().transactions == seed.transactions && store.load().accounts[0].balance == balance)

        let electronic = try store.openElectronicAccount()
        let openedAgain = try store.openElectronicAccount()
        precondition(openedAgain == electronic)
        precondition(electronic.balance == 0 && electronic.fullCardNumber != nil)
        let own = store.transferRecipients().first { $0.linkedAccountID == electronic.id }!
        let transferDraft = TransferDraft(payerAccountID: seed.accounts[0].id, savedRecipientID: own.id, amountInCents: 12_345)
        let assets = store.totalAssets()
        let internalTransfer = try store.submitTransfer(draft: transferDraft, requestID: "internal")
        _ = try store.submitTransfer(draft: transferDraft, requestID: "internal")
        precondition(store.load().transactions.count == 39)
        precondition(store.account(id: electronic.id)?.balance == 123.45 && store.totalAssets() == assets)
        precondition(store.monthlyFlow(for: "2026-11").income == flow.income && store.monthlyFlow(for: "2026-11").expense == flow.expense)
        precondition(store.receiptRecords().count == 1 && internalTransfer.reusableRecipient.linkedAccountID == electronic.id)
        let reloaded = FinanceLedgerStore(defaults: defaults, dates: dates)
        precondition(reloaded.account(id: electronic.id) == store.account(id: electronic.id))
        let restoredRecipient = try reloaded.recipient(for: transferDraft)
        precondition(restoredRecipient.linkedAccountID == electronic.id)

        let permissions = store.account(id: seed.accounts[0].id)!.permissions
        try store.setReportedLost(true, accountID: seed.accounts[0].id)
        let locked = defaults.data(forKey: key)
        func blocked(_ action: () throws -> Void) {
            do { try action(); preconditionFailure("Lost card allowed a debit") }
            catch { precondition(error as? AccountSettingsError == .cardReportedLost) }
            precondition(defaults.data(forKey: key) == locked)
        }
        blocked { try store.validateTransfer(transferDraft) }
        blocked { _ = try store.submitTransfer(draft: transferDraft, requestID: "blocked") }
        blocked { _ = try store.validateMobileRecharge(phone: "13800008000", faceInCents: 2_000, couponID: nil) }
        blocked { try store.validateUtilityPayment(billAccountID: PaymentCatalog.billAccounts[0].id) }
        blocked { try store.validateWealthPurchase(productID: "w.shishifu", amountInCents: 100) }
        blocked { _ = try store.previewPrepayment(contractID: FinanceLedgerRecord.defaultLoanId, amountInCents: 100, method: .shortenTerm) }
        try store.setReportedLost(false, accountID: seed.accounts[0].id)
        precondition(store.account(id: seed.accounts[0].id)?.permissions == permissions)
        try store.validateTransfer(transferDraft)
        // Missing new account fields in legacy JSON must retain old defaults.
        var encoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(seed.accounts[0])) as! [String: Any]
        for key in ["isReportedLost", "accountNumber", "openedOn", "branchName"] { encoded.removeValue(forKey: key) }
        let decoded = try JSONDecoder().decode(LedgerAccount.self, from: JSONSerialization.data(withJSONObject: encoded))
        precondition(!decoded.isReportedLost && decoded.fullCardNumber == "6230 4800 1234 8472")
        // Storage failure cannot partially add or remove data.
        let current = defaults.data(forKey: key)
        let failing = FinanceLedgerStore(defaults: defaults, dates: dates, dataWriter: { _ in throw LedgerEditError.persistence })
        do { _ = try failing.saveManualEntry(draft, id: "failed"); preconditionFailure() } catch {}
        precondition(defaults.data(forKey: key) == current)
        do { _ = try failing.submitTransfer(draft: transferDraft, requestID: "write_failure"); preconditionFailure() } catch {}
        precondition(defaults.data(forKey: key) == current, "Both sides of an internal transfer must persist atomically")
        var legacy = FinanceLedgerRecord(accounts: [.init(id: "legacy", tailNumber: "9999", currency: "人民币", balance: 0, openingBalance: 100)],
            transactions: [.init(id: "old_manual", accountId: "legacy", date: "2026-11-01", time: "12:00:00", title: "旧手工记录", direction: .expense,
                amount: 2.01, balanceAfter: 0, iconKey: "pencil", categoryId: "other_expense", isManual: true)],
            loanContracts: [], assetLiabilityAnnouncement: "", dataTimestamp: "")
        store.recalculate(&legacy)
        precondition(store.save(legacy) && store.account(id: "legacy")?.balance == 97.99)
        _ = try store.saveManualEntry(draft, id: "old_manual")
        precondition(store.account(id: "legacy")?.balance == 97.99)
        try store.deleteManualEntry(id: "old_manual")
        precondition(store.account(id: "legacy")?.balance == 97.99, "Legacy bookkeeping edits must preserve the bank balance")
        defaults.set(Data("broken".utf8), forKey: key)
        do { _ = try store.saveManualEntry(draft, id: "corrupt"); preconditionFailure() } catch {}
        precondition(defaults.data(forKey: key) == Data("broken".utf8))
        print("Ledger/account checks passed: manual CRUD, exact totals, export, validation, electronic account, atomic internal transfer, lost-card guards, legacy decode, persistence protection")
    }
}
