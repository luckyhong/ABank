//
//  NewsViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class NewsViewController: BaseViewController {

    private let repository = NewsRepository()
    private var snapshot = NewsRepository.initialSnapshot()
    private lazy var pageData = NewsDashboard.page(from: snapshot, followed: followedCategories)
    private var followedCategories = Set(UserDefaults.standard.stringArray(forKey: "news.followedCategories") ?? [])
    private let followCategories = ["财经", "服务", "三农", "房产"]
    private var refreshTask: Task<Void, Never>?
    private var requestGeneration = UUID()
    private var lastRefreshAttempt: Date?
    private let refreshControl = UIRefreshControl()
    private let dataStatusLabel = UILabel()

    private let headerContainer = UIView()
    private let headerBackground = UIView()
    private let searchBar = NewsSearchBarView()
    private let primaryTabs = NewsPrimaryTabsView()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let recommendHeader = NewsRecommendHeaderView()
    private let followHeader = NewsFollowHeaderView()
    private let feedSectionHeader = NewsFeedSectionHeaderView()
    private let loadFooter = NewsLoadMoreFooterView()

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

    private var currentTab: NewsPrimaryTab = .recommend
    private var selectedCategoryIndex = NewsDashboard.categories.firstIndex(of: UserDefaults.standard.string(forKey: "news.preferredCategory") ?? "热点") ?? 0
    private var feedItems: [NewsFeedEntry] = []
    private var currentPage = 1
    private var hasMore = true
    private var isLoading = false

    private var searchBarTopConstraint: Constraint?

    private var lastHeaderLayoutSize: CGSize = .zero
    private var footerState: NewsLoadMoreFooterView.State = .idle

    private let searchBarHeight: CGFloat = 48
    private let primaryTabsHeight: CGFloat = 44

    override func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func setupUI() {
        view.backgroundColor = .white

        setupHeader()
        setupTableView()
        setupBackToTop()
        applyTabLayout(animated: false)
        reloadFeed(resetPage: true)
        dataStatusLabel.text = NewsDashboard.status(snapshot)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAfterTimeChange), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAfterTimeChange), name: .NSCalendarDayChanged, object: nil)
    }

    deinit {
        refreshTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    override func setupBindings() {
        bindHeaderActions()
        bindRecommendHeader()
        bindFollowHeader()
        bindFeedSectionHeader()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        refreshContent(force: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        relayoutTableHeaderIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderLayout()
        relayoutTableHeaderIfNeeded()
        updateLoadFooter()
        updateShortFeedInset()
    }

    // MARK: - Setup

    private func setupHeader() {
        headerBackground.backgroundColor = .white
        headerBackground.alpha = 1

        headerContainer.backgroundColor = .white
        headerContainer.clipsToBounds = false
        headerContainer.layer.zPosition = 20
        headerContainer.addSubview(headerBackground)
        headerContainer.addSubview(searchBar)
        headerContainer.addSubview(primaryTabs)
        headerContainer.addSubview(dataStatusLabel)
        dataStatusLabel.font = .systemFont(ofSize: 11)
        dataStatusLabel.textColor = .abankTextSecondary
        dataStatusLabel.adjustsFontSizeToFitWidth = true
        dataStatusLabel.minimumScaleFactor = 0.8

        view.addSubview(tableView)
        view.addSubview(headerContainer)

        headerContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        headerBackground.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        searchBar.snp.makeConstraints { make in
            searchBarTopConstraint = make.top.equalToSuperview().constraint
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(searchBarHeight)
        }
        primaryTabs.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(primaryTabsHeight)
        }
        dataStatusLabel.snp.makeConstraints { make in
            make.top.equalTo(primaryTabs.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(26)
            make.bottom.equalToSuperview()
        }
    }

    private func setupTableView() {
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.sectionHeaderTopPadding = 0
        tableView.estimatedSectionHeaderHeight = 36
        tableView.estimatedRowHeight = 96
        tableView.delegate = self
        tableView.dataSource = self
        tableView.refreshControl = refreshControl
        refreshControl.tintColor = .abankTeal
        refreshControl.addTarget(self, action: #selector(manualRefresh), for: .valueChanged)

        tableView.register(NewsArticleCell.self, forCellReuseIdentifier: NewsArticleCell.reuseId)
        tableView.register(NewsFeedBannerCell.self, forCellReuseIdentifier: NewsFeedBannerCell.reuseId)
        tableView.register(NewsFeedTopicCell.self, forCellReuseIdentifier: NewsFeedTopicCell.reuseId)
        tableView.register(NewsFeedVideoCell.self, forCellReuseIdentifier: NewsFeedVideoCell.reuseId)
        tableView.register(NewsFeedStripCell.self, forCellReuseIdentifier: NewsFeedStripCell.reuseId)

        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerContainer.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func setupBackToTop() {
        view.addSubview(backToTopButton)
        backToTopButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
            make.size.equalTo(44)
        }
        backToTopButton.addTarget(self, action: #selector(backToTopTapped), for: .touchUpInside)
    }

    // MARK: - Data

    private var visibleStories: [NewsStory] {
        if currentTab == .recommend {
            return snapshot.filtered(category: pageData.categories[selectedCategoryIndex])
        }
        let ids = Set(followedCategories.flatMap { snapshot.filtered(category: $0).map(\.id) })
        return snapshot.stories.filter { ids.contains($0.id) }
    }

    private func reloadFeed(resetPage: Bool) {
        if resetPage { currentPage = 1 }
        let visible = visibleStories
        feedItems = Array(visible.prefix(currentPage * 20)).map { NewsDashboard.entry($0) }
        hasMore = visible.count > feedItems.count
        isLoading = true
        footerState = hasMore ? .idle : .finished
        tableView.reloadData()
        relayoutTableHeaderIfNeeded()
        updateLoadFooter()
        updateShortFeedInset()
        isLoading = false
    }

    private func loadMoreIfNeeded() {
        guard hasMore, !isLoading, tableView.contentSize.height > tableView.bounds.height + 80,
              tableView.contentOffset.y > 120,
              tableView.contentOffset.y > tableView.contentSize.height - tableView.bounds.height - 140 else { return }
        let visible = visibleStories
        let start = feedItems.count
        let end = min(start + 20, visible.count)
        guard start < end else { hasMore = false; updateLoadFooter(); return }
        isLoading = true
        currentPage += 1
        feedItems.append(contentsOf: visible[start..<end].map { NewsDashboard.entry($0) })
        hasMore = end < visible.count
        footerState = hasMore ? .idle : .finished
        tableView.performBatchUpdates {
            tableView.insertRows(at: (start..<end).map { IndexPath(row: $0, section: 0) }, with: .none)
        } completion: { [weak self] _ in
            self?.isLoading = false
            self?.updateLoadFooter()
        }
    }

    @objc private func manualRefresh() { refreshContent(force: true) }

    @objc private func refreshAfterTimeChange() {
        guard viewIfLoaded?.window != nil else { return }
        refreshContent(force: false)
    }

    private func refreshContent(force: Bool) {
        let now = Date()
        if !force {
            guard refreshTask == nil else { return }
            if let lastRefreshAttempt, now.timeIntervalSince(lastRefreshAttempt) < 900,
               Calendar.current.isDate(lastRefreshAttempt, inSameDayAs: now) { return }
        }
        refreshTask?.cancel()
        let generation = UUID()
        requestGeneration = generation
        lastRefreshAttempt = now
        dataStatusLabel.text = "正在更新资讯…"
        refreshTask = Task { @MainActor [weak self, repository] in
            do {
                let result = try await repository.load(now: now)
                guard let self, !Task.isCancelled, self.requestGeneration == generation else { return }
                self.snapshot = result
                self.pageData = NewsDashboard.page(from: result, followed: self.followedCategories)
                self.bindRecommendHeader()
                self.bindFollowHeader()
                self.reloadFeed(resetPage: false)
                self.dataStatusLabel.text = NewsDashboard.status(result)
                self.refreshControl.endRefreshing()
                let illustrated = try await repository.enrichVideoCovers(in: result)
                guard !Task.isCancelled, self.requestGeneration == generation else { return }
                if illustrated.stories != self.snapshot.stories {
                    self.snapshot = illustrated
                    self.pageData = NewsDashboard.page(from: illustrated, followed: self.followedCategories)
                    self.recommendHeader.updateVideoImages(self.pageData.hotVideos)
                    self.reloadFeed(resetPage: false)
                }
                self.refreshTask = nil
            } catch {
                guard let self, self.requestGeneration == generation else { return }
                self.dataStatusLabel.text = NewsDashboard.status(self.snapshot)
                self.refreshControl.endRefreshing()
                self.refreshTask = nil
            }
        }
    }

    private func openStory(id: String?) {
        guard let id, let story = snapshot.stories.first(where: { $0.id == id }) else { return }
        navigationController?.pushViewController(NewsStoryViewController(story: story), animated: true)
    }

    private func openList(title: String, stories: [NewsStory]) {
        navigationController?.pushViewController(NewsStoryListViewController(title: title, stories: stories), animated: true)
    }

    private func selectCategory(_ category: String) {
        guard let index = pageData.categories.firstIndex(of: category) else { return }
        currentTab = .recommend
        selectedCategoryIndex = index
        UserDefaults.standard.set(category, forKey: "news.preferredCategory")
        feedSectionHeader.configure(categories: pageData.categories, selectedIndex: index, showsOtherChip: false)
        applyTabLayout(animated: false)
        reloadFeed(resetPage: true)
        scrollToFeedStart()
    }

    private func scrollToFeedStart(pass: Int = 0) {
        // Scrolling replaces UITableView's estimates with measured heights. Recheck
        // the bottom allowance on the next layout turn for sparse categories.
        DispatchQueue.main.async { [weak self] in
            guard let self, self.currentTab == .recommend else { return }
            self.updateShortFeedInset()
            let target = self.tableView.rectForHeader(inSection: 0).minY
            self.tableView.setContentOffset(CGPoint(x: 0, y: target), animated: false)
            self.tableView.layoutIfNeeded()
            self.updateShortFeedInset()
            self.tableView.setContentOffset(CGPoint(x: 0, y: target), animated: false)
            if pass < 2 {
                self.scrollToFeedStart(pass: pass + 1)
            }
        }
    }

    private func updateFollows() {
        UserDefaults.standard.set(followedCategories.sorted(), forKey: "news.followedCategories")
        pageData = NewsDashboard.page(from: snapshot, followed: followedCategories)
        bindFollowHeader()
        reloadFeed(resetPage: true)
    }

    private func showSearch() {
        let alert = UIAlertController(title: "搜索资讯", message: "在已加载的资讯中搜索", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "输入标题、关键词或来源"; $0.clearButtonMode = .whileEditing }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "搜索", style: .default) { [weak self, weak alert] _ in
            guard let self, let query = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !query.isEmpty else { return }
            let matches = self.snapshot.stories.filter { ($0.title + $0.summary + $0.publisher).localizedCaseInsensitiveContains(query) }
            self.openList(title: "搜索：" + String(query.prefix(20)), stories: matches)
        })
        present(alert, animated: true)
    }

    // MARK: - Layout

    private func updateHeaderLayout() {
        searchBarTopConstraint?.update(offset: view.safeAreaInsets.top)
    }

    private func relayoutTableHeaderIfNeeded() {
        let width = tableView.bounds.width
        guard width > 1 else { return }

        let header: UIView = currentTab == .recommend ? recommendHeader : followHeader
        applyTableHeader(header, width: width)
    }

    private func applyTableHeader(_ header: UIView, width: CGFloat) {
        header.translatesAutoresizingMaskIntoConstraints = true
        if header.frame.width != width {
            header.frame = CGRect(x: 0, y: 0, width: width, height: max(header.bounds.height, 1))
        }
        header.setNeedsLayout()
        header.layoutIfNeeded()

        let fittedHeight = ceil(header.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height)
        guard fittedHeight > 1 else { return }

        let newSize = CGSize(width: width, height: fittedHeight)
        if tableView.tableHeaderView === header, lastHeaderLayoutSize == newSize {
            return
        }

        header.frame = CGRect(origin: .zero, size: newSize)
        tableView.tableHeaderView = header
        lastHeaderLayoutSize = newSize
    }

    private func updateShortFeedInset() {
        guard tableView.bounds.height > 0 else { return }
        tableView.layoutIfNeeded()
        let headerHeight = tableView.tableHeaderView?.bounds.height ?? 0
        let tailHeight = max(0, tableView.contentSize.height - headerHeight)
        let needed: CGFloat = currentTab == .recommend ? max(0, tableView.bounds.height - tailHeight) : 0
        if abs(tableView.contentInset.bottom - needed) > 0.5 {
            tableView.contentInset.bottom = needed
        }
    }

    private func updateLoadFooter() {
        if feedItems.isEmpty {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 80))
            label.text = currentTab == .follow && followedCategories.isEmpty ? "关注感兴趣的频道，开始阅读" : "近期暂无匹配资讯，试试其他频道"
            label.font = .systemFont(ofSize: 13)
            label.textColor = .abankTextSecondary
            label.textAlignment = .center
            label.numberOfLines = 0
            tableView.tableFooterView = label
            return
        }

        let width = max(tableView.bounds.width, 1)
        switch footerState {
        case .idle:
            tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: Spacing.pageBottom))
        case .loading, .finished:
            loadFooter.configure(state: footerState)
            loadFooter.frame = CGRect(x: 0, y: 0, width: width, height: 48)
            tableView.tableFooterView = loadFooter
        }
    }

    private func applyTabLayout(animated: Bool) {
        primaryTabs.select(currentTab, animated: animated)
        tableView.backgroundColor = currentTab == .recommend ? .white : .abankBackground
        lastHeaderLayoutSize = .zero
        updateHeaderLayout()
        relayoutTableHeaderIfNeeded()
        updateLoadFooter()

        let updates = { self.view.layoutIfNeeded() }
        if animated {
            UIView.animate(withDuration: 0.22, animations: updates)
        } else {
            updates()
        }
    }

    // MARK: - Bindings

    private func bindHeaderActions() {
        searchBar.configure(
            placeholders: pageData.searchPlaceholders,
            badgeCount: pageData.messageBadge
        )
        searchBar.onScanTapped = { [weak self] in self?.showToast("扫一扫") }
        searchBar.onSearchTapped = { [weak self] _ in self?.showSearch() }
        searchBar.onServiceTapped = { [weak self] in self?.showToast("在线客服") }
        searchBar.onMessageTapped = { [weak self] in self?.showToast("消息中心") }

        primaryTabs.onTabChanged = { [weak self] tab in
            guard let self, tab != self.currentTab else { return }
            self.currentTab = tab
            self.applyTabLayout(animated: true)
            self.reloadFeed(resetPage: true)
            self.tableView.setContentOffset(.zero, animated: false)
        }
    }

    private func bindFeedSectionHeader() {
        feedSectionHeader.configure(
            categories: pageData.categories,
            selectedIndex: selectedCategoryIndex,
            showsOtherChip: false
        )
        feedSectionHeader.onCategoryChanged = { [weak self] index, name in
            guard let self else { return }
            self.selectedCategoryIndex = index
            UserDefaults.standard.set(name, forKey: "news.preferredCategory")
            self.reloadFeed(resetPage: true)
            self.scrollToFeedStart()
        }
        feedSectionHeader.onMoreTapped = { [weak self] in
            guard let self else { return }
            let alert = UIAlertController(title: "选择频道", message: nil, preferredStyle: .actionSheet)
            for category in self.pageData.categories {
                alert.addAction(UIAlertAction(title: category, style: .default) { [weak self] _ in self?.selectCategory(category) })
            }
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.popoverPresentationController?.sourceView = self.feedSectionHeader
            self.present(alert, animated: true)
        }
        feedSectionHeader.onOtherTapped = { [weak self] in self?.showToast("其他频道") }
    }

    private func bindRecommendHeader() {
        recommendHeader.configure(
            banners: pageData.heroBanners,
            flash: pageData.flashNews,
            videos: pageData.hotVideos,
            hotItems: pageData.hotRankItems,
            topic: pageData.interactiveTopic
        )
        recommendHeader.onHotListTapped = { [weak self] in
            guard let self else { return }
            self.openList(title: "最新资讯", stories: self.snapshot.filtered(category: "热点"))
        }
        recommendHeader.onHotVideosTapped = { [weak self] in
            guard let self else { return }
            self.openList(title: "新闻视频", stories: self.snapshot.stories.filter { $0.channel == .video })
        }
        recommendHeader.onHeroTapped = { [weak self] index in self?.openStory(id: self?.pageData.heroBanners[safe: index]?.storyID) }
        recommendHeader.onFlashTapped = { [weak self] in self?.openStory(id: self?.snapshot.filtered(category: "热点").first?.id) }
        recommendHeader.onRankTapped = { [weak self] index in self?.openStory(id: self?.snapshot.filtered(category: "热点")[safe: index]?.id) }
        recommendHeader.onVideoTapped = { [weak self] index in self?.openStory(id: self?.pageData.hotVideos[safe: index]?.storyID) }
        recommendHeader.onTopicOptionTapped = { [weak self] index in
            guard let self, let category = self.pageData.interactiveTopic.options[safe: index] else { return }
            self.selectCategory(category)
        }
    }

    private func bindFollowHeader() {
        followHeader.configure(suggestions: pageData.followSuggestions, trending: pageData.trendingItems, poll: pageData.pkPoll)
        followHeader.onFollowAllTapped = { [weak self] in
            guard let self else { return }
            self.followedCategories.formUnion(self.followCategories)
            self.updateFollows()
        }
        followHeader.onFollowTapped = { [weak self] index in
            guard let self, let category = self.followCategories[safe: index] else { return }
            if self.followedCategories.contains(category) { self.followedCategories.remove(category) }
            else { self.followedCategories.insert(category) }
            self.updateFollows()
        }
        followHeader.onTrendingTapped = { [weak self] index in self?.openStory(id: self?.snapshot.filtered(category: "热点")[safe: index]?.id) }
        followHeader.onPKTapped = { [weak self] isLeft in
            guard let self else { return }
            let channel: NewsChannel = isLeft ? .finance : .life
            UserDefaults.standard.set(channel.rawValue, forKey: "news.readingPreference")
            self.openList(title: isLeft ? "财经资讯" : "生活服务", stories: self.snapshot.stories.filter { $0.channel == channel })
        }
    }

    @objc private func backToTopTapped() {
        tableView.setContentOffset(.zero, animated: true)
    }

    private func setBackToTopVisible(_ visible: Bool) {
        guard backToTopButton.isHidden == visible else { return }
        backToTopButton.isHidden = !visible
        UIView.animate(withDuration: 0.2) {
            self.backToTopButton.alpha = visible ? 1 : 0
        }
    }
}

// MARK: - UITableView

extension NewsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        feedItems.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        currentTab == .recommend ? feedSectionHeader : nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard currentTab == .recommend else { return 0 }
        return NewsFeedSectionHeaderView.preferredHeight(showsOtherChip: false)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let entry = feedItems[indexPath.row]
        switch entry {
        case .article(let item):
            let cell = tableView.dequeueReusableCell(withIdentifier: NewsArticleCell.reuseId, for: indexPath) as! NewsArticleCell
            cell.configure(with: item)
            return cell
        case .banner(let item):
            let cell = tableView.dequeueReusableCell(withIdentifier: NewsFeedBannerCell.reuseId, for: indexPath) as! NewsFeedBannerCell
            cell.configure(with: item)
            return cell
        case .topic(let item):
            let cell = tableView.dequeueReusableCell(withIdentifier: NewsFeedTopicCell.reuseId, for: indexPath) as! NewsFeedTopicCell
            cell.configure(with: item)
            return cell
        case .video(let item):
            let cell = tableView.dequeueReusableCell(withIdentifier: NewsFeedVideoCell.reuseId, for: indexPath) as! NewsFeedVideoCell
            cell.configure(with: item)
            return cell
        case .strip(let item):
            let cell = tableView.dequeueReusableCell(withIdentifier: NewsFeedStripCell.reuseId, for: indexPath) as! NewsFeedStripCell
            cell.configure(with: item)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let entry = feedItems[indexPath.row]
        openStory(id: entry.id)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y = max(0, scrollView.contentOffset.y)
        headerContainer.layer.shadowColor = UIColor.black.cgColor
        headerContainer.layer.shadowOpacity = Float(0.08 * min(1, y / 80))
        headerContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        headerContainer.layer.shadowRadius = 4

        setBackToTopVisible(y > 500)
        loadMoreIfNeeded()
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
