import UIKit

final class DepositsViewController: TransferFlowViewController {
    override func setupUI() { super.setupUI(); title = "存款" }
    override func refreshBankingData() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let deposits = FinanceLedgerStore.shared.activeDeposits()
        let total = deposits.reduce(Int64(0)) { $0 + $1.principalInCents }
        contentStack.addArrangedSubview(BankingPageStyle.surface([BankingPageStyle.section("我的定期存款"), BankingPageStyle.text("¥ " + TransferMoney.text(total), style: .title1)]))
        for row in deposits {
            let view = BenefitsRow(title: row.title, subtitle: "¥\(TransferMoney.text(row.principalInCents)) · \(row.maturityDate)到期", id: "deposit." + row.id, showsChevron: true)
            view.onTap = { [weak self] in guard let self else { return }; self.router.open(.depositDetail(id: row.id), from: self) }
            contentStack.addArrangedSubview(view)
        }
        if deposits.isEmpty { addNotice("暂无持有存款，可选择下方产品存入") }
        contentStack.addArrangedSubview(BankingPageStyle.section("整存整取"))
        for product in DepositProduct.all {
            let row = BenefitsRow(title: product.title, subtitle: "年利率 \(product.rateText) · 50元起存", id: product.id, showsChevron: true)
            row.onTap = { [weak self] in self?.navigationController?.pushViewController(DepositPurchaseViewController(product: product), animated: true) }
            contentStack.addArrangedSubview(row)
        }
        addNotice("提前支取按活期利率计息，到期支取按约定利率计息；资金返回原账户。")
        let closed = FinanceLedgerStore.shared.load().termDeposits.filter { $0.closedAt != nil }
        if !closed.isEmpty {
            contentStack.addArrangedSubview(BankingPageStyle.section("支取记录"))
            for row in closed {
                let view = BenefitsRow(title: row.title + " · 已支取", subtitle: "本金 \(TransferMoney.text(row.principalInCents))元 · 利息 \(TransferMoney.text(row.interestPaidInCents ?? 0))元", id: "deposit.closed." + row.id, showsChevron: true)
                view.onTap = { [weak self] in guard let self else { return }; self.router.open(.depositDetail(id: row.id), from: self) }; contentStack.addArrangedSubview(view)
            }
        }
    }
}

private final class DepositPurchaseViewController: TransferFlowViewController {
    private let product: DepositProduct
    private var accountID = FinanceLedgerRecord.defaultAccountId
    private let requestID = UUID().uuidString
    private let amount = TransferInputRow("存入金额", placeholder: "50元起存", id: "deposit.amount", keyboard: .decimalPad)
    init(product: DepositProduct) { self.product = product; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func setupUI() { super.setupUI(); title = "存入定期" }
    override func refreshBankingData() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        addGroup([TransferInfoRow("存款产品", value: product.title), TransferInfoRow("年利率", value: product.rateText),
            BankingAccountPickerRow(account: FinanceLedgerStore.shared.account(id: accountID), id: "deposit.payer") { [weak self] in
                guard let self else { return }; BankingAccountPickerRow.choose(from: self, ledger: .shared, selected: self.accountID) { [weak self] id in self?.accountID = id; self?.refreshBankingData() }
            }, amount])
        addNotice("存入金额将从付款账户转入定期存款，不计入日常支出；提前支取按活期利率计息。")
        _ = addButton("确认存入", id: "deposit.submit") { [weak self] in self?.submit() }
    }
    private func submit() {
        view.endEditing(true)
        guard let cents = TransferMoney.parse(amount.field.text ?? ""), cents >= 5_000 else { showToast("请输入不少于50元的金额"); return }
        let account = accountID
        let alert = UIAlertController(title: "确认存入？", message: "\(product.title)，金额\(TransferMoney.text(cents))元", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "存入", style: .default) { [weak self] _ in
            guard let self else { return }
            do {
                let row = try FinanceLedgerStore.shared.openDeposit(productID: self.product.id, amount: cents, accountID: account, requestID: self.requestID)
                let detail = DepositDetailViewController(id: row.id)
                if let nav = self.navigationController { nav.setViewControllers(Array(nav.viewControllers.dropLast()) + [detail], animated: true) }
            } catch { self.showToast(error.localizedDescription) }
        })
        present(alert, animated: true)
    }
}

final class DepositDetailViewController: TransferFlowViewController {
    private let id: String
    init(id: String) { self.id = id; super.init(nibName: nil, bundle: nil); hidesBottomBarWhenPushed = true }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func setupUI() { super.setupUI(); title = "存款详情" }
    override func refreshBankingData() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let ledger = FinanceLedgerStore.shared
        guard let row = ledger.load().termDeposits.first(where: { $0.id == id }) else { addNotice("该存款记录不存在"); return }
        contentStack.addArrangedSubview(BankingPageStyle.surface([BankingPageStyle.section(row.title), BankingPageStyle.text("¥ " + TransferMoney.text(row.principalInCents), style: .largeTitle)]))
        addGroup([TransferInfoRow("状态", value: row.closedAt == nil ? "存续中" : "已支取"), TransferInfoRow("存入时间", value: row.openedAt),
            TransferInfoRow("到期日", value: row.maturityDate), TransferInfoRow("年利率", value: String(format: "%.2f%%", Double(row.rateBasisPoints) / 100)),
            TransferInfoRow("原账户", value: ledger.accountCardLabel(for: row.accountID)),
            TransferInfoRow(row.closedAt == nil ? "当前可结利息" : "已付利息", value: TransferMoney.text(row.interestPaidInCents ?? ledger.depositInterest(row)) + "元")])
        if row.closedAt == nil {
            let early = ledger.dates.string(from: ledger.dates.now) < row.maturityDate
            addNotice(early ? "当前未到期，提前支取将按活期利率计算实际存期利息。" : "已到期，可支取本金和利息。")
            _ = addButton(early ? "提前支取" : "到期支取", id: "deposit.withdraw") { [weak self] in
                guard let self else { return }
                let alert = UIAlertController(title: "确认支取全部本金？", message: early ? "提前支取将按活期利率计息，本息返回原账户。" : "本息将返回原账户。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "取消", style: .cancel))
                alert.addAction(UIAlertAction(title: "确认支取", style: .default) { [weak self] _ in
                    do { _ = try ledger.withdrawDeposit(id: row.id); self?.refreshBankingData() } catch { self?.showToast(error.localizedDescription) }
                }); self.present(alert, animated: true)
            }
        } else { addNotice("支取时间：" + (row.closedAt ?? "")) }
    }
}

final class CreditCardsViewController: TransferFlowViewController {
    private var payerID = FinanceLedgerRecord.defaultAccountId
    override func setupUI() { super.setupUI(); title = "信用卡" }
    override func refreshBankingData() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let ledger = FinanceLedgerStore.shared
        let root = ledger.load()
        guard let card = root.creditCards.first else {
            contentStack.addArrangedSubview(BankingPageStyle.empty("尚未添加信用卡", detail: "添加后可查看账单、应还金额和还款记录。"))
            _ = addButton("添加信用卡", id: "credit.add") { [weak self] in self?.addCard() }
            return
        }
        contentStack.addArrangedSubview(BankingPageStyle.surface([BankingPageStyle.section("农行信用卡 · " + card.tail),
            BankingPageStyle.text("¥ " + TransferMoney.text(card.remainingInCents), style: .largeTitle),
            BankingPageStyle.text("本期剩余应还", style: .subheadline, color: .abankTextSecondary)]))
        addGroup([TransferInfoRow("账单日", value: card.statementDate), TransferInfoRow("到期还款日", value: card.dueDate),
            TransferInfoRow("本期账单", value: TransferMoney.text(card.originalBillInCents)), TransferInfoRow("已还金额", value: TransferMoney.text(card.repaidInCents)),
            TransferInfoRow("可用额度", value: TransferMoney.text(card.limitInCents - card.remainingInCents)), TransferInfoRow("最低还款", value: TransferMoney.text(card.minimumInCents))])
        if card.remainingInCents > 0 {
            contentStack.addArrangedSubview(BankingAccountPickerRow(account: ledger.account(id: payerID), id: "credit.payer") { [weak self] in
                guard let self else { return }; BankingAccountPickerRow.choose(from: self, ledger: ledger, selected: self.payerID) { [weak self] id in self?.payerID = id; self?.refreshBankingData() }
            })
            _ = addButton("全额还款", id: "credit.repay.full") { [weak self] in self?.repay(card, amount: card.remainingInCents) }
            if card.minimumInCents > 0 {
                _ = addButton("最低还款", id: "credit.repay.minimum", primary: false) { [weak self] in self?.repay(card, amount: card.minimumInCents) }
            } else { addNotice("本期最低还款已完成，剩余账单仍可继续还款。") }
        } else { addNotice("本期账单已还清") }
        contentStack.addArrangedSubview(BankingPageStyle.section("账单明细"))
        for tx in root.transactions.filter({ $0.accountId == card.id }).sorted(by: { $0.date > $1.date }) {
            let row = BenefitsRow(title: tx.title, subtitle: tx.date + " · " + tx.signedAmountText, id: "credit.tx." + tx.id, showsChevron: true)
            row.onTap = { [weak self] in self?.navigationController?.pushViewController(IncomeExpenseDetailViewController(transaction: tx), animated: true) }; contentStack.addArrangedSubview(row)
        }
        let repayments = root.creditRepayments.filter { $0.cardID == card.id }.sorted { $0.createdAt > $1.createdAt }
        if !repayments.isEmpty { contentStack.addArrangedSubview(BankingPageStyle.section("还款记录")) }
        for row in repayments { addGroup([TransferInfoRow(row.createdAt, value: TransferMoney.text(row.amountInCents) + "元")]) }
    }
    private func addCard() {
        let alert = UIAlertController(title: "添加信用卡", message: "添加尾号1968的信用卡及其本期账单1,280.50元，纳入账户负债和收支统计。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确认添加", style: .default) { [weak self] _ in
            do { _ = try FinanceLedgerStore.shared.addCreditCard(); self?.refreshBankingData() } catch { self?.showToast(error.localizedDescription) }
        }); present(alert, animated: true)
    }
    private func repay(_ card: CreditCardAccount, amount: Int64) {
        let account = payerID
        let request = UUID().uuidString
        let alert = UIAlertController(title: "确认还款？", message: "向信用卡\(card.tail)还款\(TransferMoney.text(amount))元，付款账户\(FinanceLedgerStore.shared.accountCardLabel(for: account))。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确认还款", style: .default) { [weak self] _ in
            do { _ = try FinanceLedgerStore.shared.repayCreditCard(id: card.id, amount: amount, accountID: account, requestID: request); self?.refreshBankingData(); self?.showToast("还款成功") }
            catch { self?.showToast(error.localizedDescription) }
        }); present(alert, animated: true)
    }
}
