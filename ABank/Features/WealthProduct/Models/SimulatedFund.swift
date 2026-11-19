import Foundation

enum SimulatedFund {
    static let name = "ABank 模拟稳健混合基金"
    static let minimumCents: Int64 = 100
    static let risk: ProductRiskLevel = .r2

    struct Quote: Equatable {
        let day: String
        let nav: Int64

        var navText: String { SimulatedFund.decimalText(nav) }
        var caption: String { "模拟净值 · \(day)" }
    }

    static func quote(dates: BankingDateContext) -> Quote {
        let day = dates.string(from: dates.now)
        return Quote(day: day, nav: nav(on: day, dates: dates))
    }

    // Four decimal places in both NAV and units. The fixed cycle is independent of public quotes.
    static func nav(on day: String, dates: BankingDateContext) -> Int64 {
        let prices: [Int64] = [10_000, 10_120, 9_950, 10_250, 10_050]
        let origin = dates.date(from: "2026-11-18")!
        let offset = dates.calendar.dateComponents([.day], from: origin, to: dates.date(from: day) ?? origin).day ?? 0
        return prices[(offset % prices.count + prices.count) % prices.count]
    }

    static func confirmationDay(dates: BankingDateContext) -> String {
        let today = dates.calendar.startOfDay(for: dates.now)
        return dates.string(from: dates.calendar.date(byAdding: .day, value: 1, to: today)!)
    }

    static func units(for cents: Int64, nav: Int64) -> Int64 {
        cents * 1_000_000 / nav
    }

    static func value(of units: Int64, nav: Int64) -> Int64 {
        (units * nav + 500_000) / 1_000_000
    }

    static func decimalText(_ fourDecimals: Int64) -> String {
        String(format: "%.4f", Double(fourDecimals) / 10_000)
    }
}

struct FundOrder: Codable, Equatable, Identifiable {
    let id: String
    let accountID: String
    let submittedAt: String
    let confirmationDay: String
    let amount: Int64
    var units: Int64?
    var purchaseNAV: Int64?
    var redemptionDay: String?
    var redeemedAt: String?
    var redemptionNAV: Int64?
    var redemptionAmount: Int64?

    var status: String {
        if redeemedAt != nil { return "已到账" }
        if redemptionDay != nil { return "赎回待确认" }
        return units == nil ? "申购待确认" : "持有中"
    }

    var canRedeem: Bool { units != nil && redemptionDay == nil }
}

extension FinanceLedgerStore {
    func fundOrders() -> [FundOrder] { load().fundOrders.reversed() }

    func subscribeFund(amount: Int64, accountID: String, requestID: String) throws -> FundOrder {
        var root = try loadForTransfer()
        if let order = root.fundOrders.first(where: { $0.id == requestID }) { return order }
        guard !requestID.isEmpty else { throw WealthError.invalidRequest }
        switch riskStateProvider() {
        case .none: throw WealthError.assessmentRequired
        case .expired: throw WealthError.assessmentExpired
        case .valid(let profile, _):
            guard profile >= SimulatedFund.risk.requiredProfile else { throw WealthError.riskLevelTooLow }
        }
        guard amount >= SimulatedFund.minimumCents else { throw WealthError.belowMinimum }
        guard amount <= WealthRules.maxPurchaseInCents else { throw WealthError.aboveMaximum }
        guard let account = root.accounts.first(where: { $0.id == accountID && $0.currency == "人民币" }) else {
            throw WealthError.invalidRequest
        }
        guard !account.isReportedLost else { throw AccountSettingsError.cardReportedLost }
        guard let balance = TransferMoney.cents(from: account.balance), balance >= amount else { throw WealthError.insufficientBalance }
        let now = dates.now
        let timestamp = dates.string(from: now, format: "yyyy-MM-dd HH:mm:ss")
        let order = FundOrder(id: requestID, accountID: accountID, submittedAt: timestamp,
                              confirmationDay: SimulatedFund.confirmationDay(dates: dates), amount: amount)
        root.fundOrders.append(order)
        root.transactions.append(fundTransaction(id: "fund_buy_" + order.id, account: account, amount: amount, direction: .expense, now: now))
        try saveFundChanges(&root, now: now)
        return order
    }

    func requestFundRedemption(orderID: String) throws {
        var root = try loadForTransfer()
        guard let index = root.fundOrders.firstIndex(where: { $0.id == orderID }) else { throw WealthError.orderNotFound }
        if root.fundOrders[index].redemptionDay != nil { return }
        guard root.fundOrders[index].canRedeem else { throw WealthError.notRedeemable }
        root.fundOrders[index].redemptionDay = SimulatedFund.confirmationDay(dates: dates)
        try saveFundChanges(&root, now: dates.now)
    }

    func settleDueFundOrders() throws {
        var root = try loadForTransfer()
        let now = dates.now
        let today = dates.string(from: now)
        var changed = false
        for index in root.fundOrders.indices {
            let order = root.fundOrders[index]
            if order.units == nil, order.confirmationDay <= today {
                let nav = SimulatedFund.nav(on: order.confirmationDay, dates: dates)
                root.fundOrders[index].units = SimulatedFund.units(for: order.amount, nav: nav)
                root.fundOrders[index].purchaseNAV = nav
                changed = true
            } else if let day = order.redemptionDay, day <= today, let units = order.units, order.redeemedAt == nil,
                      let account = root.accounts.first(where: { $0.id == order.accountID }) {
                let nav = SimulatedFund.nav(on: day, dates: dates)
                let amount = SimulatedFund.value(of: units, nav: nav)
                root.fundOrders[index].redeemedAt = dates.string(from: now, format: "yyyy-MM-dd HH:mm:ss")
                root.fundOrders[index].redemptionNAV = nav
                root.fundOrders[index].redemptionAmount = amount
                root.transactions.append(fundTransaction(id: "fund_redeem_" + order.id, account: account, amount: amount,
                                                         direction: .income, now: now))
                changed = true
            }
        }
        if changed { try saveFundChanges(&root, now: now) }
    }

    func fundValue(of order: FundOrder) -> Int64 {
        guard order.redeemedAt == nil else { return 0 }
        guard let units = order.units else { return order.amount }
        let today = dates.string(from: dates.now)
        let valuationDay = min(today, order.redemptionDay ?? today)
        return SimulatedFund.value(of: units, nav: SimulatedFund.nav(on: valuationDay, dates: dates))
    }

    private func saveFundChanges(_ root: inout FinanceLedgerRecord, now: Date) throws {
        recalculate(&root)
        root.dataTimestamp = dates.string(from: now, format: "yyyy-MM-dd HH:mm:ss")
        do { try persist(root) } catch { throw WealthError.persistence }
    }

    private func fundTransaction(id: String, account: LedgerAccount, amount: Int64,
                                 direction: LedgerTransactionDirection, now: Date) -> LedgerTransaction {
        let summary = direction == .expense ? "基金申购" : "基金赎回"
        return LedgerTransaction(id: id, accountId: account.id, date: dates.string(from: now),
            time: dates.string(from: now, format: "HH:mm:ss"), title: summary + "-" + SimulatedFund.name,
            direction: direction, amount: TransferMoney.amount(amount), balanceAfter: 0, iconKey: "wealth",
            categoryId: "wealth_product", includeInFlow: false, counterpartyName: SimulatedFund.name,
            summary: summary, cardNumber: account.maskedCardNumber, transactionType: summary, channel: "手机银行")
    }
}
