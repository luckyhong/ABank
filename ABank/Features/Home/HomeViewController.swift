//
//  HomeViewController.swift
//  ABank
//
//  Created by 韩继宏 on 2025/10/27.
//

import UIKit
import SnapKit

final class HomeViewController: BankingDataViewController {

    private let pageData = MockDataProvider.shared.getHomePageData()
    private let preferences: FeaturePreferencesStore = .shared
    private var favoriteGridItems: [HomeGridItem] = []
    private var preferencesObserver: NSObjectProtocol?
    private var marketQuoteTask: Task<Void, Never>?
    private var marketQuoteTimer: Timer?

    deinit {
        marketQuoteTask?.cancel()
        marketQuoteTimer?.invalidate()
        if let preferencesObserver { NotificationCenter.default.removeObserver(preferencesObserver) }
    }

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
        layer.locations = [0, 0.52, 1]
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

    override var prefersNavigationBarHidden: Bool { true }

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

        topBackgroundView.layer.addSublayer(topBackgroundGradient)
        topBackgroundView.isUserInteractionEnabled = false
        contentView.addSubview(topBackgroundView)
        topBackgroundView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            topBackgroundHeightConstraint = make.height.equalTo(260).constraint
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
            make.top.equalTo(heroBanner.snp.bottom).offset(-14)
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
            make.bottom.equalToSuperview().offset(-Spacing.pageBottom)
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

        bindData()
        bindActions()
        preferencesObserver = NotificationCenter.default.addObserver(
            forName: FeaturePreferencesStore.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.reloadFavoriteGrid() }
        for name in [BankMessageStore.didChange, BenefitsStore.didChangeNotification] {
            NotificationCenter.default.addObserver(self, selector: #selector(homeStoreDidChange), name: name, object: nil)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(reloadBranchCard),
                                               name: CitySelectionStore.didChangeNotification, object: nil)
    }

    override func refreshBankingData() {
        let dates = BankingDateContext.system
        let now = dates.now
        let messageStore = BankMessageStore.shared
        let unread = messageStore.messages().filter { !messageStore.isRead($0) }
        topSearchBar.configure(placeholders: pageData.searchPlaceholders, badgeCount: unread.count)

        let title = unread.first.map { "\($0.title) · \(unread.count)条未读" } ?? "暂无未读消息"
        let stories = NewsDemoContent.snapshot(now: now).stories
        var notices = [HomeNoticeItem(tag: "待办", text: title, route: .messages)]
        if let story = stories.first {
            notices.append(HomeNoticeItem(tag: "焦点", text: story.title, route: .newsFeed))
            let featured = stories[safe: 1] ?? story
            infoSection.configureMarket(HomeInfoMarketItem(
                title: "金融小课堂", source: featured.publisher, summary: featured.title + "。 " + featured.summary
            ))
        }
        noticeTicker.configure(with: notices)

        let benefits = BenefitsStore.shared
        let points = "可用积分 \(benefits.balance(.points))"
        let checkIn = benefits.hasCheckedInToday ? "今日已签到" : "签到可领取\(benefits.nextCheckInReward)小豆"
        let promoItems = pageData.promoBanners.map { item -> HomePromoBannerItem in
            var subtitle = item.subtitle
            switch item.route {
            case .pointsMall: subtitle = points
            case .beans: subtitle = checkIn
            default: break
            }
            return HomePromoBannerItem(title: item.title, subtitle: subtitle, tone: item.tone, route: item.route)
        }
        promoBanner.configure(with: promoItems)
        hotActivities.configure(
            featured: HomeActivityFeaturedItem(title: "小豆乐园", subtitle: checkIn, route: .beans),
            sides: [
                HomeActivitySideItem(title: "积分商城", subtitle: points, actionTitle: "去兑换 ›", route: .pointsMall),
                HomeActivitySideItem(title: "我的卡券", subtitle: "\(benefits.unusedCouponCount)张可用", actionTitle: "去查看 ›", route: .coupons)
            ]
        )
        refreshMarketQuotes()
        reloadBranchCard()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        marketQuoteTimer?.invalidate()
        marketQuoteTimer = nil
        marketQuoteTask?.cancel()
        marketQuoteTask = nil
    }

    private func refreshMarketQuotes(force: Bool = false) {
        guard marketQuoteTask == nil else { return }
        marketQuoteTimer?.invalidate()
        marketQuoteTask = Task { [weak self] in
            let repository = HomeMarketQuotesRepository.shared
            let cached = await repository.currentQuotes()
            guard !Task.isCancelled else { return }
            self?.wealthSelection.configureQuotes(cached, updating: true)
            let quotes = await repository.refresh(force: force)
            guard !Task.isCancelled, let self else { return }
            self.wealthSelection.configureQuotes(quotes)
            self.marketQuoteTask = nil
            let interval = quotes.needsRetry ? HomeMarketQuotesRepository.retryInterval : HomeMarketQuotesRepository.refreshInterval
            self.marketQuoteTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
                guard UIApplication.shared.applicationState == .active else { return }
                self?.refreshMarketQuotes()
            }
        }
    }

    @objc private func homeStoreDidChange() {
        guard isViewLoaded, view.window != nil else { return }
        refreshBankingData()
    }

    /// 网点卡显示当前城市默认网点与实时营业状态。
    @objc private func reloadBranchCard() {
        guard isViewLoaded else { return }
        branchService.configure(with: MockDataProvider.shared.homeBranchInfo())
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let safeTop = view.safeAreaInsets.top
        headerHeightConstraint?.update(offset: headerContentHeight + safeTop)
        searchBarTopConstraint?.update(offset: safeTop + 2)
        heroTopConstraint?.update(offset: headerContentHeight + safeTop)
        topBackgroundHeightConstraint?.update(offset: headerContentHeight + safeTop + 150)
        topBackgroundGradient.frame = topBackgroundView.bounds

        if !hasSetInitialOffset {
            hasSetInitialOffset = true
            scrollViewDidScroll(scrollView)
        }
    }

    private func bindData() {
        topSearchBar.apply(style: .banner)
        heroBanner.onPageChanged = { [weak self] item in
            guard let self else { return }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.topBackgroundGradient.colors = [
                item.backdropColor.withAlphaComponent(0.72).cgColor,
                item.backdropColor.cgColor,
                UIColor.abankBackground.cgColor
            ]
            CATransaction.commit()
        }
        heroBanner.configure(with: pageData.heroBanners)
        shortcutRow.configure(with: pageData.shortcuts)
        reloadFavoriteGrid()
        wealthSelection.configure(
            featured: pageData.wealthFeatured,
            sides: pageData.wealthSides
        )
        pensionZone.configure(
            slogan: pageData.pensionSlogan,
            subtitle: pageData.pensionSubtitle,
            services: pageData.pensionServices
        )
        infoSection.configure(market: pageData.infoMarket, videos: pageData.infoVideos)
        consumerProtection.configure(with: pageData.consumerProtection)
    }

    private func bindActions() {
        wealthSelection.onRetry = { [weak self] in self?.refreshMarketQuotes(force: true) }
        wealthSelection.onMore = { [weak self] in
            guard let self else { return }
            self.router.open(.wealthProducts, from: self)
        }
        wealthSelection.onFeatured = { [weak self] in guard let self else { return }; self.router.open(feature: .fund, from: self) }
        wealthSelection.onSide = { [weak self] index in guard let self else { return }; self.router.open(index == 0 ? .deposits : .comingSoon(.preciousMetals), from: self) }
        heroBanner.onItemTapped = { [weak self] index in
            guard let self, let feature = self.pageData.heroBanners[safe: index]?.featureID else { return }
            self.router.open(feature: feature, from: self)
        }
        topSearchBar.onSearchTapped = { [weak self] keyword in
            guard let self else { return }
            self.router.open(.allFeatures(searchKeyword: keyword), from: self)
        }
        topSearchBar.onGiftTapped = { [weak self] in
            guard let self else { return }; self.router.open(.benefits, from: self)
        }
        topSearchBar.onVersionTapped = { [weak self] in
            guard let self else { return }; self.router.open(.settings, from: self)
        }
        topSearchBar.onServiceTapped = { [weak self] in
            guard let self else { return }
            self.router.open(.assistant, from: self)
        }
        topSearchBar.onMessageTapped = { [weak self] in
            guard let self else { return }; self.router.open(.messages, from: self)
        }

        shortcutRow.onItemTapped = { [weak self] index in
            guard let self, let id = self.pageData.shortcuts[safe: index]?.featureID else { return }
            self.router.open(feature: id, from: self)
        }

        gridMenu.onItemTapped = { [weak self] index in
            guard let self, let item = self.favoriteGridItems[safe: index] else { return }
            if let id = item.featureID {
                self.router.open(feature: id, from: self)
            } else {
                self.router.open(.allFeatures(searchKeyword: nil), from: self)
            }
        }

        noticeTicker.onItemTapped = { [weak self] item in
            guard let self else { return }
            self.router.open(item.route, from: self)
        }
        promoBanner.onItemTapped = { [weak self] item in
            guard let self, let route = item.route else { return }
            self.router.open(route, from: self)
        }
        hotActivities.onAction = { [weak self] route in
            guard let self else { return }
            self.router.open(route, from: self)
        }

        branchService.onQueueTapped = { [weak self] in
            guard let self else { return }
            self.router.open(feature: .branchQueue, from: self)
        }
        branchService.onServiceTapped = { [weak self] index in
            guard let self, let id = self.pageData.branch.services[safe: index]?.featureID else { return }
            self.router.open(feature: id, from: self)
        }
        branchService.onPhoneTapped = { [weak self] in
            guard let self else { return }; self.router.open(.branchList, from: self)
        }
        branchService.onRefreshTapped = { [weak self] in
            self?.reloadBranchCard()
            self?.showToast("已刷新")
        }

        consumerProtection.onItemTapped = { [weak self] _ in
            guard let self else { return }
            self.router.open(.assistant, from: self)
        }
    }

    /// 首页宫格 = 常用功能（最多 9 个）+ 固定“全部”。
    private func reloadFavoriteGrid() {
        favoriteGridItems = preferences.favorites.map { HomeGridItem(descriptor: FeatureCatalog.descriptor($0)) } + [.allEntry]
        gridMenu.configure(with: favoriteGridItems)
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
        let progress = min(1, y / 80)
        headerBackground.alpha = progress
        topSearchBar.apply(style: progress > 0.5 ? .dark : .banner)
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
