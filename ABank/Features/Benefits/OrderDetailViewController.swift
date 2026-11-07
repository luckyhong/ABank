//
//  OrderDetailViewController.swift
//  ABank
//
//  订单详情：状态、商品、支付、订单号、关联卡券；待使用订单可取消并原币种退回。
//

import UIKit
import SnapKit

final class OrderDetailViewController: BenefitsFlowViewController, RouteHosting {
    private let orderID: String
    private let justRedeemed: Bool

    var hostedRoute: AppRoute? { .orderDetail(orderID: orderID, justRedeemed: justRedeemed) }

    init(orderID: String, justRedeemed: Bool, benefits: BenefitsStore = .shared, dates: BankingDateContext = .system) {
        self.orderID = orderID
        self.justRedeemed = justRedeemed
        super.init(benefits: benefits, dates: dates)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "订单详情"
    }

    override func refreshBankingData() {
        clearContent()
        guard let order = benefits.order(id: orderID) else {
            addEmptyState("订单不存在", id: "order.missing")
            return
        }
        let status = benefits.status(of: order)
        let cost = "\(formattedAmount(order.cost)) \(order.currency.unit)"

        if justRedeemed && status == .pendingUse {
            let banner = UILabel()
            banner.text = "✓ 兑换成功"
            banner.font = .abankBodyMedium()
            banner.textColor = .abankSuccess
            banner.accessibilityIdentifier = "order.success"
            addCard([banner])
        }

        let name = UILabel()
        name.text = order.title
        name.font = .abankTitle3()
        name.textColor = .abankTextPrimary
        name.numberOfLines = 0
        let line = UIStackView(arrangedSubviews: [name, BranchStatusTagView(text: status.title, active: status.tagActive), UIView()])
        line.spacing = Spacing.sm
        line.alignment = .center
        addCard([line])

        var rows: [UIView] = [
            TransferInfoRow("订单状态", value: status.title),
            TransferInfoRow("数量", value: "× \(order.quantity)"),
            TransferInfoRow("支付", value: cost),
            TransferInfoRow("订单号", value: order.orderNo),
            TransferInfoRow("下单时间", value: dateText(order.createdAt))
        ]
        if let cancelledAt = order.cancelledAt {
            rows.append(TransferInfoRow("取消时间", value: dateText(cancelledAt)))
        }
        addGroup(rows)

        if benefits.coupon(id: order.couponID) != nil {
            let row = BenefitsRow(title: "关联卡券", subtitle: "查看券码与有效期", id: "order.coupon", showsChevron: true)
            row.onTap = { [weak self] in
                guard let self else { return }
                self.router.open(.couponDetail(couponID: order.couponID), from: self)
            }
            contentStack.addArrangedSubview(row)
        }

        switch status {
        case .pendingUse:
            _ = addButton("取消订单", id: "order.cancel", primary: false) { [weak self] in
                self?.confirm("取消后卡券作废，\(cost)将原路退回，确定取消？", confirmTitle: "取消订单") { self?.cancel(order, cost: cost) }
            }
        case .used:
            addCaption("卡券已使用，订单不可取消")
        case .expired:
            addCaption("卡券已过期，订单不可取消")
        case .cancelled:
            addCaption("订单已取消，\(cost)已原路退回")
        }
        addNotice()
    }

    private func addCaption(_ text: String) {
        let label = branchCaption(text)
        label.accessibilityIdentifier = "order.reason"
        contentStack.addArrangedSubview(label)
    }

    private func cancel(_ order: RewardOrder, cost: String) {
        do {
            try benefits.cancelOrder(id: order.id)
            showToast("已取消，\(cost)已退回")
        } catch {
            showError(error)
        }
    }
}
