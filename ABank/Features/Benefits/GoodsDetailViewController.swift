//
//  GoodsDetailViewController.swift
//  ABank
//
//  商品详情：卡券说明、标价、余额与兑换后余额；确认后兑换并进入订单详情。
//

import UIKit
import SnapKit

final class GoodsDetailViewController: BenefitsFlowViewController, RouteHosting {
    private let goodsID: String

    var hostedRoute: AppRoute? { .goodsDetail(goodsID: goodsID) }

    init(goodsID: String, benefits: BenefitsStore = .shared, dates: BankingDateContext = .system) {
        self.goodsID = goodsID
        super.init(benefits: benefits, dates: dates)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "商品详情"
    }

    override func refreshBankingData() {
        clearContent()
        guard let goods = BenefitsCatalog.goods(id: goodsID), let template = BenefitsCatalog.template(id: goods.templateID) else {
            addEmptyState("商品不存在", id: "goods.missing")
            return
        }
        let currency = goods.currency
        let balance = benefits.balance(currency)
        let remaining = max(0, goods.monthlyLimit - benefits.redeemedCount(goodsID: goods.id))

        let name = UILabel()
        name.text = template.title
        name.font = .abankTitle3()
        name.textColor = .abankTextPrimary
        name.numberOfLines = 0
        let price = UILabel()
        price.text = formattedAmount(goods.price) + " " + currency.unit
        price.font = .systemFont(ofSize: 24, weight: .semibold)
        price.textColor = currency.tint
        addCard([name, branchCaption(template.brand + " · " + template.faceText), price])

        addGroup([
            TransferInfoRow("当前\(currency.title)", value: formattedAmount(balance)),
            TransferInfoRow("兑换后\(currency.title)", value: balance >= goods.price ? formattedAmount(balance - goods.price) : "—"),
            TransferInfoRow("有效期", value: "兑换后 \(template.validDays) 天"),
            TransferInfoRow("本月可兑", value: "还剩 \(remaining) 次（每月限 \(goods.monthlyLimit) 次）")
        ])
        addCard([branchCaption("使用说明"), branchCaption(template.note, color: .abankTextPrimary)])

        let redeemTitle: String
        if remaining == 0 {
            redeemTitle = "本月兑换次数已达上限"
        } else if balance < goods.price {
            redeemTitle = "\(currency.title)不足"
        } else {
            redeemTitle = "立即兑换"
        }
        let button = addButton(redeemTitle, id: "goods.redeem") { [weak self] in
            self?.confirm("确认用 \(formattedAmount(goods.price)) \(currency.unit)兑换「\(template.title)」？", confirmTitle: "兑换") {
                self?.redeem(goods)
            }
        }
        if remaining == 0 || balance < goods.price {
            button.isEnabled = false
            button.backgroundColor = .abankTextTertiary
        }
        addNotice()
    }

    private func redeem(_ goods: RewardGoods) {
        do {
            let order = try benefits.redeem(goodsID: goods.id)
            router.open(.orderDetail(orderID: order.id, justRedeemed: true), from: self)
        } catch {
            showError(error)
        }
    }
}
