//
//  RewardMallViewController.swift
//  ABank
//
//  积分商城与小豆乐园共用：余额条、（小豆）签到卡、商品列表。
//

import UIKit
import SnapKit

final class RewardMallViewController: BenefitsFlowViewController, RouteHosting {
    private let currency: RewardCurrency

    var hostedRoute: AppRoute? { currency == .points ? .pointsMall : .beans }

    init(currency: RewardCurrency, benefits: BenefitsStore = .shared, dates: BankingDateContext = .system) {
        self.currency = currency
        super.init(benefits: benefits, dates: dates)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = currency == .points ? "积分商城" : "小豆乐园"
    }

    override func refreshBankingData() {
        clearContent()
        let balance = BenefitsRow(title: "我的\(currency.title) \(formattedAmount(benefits.balance(currency)))",
                                  subtitle: "查看\(currency.title)明细", id: "mall.balance", showsChevron: true)
        balance.onTap = { [weak self] in
            guard let self else { return }
            self.router.open(.rewardLedger(currency: self.currency), from: self)
        }
        contentStack.addArrangedSubview(balance)

        if currency == .beans {
            let card = CheckInCardView(streak: benefits.checkInStreak, todayReward: benefits.nextCheckInReward,
                                       checkedIn: benefits.hasCheckedInToday, rewards: BenefitsRules.checkInRewards)
            card.onCheckIn = { [weak self] in self?.checkIn() }
            contentStack.addArrangedSubview(card)
        }

        addSectionTitle(currency == .points ? "积分兑好礼" : "小豆兑好礼")
        for goods in BenefitsCatalog.goods(in: currency) {
            guard let template = BenefitsCatalog.template(id: goods.templateID) else { continue }
            let remaining = max(0, goods.monthlyLimit - benefits.redeemedCount(goodsID: goods.id))
            contentStack.addArrangedSubview(goodsRow(goods: goods, template: template, remaining: remaining) { [weak self] in
                guard let self else { return }
                self.router.open(.goodsDetail(goodsID: goods.id), from: self)
            })
        }
        addNotice()
    }

    private func checkIn() {
        do {
            let reward = try benefits.checkIn()
            showToast("签到成功，获得 \(reward) 小豆")
        } catch {
            showError(error)
        }
    }
}
