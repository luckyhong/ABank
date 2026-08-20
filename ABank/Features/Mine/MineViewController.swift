//
//  MineViewController.swift
//  ABank
//
//  Created by 韩继宏 on 2025/10/27.
//

import UIKit
import SnapKit

final class MineViewController: BaseViewController {

    private let pageData = MockDataProvider.shared.getMinePageData()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        return scrollView
    }()
    private let contentView = UIView()

    private let topActionBar = MineTopActionBarView()
    private let profileHeader = MineProfileHeaderView()
    private let assetStatsCard = MineAssetStatsCardView()
    private let assetLiabilityCard = MineAssetLiabilityCardView()
    private let monthlyFlowCard = MineMonthlyFlowCardView()
    private let branchCard = MineBranchCardView()
    private let securityCard = MineSecurityCenterCardView()
    private let orderCard = MineOrderCardView()
    private let customerManagerCard = MineCustomerManagerCardView()

    override func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        refreshProfileFromStore()
    }

    private func refreshProfileFromStore() {
        let record = CustomerInfoStore.shared.load()
        let profile = pageData.profile
        profileHeader.configure(with: MineProfileInfo(
            displayName: record.maskedName,
            lastLoginDevice: profile.lastLoginDevice,
            lastLoginTime: profile.lastLoginTime,
            vipLevel: profile.vipLevel,
            benefitsTitle: profile.benefitsTitle
        ))
    }

    override func setupUI() {
        view.backgroundColor = .abankBackground

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        let sections: [UIView] = [
            topActionBar, profileHeader, assetStatsCard, assetLiabilityCard,
            monthlyFlowCard, branchCard, securityCard, orderCard, customerManagerCard
        ]
        sections.forEach { contentView.addSubview($0) }

        let horizontalInset = Spacing.md
        let sectionSpacing: CGFloat = 12

        topActionBar.snp.makeConstraints { make in
            make.top.equalTo(contentView.safeAreaLayoutGuide).offset(Spacing.sm)
            make.leading.trailing.equalToSuperview().inset(horizontalInset)
        }
        profileHeader.snp.makeConstraints { make in
            make.top.equalTo(topActionBar.snp.bottom).offset(Spacing.md)
            make.leading.trailing.equalToSuperview().inset(horizontalInset)
        }
        assetStatsCard.snp.makeConstraints { make in
            make.top.equalTo(profileHeader.snp.bottom).offset(Spacing.md)
            make.leading.trailing.equalToSuperview().inset(horizontalInset)
        }
        assetLiabilityCard.snp.makeConstraints { make in
            make.top.equalTo(assetStatsCard.snp.bottom).offset(sectionSpacing)
            make.leading.trailing.equalToSuperview().inset(horizontalInset)
        }
        monthlyFlowCard.snp.makeConstraints { make in
            make.top.equalTo(assetLiabilityCard.snp.bottom).offset(sectionSpacing)
            make.leading.trailing.equalToSuperview().inset(horizontalInset)
        }
        branchCard.snp.makeConstraints { make in
            make.top.equalTo(monthlyFlowCard.snp.bottom).offset(sectionSpacing)
            make.leading.trailing.equalToSuperview().inset(horizontalInset)
        }
        securityCard.snp.makeConstraints { make in
            make.top.equalTo(branchCard.snp.bottom).offset(sectionSpacing)
            make.leading.trailing.equalToSuperview().inset(horizontalInset)
        }
        orderCard.snp.makeConstraints { make in
            make.top.equalTo(securityCard.snp.bottom).offset(sectionSpacing)
            make.leading.trailing.equalToSuperview().inset(horizontalInset)
        }
        customerManagerCard.snp.makeConstraints { make in
            make.top.equalTo(orderCard.snp.bottom).offset(sectionSpacing)
            make.leading.trailing.equalToSuperview().inset(horizontalInset)
            make.bottom.equalToSuperview().offset(-Spacing.pageBottom)
        }
    }

    override func setupBindings() {
        bindData()
        bindActions()
    }

    private func bindData() {
        profileHeader.configure(with: pageData.profile)
        assetStatsCard.configure(with: pageData.assetStats)
        assetLiabilityCard.configure(with: pageData.assetLiability)
        monthlyFlowCard.configure(with: pageData.monthlyFlow)
        branchCard.configure(with: pageData.branch)
        securityCard.configure(with: pageData.securityItems)
        customerManagerCard.configure(with: pageData.customerManager)
    }

    private func bindActions() {
        topActionBar.onLogoutTapped = { [weak self] in
            self?.showToast("退出登录")
        }
        topActionBar.onSearchTapped = { [weak self] in
            self?.showToast("搜索")
        }
        topActionBar.onSettingsTapped = { [weak self] in
            self?.showToast("设置")
        }
        topActionBar.onMoreTapped = { [weak self] in
            self?.showToast("更多")
        }

        profileHeader.onAvatarTapped = { [weak self] in
            let controller = CustomerInfoViewController()
            self?.navigationController?.pushViewController(controller, animated: true)
        }
        profileHeader.onBenefitsTapped = { [weak self] in
            self?.showToast("权益中心")
        }
        profileHeader.onVIPTapped = { [weak self] in
            self?.showToast("客户等级")
        }

        assetLiabilityCard.onTap = { [weak self] in
            let controller = AssetLiabilityViewController()
            self?.navigationController?.pushViewController(controller, animated: true)
        }
        assetLiabilityCard.onBillTapped = { [weak self] in
            self?.showToast("月度账单")
        }

        monthlyFlowCard.onTap = { [weak self] in
            self?.showToast("本月收支")
        }
        monthlyFlowCard.onBillTapped = { [weak self] in
            self?.showToast("7月份账单")
        }

        branchCard.onTap = { [weak self] in
            self?.showToast("我的网点")
        }
        branchCard.onRefreshTapped = { [weak self] in
            self?.showToast("刷新网点信息")
        }
        branchCard.onItemTapped = { [weak self] index in
            let title = self?.pageData.branch.services[safe: index]?.title ?? "网点服务"
            self?.showToast(title)
        }

        securityCard.onTap = { [weak self] in
            self?.showToast("安全中心")
        }
        securityCard.onItemTapped = { [weak self] index in
            let title = self?.pageData.securityItems[safe: index]?.title ?? "安全设置"
            self?.showToast(title)
        }

        orderCard.onTap = { [weak self] in
            self?.showToast("我的订单")
        }

        customerManagerCard.onWeChatTapped = { [weak self] in
            self?.showToast("联系客户经理")
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
