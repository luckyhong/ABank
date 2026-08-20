//
//  HomeViewController.swift
//  ABank
//
//  Created by 韩继宏 on 2025/10/27.
//

import UIKit
import SnapKit

final class HomeViewController: BaseViewController {

    private let pageData = MockDataProvider.shared.getHomePageData()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        return scrollView
    }()
    private let contentView = UIView()

    private let topBackgroundView = UIView()
    private let topBackgroundGradient: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(red: 1.0, green: 0.70, blue: 0.42, alpha: 1).cgColor,
            UIColor(red: 1.0, green: 0.84, blue: 0.68, alpha: 1).cgColor,
            UIColor.abankBackground.cgColor
        ]
        layer.locations = [0, 0.45, 1]
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1)
        return layer
    }()

    private let headerContainer = UIView()
    private let headerBackground = UIView()
    private let topSearchBar = TopSearchBarView()

    private let heroBanner = HeroBannerView()
    private let shortcutRow = ShortcutRowView()
    private let gridMenu = GridMenuView()
    private let noticeTicker = NoticeTickerView()
    private let promoBanner = PromoBannerView()
    private let wealthSelection = WealthSelectionView()
    private let hotActivities = HotActivitiesView()
    private let pensionZone = PensionZoneView()
    private let branchService = BranchServiceView()
    private let infoSection = InfoSectionView()
    private let consumerProtection = ConsumerProtectionView()

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
    private var topBackgroundHeightConstraint: Constraint?
    private var heroTopConstraint: Constraint?
    private var hasSetInitialOffset = false

    private let headerContentHeight: CGFloat = 52

    override func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func setupUI() {
        view.backgroundColor = .abankBackground

        topBackgroundView.layer.addSublayer(topBackgroundGradient)
        topBackgroundView.clipsToBounds = true
        view.addSubview(topBackgroundView)
        topBackgroundView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            topBackgroundHeightConstraint = make.height.equalTo(300).constraint
        }

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
            heroBanner, shortcutRow, gridMenu, noticeTicker, promoBanner,
            wealthSelection, hotActivities, pensionZone, branchService,
            infoSection, consumerProtection
        ]
        sections.forEach { contentView.addSubview($0) }

        heroBanner.snp.makeConstraints { make in
            heroTopConstraint = make.top.equalToSuperview().constraint
            make.leading.trailing.equalToSuperview()
        }
        shortcutRow.snp.makeConstraints { make in
            make.top.equalTo(heroBanner.snp.bottom).offset(-32)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        gridMenu.snp.makeConstraints { make in
            make.top.equalTo(shortcutRow.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(12)
        }
        noticeTicker.snp.makeConstraints { make in
            make.top.equalTo(gridMenu.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        promoBanner.snp.makeConstraints { make in
            make.top.equalTo(noticeTicker.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        wealthSelection.snp.makeConstraints { make in
            make.top.equalTo(promoBanner.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        hotActivities.snp.makeConstraints { make in
            make.top.equalTo(wealthSelection.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        pensionZone.snp.makeConstraints { make in
            make.top.equalTo(hotActivities.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        branchService.snp.makeConstraints { make in
            make.top.equalTo(pensionZone.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        infoSection.snp.makeConstraints { make in
            make.top.equalTo(branchService.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        consumerProtection.snp.makeConstraints { make in
            make.top.equalTo(infoSection.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.bottom.equalToSuperview().offset(-24)
        }

        headerBackground.backgroundColor = .white
        headerBackground.alpha = 0
        headerContainer.addSubview(headerBackground)
        headerContainer.addSubview(topSearchBar)
        view.addSubview(headerContainer)
        headerContainer.layer.zPosition = 20

        headerContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            headerHeightConstraint = make.height.equalTo(headerContentHeight).constraint
        }
        headerBackground.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        topSearchBar.snp.makeConstraints { make in
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

        view.sendSubviewToBack(topBackgroundView)
        bindData()
        bindActions()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let safeTop = view.safeAreaInsets.top
        headerHeightConstraint?.update(offset: headerContentHeight + safeTop)
        searchBarTopConstraint?.update(offset: safeTop + 2)
        heroTopConstraint?.update(offset: headerContentHeight + safeTop + 4)
        topBackgroundHeightConstraint?.update(offset: headerContentHeight + safeTop + 210)
        topBackgroundGradient.frame = topBackgroundView.bounds

        let bottomInset = tabBarController?.tabBar.frame.height ?? 49
        if scrollView.contentInset.bottom != bottomInset {
            scrollView.contentInset.bottom = bottomInset
            scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        }

        if !hasSetInitialOffset {
            hasSetInitialOffset = true
            scrollViewDidScroll(scrollView)
        }
    }

    private func bindData() {
        topSearchBar.configure(placeholders: pageData.searchPlaceholders, badgeCount: pageData.messageBadge)
        topSearchBar.apply(style: .light)
        heroBanner.configure(with: pageData.heroBanners)
        shortcutRow.configure(with: pageData.shortcuts)
        gridMenu.configure(with: pageData.gridItems)
        noticeTicker.configure(with: pageData.notices)
        promoBanner.configure(with: pageData.promoBanners)
        wealthSelection.configure(
            featured: pageData.wealthFeatured,
            sides: pageData.wealthSides,
            quotes: pageData.marketQuotes
        )
        hotActivities.configure(featured: pageData.activityFeatured, sides: pageData.activitySides)
        pensionZone.configure(
            slogan: pageData.pensionSlogan,
            subtitle: pageData.pensionSubtitle,
            services: pageData.pensionServices
        )
        branchService.configure(with: pageData.branch)
        infoSection.configure(market: pageData.infoMarket, videos: pageData.infoVideos)
        consumerProtection.configure(with: pageData.consumerProtection)
    }

    private func bindActions() {
        topSearchBar.onSearchTapped = { [weak self] keyword in
            self?.showToast("搜索「\(keyword)」")
        }
        topSearchBar.onGiftTapped = { [weak self] in
            self?.showToast("幸运抽奖活动即将开启")
        }
        topSearchBar.onVersionTapped = { [weak self] in
            self?.showToast("已切换至标准版")
        }
        topSearchBar.onServiceTapped = { [weak self] in
            self?.showToast("正在为您接入在线客服")
        }
        topSearchBar.onMessageTapped = { [weak self] in
            let count = self?.pageData.messageBadge ?? 0
            self?.showToast("您有 \(count) 条未读消息")
        }

        shortcutRow.onItemTapped = { [weak self] index in
            guard let self, let item = self.pageData.shortcuts[safe: index] else { return }
            switch item.title {
            case "转账":
                self.navigationController?.pushViewController(TransferViewController(), animated: true)
            case "我的账户":
                self.showToast("尾号7890 储蓄卡")
            case "收支":
                self.showToast("本月收入 ¥12,986.32")
            default:
                self.showToast("打开\(item.title)")
            }
        }

        gridMenu.onItemTapped = { [weak self] index in
            guard let self, let item = self.pageData.gridItems[safe: index] else { return }
            if item.title == "全部" {
                self.showToast("全部功能")
            } else {
                self.showToast(item.title)
            }
        }

        noticeTicker.onItemTapped = { [weak self] item in
            self?.showToast(item.text)
        }

        branchService.onQueueTapped = { [weak self] in
            self?.showToast("已为您取号，请留意叫号信息")
        }
        branchService.onPhoneTapped = { [weak self] in
            self?.showToast("正在拨打网点电话")
        }
        branchService.onRefreshTapped = { [weak self] in
            self?.showToast("已刷新附近网点")
        }

        consumerProtection.onItemTapped = { [weak self] item in
            self?.showToast(item.title)
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

extension HomeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y = max(0, scrollView.contentOffset.y)
        let progress = min(1, y / 100)
        headerBackground.alpha = progress
        topSearchBar.apply(style: progress > 0.5 ? .dark : .light)
        headerContainer.layer.shadowColor = UIColor.black.cgColor
        headerContainer.layer.shadowOpacity = Float(0.1 * progress)
        headerContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        headerContainer.layer.shadowRadius = 4
        setBackToTopVisible(y > 480)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
