//
//  FinanceViewController.swift
//  ABank
//
//  Created by 韩继宏 on 2025/10/27.
//

import UIKit
import SnapKit

final class WealthViewController: BaseViewController {

    private let pageData = MockDataProvider.shared.getWealthPageData()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        return scrollView
    }()
    private let contentView = UIView()

    private let headerContainer = UIView()
    private let headerBackground = UIView()
    private let searchBar = WealthSearchBarView()

    private let loginCard = WealthLoginCardView()
    private let functionGrid = WealthFunctionGridView()
    private let hotspotView = WealthHotspotView()
    private let featuredProduct = WealthFeaturedProductView()
    private let spareMoneyZone = WealthSpareMoneyZoneView()
    private let steadyGrowth = WealthSteadyGrowthView()
    private let incomeAdvance = WealthIncomeAdvanceView()
    private let popularDeposit = WealthPopularDepositView()
    private let bondIndex = WealthBondIndexView()
    private let studySection = WealthStudyView()

    private let backToTopButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.up"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(white: 0.55, alpha: 0.92)
        button.layer.cornerRadius = 22
        button.alpha = 0
        button.isHidden = true
        return button
    }()

    private var headerHeightConstraint: Constraint?
    private var searchBarTopConstraint: Constraint?
    private var contentTopConstraint: Constraint?

    private let headerContentHeight: CGFloat = 52

    override func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func setupUI() {
        view.backgroundColor = .abankBackground

        view.addSubview(scrollView)
        scrollView.delegate = self
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        let sections: [UIView] = [
            loginCard, functionGrid, hotspotView, featuredProduct,
            spareMoneyZone, steadyGrowth, incomeAdvance, popularDeposit,
            bondIndex, studySection
        ]
        sections.forEach { contentView.addSubview($0) }

        let inset = Spacing.md
        let spacing: CGFloat = 16

        loginCard.snp.makeConstraints { make in
            contentTopConstraint = make.top.equalToSuperview().offset(headerContentHeight + 8).constraint
            make.leading.trailing.equalToSuperview().inset(inset)
        }
        functionGrid.snp.makeConstraints { make in
            make.top.equalTo(loginCard.snp.bottom).offset(spacing)
            make.leading.trailing.equalToSuperview().inset(inset)
        }
        hotspotView.snp.makeConstraints { make in
            make.top.equalTo(functionGrid.snp.bottom).offset(spacing)
            make.leading.trailing.equalToSuperview().inset(inset)
        }
        featuredProduct.snp.makeConstraints { make in
            make.top.equalTo(hotspotView.snp.bottom).offset(spacing)
            make.leading.trailing.equalToSuperview().inset(inset)
        }
        spareMoneyZone.snp.makeConstraints { make in
            make.top.equalTo(featuredProduct.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(inset)
        }
        steadyGrowth.snp.makeConstraints { make in
            make.top.equalTo(spareMoneyZone.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(inset)
        }
        incomeAdvance.snp.makeConstraints { make in
            make.top.equalTo(steadyGrowth.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(inset)
        }
        popularDeposit.snp.makeConstraints { make in
            make.top.equalTo(incomeAdvance.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(inset)
        }
        bondIndex.snp.makeConstraints { make in
            make.top.equalTo(popularDeposit.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(inset)
        }
        studySection.snp.makeConstraints { make in
            make.top.equalTo(bondIndex.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(inset)
            make.bottom.equalToSuperview().offset(-Spacing.xl)
        }

        headerBackground.backgroundColor = .white
        headerBackground.alpha = 0
        headerContainer.addSubview(headerBackground)
        headerContainer.addSubview(searchBar)
        view.addSubview(headerContainer)
        headerContainer.layer.zPosition = 20

        headerContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            headerHeightConstraint = make.height.equalTo(headerContentHeight).constraint
        }
        headerBackground.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        searchBar.snp.makeConstraints { make in
            searchBarTopConstraint = make.top.equalToSuperview().constraint
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().offset(-4)
        }

        view.addSubview(backToTopButton)
        backToTopButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
            make.size.equalTo(44)
        }
        backToTopButton.addTarget(self, action: #selector(backToTopTapped), for: .touchUpInside)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let safeTop = view.safeAreaInsets.top
        headerHeightConstraint?.update(offset: headerContentHeight + safeTop)
        searchBarTopConstraint?.update(offset: safeTop + 2)
        contentTopConstraint?.update(offset: headerContentHeight + safeTop + 8)

        let bottomInset = tabBarController?.tabBar.frame.height ?? 49
        if scrollView.contentInset.bottom != bottomInset {
            scrollView.contentInset.bottom = bottomInset
            scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        }
    }

    override func setupBindings() {
        bindData()
        bindActions()
    }

    private func bindData() {
        searchBar.configure(placeholder: pageData.searchPlaceholder, badgeCount: pageData.messageBadge)
        loginCard.configure(with: pageData.greeting)
        functionGrid.configure(with: pageData.gridItems)
        hotspotView.configure(with: pageData.hotspot)
        featuredProduct.configure(with: pageData.productTabs)
        spareMoneyZone.configure(
            featured: pageData.spareMoneyFeatured,
            sides: pageData.spareMoneySides
        )
        steadyGrowth.configure(with: pageData.steadyProducts)
        incomeAdvance.configure(with: pageData.fundItems)
        popularDeposit.configure(with: pageData.depositItems)
        bondIndex.configure(with: pageData.bondIndex)
        studySection.configure(banner: pageData.studyBanner, cards: pageData.studyCards)
    }

    private func bindActions() {
        searchBar.onScanTapped = { [weak self] in self?.showToast("扫一扫") }
        searchBar.onSearchTapped = { [weak self] in
            self?.showToast("搜索「\(self?.pageData.searchPlaceholder ?? "")」")
        }
        searchBar.onServiceTapped = { [weak self] in self?.showToast("正在为您接入在线客服") }
        searchBar.onMessageTapped = { [weak self] in
            self?.showToast("您有 \(self?.pageData.messageBadge ?? 0) 条未读消息")
        }

        loginCard.onLoginTapped = { [weak self] in self?.showToast("请登录查看持仓") }

        functionGrid.onItemTapped = { [weak self] index in
            let title = self?.pageData.gridItems[safe: index]?.title ?? "功能"
            self?.showToast(title)
        }

        hotspotView.onTap = { [weak self] in
            self?.showToast(self?.pageData.hotspot.headline ?? "热点资讯")
        }

        featuredProduct.onTabSelected = { [weak self] index in
            let title = self?.pageData.productTabs[safe: index]?.title ?? "产品"
            self?.showToast("切换至\(title)")
        }
        featuredProduct.onBuyTapped = { [weak self] in
            self?.showToast("立即购买")
        }

        spareMoneyZone.onHeaderTapped = { [weak self] in self?.showToast("活钱专区") }
        spareMoneyZone.onFeaturedTapped = { [weak self] in
            self?.showToast(self?.pageData.spareMoneyFeatured.title ?? "农银时时付")
        }
        spareMoneyZone.onSideTapped = { [weak self] index in
            let title = self?.pageData.spareMoneySides[safe: index]?.title ?? "产品"
            self?.showToast(title)
        }

        steadyGrowth.onHeaderTapped = { [weak self] in self?.showToast("稳健增长") }
        steadyGrowth.onProductTapped = { [weak self] index in
            let name = self?.pageData.steadyProducts[safe: index]?.name ?? "理财产品"
            self?.showToast(name)
        }

        incomeAdvance.onHeaderTapped = { [weak self] in self?.showToast("收益进阶") }
        incomeAdvance.onItemTapped = { [weak self] index in
            let name = self?.pageData.fundItems[safe: index]?.name ?? "基金"
            self?.showToast(name)
        }

        popularDeposit.onHeaderTapped = { [weak self] in self?.showToast("热门存款") }
        popularDeposit.onItemTapped = { [weak self] index in
            let name = self?.pageData.depositItems[safe: index]?.name ?? "大额存单"
            self?.showToast(name)
        }

        bondIndex.onTap = { [weak self] in
            self?.showToast(self?.pageData.bondIndex.name ?? "债券指数")
        }

        studySection.onHeaderTapped = { [weak self] in self?.showToast("财富研习所") }
        studySection.onBannerTapped = { [weak self] in
            self?.showToast(self?.pageData.studyBanner.title ?? "财富研习")
        }
        studySection.onCardTapped = { [weak self] index in
            let title = self?.pageData.studyCards[safe: index]?.title ?? "文章"
            self?.showToast(title)
        }
    }

    @objc private func backToTopTapped() {
        scrollView.setContentOffset(.zero, animated: true)
    }

    private func setBackToTopVisible(_ visible: Bool) {
        guard backToTopButton.isHidden == visible else { return }
        backToTopButton.isHidden = !visible
        UIView.animate(withDuration: 0.2) {
            self.backToTopButton.alpha = visible ? 1 : 0
        }
    }
}

extension WealthViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y = max(0, scrollView.contentOffset.y)
        let progress = min(1, y / 80)
        headerBackground.alpha = progress
        headerContainer.layer.shadowColor = UIColor.black.cgColor
        headerContainer.layer.shadowOpacity = Float(0.08 * progress)
        headerContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        headerContainer.layer.shadowRadius = 4
        setBackToTopVisible(y > 600)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
