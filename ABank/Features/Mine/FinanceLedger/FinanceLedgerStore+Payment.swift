//
//  FinanceLedgerStore+Payment.swift
//  ABank
//
//  手机充值与生活缴费：订单放在账本根快照内，扣款、流水与订单一次原子写入。话费券先标记已使用、
//  再写账本；账本写入失败时释放券。同一 `requestID` 重复提交只返回首次订单。
//

import Foundation

extension FinanceLedgerStore {
    // MARK: - 读取

    func paymentOrders() -> [PaymentOrder] {
        load().paymentOrders.enumerated().sorted { lhs, rhs in
            lhs.element.createdAt != rhs.element.createdAt
                ? lhs.element.createdAt > rhs.element.createdAt : lhs.offset > rhs.offset
        }.map(\.element)
    }

    func paymentOrder(id: String) -> PaymentOrder? {
        load().paymentOrders.first { $0.id == id }
    }

    func currentBill(for account: BillAccount) -> UtilityBill {
        PaymentRules.bill(for: account, orders: load().paymentOrders, now: dates.now, dates: dates)
    }

    /// 待使用、属于话费券且面值小于面额的券，保持权益存储的顺序。
    func usableCoupons(forFaceInCents amount: Int64) -> [Coupon] {
        let benefits = benefitsProvider()
        return benefits.coupons.filter { coupon in
            benefits.status(of: coupon) == .unused
                && PaymentRules.usableCouponFaceInCents(templateID: coupon.templateID, faceInCents: amount) != nil
        }
    }

    // MARK: - 手机充值

    /// 校验并返回实付分；不写入、不动券。
    func validateMobileRecharge(phone: String, faceInCents: Int64, couponID: String?) throws -> Int64 {
        try checkedRecharge(phone: phone, faceInCents: faceInCents, couponID: couponID, record: try strictPaymentRecord()).paid
    }

    @discardableResult
    func submitMobileRecharge(phone: String, faceInCents: Int64, couponID: String?, requestID: String,
                              expectedPaidInCents: Int64? = nil) throws -> PaymentOrder {
        guard !requestID.isEmpty, requestID.count <= 100 else { throw PaymentError.invalidRequest }
        var root = try strictPaymentRecord()
        if let existing = root.paymentOrders.first(where: { $0.requestID == requestID }) { return existing }
        let checked = try checkedRecharge(phone: phone, faceInCents: faceInCents, couponID: couponID, record: root)
        // 用户确认的实付金额与此刻重新算出的不一致时拒绝，且在动券之前。
        if let expectedPaidInCents, expectedPaidInCents != checked.paid { throw PaymentError.amountChanged }
        let benefits = benefitsProvider()
        if let couponID {
            do { try benefits.useCoupon(id: couponID) } catch { throw PaymentError.couponUnavailable }
        }
        let now = dates.now
        let timestamp = dates.string(from: now, format: "yyyy-MM-dd HH:mm:ss")
        let id = UUID().uuidString
        let order = PaymentOrder(
            id: id, orderNo: PaymentRules.orderNo(id: id, createdAt: now, dates: dates), requestID: requestID,
            kind: .mobile, targetID: checked.phone, targetTitle: PaymentRules.targetTitle(phone: checked.phone),
            period: nil, faceInCents: faceInCents, couponID: couponID, couponDiscountInCents: checked.couponFace,
            paidInCents: checked.paid, accountID: checked.account.id, createdAt: timestamp, transactionID: "payment_" + id
        )
        root.paymentOrders.append(order)
        root.transactions.append(paymentTransaction(
            order: order, title: "手机充值-" + PaymentRules.maskedPhone(checked.phone), counterparty: "模拟通信服务商",
            summary: "模拟手机充值", account: checked.account, now: now
        ))
        recalculate(&root)
        root.dataTimestamp = timestamp
        do { try persist(root) } catch {
            if let couponID { try? benefits.releaseCoupon(id: couponID) }
            throw PaymentError.persistence
        }
        return order
    }

    // MARK: - 生活缴费

    @discardableResult
    func submitUtilityPayment(billAccountID: String, requestID: String, expectedPeriod: String? = nil,
                              expectedAmountInCents: Int64? = nil) throws -> PaymentOrder {
        guard !requestID.isEmpty, requestID.count <= 100 else { throw PaymentError.invalidRequest }
        var root = try strictPaymentRecord()
        if let existing = root.paymentOrders.first(where: { $0.requestID == requestID }) { return existing }
        guard let billAccount = PaymentCatalog.billAccount(id: billAccountID) else { throw PaymentError.billNotFound }
        let now = dates.now
        let bill = PaymentRules.bill(for: billAccount, orders: root.paymentOrders, now: now, dates: dates)
        // 确认弹窗期间账期跨月或金额变化时拒绝，避免扣款与用户确认的不一致。
        if let expectedPeriod, expectedPeriod != bill.period { throw PaymentError.amountChanged }
        if let expectedAmountInCents, expectedAmountInCents != bill.amountInCents { throw PaymentError.amountChanged }
        guard !bill.isPaid else { throw PaymentError.alreadyPaid }
        let account = try payerAccount(in: root, payingInCents: bill.amountInCents)
        let timestamp = dates.string(from: now, format: "yyyy-MM-dd HH:mm:ss")
        let id = UUID().uuidString
        let order = PaymentOrder(
            id: id, orderNo: PaymentRules.orderNo(id: id, createdAt: now, dates: dates), requestID: requestID,
            kind: billAccount.kind, targetID: billAccount.id, targetTitle: PaymentRules.targetTitle(for: billAccount),
            period: bill.period, faceInCents: bill.amountInCents, couponID: nil, couponDiscountInCents: 0,
            paidInCents: bill.amountInCents, accountID: account.id, createdAt: timestamp, transactionID: "payment_" + id
        )
        root.paymentOrders.append(order)
        root.transactions.append(paymentTransaction(
            order: order, title: billAccount.kind.title + "缴费-" + billAccount.name, counterparty: billAccount.provider,
            summary: "模拟生活缴费", account: account, now: now
        ))
        recalculate(&root)
        root.dataTimestamp = timestamp
        do { try persist(root) } catch { throw PaymentError.persistence }
        return order
    }

    // MARK: - 内部

    private func strictPaymentRecord() throws -> FinanceLedgerRecord {
        do { return try loadForTransfer() } catch { throw PaymentError.corruptLedger }
    }

    /// 付款账户固定为默认人民币借记卡；实付不得超过余额。
    private func payerAccount(in record: FinanceLedgerRecord, payingInCents paid: Int64) throws -> LedgerAccount {
        guard let account = record.accounts.first(where: { $0.id == FinanceLedgerRecord.defaultAccountId }),
              account.currency == "人民币" else { throw PaymentError.invalidRequest }
        guard let balance = TransferMoney.cents(from: account.balance), paid <= balance else {
            throw PaymentError.insufficientBalance
        }
        return account
    }

    private func checkedRecharge(phone: String, faceInCents: Int64, couponID: String?,
                                 record: FinanceLedgerRecord) throws -> (phone: String, couponFace: Int64, paid: Int64, account: LedgerAccount) {
        let normalized = PaymentRules.normalizedPhone(phone)
        guard PaymentRules.isValidPhone(normalized) else { throw PaymentError.invalidPhone }
        guard PaymentCatalog.denominationsInCents.contains(faceInCents) else { throw PaymentError.invalidDenomination }
        var couponFace: Int64 = 0
        if let couponID {
            let benefits = benefitsProvider()
            guard let coupon = benefits.coupon(id: couponID), benefits.status(of: coupon) == .unused,
                  let face = PaymentRules.usableCouponFaceInCents(templateID: coupon.templateID, faceInCents: faceInCents) else {
                throw PaymentError.couponUnavailable
            }
            couponFace = face
        }
        let paid = faceInCents - couponFace
        let account = try payerAccount(in: record, payingInCents: paid)
        return (normalized, couponFace, paid, account)
    }

    private func paymentTransaction(order: PaymentOrder, title: String, counterparty: String, summary: String,
                                    account: LedgerAccount, now: Date) -> LedgerTransaction {
        LedgerTransaction(
            id: order.transactionID, accountId: account.id, date: dates.string(from: now),
            time: dates.string(from: now, format: "HH:mm:ss"), title: title, direction: .expense,
            amount: TransferMoney.amount(order.paidInCents), balanceAfter: 0,
            iconKey: order.kind.iconKey, categoryId: order.kind.categoryId, includeInFlow: true,
            counterpartyName: counterparty, summary: summary, cardNumber: "****" + account.tailNumber,
            transactionType: order.kind.transactionType, channel: "本机模拟"
        )
    }
}
