import UIKit

final class FundViewController: WealthFlowViewController, RouteHosting {
    override var maximumContentWidth: CGFloat? { 560 }

    private let amountRow = TransferInputRow("申购金额", placeholder: wealthPurchaseMinimumText(SimulatedFund.minimumCents),
                                             id: "fund.amount", keyboard: .decimalPad)
    private var accountID = FinanceLedgerRecord.defaultAccountId
    private var requestID = UUID().uuidString
    var hostedRoute: AppRoute? { .fund }

    override func refreshBankingData() {
        clearContent()
        title = "基金"
        let quote = SimulatedFund.quote(dates: dates)
        let product = BankingPageStyle.text(SimulatedFund.name, style: .title3)
        let nav = BankingPageStyle.text(quote.navText, style: .title2, color: .abankMintInk)
        let productRisk = SimulatedFund.risk
        let metadata = BankingPageStyle.text("\(quote.caption)\n\(productRisk.shortTitle) \(productRisk.title)",
                                             style: .footnote, color: .abankTextSecondary)
        contentStack.addArrangedSubview(BankingPageStyle.surface([product, nav, metadata], spacing: Spacing.sm))
        addNotice("申购和全额赎回均按北京时间次日的模拟净值确认，免手续费。")
        addGroup([
            BankingAccountPickerRow(account: ledger.account(id: accountID), id: "fund.payer") { [weak self] in
                guard let self else { return }
                BankingAccountPickerRow.choose(from: self, ledger: self.ledger, selected: self.accountID) { [weak self] in
                    self?.accountID = $0
                    self?.refreshBankingData()
                }
            },
            amountRow
        ])
        if case .valid(let profile, _) = risk.state, profile >= SimulatedFund.risk.requiredProfile {
            _ = addButton("申购", id: "fund.subscribe") { [weak self] in self?.confirmPurchase() }
        } else {
            _ = addButton("完成风险测评", id: "fund.assessment") { [weak self] in
                guard let self else { return }
                self.router.open(.riskAssessment, from: self)
            }
        }
        if let previous = contentStack.arrangedSubviews.last { contentStack.setCustomSpacing(Spacing.lg, after: previous) }
        addSectionTitle("基金订单")
        let orders = ledger.fundOrders()
        if orders.isEmpty {
            addEmptyState("暂无基金订单", id: "fund.empty")
        }
        for order in orders {
            let row = BenefitsRow(title: order.status, subtitle: order.submittedAt + " · " + TransferMoney.text(order.amount) + " 元",
                                  trailing: nil, id: "fund.order." + order.id, showsChevron: true, scalesType: true)
            row.onTap = { [weak self] in
                guard let self else { return }
                self.router.open(.fundOrder(id: order.id), from: self)
            }
            contentStack.addArrangedSubview(row)
        }
    }

    private func confirmPurchase() {
        guard let amount = TransferMoney.parse(amountRow.field.text ?? "") else { return showError(WealthError.invalidAmount) }
        let payer = accountID
        view.endEditing(true)
        let accountLabel = ledger.account(id: payer)?.cardLabel ?? "—"
        confirm("从\(accountLabel)扣款 \(TransferMoney.text(amount)) 元。次日按模拟净值确认。",
                confirmTitle: "确认申购") { [weak self] in
            guard let self else { return }
            do {
                let order = try self.ledger.subscribeFund(amount: amount, accountID: payer, requestID: self.requestID)
                self.requestID = UUID().uuidString
                self.amountRow.field.text = nil
                self.router.open(.fundOrder(id: order.id), from: self)
            } catch { self.showError(error) }
        }
    }
}

final class FundOrderViewController: WealthFlowViewController, RouteHosting {
    override var maximumContentWidth: CGFloat? { 560 }

    private let id: String
    var hostedRoute: AppRoute? { .fundOrder(id: id) }

    init(id: String, ledger: FinanceLedgerStore) {
        self.id = id
        super.init(ledger: ledger, dates: ledger.dates)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func refreshBankingData() {
        clearContent()
        title = "基金订单"
        guard let order = ledger.fundOrders().first(where: { $0.id == id }) else {
            return addEmptyState("基金订单不存在", id: "fund.order.missing")
        }
        let headlineLabel: String
        let headlineAmount: Int64
        if let redeemed = order.redemptionAmount {
            headlineLabel = "到账金额"
            headlineAmount = redeemed
        } else if order.units != nil {
            headlineLabel = "模拟市值"
            headlineAmount = ledger.fundValue(of: order)
        } else {
            headlineLabel = "申购金额"
            headlineAmount = order.amount
        }
        contentStack.addArrangedSubview(BankingPageStyle.amountSummary(
            "¥ " + TransferMoney.text(headlineAmount), label: headlineLabel, status: order.status, detail: SimulatedFund.name,
            statusColor: order.canRedeem || order.redeemedAt != nil ? .abankMintInk : .abankTextSecondary))
        var rows: [UIView] = [
            TransferInfoRow("确认日期", value: order.confirmationDay),
            TransferInfoRow("资金账户", value: ledger.account(id: order.accountID)?.cardLabel ?? "—")
        ]
        if let units = order.units, let nav = order.purchaseNAV {
            rows.insert(TransferInfoRow("申购金额", value: TransferMoney.text(order.amount) + " 元"), at: 0)
            rows.append(TransferInfoRow("确认份额", value: SimulatedFund.decimalText(units) + " 份"))
            rows.append(TransferInfoRow("申购净值", value: SimulatedFund.decimalText(nav)))
        }
        if let day = order.redemptionDay {
            rows.append(TransferInfoRow("赎回确认日", value: day))
        }
        if let nav = order.redemptionNAV {
            rows.append(TransferInfoRow("赎回净值", value: SimulatedFund.decimalText(nav)))
        }
        addGroup(rows)
        if order.canRedeem {
            _ = addButton("全部赎回", id: "fund.redeem") { [weak self] in
                self?.confirm("赎回该笔申购的全部份额，次日确认后资金回到原付款账户。", confirmTitle: "确认赎回") { [weak self] in
                    guard let self else { return }
                    do { try self.ledger.requestFundRedemption(orderID: self.id) }
                    catch { self.showError(error) }
                }
            }
        }
    }
}
