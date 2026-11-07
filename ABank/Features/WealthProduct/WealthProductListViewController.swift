//
//  WealthProductListViewController.swift
//  ABank
//
//  理财产品列表：分类、风险等级、持有期限三组筛选叠加。
//

import UIKit
import SnapKit

final class WealthProductListViewController: WealthFlowViewController, RouteHosting {
    private var categoryIndex = 0
    private var riskIndex = 0
    private var periodIndex = 0

    var hostedRoute: AppRoute? { .wealthProducts }

    override func setupUI() {
        super.setupUI()
        title = "理财产品"
    }

    override func setupNavigationBar() {
        super.setupNavigationBar()
        let holdings = UIBarButtonItem(title: "我的持仓", style: .plain, target: self, action: #selector(openHoldings))
        holdings.accessibilityIdentifier = "wealth.holdings"
        navigationItem.rightBarButtonItem = holdings
    }

    @objc private func openHoldings() {
        router.open(.wealthHoldings, from: self)
    }

    override func refreshBankingData() {
        clearContent()
        let categories = WealthCategory.allCases
        let risks = ProductRiskLevel.allCases
        let periods = HoldingPeriodFilter.allCases

        addBar(["全部"] + categories.map(\.title), selected: categoryIndex, prefix: "wealth.filter.category") { [weak self] in self?.categoryIndex = $0 }
        addBar(["全部风险"] + risks.map { "\($0.shortTitle) \($0.title)" }, selected: riskIndex, prefix: "wealth.filter.risk") { [weak self] in self?.riskIndex = $0 }
        addBar(periods.map(\.title), selected: periodIndex, prefix: "wealth.filter.period") { [weak self] in self?.periodIndex = $0 }

        let products = WealthProductCatalog.filtered(
            category: categoryIndex == 0 ? nil : categories[categoryIndex - 1],
            risk: riskIndex == 0 ? nil : risks[riskIndex - 1],
            period: periods[periodIndex]
        )
        guard !products.isEmpty else {
            addEmptyState("暂无符合条件的产品", id: "wealth.empty")
            return
        }
        for product in products {
            contentStack.addArrangedSubview(wealthProductRow(product) { [weak self] in
                guard let self else { return }
                self.router.open(.wealthProductDetail(productID: product.id), from: self)
            })
        }
        addNotice("本机模拟 · 产品与收益均为演示数据")
    }

    private func addBar(_ titles: [String], selected: Int, prefix: String, onChange: @escaping (Int) -> Void) {
        let bar = BranchChipBar(titles: titles, selected: selected, idPrefix: prefix)
        bar.onSelect = { [weak self] index in
            onChange(index)
            self?.refreshBankingData()
        }
        contentStack.addArrangedSubview(bar)
    }
}
