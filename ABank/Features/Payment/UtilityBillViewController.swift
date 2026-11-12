//
//  UtilityBillViewController.swift
//  ABank
//
//  账单详情与缴费：整笔缴清当期账单；同户号同账期缴清后不可重复缴费。
//  `requestID` 在页面创建（及每次成功后）生成，重复点击不会重复扣款。
//

import UIKit
import SnapKit

final class UtilityBillViewController: PaymentFlowViewController, RouteHosting {
    private let billAccountID: String
    private var selectedPeriod: String?
    private var requestID = UUID().uuidString

    var hostedRoute: AppRoute? { .utilityBill(billAccountID: billAccountID) }

    init(billAccountID: String, ledger: FinanceLedgerStore = .shared,
         benefits: BenefitsStore = .shared, dates: BankingDateContext = .system) {
        self.billAccountID = billAccountID
        super.init(ledger: ledger, benefits: benefits, dates: dates)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "账单详情"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "历史账单", style: .plain, target: self, action: #selector(choosePeriod))
    }

    override func refreshBankingData() {
        clearContent()
        guard let account = PaymentCatalog.billAccount(id: billAccountID) else {
            addEmptyState("账单不存在", id: "bill.missing")
            return
        }
        guard let bill = try? ledger.utilityBill(account: account, period: selectedPeriod) else { addNotice("该账期不可用"); return }
        let payer = payerAccount()

        let name = UILabel()
        name.text = "\(account.kind.title) · \(account.name)"
        name.font = .abankTitle3()
        name.textColor = .abankTextPrimary
        name.numberOfLines = 0
        let amount = UILabel()
        amount.text = "¥\(wealthMoneyText(bill.amountInCents))"
        amount.font = .systemFont(ofSize: 28, weight: .semibold)
        amount.textColor = .abankTextPrimary
        amount.accessibilityIdentifier = "bill.amount"
        addCard([name, branchCaption(account.provider), amount])

        addGroup([
            TransferInfoRow("户号", value: account.accountNo),
            TransferInfoRow("地址", value: account.address),
            TransferInfoRow("账期", value: bill.period),
            TransferInfoRow("到期日", value: bill.dueDate),
            TransferInfoRow("本期用量", value: bill.usageText),
            TransferInfoRow("计费单价", value: bill.unitPriceText),
            TransferInfoRow("状态", value: bill.isPaid ? "本期已缴清" : "待缴"),
            payerPickerRow(),
            TransferInfoRow("可用余额", value: "\(wealthMoneyText(payer.balanceInCents)) 元")
        ])

        let button = addButton(bill.isPaid ? "本期已缴清" : "立即缴费", id: "bill.pay") { [weak self] in
            self?.payTapped(bill)
        }
        button.isEnabled = !bill.isPaid
        button.backgroundColor = bill.isPaid ? .abankTextTertiary : .abankTeal
        addNotice("请核对账户与交易信息后办理")
    }

    @objc private func choosePeriod() {
        let start = dates.calendar.dateInterval(of: .month, for: dates.now)!.start
        let options = (0..<12).map { offset -> (String, String) in
            let date = dates.calendar.date(byAdding: .month, value: -offset, to: start)!
            let month = dates.string(from: date, format: "yyyy-MM")
            return (month, month + (offset == 0 ? " · 本期" : ""))
        }
        let sheet = IncomeExpenseOptionPickerSheet()
        sheet.onSelect = { [weak self] month in
            guard let self else { return }; self.selectedPeriod = month == self.dates.currentMonth ? nil : month; self.refreshBankingData()
        }
        sheet.present(in: navigationController?.view ?? view, title: "选择账期", options: options, selectedId: selectedPeriod ?? dates.currentMonth)
    }

    private func payTapped(_ bill: UtilityBill) {
        do { try ledger.validateUtilityPayment(billAccountID: billAccountID, accountID: selectedPayerAccountID, period: selectedPeriod) }
        catch {
            showError(error)
            refreshBankingData()
            return
        }
        confirm("确认缴纳 \(wealthMoneyText(bill.amountInCents)) 元？", confirmTitle: "确认缴费") { [weak self] in
            self?.pay(bill)
        }
    }

    private func pay(_ bill: UtilityBill) {
        do {
            let order = try ledger.submitUtilityPayment(billAccountID: billAccountID, requestID: requestID,
                                                        expectedPeriod: bill.period, expectedAmountInCents: bill.amountInCents, accountID: selectedPayerAccountID, period: selectedPeriod)
            requestID = UUID().uuidString
            router.open(.paymentOrderDetail(orderID: order.id, justPaid: true), from: self)
        } catch {
            showError(error)
            refreshBankingData()
        }
    }
}
