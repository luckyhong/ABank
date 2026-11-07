//
//  CustomerLevelViewController.swift
//  ABank
//
//  客户等级（只读）：由累计获得积分推算，显示进度与各等级权益对比。
//

import UIKit
import SnapKit

final class CustomerLevelViewController: BenefitsFlowViewController, RouteHosting {
    var hostedRoute: AppRoute? { .customerLevel }

    override func setupUI() {
        super.setupUI()
        title = "客户等级"
    }

    override func refreshBankingData() {
        clearContent()
        let level = benefits.level
        let earned = benefits.lifetimeEarnedPoints

        let name = UILabel()
        name.text = level.title
        name.font = .systemFont(ofSize: 26, weight: .semibold)
        name.textColor = .abankPrimary
        name.accessibilityIdentifier = "level.current"
        var views: [UIView] = [name, branchCaption("累计获得积分 \(formattedAmount(earned))")]
        if let next = level.next {
            let progress = UIProgressView(progressViewStyle: .default)
            progress.progressTintColor = .abankPrimary
            progress.trackTintColor = .abankSeparator
            let span = Float(next.threshold - level.threshold)
            progress.progress = min(1, max(0, Float(earned - level.threshold) / span))
            views.append(progress)
            views.append(branchCaption("距\(next.shortTitle)客户还差 \(formattedAmount(next.threshold - earned)) 积分"))
        } else {
            views.append(branchCaption("已是最高等级"))
        }
        addCard(views)

        addSectionTitle("等级权益对比")
        let rows = CustomerLevel.allCases.map { item -> UIView in
            let count = BenefitsCatalog.benefits.filter { $0.minLevel <= item }.count
            let title = item.title + (item == level ? "（当前）" : "")
            return TransferInfoRow(title, value: "≥ \(formattedAmount(item.threshold)) 积分 · \(count) 项权益")
        }
        addGroup(rows)
        addCaption("兑换或取消订单不影响累计获得积分。")
    }

    private func addCaption(_ text: String) {
        contentStack.addArrangedSubview(branchCaption(text))
    }
}
