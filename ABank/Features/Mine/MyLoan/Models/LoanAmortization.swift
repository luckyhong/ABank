//
//  LoanAmortization.swift
//  ABank
//
//  等额本息：月利率 = 年化 / 1200，每期利息按分四舍五入；末期还清剩余本金。
//

import Foundation

enum LoanAmortization {
    static func interest(principalInCents: Int64, annualPercent: Double) -> Int64 {
        let rate = Decimal(string: String(annualPercent)) ?? 0
        var value = Decimal(principalInCents) * rate / 1200
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 0, .plain)
        return NSDecimalNumber(decimal: rounded).int64Value
    }

    /// 缩短期限：理论期数 x 小数部分 < 0.01 时取 floor（尾差并入末期），否则取 ceil。
    static func terms(principalInCents: Int64, installmentInCents: Int64, annualPercent: Double) -> Int {
        guard principalInCents > 0, installmentInCents > 0 else { return 0 }
        let r = annualPercent / 1200
        guard r > 0 else { return Int((Double(principalInCents) / Double(installmentInCents)).rounded(.up)) }
        let ratio = Double(principalInCents) * r / Double(installmentInCents)
        guard ratio < 1 else { return 9_999 }
        let x = -log(1 - ratio) / log(1 + r)
        let whole = x.rounded(.down)
        return max(1, Int(x - whole < 0.01 ? whole : x.rounded(.up)))
    }

    /// 减少月供：期数不变，每期还款额按公式四舍五入到分。
    static func installment(principalInCents: Int64, terms: Int, annualPercent: Double) -> Int64 {
        guard terms > 0 else { return principalInCents }
        let r = annualPercent / 1200
        let p = Double(principalInCents)
        let value = r > 0 ? p * r * pow(1 + r, Double(terms)) / (pow(1 + r, Double(terms)) - 1) : p / Double(terms)
        var decimal = Decimal(value)
        var rounded = Decimal()
        NSDecimalRound(&rounded, &decimal, 0, .plain)
        return NSDecimalNumber(decimal: rounded).int64Value
    }

    static func schedule(principalInCents: Int64, installmentInCents: Int64, terms: Int, annualPercent: Double,
                         firstPeriod: Int, firstDueDate: String, contractNumber: String,
                         dates: BankingDateContext) -> [LoanRepaymentPlanItem] {
        guard terms > 0, let first = dates.date(from: firstDueDate) else { return [] }
        var remaining = principalInCents
        var items: [LoanRepaymentPlanItem] = []
        for index in 0..<terms {
            let interest = interest(principalInCents: remaining, annualPercent: annualPercent)
            let principal = index == terms - 1 ? remaining : min(remaining, installmentInCents - interest)
            remaining -= principal
            let date = dates.calendar.date(byAdding: .month, value: index, to: first) ?? first
            let period = firstPeriod + index
            items.append(LoanRepaymentPlanItem(
                id: "plan_\(period)", contractNumber: contractNumber, period: period,
                date: dates.string(from: date), repaymentAmount: TransferMoney.amount(principal + interest),
                principal: TransferMoney.amount(principal), interest: TransferMoney.amount(interest),
                balance: TransferMoney.amount(remaining)
            ))
        }
        return items
    }

    /// 到期日 = 末期还款日的前一天（yyyy-MM-dd）。
    static func maturityDate(firstDueDate: String, terms: Int, dates: BankingDateContext) -> String {
        guard let first = dates.date(from: firstDueDate),
              let last = dates.calendar.date(byAdding: .month, value: max(0, terms - 1), to: first),
              let maturity = dates.calendar.date(byAdding: .day, value: -1, to: last) else { return firstDueDate }
        return dates.string(from: maturity)
    }

    static func maturityText(_ date: String) -> String {
        let parts = date.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return date }
        return "\(parts[0])年\(parts[1])月\(parts[2])日"
    }

    /// 试算：校验顺序为金额下限 → 小于本金 → 余额。
    static func preview(contract: LoanContract, balanceInCents: Int64, amountInCents: Int64,
                        method: LoanRepaymentMethod, dates: BankingDateContext) throws -> LoanPrepaymentPreview {
        guard amountInCents >= LoanRules.minimumPrepaymentInCents else { throw LoanError.amountInvalid }
        guard let principal = TransferMoney.cents(from: contract.unpaidPrincipal),
              let installment = TransferMoney.cents(from: contract.installmentAmount) else {
            throw LoanError.contractUnavailable
        }
        guard amountInCents < principal else { throw LoanError.amountNotLessThanPrincipal }
        guard amountInCents <= balanceInCents else { throw LoanError.insufficientBalance }
        let rate = contract.annualRatePercent
        let principalAfter = principal - amountInCents
        let termsBefore = contract.remainingTerms
        let termsAfter: Int
        let installmentAfter: Int64
        switch method {
        case .shortenTerm:
            installmentAfter = installment
            termsAfter = terms(principalInCents: principalAfter, installmentInCents: installment, annualPercent: rate)
        case .reduceInstallment:
            termsAfter = termsBefore
            installmentAfter = self.installment(principalInCents: principalAfter, terms: termsAfter, annualPercent: rate)
        }
        let lastBefore = schedule(principalInCents: principal, installmentInCents: installment, terms: termsBefore,
                                  annualPercent: rate, firstPeriod: contract.nextPeriod, firstDueDate: contract.nextDueDate,
                                  contractNumber: contract.contractNumber, dates: dates).last
        let last = schedule(principalInCents: principalAfter, installmentInCents: installmentAfter, terms: termsAfter,
                            annualPercent: rate, firstPeriod: contract.nextPeriod, firstDueDate: contract.nextDueDate,
                            contractNumber: contract.contractNumber, dates: dates).last
        return LoanPrepaymentPreview(
            amountInCents: amountInCents, balanceInCents: balanceInCents,
            principalBefore: principal, principalAfter: principalAfter,
            installmentBefore: installment, installmentAfter: installmentAfter,
            termsBefore: termsBefore, termsAfter: termsAfter,
            maturityBefore: maturityDate(firstDueDate: contract.nextDueDate, terms: termsBefore, dates: dates),
            maturityAfter: maturityDate(firstDueDate: contract.nextDueDate, terms: termsAfter, dates: dates),
            lastInstallmentBefore: lastBefore.flatMap { TransferMoney.cents(from: $0.repaymentAmount) } ?? 0,
            lastInstallmentAfter: last.flatMap { TransferMoney.cents(from: $0.repaymentAmount) } ?? 0
        )
    }
}
