//
//  WealthProductDetailViewController.swift
//  ABank
//
//  产品详情：年化、风险等级、持有期、起购额；购买前检查风险测评并引导。
//

import UIKit
import SnapKit

final class WealthProductDetailViewController: WealthFlowViewController, RouteHosting {
    private let productID: String
    private var accountID: String?

    var hostedRoute: AppRoute? { .wealthProductDetail(productID: productID) }

    init(productID: String, accountID: String? = nil, ledger: FinanceLedgerStore = .shared, risk: RiskAssessmentStore = .shared,
         dates: BankingDateContext = .system) {
        self.productID = productID
        self.accountID = accountID
        super.init(ledger: ledger, risk: risk, dates: dates)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "产品详情"
    }

    override func refreshBankingData() {
        clearContent()
        guard let product = WealthProductCatalog.product(id: productID) else {
            addEmptyState("产品不存在", id: "wealth.missing")
            return
        }
        let name = UILabel()
        name.text = product.name
        name.font = .abankTitle3()
        name.textColor = .abankTextPrimary
        name.numberOfLines = 0
        let rate = UILabel()
        rate.text = product.rateText
        rate.font = .systemFont(ofSize: 32, weight: .semibold)
        rate.textColor = .abankHighlight
        addCard([name, rate, branchCaption("年化收益率")])

        addGroup([
            TransferInfoRow("风险等级", value: "\(product.risk.shortTitle) \(product.risk.title)"),
            TransferInfoRow("产品分类", value: product.category.title),
            TransferInfoRow("最低持有", value: "\(product.minHoldDays) 天"),
            TransferInfoRow("起购金额", value: "\(wealthMoneyText(product.minPurchaseInCents)) 元")
        ])
        contentStack.addArrangedSubview(BankingReadSection(title: "产品简介", body: product.summary + "\n持有满\(product.minHoldDays)天后可赎回，本息返回原付款账户。"))
        contentStack.addArrangedSubview(BankingReadSection(title: "风险提示", body: "理财产品过往业绩不代表其未来表现，不等于理财产品实际收益。请根据风险承受能力选择产品。"))
        _ = addButton("立即购买", id: "wealth.buy") { [weak self] in self?.buyTapped(product) }
        addNotice("请核对账户与交易信息后办理")
    }

    private func buyTapped(_ product: WealthProduct) {
        let message: String?
        switch risk.state {
        case .none:
            message = "购买前需先完成风险测评。"
        case .expired:
            message = "您的风险测评已过期，请重新测评。"
        case .valid(let profile, _):
            message = WealthRules.canBuy(product, with: profile) ? nil
                : "您的风险承受等级为\(profile.title)（\(profile.shortTitle)），低于该产品风险等级\(product.risk.shortTitle)，请重新测评或选择其他产品。"
        }
        if let message {
            confirm(message, confirmTitle: "去测评") { [weak self] in
                guard let self else { return }
                self.router.open(.riskAssessment, from: self)
            }
        } else {
            router.open(accountID.map { .wealthAccountPurchase(productID: product.id, accountID: $0) } ?? .wealthPurchase(productID: product.id), from: self)
        }
    }
}
