//
//  FinanceLedgerStore+Wealth.swift
//  ABank
//
//  理财订单的购买、赎回与持仓读取。订单放在账本根快照内，购买/赎回与账户流水一次原子写入；
//  持仓即未赎回的订单，价值与收益在读取时按上海自然日推算。
//

import Foundation

extension FinanceLedgerStore {
    // MARK: - 读取

    func wealthOrders() -> [WealthOrder] {
        load().wealthOrders.enumerated().sorted { lhs, rhs in
            lhs.element.createdAt != rhs.element.createdAt
                ? lhs.element.createdAt > rhs.element.createdAt : lhs.offset > rhs.offset
        }.map(\.element)
    }

    func wealthOrder(id: String) -> WealthOrder? {
        load().wealthOrders.first { $0.id == id }
    }

    func wealthStatus(of order: WealthOrder) -> WealthOrderStatus {
        WealthRules.status(of: order, now: dates.now, dates: dates)
    }

    func accruedInterestInCents(of order: WealthOrder) -> Int64 {
        let days = WealthRules.holdingDays(since: order.createdAt, now: dates.now, dates: dates)
        return WealthRules.accruedInterestInCents(principal: order.principalInCents,
                                                  rateBasisPoints: order.rateBasisPoints, days: days)
    }

    func holdingValueInCents(of order: WealthOrder) -> Int64 {
        WealthRules.holdingValueInCents(of: order, now: dates.now, dates: dates)
    }

    func totalHoldingValueInCents() -> Int64 {
        holdingValueInCents(in: load())
    }

    func holdingValueInCents(in record: FinanceLedgerRecord) -> Int64 {
        record.wealthOrders.reduce(0) { $0 + WealthRules.holdingValueInCents(of: $1, now: dates.now, dates: dates) }
    }

    /// 资产负债页“理财”类别；没有未赎回订单时返回 nil。
    func wealthAssetCategory(in record: FinanceLedgerRecord) -> AssetLiabilityCategory? {
        let holding = record.wealthOrders.filter { $0.redeemedAt == nil }
        guard !holding.isEmpty else { return nil }
        let items = holding.map { order -> AssetLiabilityItem in
            let value = WealthRules.holdingValueInCents(of: order, now: dates.now, dates: dates)
            return AssetLiabilityItem(
                id: order.id, title: order.productName, amount: TransferMoney.amount(value),
                showsCurrencySymbol: true,
                subtitle: "本金 \(TransferMoney.text(order.principalInCents)) · 收益 \(TransferMoney.text(value - order.principalInCents))",
                showsMenu: false
            )
        }
        return AssetLiabilityCategory(id: FinanceLedgerRecord.wealthCategoryId, title: "理财",
                                      totalAmount: TransferMoney.amount(holdingValueInCents(in: record)), items: items)
    }

    // MARK: - 购买

    func validateWealthPurchase(productID: String, amountInCents: Int64) throws {
        _ = try checkedPurchase(productID: productID, amountInCents: amountInCents, record: try strictRecord())
    }

    @discardableResult
    func submitWealthPurchase(productID: String, amountInCents: Int64, requestID: String) throws -> WealthOrder {
        guard !requestID.isEmpty, requestID.count <= 100 else { throw WealthError.invalidRequest }
        var root = try strictRecord()
        if let existing = root.wealthOrders.first(where: { $0.requestID == requestID }) { return existing }
        let (product, account) = try checkedPurchase(productID: productID, amountInCents: amountInCents, record: root)
        let now = dates.now
        let timestamp = dates.string(from: now, format: "yyyy-MM-dd HH:mm:ss")
        let id = UUID().uuidString
        let transactionID = "wealth_buy_" + id
        let order = WealthOrder(
            id: id, requestID: requestID, productID: product.id, productName: product.name, accountID: account.id,
            principalInCents: amountInCents, rateBasisPoints: product.rateBasisPoints, minHoldDays: product.minHoldDays,
            createdAt: timestamp, purchaseTransactionID: transactionID,
            redeemedAt: nil, redeemedAmountInCents: nil, redeemTransactionID: nil
        )
        root.wealthOrders.append(order)
        root.transactions.append(wealthTransaction(
            id: transactionID, title: "理财购买-" + product.name, direction: .expense, cents: amountInCents,
            type: "理财购买", summary: "模拟理财购买", account: account, now: now
        ))
        recalculate(&root)
        root.dataTimestamp = timestamp
        do { try persist(root) } catch { throw WealthError.persistence }
        return order
    }

    // MARK: - 赎回

    @discardableResult
    func redeemWealthOrder(orderID: String) throws -> WealthOrder {
        var root = try strictRecord()
        guard let index = root.wealthOrders.firstIndex(where: { $0.id == orderID }) else { throw WealthError.orderNotFound }
        var order = root.wealthOrders[index]
        guard order.redeemedAt == nil else { throw WealthError.alreadyRedeemed }
        let now = dates.now
        let days = WealthRules.holdingDays(since: order.createdAt, now: now, dates: dates)
        guard days >= order.minHoldDays else { throw WealthError.notRedeemable }
        guard let account = root.accounts.first(where: { $0.id == order.accountID }) else { throw WealthError.invalidRequest }
        let amount = order.principalInCents
            + WealthRules.accruedInterestInCents(principal: order.principalInCents, rateBasisPoints: order.rateBasisPoints, days: days)
        let timestamp = dates.string(from: now, format: "yyyy-MM-dd HH:mm:ss")
        let transactionID = "wealth_redeem_" + order.id
        order.redeemedAt = timestamp
        order.redeemedAmountInCents = amount
        order.redeemTransactionID = transactionID
        root.wealthOrders[index] = order
        root.transactions.append(wealthTransaction(
            id: transactionID, title: "理财赎回-" + order.productName, direction: .income, cents: amount,
            type: "理财赎回", summary: "模拟理财赎回", account: account, now: now
        ))
        recalculate(&root)
        root.dataTimestamp = timestamp
        do { try persist(root) } catch { throw WealthError.persistence }
        return order
    }

    // MARK: - 内部

    private func strictRecord() throws -> FinanceLedgerRecord {
        do { return try loadForTransfer() } catch { throw WealthError.corruptLedger }
    }

    private func checkedPurchase(productID: String, amountInCents: Int64,
                                 record: FinanceLedgerRecord) throws -> (WealthProduct, LedgerAccount) {
        guard let product = WealthProductCatalog.product(id: productID) else { throw WealthError.productNotFound }
        switch riskStateProvider() {
        case .none: throw WealthError.assessmentRequired
        case .expired: throw WealthError.assessmentExpired
        case .valid(let profile, _):
            guard WealthRules.canBuy(product, with: profile) else { throw WealthError.riskLevelTooLow }
        }
        guard amountInCents > 0 else { throw WealthError.invalidAmount }
        guard amountInCents >= product.minPurchaseInCents else { throw WealthError.belowMinimum }
        guard amountInCents <= WealthRules.maxPurchaseInCents else { throw WealthError.aboveMaximum }
        guard let account = record.accounts.first(where: { $0.id == FinanceLedgerRecord.defaultAccountId }),
              account.currency == "人民币" else { throw WealthError.invalidRequest }
        guard let balance = TransferMoney.cents(from: account.balance), amountInCents <= balance else {
            throw WealthError.insufficientBalance
        }
        return (product, account)
    }

    private func wealthTransaction(id: String, title: String, direction: LedgerTransactionDirection, cents: Int64,
                                   type: String, summary: String, account: LedgerAccount, now: Date) -> LedgerTransaction {
        LedgerTransaction(
            id: id, accountId: account.id, date: dates.string(from: now), time: dates.string(from: now, format: "HH:mm:ss"),
            title: title, direction: direction, amount: TransferMoney.amount(cents), balanceAfter: 0,
            iconKey: "wealth", categoryId: "wealth_product", includeInFlow: false,
            counterpartyName: "农银理财（模拟）", summary: summary, cardNumber: "****" + account.tailNumber,
            transactionType: type, channel: "本机模拟"
        )
    }
}
