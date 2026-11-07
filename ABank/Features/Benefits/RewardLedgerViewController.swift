//
//  RewardLedgerViewController.swift
//  ABank
//
//  积分/小豆明细：余额头、全部/收入/支出筛选、按月分组（种子与用户流水合并倒序）。
//

import UIKit
import SnapKit

final class RewardLedgerViewController: BenefitsFlowViewController, RouteHosting {
    private let currency: RewardCurrency
    private var filter = 0

    var hostedRoute: AppRoute? { .rewardLedger(currency: currency) }

    init(currency: RewardCurrency, benefits: BenefitsStore = .shared, dates: BankingDateContext = .system) {
        self.currency = currency
        super.init(benefits: benefits, dates: dates)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = currency.title + "明细"
    }

    override func refreshBankingData() {
        clearContent()
        let value = UILabel()
        value.text = formattedAmount(benefits.balance(currency))
        value.font = .systemFont(ofSize: 32, weight: .semibold)
        value.textColor = currency.tint
        value.accessibilityIdentifier = "ledger.balance"
        addCard([branchCaption("当前\(currency.title)"), value])

        let bar = BranchChipBar(titles: ["全部", "收入", "支出"], selected: filter, idPrefix: "ledger.filter")
        bar.onSelect = { [weak self] index in
            self?.filter = index
            self?.refreshBankingData()
        }
        contentStack.addArrangedSubview(bar)

        let entries = benefits.ledger(currency: currency).filter {
            filter == 0 || (filter == 1 ? $0.amount > 0 : $0.amount < 0)
        }
        guard !entries.isEmpty else {
            addEmptyState("暂无明细", id: "ledger.empty")
            return
        }
        var currentMonth = ""
        for entry in entries {
            let month = dateText(entry.createdAt, format: "yyyy年M月")
            if month != currentMonth {
                currentMonth = month
                addSectionTitle(month)
            }
            let amount = UILabel()
            amount.text = (entry.amount > 0 ? "+" : "") + formattedAmount(entry.amount)
            amount.font = .abankBodyMedium()
            amount.textColor = entry.amount > 0 ? .abankSuccess : .abankTextPrimary
            amount.setContentHuggingPriority(.required, for: .horizontal)
            let row = BenefitsRow(title: entry.title, subtitle: dateText(entry.createdAt), trailing: amount,
                                  id: "ledger.row.\(entry.id)")
            row.isUserInteractionEnabled = false
            contentStack.addArrangedSubview(row)
        }
    }
}
