//
//  CouponDetailViewController.swift
//  ABank
//
//  卡券详情：状态、模拟券码、有效期、来源与“模拟使用”。
//

import UIKit
import SnapKit

final class CouponDetailViewController: BenefitsFlowViewController, RouteHosting {
    private let couponID: String

    var hostedRoute: AppRoute? { .couponDetail(couponID: couponID) }

    init(couponID: String, benefits: BenefitsStore = .shared, dates: BankingDateContext = .system) {
        self.couponID = couponID
        super.init(benefits: benefits, dates: dates)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "卡券详情"
    }

    override func refreshBankingData() {
        clearContent()
        guard let coupon = benefits.coupon(id: couponID), let template = BenefitsCatalog.template(id: coupon.templateID) else {
            addEmptyState("卡券不存在", id: "coupon.missing")
            return
        }
        let status = benefits.status(of: coupon)
        let name = UILabel()
        name.text = template.title
        name.font = .abankTitle3()
        name.textColor = .abankTextPrimary
        name.numberOfLines = 0
        let line = UIStackView(arrangedSubviews: [name, BranchStatusTagView(text: status.title, active: status.tagActive), UIView()])
        line.spacing = Spacing.sm
        line.alignment = .center
        addCard([line, branchCaption(template.brand + " · " + template.faceText)])

        let until = dateText(benefits.expiresAt(coupon).addingTimeInterval(-1), format: "yyyy-MM-dd")
        let codeRow = TransferInfoRow("券码（模拟）", value: benefits.couponCode(for: coupon))
        codeRow.accessibilityIdentifier = "coupon.code"
        var rows: [UIView] = [
            codeRow,
            TransferInfoRow("领取时间", value: dateText(coupon.receivedAt)),
            TransferInfoRow("有效期至", value: until)
        ]
        if let usedAt = coupon.usedAt { rows.append(TransferInfoRow("使用时间", value: dateText(usedAt))) }
        if let benefit = coupon.benefitID.flatMap(BenefitsCatalog.benefit(id:)) {
            rows.append(TransferInfoRow("来源", value: "权益领取 · " + benefit.title))
        }
        addGroup(rows)

        if let orderID = coupon.orderID, let order = benefits.order(id: orderID) {
            let row = BenefitsRow(title: "关联订单", subtitle: order.orderNo, id: "coupon.order", showsChevron: true)
            row.onTap = { [weak self] in
                guard let self else { return }
                self.router.open(.orderDetail(orderID: order.id, justRedeemed: false), from: self)
            }
            contentStack.addArrangedSubview(row)
        }
        addCard([branchCaption("使用说明"), branchCaption(template.note, color: .abankTextPrimary)])

        if status == .unused {
            _ = addButton("模拟使用", id: "coupon.use") { [weak self] in
                self?.confirm("模拟使用该卡券？使用后不可撤销。", confirmTitle: "使用") { self?.use() }
            }
        }
        addNotice("本机模拟 · 券码仅用于演示")
    }

    private func use() {
        do {
            try benefits.useCoupon(id: couponID)
            showToast("已模拟使用")
        } catch {
            showError(error)
        }
    }
}
