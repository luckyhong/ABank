//
//  PaymentOrderDetailViewController.swift
//  ABank
//
//  充值缴费订单详情：金额、抵扣、实付、付款账户与流水号；充值缴费不可撤销，无退款。
//

import UIKit
import SnapKit

final class PaymentOrderDetailViewController: PaymentFlowViewController, RouteHosting {
    private let orderID: String
    private let justPaid: Bool

    var hostedRoute: AppRoute? { .paymentOrderDetail(orderID: orderID, justPaid: justPaid) }

    init(orderID: String, justPaid: Bool, ledger: FinanceLedgerStore = .shared,
         benefits: BenefitsStore = .shared, dates: BankingDateContext = .system) {
        self.orderID = orderID
        self.justPaid = justPaid
        super.init(ledger: ledger, benefits: benefits, dates: dates)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "订单详情"
    }

    override func refreshBankingData() {
        clearContent()
        guard let order = ledger.paymentOrder(id: orderID) else {
            addEmptyState("订单不存在", id: "payment.missing")
            return
        }
        if justPaid {
            let banner = UILabel()
            banner.text = order.kind.isUtility ? "缴费成功" : "充值成功"
            banner.font = .abankBodyMedium()
            banner.textColor = .abankSuccess
            banner.accessibilityIdentifier = "payment.success"
            let icon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill")); icon.tintColor = .abankSuccess
            icon.snp.makeConstraints { $0.size.equalTo(22) }
            let status = UIStackView(arrangedSubviews: [icon, banner, UIView()]); status.spacing = 8; status.alignment = .center
            addCard([status])
        }

        let name = UILabel()
        name.text = paymentOrderTitle(order)
        name.font = .abankTitle3()
        name.textColor = .abankTextPrimary
        name.numberOfLines = 0
        let tag = BranchStatusTagView(text: "已完成", active: false)
        tag.setContentCompressionResistancePriority(.required, for: .horizontal)
        let line = UIStackView(arrangedSubviews: [name, tag])
        line.spacing = Spacing.sm
        line.alignment = .center
        addCard([line])

        var rows: [UIView] = [
            TransferInfoRow("类型", value: order.kind.title),
            TransferInfoRow("对象", value: order.targetTitle)
        ]
        if let period = order.period { rows.append(TransferInfoRow("账期", value: period)) }
        rows.append(TransferInfoRow(order.kind.isUtility ? "账单金额" : "充值面额", value: "\(wealthMoneyText(order.faceInCents)) 元"))
        if order.couponDiscountInCents > 0 {
            rows.append(TransferInfoRow("话费券抵扣", value: "-\(wealthMoneyText(order.couponDiscountInCents)) 元"))
        }
        rows.append(TransferInfoRow("实付金额", value: "\(wealthMoneyText(order.paidInCents)) 元", emphasized: true))
        rows.append(TransferInfoRow("付款账户", value: accountLabel(order.accountID)))
        rows.append(TransferInfoRow("订单号", value: order.orderNo.hasPrefix("M8") ? "JF" + order.orderNo.dropFirst(2) : order.orderNo))
        rows.append(TransferInfoRow("创建时间", value: order.createdAt))
        addGroup(rows)
        _ = addButton("查看关联流水", id: "payment.transaction", primary: false) { [weak self] in
            guard let self, let transaction = self.ledger.transaction(id: order.transactionID) else { return }
            self.navigationController?.pushViewController(IncomeExpenseDetailViewController(transaction: transaction), animated: true)
        }
        addNotice("交易完成后不可撤销")
    }

    private func accountLabel(_ accountID: String) -> String {
        ledger.load().accounts.first { $0.id == accountID }?.cardLabel ?? "借记卡"
    }
}
