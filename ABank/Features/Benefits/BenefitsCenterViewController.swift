//
//  BenefitsCenterViewController.swift
//  ABank
//
//  权益中心：等级与余额、快捷入口、可领取权益。
//

import UIKit
import SnapKit

final class BenefitsCenterViewController: BenefitsFlowViewController, RouteHosting {
    var hostedRoute: AppRoute? { .benefits }

    override func setupUI() {
        super.setupUI()
        title = "权益中心"
    }

    override func refreshBankingData() {
        clearContent()
        let balance = BalanceCardView(level: benefits.level, points: benefits.balance(.points), beans: benefits.balance(.beans))
        balance.onPointsTapped = { [weak self] in self?.open(.rewardLedger(currency: .points)) }
        balance.onBeansTapped = { [weak self] in self?.open(.rewardLedger(currency: .beans)) }
        balance.onLevelTapped = { [weak self] in self?.open(.customerLevel) }
        contentStack.addArrangedSubview(balance)

        let routes: [AppRoute] = [.pointsMall, .beans, .coupons, .orders]
        let shortcuts = BenefitsShortcutBar(items: [
            ("积分商城", "star.circle.fill", "benefits.entry.mall"),
            ("小豆乐园", "leaf.circle.fill", "benefits.entry.beans"),
            ("我的卡券", "ticket.fill", "benefits.entry.coupons"),
            ("我的订单", "doc.text.fill", "benefits.entry.orders")
        ])
        shortcuts.onSelect = { [weak self] index in self?.open(routes[index]) }
        contentStack.addArrangedSubview(shortcuts)

        addSectionTitle("可领取权益")
        for benefit in BenefitsCatalog.benefits {
            let state = benefits.claimState(of: benefit)
            let trailing: UIView
            if state == .available {
                trailing = benefitsActionButton("领取", id: "benefits.claim.\(benefit.id)") { [weak self] in self?.claim(benefit) }
            } else {
                trailing = BranchStatusTagView(text: state.title, active: false)
            }
            contentStack.addArrangedSubview(BenefitsRow(title: benefit.title, subtitle: benefit.subtitle,
                                                        trailing: trailing, id: "benefits.row.\(benefit.id)"))
        }
        addNotice()
    }

    private func open(_ route: AppRoute) {
        router.open(route, from: self)
    }

    private func claim(_ benefit: Benefit) {
        do {
            try benefits.claim(benefitID: benefit.id)
            showToast("领取成功")
        } catch {
            showError(error)
        }
    }
}
