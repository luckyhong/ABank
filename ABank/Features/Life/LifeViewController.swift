//
//  LifeViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class LifeViewController: BaseViewController {

    private let pageData = MockDataProvider.shared.getLifePageData()

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
    private let moreHeader = SectionHeaderView(title: "更多精彩", showsChevron: false)
    private let masonryGrid = LifeMasonryGridView()
    private let loadFinishedLabel = UILabel()

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

        [bannerView, serviceGrid, colorfulActivities, moreHeader, masonryGrid, loadFinishedLabel]
            .forEach { contentView.addSubview($0) }

        let inset = Spacing.md
        bannerView.snp.makeConstraints { make in
            contentTopConstraint = make.top.equalToSuperview().offset(headerContentHeight + 8).constraint
            make.leading.trailing.equalToSuperview().inset(inset)
        }
        serviceGrid.snp.makeConstraints { make in
            make.top.equalTo(bannerView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(inset)
        }
        colorfulActivities.snp.makeConstraints { make in
            make.top.equalTo(serviceGrid.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(inset)
        }
        moreHeader.snp.makeConstraints { make in
            make.top.equalTo(colorfulActivities.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(inset)
            make.height.equalTo(24)
        }
        masonryGrid.snp.makeConstraints { make in
            make.top.equalTo(moreHeader.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(inset)
        }
        loadFinishedLabel.snp.makeConstraints { make in
            make.top.equalTo(masonryGrid.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-Spacing.pageBottom)
        }

        loadFinishedLabel.font = .systemFont(ofSize: 13)
        loadFinishedLabel.textColor = .abankTextTertiary
        loadFinishedLabel.textAlignment = .center

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
    }

    override func setupBindings() {
        bindData()
        bindActions()
    }

    private func bindData() {
        searchBar.configure(city: pageData.city, placeholders: pageData.searchPlaceholders)
        bannerView.configure(with: pageData.banners)
        serviceGrid.configure(with: pageData.gridPages)
        colorfulActivities.configure(
            featured: pageData.colorfulFeatured,
            sides: pageData.colorfulSides,
            promo: pageData.promoBanner
        )
        masonryGrid.configure(with: pageData.feedItems)
        loadFinishedLabel.text = pageData.loadFinishedText
    }

    private func bindActions() {
        searchBar.onCityTapped = { [weak self] in self?.showToast("切换城市") }
        searchBar.onSearchTapped = { [weak self] keyword in
            self?.showToast("搜索「\(keyword)」")
        }
        searchBar.onOrdersTapped = { [weak self] in self?.showToast("我的订单") }
        searchBar.onCouponsTapped = { [weak self] in self?.showToast("我的卡券") }

        serviceGrid.onItemTapped = { [weak self] page, index in
            let title = self?.pageData.gridPages[safe: page]?[safe: index]?.title ?? "服务"
            self?.showToast(title)
        }

        colorfulActivities.onHeaderTapped = { [weak self] in self?.showToast("缤纷活动") }
        colorfulActivities.onFeaturedTapped = { [weak self] in
            self?.showToast(self?.pageData.colorfulFeatured.title ?? "小豆乐园")
        }
        colorfulActivities.onSideTapped = { [weak self] index in
            let title = self?.pageData.colorfulSides[safe: index]?.title ?? "活动"
            self?.showToast(title)
        }
        colorfulActivities.onPromoTapped = { [weak self] in
            self?.showToast(self?.pageData.promoBanner.title ?? "海量权益")
        }

        masonryGrid.onItemTapped = { [weak self] index in
            let title = self?.pageData.feedItems[safe: index]?.title ?? "精彩内容"
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

extension LifeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y = max(0, scrollView.contentOffset.y)
        let progress = min(1, y / 80)
        headerBackground.alpha = progress
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
