//
//  AssetLiabilityViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class AssetLiabilityViewController: BaseViewController {

    private var pageData = FinanceLedgerStore.shared.assetLiabilityPageData()
    private var selectedTab: AssetLiabilityTab = .assets

    private let topBackgroundView = UIView()
    private let topBackgroundGradient: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(red: 248 / 255, green: 225 / 255, blue: 190 / 255, alpha: 1).cgColor,
            UIColor(red: 252 / 255, green: 240 / 255, blue: 220 / 255, alpha: 1).cgColor,
            UIColor.abankBackground.cgColor
        ]
        layer.locations = [0, 0.55, 1]
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1)
        return layer
    }()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never
        return scrollView
    }()
    private let contentView = UIView()

    private let announcementBar = AssetLiabilityAnnouncementBarView()
    private let summaryCard = AssetLiabilitySummaryCardView()
    private let categoryList = AssetLiabilityCategoryListView()
    private let tipsView = AssetLiabilityTipsView()

    init() {
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupNavigationBar() {
        title = "资产负债"
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.tintColor = .abankTextPrimary

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.abankTextPrimary,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        appearance.shadowColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        let photoConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "photo.on.rectangle.angled", withConfiguration: photoConfig),
            style: .plain,
            target: self,
            action: #selector(shareTapped)
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        reloadFromStore()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        topBackgroundGradient.frame = topBackgroundView.bounds
        updateScrollInsets()
    }

    private func updateScrollInsets() {
        guard let navBar = navigationController?.navigationBar else { return }
        let topInset = navBar.frame.maxY
        if scrollView.contentInset.top != topInset {
            scrollView.contentInset.top = topInset
            scrollView.verticalScrollIndicatorInsets.top = topInset
        }
    }

    override func setupUI() {
        view.backgroundColor = .abankBackground

        topBackgroundView.layer.addSublayer(topBackgroundGradient)
        topBackgroundView.clipsToBounds = true
        view.insertSubview(topBackgroundView, at: 0)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        [announcementBar, summaryCard, categoryList, tipsView].forEach { contentView.addSubview($0) }

        topBackgroundView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(260)
        }
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        announcementBar.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        summaryCard.snp.makeConstraints { make in
            make.top.equalTo(announcementBar.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        categoryList.snp.makeConstraints { make in
            make.top.equalTo(summaryCard.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
        }
        tipsView.snp.makeConstraints { make in
            make.top.equalTo(categoryList.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.bottom.equalToSuperview().offset(-Spacing.pageBottom - 24)
        }

        bindData()
    }

    override func setupBindings() {
        announcementBar.onTap = { [weak self] in self?.showToast("储蓄计划") }
        summaryCard.onTabChanged = { [weak self] tab in
            self?.selectedTab = tab
            self?.refreshCategoryList()
            self?.refreshTips()
        }
        summaryCard.onWealthCheckupTapped = { [weak self] in self?.showToast("财富体检") }
        categoryList.onCategoryTapped = { [weak self] index in
            self?.handleCategoryTap(at: index)
        }
        categoryList.onItemTapped = { [weak self] ci, ii in
            self?.handleItemTap(categoryIndex: ci, itemIndex: ii)
        }
        categoryList.onItemMenuTapped = { [weak self] _, _ in self?.showToast("更多操作") }
        tipsView.onPhoneTapped = { [weak self] in self?.showToast("拨打客服 95599") }
    }

    private var currentCategories: [AssetLiabilityCategory] {
        selectedTab == .assets ? pageData.assetCategories : pageData.liabilityCategories
    }

    private var currentTips: [String] {
        selectedTab == .assets ? pageData.assetTips : pageData.liabilityTips
    }

    private func reloadFromStore() {
        pageData = FinanceLedgerStore.shared.assetLiabilityPageData()
        bindData()
    }

    private func bindData() {
        announcementBar.configure(message: pageData.announcement)
        summaryCard.configure(
            totalAssets: pageData.totalAssets,
            totalLiabilities: pageData.totalLiabilities,
            timestamp: pageData.dataTimestamp,
            selectedTab: selectedTab
        )
        tipsView.configure(tips: currentTips)
        refreshCategoryList()
    }

    private func refreshTips() {
        tipsView.configure(tips: currentTips)
    }

    private func refreshCategoryList() {
        categoryList.configure(categories: currentCategories)
    }

    private func handleCategoryTap(at index: Int) {
        guard let category = currentCategories[safe: index] else { return }
        navigate(for: category.id)
    }

    private func handleItemTap(categoryIndex: Int, itemIndex: Int) {
        guard let category = currentCategories[safe: categoryIndex],
              let item = category.items[safe: itemIndex] else { return }
        navigate(for: category.id, itemId: item.id)
    }

    private func navigate(for categoryId: String, itemId: String? = nil) {
        switch categoryId {
        case FinanceLedgerRecord.demandDepositCategoryId:
            // 分类行进全部账户；子项（尾号）带账户筛选
            navigationController?.pushViewController(
                IncomeExpenseViewController(accountId: itemId),
                animated: true
            )
        case FinanceLedgerRecord.loanCategoryId:
            navigationController?.pushViewController(MyLoanViewController(), animated: true)
        default:
            showToast("详情")
        }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func shareTapped() {
        showToast("分享")
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
