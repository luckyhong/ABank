//
//  MobileRechargeConfirmViewController.swift
//  ABank
//
//  充值确认：号码、面额、付款账户与余额、可选话费券；确认后提交，成功进入订单详情。
//  `requestID` 在页面创建（及每次成功后）生成，重复点击不会重复扣款。
//

import UIKit
import SnapKit

final class MobileRechargeConfirmViewController: PaymentFlowViewController, RouteHosting {
    private let phone: String
    private let faceInCents: Int64
    private var selectedCouponID: String?
    private var requestID = UUID().uuidString

    var hostedRoute: AppRoute? { .mobileRechargeConfirm(phone: phone, faceInCents: faceInCents) }

    init(phone: String, faceInCents: Int64, ledger: FinanceLedgerStore = .shared,
         benefits: BenefitsStore = .shared, dates: BankingDateContext = .system) {
        self.phone = phone
        self.faceInCents = faceInCents
        super.init(ledger: ledger, benefits: benefits, dates: dates)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "确认充值"
    }

    override func refreshBankingData() {
        clearContent()
        let usable = ledger.usableCoupons(forFaceInCents: faceInCents)
        if let id = selectedCouponID, !usable.contains(where: { $0.id == id }) { selectedCouponID = nil }
        let selected = usable.first { $0.id == selectedCouponID }
        let discount = selected.flatMap { PaymentRules.usableCouponFaceInCents(templateID: $0.templateID, faceInCents: faceInCents) } ?? 0
        let paid = faceInCents - discount
        let payer = payerAccount()

        addGroup([
            TransferInfoRow("充值号码", value: PaymentRules.maskedPhone(phone)),
            TransferInfoRow("运营商", value: PaymentRules.phoneOperator(of: phone).title),
            TransferInfoRow("充值面额", value: "\(wealthMoneyText(faceInCents)) 元"),
            TransferInfoRow("付款账户", value: payer.label),
            TransferInfoRow("可用余额", value: "\(wealthMoneyText(payer.balanceInCents)) 元")
        ])

        let subtitle: String
        if let selected {
            subtitle = "已选 \(couponTitle(selected)) -\(wealthMoneyText(discount)) 元"
        } else {
            subtitle = usable.isEmpty ? "暂无可用话费券" : "可用 \(usable.count) 张"
        }
        let couponRow = BenefitsRow(title: "话费券", subtitle: subtitle, id: "recharge.coupon", showsChevron: !usable.isEmpty)
        if !usable.isEmpty {
            couponRow.onTap = { [weak self] in self?.chooseCoupon(usable) }
        }
        contentStack.addArrangedSubview(couponRow)

        let payLabel = UILabel()
        payLabel.text = "实付 ¥\(wealthMoneyText(paid))"
        payLabel.font = .systemFont(ofSize: 28, weight: .semibold)
        payLabel.textColor = .abankTextPrimary
        payLabel.adjustsFontSizeToFitWidth = true
        payLabel.accessibilityIdentifier = "recharge.pay"
        addCard([payLabel])

        _ = addButton("确认充值", id: "recharge.submit") { [weak self] in self?.submitTapped(paid: paid, couponID: selected?.id) }
        addNotice("本机模拟 · 不发生真实资金交易")
    }

    private func couponTitle(_ coupon: Coupon) -> String {
        BenefitsCatalog.template(id: coupon.templateID)?.title ?? "话费券"
    }

    private func chooseCoupon(_ usable: [Coupon]) {
        let sheet = UIAlertController(title: "选择话费券", message: nil, preferredStyle: .actionSheet)
        for coupon in usable {
            let face = PaymentRules.usableCouponFaceInCents(templateID: coupon.templateID, faceInCents: faceInCents) ?? 0
            sheet.addAction(UIAlertAction(title: "\(couponTitle(coupon))（-\(wealthMoneyText(face)) 元）", style: .default) { [weak self] _ in
                self?.selectedCouponID = coupon.id
                self?.refreshBankingData()
            })
        }
        sheet.addAction(UIAlertAction(title: "不使用", style: .default) { [weak self] _ in
            self?.selectedCouponID = nil
            self?.refreshBankingData()
        })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        sheet.popoverPresentationController?.sourceView = view
        sheet.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        present(sheet, animated: true)
    }

    /// 弹窗确认的是此刻的券与实付金额；提交时携带它们，状态在弹窗期间变化则拒绝而不是替换。
    private func submitTapped(paid: Int64, couponID: String?) {
        confirm("确认充值 \(wealthMoneyText(faceInCents)) 元？实付 \(wealthMoneyText(paid)) 元。", confirmTitle: "确认充值") { [weak self] in
            self?.submit(paid: paid, couponID: couponID)
        }
    }

    private func submit(paid: Int64, couponID: String?) {
        do {
            let order = try ledger.submitMobileRecharge(phone: phone, faceInCents: faceInCents, couponID: couponID,
                                                        requestID: requestID, expectedPaidInCents: paid)
            requestID = UUID().uuidString
            selectedCouponID = nil
            router.open(.paymentOrderDetail(orderID: order.id, justPaid: true), from: self)
        } catch {
            showError(error)
            refreshBankingData()
        }
    }
}
