//
//  WealthPurchaseViewController.swift
//  ABank
//
//  购买页：付款账户与余额、金额输入、风险揭示；确认后提交，成功进入订单详情。
//  `requestID` 在页面创建（及每次成功后）生成，重复点击不会重复成交。
//

import UIKit
import SnapKit

final class WealthPurchaseViewController: WealthFlowViewController, RouteHosting {
    private let productID: String
    private var requestID = UUID().uuidString
    private let amountRow = TransferInputRow("购买金额", placeholder: "请输入金额（元）", id: "wealth.amount", keyboard: .decimalPad)
    private let agreeSwitch = UISwitch()
    private let errorLabel = UILabel()
    private var submitButton: UIButton?

    var hostedRoute: AppRoute? { .wealthPurchase(productID: productID) }

    init(productID: String, ledger: FinanceLedgerStore = .shared, risk: RiskAssessmentStore = .shared,
         dates: BankingDateContext = .system) {
        self.productID = productID
        super.init(ledger: ledger, risk: risk, dates: dates)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "购买"
        amountRow.field.addAction(UIAction { [weak self] _ in self?.inputDidChange() }, for: .editingChanged)
        agreeSwitch.accessibilityIdentifier = "wealth.agree"
        agreeSwitch.addAction(UIAction { [weak self] _ in self?.inputDidChange() }, for: .valueChanged)
        errorLabel.font = .abankCaption()
        errorLabel.textColor = .abankError
        errorLabel.numberOfLines = 0
        errorLabel.accessibilityIdentifier = "wealth.error"
        errorLabel.isHidden = true
    }

    override func refreshBankingData() {
        clearContent()
        guard let product = WealthProductCatalog.product(id: productID) else {
            addEmptyState("产品不存在", id: "wealth.missing")
            return
        }
        let name = UILabel()
        name.text = product.name
        name.font = .abankBodyMedium()
        name.textColor = .abankTextPrimary
        name.numberOfLines = 0
        addCard([name, branchCaption("\(product.risk.shortTitle) \(product.risk.title) · 年化 \(product.rateText) · 最低持有 \(product.minHoldDays) 天")])

        let account = ledger.load().accounts.first { $0.id == FinanceLedgerRecord.defaultAccountId }
        let balance = account.flatMap { TransferMoney.cents(from: $0.balance) } ?? 0
        addGroup([
            TransferInfoRow("付款账户", value: account.map { "借记卡 尾号\($0.tailNumber)" } ?? "无可用账户"),
            TransferInfoRow("可用余额", value: "\(wealthMoneyText(balance)) 元"),
            amountRow
        ])
        contentStack.addArrangedSubview(errorLabel)
        contentStack.addArrangedSubview(branchCaption("起购 \(wealthMoneyText(product.minPurchaseInCents)) 元，单笔最高 \(wealthMoneyText(WealthRules.maxPurchaseInCents)) 元；预计 \(redeemableDayText(product)) 起可赎回。"))

        let agreeLabel = UILabel()
        agreeLabel.text = "我已阅读并理解风险提示：理财产品过往业绩不代表未来表现，投资须谨慎。"
        agreeLabel.font = .abankCaption()
        agreeLabel.textColor = .abankTextSecondary
        agreeLabel.numberOfLines = 0
        let agree = UIStackView(arrangedSubviews: [agreeLabel, agreeSwitch])
        agree.spacing = Spacing.sm
        agree.alignment = .center
        contentStack.addArrangedSubview(agree)

        submitButton = addButton("确认购买", id: "wealth.submit") { [weak self] in self?.submitTapped(product) }
        addNotice("本机模拟 · 不发生真实资金交易")
        inputDidChange()
    }

    private func redeemableDayText(_ product: WealthProduct) -> String {
        let start = dates.calendar.startOfDay(for: dates.now)
        let day = dates.calendar.date(byAdding: .day, value: product.minHoldDays, to: start)!
        return dates.string(from: day)
    }

    /// 返回错误文案；金额为空返回 nil（仅禁用，不提示）。
    private func currentError(_ product: WealthProduct) -> (message: String?, cents: Int64?) {
        let text = amountRow.field.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !text.isEmpty else { return (nil, nil) }
        guard let cents = TransferMoney.parse(text) else { return (WealthError.invalidAmount.localizedDescription, nil) }
        do {
            try ledger.validateWealthPurchase(productID: product.id, amountInCents: cents)
            return (nil, cents)
        } catch {
            return (error.localizedDescription, nil)
        }
    }

    private func inputDidChange() {
        guard let product = WealthProductCatalog.product(id: productID) else { return }
        let result = currentError(product)
        errorLabel.text = result.message
        errorLabel.isHidden = result.message == nil
        let enabled = result.cents != nil && agreeSwitch.isOn
        submitButton?.isEnabled = enabled
        submitButton?.backgroundColor = enabled ? .abankTeal : .abankTextTertiary
    }

    private func submitTapped(_ product: WealthProduct) {
        guard let cents = currentError(product).cents else { return }
        confirm("确认购买 \(wealthMoneyText(cents)) 元「\(product.name)」？", confirmTitle: "确认购买") { [weak self] in
            self?.submit(product, cents: cents)
        }
    }

    private func submit(_ product: WealthProduct, cents: Int64) {
        do {
            let order = try ledger.submitWealthPurchase(productID: product.id, amountInCents: cents, requestID: requestID)
            requestID = UUID().uuidString
            amountRow.field.text = ""
            agreeSwitch.isOn = false
            router.open(.wealthOrderDetail(orderID: order.id, justPurchased: true), from: self)
        } catch {
            showError(error)
        }
    }
}
