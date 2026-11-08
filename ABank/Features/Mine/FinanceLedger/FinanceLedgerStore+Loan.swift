//
//  FinanceLedgerStore+Loan.swift
//  ABank
//
//  M9b 贷款：提前还款扣款、流水、合同与办理记录一次原子写入；同一 `requestID` 只返回首次记录。
//  结清证明申请按贷款幂等；待办任务与办理进度由账本派生，不另存状态。
//

import Foundation

struct LoanProgressStep: Equatable {
    let title: String
    let time: String
}

struct LoanProgressItem: Equatable, Identifiable {
    let id: String
    let title: String
    let loanName: String
    /// yyyy-MM-dd HH:mm:ss
    let time: String
    let status: String
    let steps: [LoanProgressStep]
    let record: LoanServiceRecord?
}

enum LoanTaskKind: Equatable {
    case repaymentReminder
    case insufficientBalance
    case certificatePending(loanID: String)
}

struct LoanTask: Equatable, Identifiable {
    let id: String
    let title: String
    let detail: String
    let kind: LoanTaskKind
}

extension FinanceLedgerStore {
    // MARK: - 读取

    func loanServiceRecords() -> [LoanServiceRecord] {
        load().loanServiceRecords.enumerated().sorted { lhs, rhs in
            lhs.element.createdAt != rhs.element.createdAt
                ? lhs.element.createdAt > rhs.element.createdAt : lhs.offset > rhs.offset
        }.map(\.element)
    }

    func settlementCertificate(loanID: String) -> LoanServiceRecord? {
        load().loanServiceRecords.first { $0.kind == .settlementCertificate && $0.contractID == loanID }
    }

    func loanProgressItems() -> [LoanProgressItem] {
        let recorded = loanServiceRecords().map { record in
            LoanProgressItem(
                id: record.id, title: record.kind.title, loanName: record.loanName, time: record.createdAt,
                status: "已办结",
                steps: ["提交", "受理", "办结"].map { LoanProgressStep(title: $0, time: record.createdAt) },
                record: record
            )
        }
        return (recorded + Self.seededLoanApplications).sorted { $0.time > $1.time }
    }

    func loanTasks() -> [LoanTask] {
        let record = load()
        var tasks: [LoanTask] = []
        let active = record.loanContracts.filter { $0.unpaidPrincipal > 0 }
        if let nextDue = active.map(\.nextDueDate).min() {
            let due = active.reduce(Int64(0)) { $0 + (TransferMoney.cents(from: $1.installmentAmount) ?? 0) }
            tasks.append(LoanTask(id: "task_repayment", title: "还款提醒",
                                  detail: "\(nextDue.dropFirst(5)) 应还 \(TransferMoney.text(due)) 元",
                                  kind: .repaymentReminder))
            let balance = record.accounts.first { $0.id == FinanceLedgerRecord.defaultAccountId }
                .flatMap { TransferMoney.cents(from: $0.balance) } ?? 0
            if balance < due {
                tasks.append(LoanTask(id: "task_balance", title: "余额不足",
                                      detail: "账户余额不足以支付下期还款，还差 \(TransferMoney.text(due - balance)) 元",
                                      kind: .insufficientBalance))
            }
        }
        for loan in LoanHistoryCatalog.settledLoans
        where !record.loanServiceRecords.contains(where: { $0.kind == .settlementCertificate && $0.contractID == loan.id }) {
            tasks.append(LoanTask(id: "task_certificate_" + loan.id, title: "结清证明待开具",
                                  detail: "\(loan.name)已结清，可申请结清证明",
                                  kind: .certificatePending(loanID: loan.id)))
        }
        return tasks
    }

    // MARK: - 提前还款

    func previewPrepayment(contractID: String, amountInCents: Int64,
                           method: LoanRepaymentMethod) throws -> LoanPrepaymentPreview {
        try checkedPreview(in: load(), contractID: contractID, amountInCents: amountInCents, method: method)
    }

    @discardableResult
    func submitPrepayment(contractID: String, amountInCents: Int64, method: LoanRepaymentMethod,
                          requestID: String, expected: LoanPrepaymentPreview?) throws -> LoanServiceRecord {
        guard !requestID.isEmpty, requestID.count <= 100 else { throw LoanError.invalidRequest }
        var root = try strictLoanRecord()
        if let existing = root.loanServiceRecords.first(where: { $0.requestID == requestID }) { return existing }
        let preview = try checkedPreview(in: root, contractID: contractID, amountInCents: amountInCents, method: method)
        // 确认弹窗期间余额、本金或每期还款额变化时拒绝，避免扣款与用户确认的不一致。
        if let expected, expected != preview { throw LoanError.changed }
        guard let index = root.loanContracts.firstIndex(where: { $0.id == contractID }),
              let account = root.accounts.first(where: { $0.id == FinanceLedgerRecord.defaultAccountId }) else {
            throw LoanError.contractUnavailable
        }
        let contract = root.loanContracts[index]
        let now = dates.now
        let numbers = serviceNumbers(now: now)
        let record = LoanServiceRecord(
            id: numbers.id, requestID: requestID, kind: .prepayment, contractID: contract.id,
            contractNumber: contract.contractNumber, loanName: contract.name, createdAt: numbers.timestamp,
            businessNo: numbers.businessNo, amountInCents: amountInCents, method: method, accountID: account.id,
            transactionID: "loan_" + numbers.id,
            principalBefore: preview.principalBefore, principalAfter: preview.principalAfter,
            installmentBefore: preview.installmentBefore, installmentAfter: preview.installmentAfter,
            termsBefore: preview.termsBefore, termsAfter: preview.termsAfter,
            maturityBefore: preview.maturityBefore, maturityAfter: preview.maturityAfter
        )
        root.loanContracts[index].unpaidPrincipal = TransferMoney.amount(preview.principalAfter)
        root.loanContracts[index].installmentAmount = TransferMoney.amount(preview.installmentAfter)
        root.loanContracts[index].remainingTerms = preview.termsAfter
        root.loanContracts[index].maturityDateText = LoanAmortization.maturityText(preview.maturityAfter)
        root.transactions.append(LedgerTransaction(
            id: "loan_" + numbers.id, accountId: account.id, date: dates.string(from: now),
            time: dates.string(from: now, format: "HH:mm:ss"), title: "提前还款-" + contract.name, direction: .expense,
            amount: TransferMoney.amount(amountInCents), balanceAfter: 0, iconKey: "house.fill", categoryId: "loan_repay",
            includeInFlow: true, counterpartyName: "ABank 个人贷款", summary: "模拟提前还款",
            cardNumber: "****" + account.tailNumber, transactionType: "贷款还款", channel: "本机模拟"
        ))
        root.loanServiceRecords.append(record)
        recalculate(&root)
        root.dataTimestamp = numbers.timestamp
        do { try persist(root) } catch { throw LoanError.persistence }
        return record
    }

    // MARK: - 结清证明

    @discardableResult
    func requestSettlementCertificate(loanID: String, requestID: String) throws -> LoanServiceRecord {
        guard !requestID.isEmpty, requestID.count <= 100 else { throw LoanError.invalidRequest }
        var root = try strictLoanRecord()
        guard let loan = LoanHistoryCatalog.loan(id: loanID) else { throw LoanError.contractUnavailable }
        if let existing = root.loanServiceRecords.first(where: { $0.kind == .settlementCertificate && $0.contractID == loanID }) {
            return existing
        }
        let numbers = serviceNumbers(now: dates.now)
        let record = LoanServiceRecord(
            id: numbers.id, requestID: requestID, kind: .settlementCertificate, contractID: loan.id,
            contractNumber: loan.contractNumber, loanName: loan.name, createdAt: numbers.timestamp,
            businessNo: numbers.businessNo, certificateNo: "JQ" + numbers.suffix
        )
        root.loanServiceRecords.append(record)
        root.dataTimestamp = numbers.timestamp
        do { try persist(root) } catch { throw LoanError.persistence }
        return record
    }

    // MARK: - 内部

    private func strictLoanRecord() throws -> FinanceLedgerRecord {
        do { return try loadForTransfer() } catch { throw LoanError.corruptLedger }
    }

    private func checkedPreview(in record: FinanceLedgerRecord, contractID: String, amountInCents: Int64,
                                method: LoanRepaymentMethod) throws -> LoanPrepaymentPreview {
        guard let contract = record.loanContracts.first(where: { $0.id == contractID }),
              contract.unpaidPrincipal > 0 else { throw LoanError.contractUnavailable }
        let balance = record.accounts.first { $0.id == FinanceLedgerRecord.defaultAccountId }
            .flatMap { TransferMoney.cents(from: $0.balance) } ?? 0
        return try LoanAmortization.preview(contract: contract, balanceInCents: balance, amountInCents: amountInCents,
                                            method: method, dates: dates)
    }

    /// 业务编号 DK + yyyyMMddHHmmss + UUID 前 4 位；证明编号用同一后缀加 JQ。
    private func serviceNumbers(now: Date) -> (id: String, timestamp: String, businessNo: String, suffix: String) {
        let id = UUID().uuidString
        let suffix = dates.string(from: now, format: "yyyyMMddHHmmss") + String(id.prefix(4)).uppercased()
        return (id, dates.string(from: now, format: "yyyy-MM-dd HH:mm:ss"), "DK" + suffix, suffix)
    }

    private static let seededLoanApplications: [LoanProgressItem] = [
        LoanProgressItem(
            id: "apply_housing_2017", title: "住房贷款申请", loanName: "个人住房贷款", time: "2017-10-09 10:00:00",
            status: "已放款",
            steps: [LoanProgressStep(title: "提交申请", time: "2017-09-15 09:30:00"),
                    LoanProgressStep(title: "审批通过", time: "2017-09-28 16:20:00"),
                    LoanProgressStep(title: "贷款发放", time: "2017-10-09 10:00:00")],
            record: nil
        ),
        LoanProgressItem(
            id: "apply_consumer_2019", title: "消费贷款申请", loanName: "个人消费贷款", time: "2019-03-12 11:00:00",
            status: "已放款",
            steps: [LoanProgressStep(title: "提交申请", time: "2019-03-08 14:10:00"),
                    LoanProgressStep(title: "审批通过", time: "2019-03-11 15:40:00"),
                    LoanProgressStep(title: "贷款发放", time: "2019-03-12 11:00:00")],
            record: nil
        )
    ]
}
