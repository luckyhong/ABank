//
//  LifeViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class LifeViewController: BankingDataViewController {

    private var pageData: LifePageData?

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.contentInsetAdjustmentBehavior = .never
        return sv
    }()
    private let contentView = UIView()

    private let headerContainer = UIView()
    private let headerBackground = UIView()
    private let searchBar = LifeSearchBarView()

    private let bannerView = LifeBannerView()
    private let serviceGrid = LifeServiceGridView()
    private let colorfulActivities = LifeColorfulActivitiesView()
    private let moreHeader = SectionHeaderView(title: "更多精彩", showsChevron: false, titleFont: .abankTitle2())
    private let masonryGrid = LifeMasonryGridView()

    private let backToTopButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.up"), for: .normal)
        button.tintColor = .white
        button.accessibilityLabel = "返回生活页顶部"
        button.accessibilityIdentifier = "life.backToTop"
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

    override var prefersNavigationBarHidden: Bool { true }

    override func setupUI() {
        view.backgroundColor = .abankSectionBackground

        view.addSubview(scrollView)
        scrollView.delegate = self
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        [bannerView, serviceGrid, colorfulActivities, moreHeader, masonryGrid]
            .forEach { contentView.addSubview($0) }

        let inset = Spacing.md
        bannerView.snp.makeConstraints { make in
            contentTopConstraint = make.top.equalToSuperview().offset(headerContentHeight + 8).constraint
            make.leading.trailing.equalToSuperview().inset(inset)
        }
        serviceGrid.snp.makeConstraints { make in
            make.top.equalTo(bannerView.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(Spacing.sm)
        }
        colorfulActivities.snp.makeConstraints { make in
            make.top.equalTo(serviceGrid.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(inset)
        }
        moreHeader.snp.makeConstraints { make in
            make.top.equalTo(colorfulActivities.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview().inset(inset)
            make.height.equalTo(36)
        }
        masonryGrid.snp.makeConstraints { make in
            make.top.equalTo(moreHeader.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(inset)
            make.bottom.equalToSuperview().inset(Spacing.pageBottom)
        }

        headerBackground.backgroundColor = .white
        headerBackground.alpha = 1
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
    }

    override func setupBindings() {
        bindActions()
        for name in [CitySelectionStore.didChangeNotification, BenefitsStore.didChangeNotification] {
            NotificationCenter.default.addObserver(self, selector: #selector(lifeContentDidChange), name: name, object: nil)
        }
    }

    override func refreshBankingData() {
        let next = MockDataProvider.shared.getLifePageData()
        let previous = pageData
        pageData = next
        searchBar.configure(city: next.city, placeholders: next.searchPlaceholders)
        bannerView.configure(with: next.banners)
        if previous == nil { serviceGrid.configure(with: next.gridPages) }
        if previous?.colorfulFeatured != next.colorfulFeatured
            || previous?.colorfulSides != next.colorfulSides || previous?.promoBanner != next.promoBanner {
            colorfulActivities.configure(featured: next.colorfulFeatured, sides: next.colorfulSides, promo: next.promoBanner)
        }
        if previous?.feedItems != next.feedItems {
            masonryGrid.configure(with: next.feedItems)
        }
    }

    @objc private func lifeContentDidChange() {
        guard viewIfLoaded?.window != nil else { return }
        refreshBankingData()
    }

    private func bindActions() {
        searchBar.onCityTapped = { [weak self] in
            guard let self else { return }
            self.router.open(.cityPicker, from: self)
        }
        searchBar.onSearchTapped = { [weak self] keyword in
            guard let self else { return }; self.router.open(.allFeatures(searchKeyword: keyword), from: self)
        }
        searchBar.onOrdersTapped = { [weak self] in
            guard let self else { return }
            self.router.open(feature: .orders, from: self)
        }
        searchBar.onCouponsTapped = { [weak self] in
            guard let self else { return }
            self.router.open(.coupons, from: self)
        }

        bannerView.onItemTapped = { [weak self] index in
            guard let self, let item = self.pageData?.banners[safe: index] else { return }
            self.router.open(item.route, from: self)
        }

        serviceGrid.onItemTapped = { [weak self] page, index in
            guard let self, let item = self.pageData?.gridPages[safe: page]?[safe: index] else { return }
            if let route = item.route {
                self.router.open(route, from: self)
            } else if let id = item.featureID {
                self.router.open(feature: id, from: self)
            } else {
                self.router.open(.allFeatures(searchKeyword: nil), from: self)
            }
        }

        colorfulActivities.onHeaderTapped = { [weak self] in guard let self else { return }; self.router.open(.benefits, from: self) }
        colorfulActivities.onFeaturedTapped = { [weak self] in
            guard let self else { return }
            self.router.open(feature: .beans, from: self)
        }
        colorfulActivities.onSideTapped = { [weak self] index in
            guard let self else { return }
            self.router.open(index == 0 ? .cityPicker : .coupons, from: self)
        }
        colorfulActivities.onPromoTapped = { [weak self] in
            guard let self else { return }
            self.router.open(feature: .benefits, from: self)
        }

        masonryGrid.onItemTapped = { [weak self] index in
            guard let self, let item = self.pageData?.feedItems[safe: index] else { return }
            if let route = item.route {
                self.router.open(route, from: self)
            } else {
                self.navigationController?.pushViewController(
                    LifeTipViewController(tip: item.subtitle), animated: true
                )
            }
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

extension LifeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y = max(0, scrollView.contentOffset.y)
        let progress = min(1, y / 80)
        headerContainer.layer.shadowColor = UIColor.black.cgColor
        headerContainer.layer.shadowOpacity = Float(0.08 * progress)
        headerContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        headerContainer.layer.shadowRadius = 4
        setBackToTopVisible(y > 500)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
