//
//  CouponsViewController.swift
//  ABank
//
//  我的卡券：待使用 / 已使用 / 已失效（已过期与已作废）三段。
//

import UIKit
import SnapKit

final class CouponsViewController: BenefitsFlowViewController, RouteHosting {
    private var segment = 0

    var hostedRoute: AppRoute? { .coupons }

    override func setupUI() {
        super.setupUI()
        title = "我的卡券"
    }

    private func matches(_ status: CouponStatus) -> Bool {
        switch segment {
        case 0: return status == .unused
        case 1: return status == .used
        default: return status == .expired || status == .voided
        }
    }

    override func refreshBankingData() {
        clearContent()
        let control = UISegmentedControl(items: ["待使用", "已使用", "已失效"])
        control.selectedSegmentIndex = segment
        control.accessibilityIdentifier = "coupons.segment"
        control.addAction(UIAction { [weak self, weak control] _ in
            self?.segment = control?.selectedSegmentIndex ?? 0
            self?.refreshBankingData()
        }, for: .valueChanged)
        contentStack.addArrangedSubview(control)

        let visible = benefits.coupons.filter { matches(benefits.status(of: $0)) }
        guard !visible.isEmpty else {
            addEmptyState("暂无卡券", id: "coupons.empty")
            return
        }
        for coupon in visible {
            guard let template = BenefitsCatalog.template(id: coupon.templateID) else { continue }
            let status = benefits.status(of: coupon)
            let until = dateText(benefits.expiresAt(coupon).addingTimeInterval(-1), format: "yyyy-MM-dd")
            let row = BenefitsRow(title: template.title, subtitle: "\(template.faceText) · 有效期至 \(until)",
                                  trailing: BranchStatusTagView(text: status.title, active: status.tagActive),
                                  id: "coupons.row.\(coupon.id)", showsChevron: true)
            row.onTap = { [weak self] in
                guard let self else { return }
                self.router.open(.couponDetail(couponID: coupon.id), from: self)
            }
            contentStack.addArrangedSubview(row)
        }
    }
}
