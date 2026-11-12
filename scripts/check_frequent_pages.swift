import Foundation

@main struct FrequentPageChecks {
    @MainActor static func main() throws {
        let suite = "ABank.FrequentPages." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let fixed = BankingDateContext.system.date(from: "2027-01-15")!
        let dates = BankingDateContext(now: { fixed })
        let ledger = FinanceLedgerStore(defaults: defaults, dates: dates, riskStateProvider: { .valid(.c5, expiresOn: "2027-12-01") })
        let initial = ledger.load()
        let before = defaults.data(forKey: "abank.financeLedger.record.v8")
        let current = ledger.loanDuePageData(period: .thisMonth)
        let next = ledger.loanDuePageData(period: .nextMonth)
        precondition(!current.installments.isEmpty && current.installments.allSatisfy { $0.date.hasPrefix("2027-01") })
        precondition(next.installments.allSatisfy { $0.date.hasPrefix("2027-02") } && next.totalAmount == 127.91)
        precondition(current.tip.contains("待处理"))
        precondition(defaults.data(forKey: "abank.financeLedger.record.v8") == before, "Due projections must never post repayments")
        precondition(FeatureCatalog.defaultFavorites.allSatisfy { FeatureCatalog.descriptor($0).isAvailable })
        let secondary = try ledger.openElectronicAccount()
        let recipient = ledger.transferRecipients().first { $0.linkedAccountID == secondary.id }!
        _ = try ledger.submitTransfer(draft: .init(payerAccountID: initial.accounts[0].id, savedRecipientID: recipient.id, amountInCents: 100_000), requestID: "fund")
        let mainBalance = ledger.account(id: initial.accounts[0].id)!.balance
        let order = try ledger.submitWealthPurchase(productID: "w.shishifu", amountInCents: 10_000, requestID: "buy", accountID: secondary.id)
        precondition(order.accountID == secondary.id && ledger.account(id: secondary.id)?.balance == 900)
        precondition(ledger.account(id: initial.accounts[0].id)?.balance == mainBalance)
        let recharge = try ledger.submitMobileRecharge(phone: "13800008000", faceInCents: 2_000, couponID: nil, requestID: "recharge", accountID: secondary.id)
        precondition(recharge.accountID == secondary.id && ledger.account(id: secondary.id)?.balance == 880)
        precondition(ledger.account(id: initial.accounts[0].id)?.balance == mainBalance)
        do { try ledger.validateWealthPurchase(productID: "w.shishifu", amountInCents: 100, accountID: "missing"); preconditionFailure() } catch {}
        let billAccount = PaymentCatalog.billAccounts[0]
        for month in ["2026-01", "2026-02", "2026-11", "2026-12", "2027-01"] {
            for account in PaymentCatalog.billAccounts {
                let bill = try ledger.utilityBill(account: account, period: month)
                precondition(bill.calculatedChargeInCents == bill.amountInCents, "Displayed usage times tariff must match billed cents")
            }
        }
        let bill = try ledger.utilityBill(account: billAccount, period: "2026-12")
        let paid = try ledger.submitUtilityPayment(billAccountID: billAccount.id, requestID: "past-bill", expectedPeriod: bill.period, expectedAmountInCents: bill.amountInCents, accountID: secondary.id, period: bill.period)
        precondition(paid.accountID == secondary.id && paid.period == "2026-12")
        precondition(ledger.account(id: initial.accounts[0].id)?.balance == mainBalance)
        let paidBytes = defaults.data(forKey: "abank.financeLedger.record.v8")
        do { _ = try ledger.submitUtilityPayment(billAccountID: billAccount.id, requestID: "past-bill-again", accountID: secondary.id, period: bill.period); preconditionFailure() } catch { precondition(error as? PaymentError == .alreadyPaid) }
        do { _ = try ledger.utilityBill(account: billAccount, period: "2027-02"); preconditionFailure() } catch {}
        do { _ = try ledger.utilityBill(account: billAccount, period: "2027-1"); preconditionFailure() } catch {}
        precondition(defaults.data(forKey: "abank.financeLedger.record.v8") == paidBytes)
        var entry = ManualEntryDraft()
        entry.title = "午餐"; entry.amountInCents = 3500; entry.date = "2027-01-15"; entry.purposeID = "food"
        let saved = try ledger.saveManualEntry(entry, id: "entry-purpose")
        precondition(saved.purposeCategoryID == "food" && ledger.transaction(id: saved.id)?.purposeCategoryID == "food")
        precondition(ledger.statementCSV(query: .init(dateMode: .month("2027-01"))).contains("餐饮美食"))
        precondition(ledger.account(id: initial.accounts[0].id)?.balance == mainBalance)
        entry.purposeID = "missing"
        do { _ = try ledger.saveManualEntry(entry, id: "bad-purpose"); preconditionFailure() } catch { precondition(error as? LedgerEditError == .invalidCategory) }
        try ledger.setReportedLost(true, accountID: secondary.id)
        do { _ = try ledger.validateMobileRecharge(phone: "13800008000", faceInCents: 2_000, couponID: nil, accountID: secondary.id); preconditionFailure() } catch { precondition(error as? AccountSettingsError == .cardReportedLost) }
        let messages = BankMessageStore(defaults: defaults)
        let rows = messages.messages(ledger: ledger)
        precondition(rows.count >= 3 && Set(rows.map(\.id)).count == rows.count)
        precondition(messages.unreadCount(ledger: ledger) == rows.count)
        messages.markRead([rows[0]])
        precondition(BankMessageStore(defaults: defaults).unreadCount(ledger: ledger) == rows.count - 1)
        messages.markRead(rows)
        precondition(messages.unreadCount(ledger: ledger) == 0)
        let session = CustomerSessionStore(defaults: defaults, dates: dates)
        precondition(session.isSignedIn)
        session.signOut(); precondition(!CustomerSessionStore(defaults: defaults).isSignedIn)
        session.signIn(); precondition(session.isSignedIn && session.lastLogin.hasPrefix("2027-01-15"))
        var clock = fixed
        let challenge = VerificationChallenge(clock: { clock }, codeProvider: { "246810" })
        let code = try challenge.request(phone: "13800008000")
        precondition(code == "246810" && challenge.resendSeconds == 60)
        do { _ = try challenge.request(phone: "13800008000"); preconditionFailure() } catch {}
        do { try challenge.verify(phone: "13900008000", code: code); preconditionFailure() } catch {}
        for _ in 0..<5 { do { try challenge.verify(phone: "13800008000", code: "000000"); preconditionFailure() } catch {} }
        do { try challenge.verify(phone: "13800008000", code: code); preconditionFailure() } catch {}
        clock = clock.addingTimeInterval(61)
        _ = try challenge.request(phone: "13800008000")
        clock = clock.addingTimeInterval(301)
        do { try challenge.verify(phone: "13800008000", code: code); preconditionFailure() } catch {}
        _ = try challenge.request(phone: "13800008000")
        try challenge.verify(phone: "13800008000", code: code)
        do { try challenge.verify(phone: "13800008000", code: code); preconditionFailure() } catch {}
        print("Frequent page checks passed: month/year due projections, unchanged history, payer context, message read state, session and one-time-code boundaries")
    }
}
