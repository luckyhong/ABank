//
//  NewsViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class NewsViewController: BaseViewController {

    private let pageData = MockDataProvider.shared.getNewsPageData()

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
    private var selectedCategoryIndex = 0
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
            make.bottom.equalToSuperview()
        }
    }

    private func setupTableView() {
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.sectionHeaderTopPadding = 0
        tableView.estimatedSectionHeaderHeight = 54
        tableView.estimatedRowHeight = 96
        tableView.delegate = self
        tableView.dataSource = self

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

    private func reloadFeed(resetPage: Bool) {
        if resetPage {
            currentPage = 1
            hasMore = true
            isLoading = false
            feedItems = pageData.initialFeed
            footerState = .idle
        }
        tableView.reloadData()
        relayoutTableHeaderIfNeeded()
        updateLoadFooter()
    }

    private func loadMoreIfNeeded() {
        guard currentTab == .recommend, hasMore, !isLoading else { return }
        guard tableView.bounds.width > 1, recommendHeader.bounds.height > 200 else { return }

        let offsetY = tableView.contentOffset.y
        let contentHeight = tableView.contentSize.height
        let frameHeight = tableView.frame.height
        guard contentHeight > frameHeight + 80 else { return }
        guard offsetY > 120, offsetY > contentHeight - frameHeight - 140 else { return }

        isLoading = true
        footerState = .loading
        updateLoadFooter()

        let category = pageData.categories[selectedCategoryIndex]
        let page = currentPage + 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self else { return }
            let result = MockDataProvider.shared.loadMoreNewsFeed(page: page, category: category)
            self.currentPage = page
            self.feedItems.append(contentsOf: result.items)
            self.hasMore = result.hasMore
            self.isLoading = false
            self.footerState = result.hasMore ? .idle : .finished
            self.tableView.reloadData()
            self.relayoutTableHeaderIfNeeded()
            self.updateLoadFooter()
        }
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

    private func updateLoadFooter() {
        guard currentTab == .recommend else {
            tableView.tableFooterView = UIView(frame: .zero)
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
        searchBar.onSearchTapped = { [weak self] keyword in self?.showToast("搜索「\(keyword)」") }
        searchBar.onServiceTapped = { [weak self] in self?.showToast("在线客服") }
        searchBar.onMessageTapped = { [weak self] in self?.showToast("消息中心") }

        primaryTabs.onTabChanged = { [weak self] tab in
            guard let self, tab != self.currentTab else { return }
            self.currentTab = tab
            self.applyTabLayout(animated: true)
            if tab == .recommend {
                self.reloadFeed(resetPage: true)
            } else {
                self.tableView.reloadData()
                self.updateLoadFooter()
            }
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
            self.showToast("切换至「\(name)」")
            self.reloadFeed(resetPage: true)
            self.tableView.setContentOffset(
                CGPoint(x: 0, y: self.recommendHeader.bounds.height),
                animated: false
            )
        }
        feedSectionHeader.onMoreTapped = { [weak self] in self?.showToast("更多分类") }
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
        recommendHeader.onHotListTapped = { [weak self] in self?.showToast("资讯热榜") }
        recommendHeader.onHotVideosTapped = { [weak self] in self?.showToast("热门视频") }
        recommendHeader.onVideoTapped = { [weak self] index in
            let title = self?.pageData.hotVideos[safe: index]?.title ?? "视频"
            self?.showToast(title)
        }
        recommendHeader.onTopicOptionTapped = { [weak self] index in
            let option = self?.pageData.interactiveTopic.options[safe: index] ?? "选项"
            self?.showToast("已选择 \(option)")
        }
    }

    private func bindFollowHeader() {
        followHeader.configure(
            suggestions: pageData.followSuggestions,
            trending: pageData.trendingItems,
            poll: pageData.pkPoll
        )
        followHeader.onFollowAllTapped = { [weak self] in self?.showToast("已一键关注") }
        followHeader.onFollowTapped = { [weak self] index in
            let name = self?.pageData.followSuggestions[safe: index]?.name ?? "账号"
            self?.showToast("已关注 \(name)")
        }
        followHeader.onTrendingTapped = { [weak self] index in
            let title = self?.pageData.trendingItems[safe: index]?.title ?? "热点"
            self?.showToast(title)
        }
        followHeader.onPKTapped = { [weak self] isLeft in
            let option = isLeft ? self?.pageData.pkPoll.leftOption : self?.pageData.pkPoll.rightOption
            self?.showToast("已投票：\(option ?? "")")
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
        currentTab == .recommend ? 1 : 0
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
        switch entry {
        case .article(let item): showToast(item.title)
        case .banner(let item): showToast(item.title)
        case .topic(let item): showToast(item.title)
        case .video(let item): showToast(item.title)
        case .strip(let item): showToast(item.headline)
        }
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
