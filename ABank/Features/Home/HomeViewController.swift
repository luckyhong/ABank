//
//  HomeViewController.swift
//  ABank
//
//  Created by 韩继宏 on 2025/10/27.
//

import UIKit
import SnapKit

class HomeViewController: BaseViewController {
    private let headerHeight: CGFloat = 56
    private var hasSetInitialContentOffset = false
    private var headerHeightConstraint: Constraint?
    private var searchBarTopConstraint: Constraint?
    private var topBackgroundHeightConstraint: Constraint?
    private var shortcutRowTopConstraint: Constraint?
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    private let contentView = UIView()
    private let topBackgroundView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    private let topBackgroundGradient: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(red: 1.0, green: 0.65, blue: 0.35, alpha: 1).cgColor,
            UIColor(red: 1.0, green: 0.82, blue: 0.62, alpha: 1).cgColor
        ]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 1)
        return layer
    }()
    
    // 固定导航容器 + 渐变白色背景
    private let headerContainer = UIView()
    private let headerBackground = UIView()
    private let topSearchBar = TopSearchBarView()
    private let bannerView = BannerView()
    private lazy var shortcutRow = ShortcutRowView(items: [
        .init(title: "我的账户", systemIcon: "person.crop.circle"),
        .init(title: "转账", systemIcon: "arrow.left.arrow.right"),
        .init(title: "收支", systemIcon: "list.bullet.rectangle.portrait"),
        .init(title: "扫一扫", systemIcon: "qrcode.viewfinder")
    ])
    private let gridMenu = GridMenuView(items: [
        .init(title: "信用卡", systemIcon: "creditcard"),
        .init(title: "养老社区", systemIcon: "house"),
        .init(title: "普惠金融", systemIcon: "coloncurrencysign.circle"),
        .init(title: "存款", systemIcon: "banknote"),
        .init(title: "理财产品", systemIcon: "chart.line.uptrend.xyaxis"),
        .init(title: "贷款", systemIcon: "yensign.circle"),
        .init(title: "生活缴费", systemIcon: "bolt"),
        .init(title: "热门活动", systemIcon: "megaphone"),
        .init(title: "城市专区", systemIcon: "building.2"),
        .init(title: "全部", systemIcon: "ellipsis")
    ])
    private let newsList = NewsListView()
    private let promoBanner = PromoBannerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func setupNavigationBar() {
        title = "首页"
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.rightBarButtonItem = nil
    }
    
    override func setupUI() {
        view.backgroundColor = .abankBackground
        
        // 背景渐变，位于最底层
        topBackgroundView.layer.addSublayer(topBackgroundGradient)
        view.addSubview(topBackgroundView)
        topBackgroundView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            topBackgroundHeightConstraint = make.height.equalTo(headerHeight + 180).constraint
        }
        
        // 滚动内容
        view.addSubview(scrollView)
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        contentView.addSubview(bannerView)
        contentView.addSubview(shortcutRow)
        contentView.addSubview(gridMenu)
        contentView.addSubview(newsList)
        contentView.addSubview(promoBanner)
        
        bannerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        shortcutRow.snp.makeConstraints { make in
            shortcutRowTopConstraint = make.top.equalToSuperview().constraint
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        bannerView.snp.makeConstraints { make in
            make.bottom.equalTo(shortcutRow.snp.top)
            make.leading.trailing.equalToSuperview()
        }
        gridMenu.snp.makeConstraints { make in
            make.top.equalTo(shortcutRow.snp.bottom).offset(Spacing.lg)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        newsList.snp.makeConstraints { make in
            make.top.equalTo(gridMenu.snp.bottom).offset(Spacing.lg)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        promoBanner.snp.makeConstraints { make in
            make.top.equalTo(newsList.snp.bottom).offset(Spacing.lg)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.bottom.equalToSuperview().offset(-Spacing.xl)
        }
        promoBanner.configure(with: [
            PromoBannerItem(imageURL: URL(string: "https://picsum.photos/800/320?random=1")!),
            PromoBannerItem(imageURL: URL(string: "https://picsum.photos/800/320?random=2")!),
            PromoBannerItem(imageURL: URL(string: "https://picsum.photos/800/320?random=3")!)
        ])
        
        // 固定顶部导航覆盖在滚动内容之上
        view.addSubview(headerContainer)
        headerContainer.addSubview(headerBackground)
        headerContainer.addSubview(topSearchBar)
        headerContainer.layer.zPosition = 10
        headerBackground.alpha = 0
        headerBackground.backgroundColor = .white
        topSearchBar.apply(style: .light)
        headerContainer.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top)
            make.leading.trailing.equalToSuperview()
            headerHeightConstraint = make.height.equalTo(headerHeight).constraint
        }
        headerBackground.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        topSearchBar.snp.makeConstraints { make in
            searchBarTopConstraint = make.top.equalToSuperview().constraint
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.bottom.equalToSuperview().offset(-8)
        }
        
        view.sendSubviewToBack(topBackgroundView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let safeTop = view.safeAreaInsets.top
        headerHeightConstraint?.update(offset: headerHeight + safeTop)
        searchBarTopConstraint?.update(offset: safeTop + 4)
        shortcutRowTopConstraint?.update(offset: headerHeight + safeTop + 12)
        topBackgroundHeightConstraint?.update(offset: headerHeight + safeTop + 180)
        let topInset: CGFloat = 0
        if scrollView.contentInset.top != topInset || scrollView.contentInset.bottom != Spacing.xl {
            scrollView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: Spacing.xl, right: 0)
            scrollView.scrollIndicatorInsets = UIEdgeInsets(top: headerHeight + safeTop, left: 0, bottom: Spacing.xl, right: 0)
        }
        topBackgroundGradient.frame = topBackgroundView.bounds
        if !hasSetInitialContentOffset {
            hasSetInitialContentOffset = true
            scrollView.setContentOffset(CGPoint(x: 0, y: -topInset), animated: false)
            scrollViewDidScroll(scrollView)
        }
    }
    
    @objc private func messageButtonTapped() {
        // TODO: 跳转到消息中心
        print("消息中心")
    }
}

// MARK: - Scroll fade behavior
extension HomeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y = max(0, scrollView.contentOffset.y + scrollView.adjustedContentInset.top)
        let fadeDistance: CGFloat = 120
        let progress = max(0, min(1, y / fadeDistance))
        headerBackground.alpha = progress
        if progress > 0.6 {
            topSearchBar.apply(style: .dark)
        } else {
            topSearchBar.apply(style: .light)
        }
        // Optional shadow when white
        headerContainer.layer.shadowColor = UIColor.black.cgColor
        headerContainer.layer.shadowOpacity = Float(0.15 * progress)
        headerContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        headerContainer.layer.shadowRadius = 4
    }
}

