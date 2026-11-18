import Foundation

@MainActor
enum BankingDemoMigration {
    static func upgrade(_ stored: FinanceLedgerRecord) -> FinanceLedgerRecord? {
        switch stored.demoDataVersion {
        case BankingDemoFixture.previousVersion:
            return appendFixtureTransactions(in: stored, additions: BankingDemoFixture.addedTransactionIDs.union([BankingDemoFixture.latestTransactionID]))
        case BankingDemoFixture.previousSupplementVersion, BankingDemoFixture.previousCorrectedVersion:
            return appendFixtureTransactions(in: stored, additions: [BankingDemoFixture.latestTransactionID])
        case nil:
            return upgradeLegacyRecord(stored)
        default:
            return nil
        }
    }

    private static func upgradeLegacyRecord(_ stored: FinanceLedgerRecord) -> FinanceLedgerRecord? {
        let legacy = FinanceLedgerStore.makeLegacySeedRecord()
        let ownedIDs = Set(legacy.transactions.map(\.id))
        guard Set(stored.transactions.map(\.id)).count == stored.transactions.count,
              Set(stored.accounts.map(\.id)).count == stored.accounts.count,
              Set(stored.loanContracts.map(\.id)).count == stored.loanContracts.count,
              legacy.transactions.allSatisfy({ original in
                  stored.transactions.contains { $0.id == original.id && $0.date == original.date && $0.accountId == original.accountId }
              }),
              let index = stored.accounts.firstIndex(where: { $0.id == FinanceLedgerRecord.defaultAccountId }),
              stored.accounts[index].currency == "人民币" else { return nil }

        let baseline = BankingDemoFixture.makeRecord()
        var updated = stored
        let preserved = stored.transactions.filter { !ownedIDs.contains($0.id) }
        guard Set(preserved.map(\.id)).isDisjoint(with: Set(baseline.transactions.map(\.id))) else { return nil }
        let mapping = [
            "tx_007": "fixture-2026-08-15-alipay",
            "tx_008": "fixture-2026-08-15-douyin",
            "tx_010": "fixture-2026-08-20-alipay",
            "tx_011": "fixture-2026-08-22-alipay-refund",
            "tx_012": "fixture-2026-08-22-alipay",
        ]
        var transactions = baseline.transactions
        for old in stored.transactions {
            guard let target = mapping[old.id], let i = transactions.firstIndex(where: { $0.id == target }) else { continue }
            // 保留用户可编辑的信息；已明确重新制定的历史金额来自新基线。
            transactions[i].categoryId = old.categoryId
            transactions[i].includeInFlow = old.includeInFlow
            transactions[i].ledgerId = old.ledgerId
            transactions[i].note = old.note
        }
        updated.transactions = transactions + preserved
        // 旧演示上的手动充值/期初调整保留为增量，不影响新基线自身的准确余额。
        let oldOpening = legacy.accounts[0].openingBalance
        updated.accounts[index].openingBalance = baseline.accounts[0].openingBalance
            + (stored.accounts[index].openingBalance - oldOpening)

        if let loanIndex = stored.loanContracts.firstIndex(where: { $0.id == FinanceLedgerRecord.defaultLoanId }) {
            let old = stored.loanContracts[loanIndex]
            let original = legacy.loanContracts[0]
            let hasPrepayment = stored.loanServiceRecords.contains { $0.contractID == old.id && $0.kind == .prepayment }
            if !hasPrepayment, old.unpaidPrincipal == original.unpaidPrincipal,
               old.installmentAmount == original.installmentAmount,
               old.remainingTerms == original.remainingTerms, old.nextDueDate == original.nextDueDate,
               old.annualRatePercent == original.annualRatePercent {
                var replacement = baseline.loanContracts[0]
                replacement.isDetailExpanded = old.isDetailExpanded
                updated.loanContracts[loanIndex] = replacement
            }
            // 已经有额外还本/自定义合同的演示保留原合同，避免把实际操作悄悄抹掉。
        }
        updated.demoDataVersion = BankingDemoFixture.version
        updated.dataTimestamp = max(stored.dataTimestamp, baseline.dataTimestamp)
        return updated
    }

    /// Append only the transactions missing from this release's baseline.
    private static func appendFixtureTransactions(in stored: FinanceLedgerRecord, additions: Set<String>) -> FinanceLedgerRecord? {
        let baseline = BankingDemoFixture.makeRecord()
        let storedIDs = Set(stored.transactions.map(\.id))
        let required = baseline.transactions.filter { !additions.contains($0.id) }
        guard storedIDs.count == stored.transactions.count,
              Set(stored.accounts.map(\.id)).count == stored.accounts.count,
              stored.accounts.contains(where: { $0.id == FinanceLedgerRecord.defaultAccountId && $0.currency == "人民币" }),
              required.allSatisfy({ original in
                  stored.transactions.contains { $0.id == original.id && $0.date == original.date && $0.accountId == original.accountId }
              }),
              storedIDs.isDisjoint(with: additions) else { return nil }
        var updated = stored
        updated.transactions += baseline.transactions.filter { additions.contains($0.id) }
        if stored.demoDataVersion != BankingDemoFixture.previousCorrectedVersion {
            applyCorrectedTransferDetails(to: &updated)
        }
        updated.demoDataVersion = BankingDemoFixture.version
        updated.dataTimestamp = max(stored.dataTimestamp, baseline.dataTimestamp)
        return updated
    }

    static func applyCorrectedTransferDetails(to record: inout FinanceLedgerRecord) {
        let reference = BankingDemoFixture.makeRecord().transactions
        for index in record.transactions.indices where BankingDemoFixture.correctedTransactionIDs.contains(record.transactions[index].id) {
            guard let correct = reference.first(where: { $0.id == record.transactions[index].id }) else { continue }
            if ["转给欧", "转出（欧）"].contains(record.transactions[index].title) { record.transactions[index].title = correct.title }
            if ["转给欧", "转出（欧）"].contains(record.transactions[index].summary) { record.transactions[index].summary = correct.summary }
            if ["", "欧"].contains(record.transactions[index].counterpartyName) { record.transactions[index].counterpartyName = correct.counterpartyName }
            if record.transactions[index].counterpartyAccount.isEmpty { record.transactions[index].counterpartyAccount = correct.counterpartyAccount }
            if record.transactions[index].counterpartyBank.isEmpty { record.transactions[index].counterpartyBank = correct.counterpartyBank }
            if ["", "—", "---"].contains(record.transactions[index].channel) { record.transactions[index].channel = correct.channel }
        }
    }
}
