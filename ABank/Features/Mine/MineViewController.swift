//
//  MineViewController.swift
//  ABank
//
//  Created by 韩继宏 on 2025/10/27.
//

import UIKit
import SnapKit

final class MineViewController: BankingDataViewController {

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
    private let security: SecuritySettingsStore = .shared
    private let benefits: BenefitsStore = .shared
    private var assetStats: [MineAssetStat] = []

    override var prefersNavigationBarHidden: Bool { true }

    private func refreshFinanceCardsFromStore() {
        assetLiabilityCard.configure(with: FinanceLedgerStore.shared.mineAssetLiability())
        monthlyFlowCard.configure(with: FinanceLedgerStore.shared.mineMonthlyFlow())
    }

    private func refreshProfileFromStore() {
        let record = CustomerInfoStore.shared.load()
        let profile = pageData.profile
        profileHeader.configure(with: MineProfileInfo(
            displayName: record.maskedName,
            lastLoginDevice: profile.lastLoginDevice,
            lastLoginTime: profile.lastLoginTime,
            vipLevel: benefits.level.title,
            benefitsTitle: profile.benefitsTitle
        ))
    }

    private func refreshAssetStats() {
        assetStats = MineAssetStats.make(benefits: benefits, accountCount: FinanceLedgerStore.shared.load().accounts.count + FinanceLedgerStore.shared.load().creditCards.count)
        assetStatsCard.configure(with: assetStats)
    }

    @objc private func benefitsDidChange() {
        guard isViewLoaded else { return }
        refreshAssetStats()
        refreshProfileFromStore()
    }

    override func refreshBankingData() {
        refreshAssetStats()
        refreshProfileFromStore()
        refreshFinanceCardsFromStore()
        applyAmountVisibility()
    }

    /// 金额隐私以安全中心的全局设置为准
    private func applyAmountVisibility() {
        let visible = !security.hidesAmounts
        assetLiabilityCard.setAmountVisible(visible)
        monthlyFlowCard.setAmountVisible(visible)
    }

    private func toggleAmountVisibility() {
        if !security.setHidesAmounts(!security.hidesAmounts) {
            showToast(SecuritySettingsError.persistence.localizedDescription)
        }
        applyAmountVisibility()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadBranchCard()
    }

    /// 我的网点显示当前城市默认网点。
    @objc private func reloadBranchCard() {
        guard isViewLoaded else { return }
        branchCard.configure(with: MockDataProvider.shared.mineBranchInfo())
    }

    @objc private func securitySettingsDidChange() {
        guard isViewLoaded else { return }
        applyAmountVisibility()
    }

    override func setupUI() {
        view.backgroundColor = .white

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
            make.top.equalTo(topActionBar.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(horizontalInset)
        }
        assetStatsCard.snp.makeConstraints { make in
            make.top.equalTo(profileHeader.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(horizontalInset)
        }
        assetLiabilityCard.snp.makeConstraints { make in
            make.top.equalTo(assetStatsCard.snp.bottom).offset(22)
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
        refreshAssetStats()
        assetLiabilityCard.configure(with: FinanceLedgerStore.shared.mineAssetLiability())
        monthlyFlowCard.configure(with: FinanceLedgerStore.shared.mineMonthlyFlow())
        branchCard.configure(with: pageData.branch)
        securityCard.configure(with: pageData.securityItems)
        customerManagerCard.configure(with: pageData.customerManager)
    }

    private func bindActions() {
        NotificationCenter.default.addObserver(self, selector: #selector(securitySettingsDidChange),
                                               name: SecuritySettingsStore.didChangeNotification, object: security)
        NotificationCenter.default.addObserver(self, selector: #selector(benefitsDidChange),
                                               name: BenefitsStore.didChangeNotification, object: benefits)
        assetStatsCard.onItemTapped = { [weak self] index in
            guard let self, let route = self.assetStats[safe: index]?.route else { return }
            self.router.open(route, from: self)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(reloadBranchCard),
                                               name: CitySelectionStore.didChangeNotification, object: nil)
        assetLiabilityCard.onEyeTapped = { [weak self] in self?.toggleAmountVisibility() }
        monthlyFlowCard.onEyeTapped = { [weak self] in self?.toggleAmountVisibility() }
        topActionBar.onLogoutTapped = { [weak self] in
            if let self { AppSettingsViewController.confirmLogout(from: self) }
        }
        topActionBar.onSearchTapped = { [weak self] in
            guard let self else { return }
            self.router.open(.allFeatures(searchKeyword: nil), from: self)
        }
        topActionBar.onSettingsTapped = { [weak self] in
            guard let self else { return }; self.router.open(.settings, from: self)
        }
        topActionBar.onMoreTapped = { [weak self] in
            guard let self else { return }; self.router.open(.allFeatures(searchKeyword: nil), from: self)
        }

        profileHeader.onAvatarTapped = { [weak self] in
            guard let self else { return }
            self.router.open(.customerInfo, from: self)
        }
        profileHeader.onBenefitsTapped = { [weak self] in
            guard let self else { return }
            self.router.open(feature: .benefits, from: self)
        }
        profileHeader.onVIPTapped = { [weak self] in
            guard let self else { return }
            self.router.open(feature: .customerLevel, from: self)
        }

        assetLiabilityCard.onTap = { [weak self] in
            guard let self else { return }
            self.router.open(.assetLiability, from: self)
        }
        assetLiabilityCard.onBillTapped = { [weak self] in
            guard let self else { return }
            self.router.open(.ledgerAnalysis, from: self)
        }

        monthlyFlowCard.onTap = { [weak self] in
            guard let self else { return }
            self.router.open(.incomeExpense(accountID: nil), from: self)
        }
        monthlyFlowCard.onBillTapped = { [weak self] in
            guard let self else { return }
            self.router.open(.ledgerAnalysis, from: self)
        }

        branchCard.onTap = { [weak self] in
            guard let self else { return }
            self.router.open(feature: .branchQuery, from: self)
        }
        branchCard.onRefreshTapped = { [weak self] in
            self?.reloadBranchCard()
            self?.showToast("已刷新")
        }
        branchCard.onItemTapped = { [weak self] index in
            guard let self, let id = self.pageData.branch.services[safe: index]?.featureID else { return }
            self.router.open(feature: id, from: self)
        }

        securityCard.onTap = { [weak self] in
            guard let self else { return }
            self.router.open(feature: .securityCenter, from: self)
        }
        securityCard.onItemTapped = { [weak self] index in
            guard let self, let id = self.pageData.securityItems[safe: index]?.featureID else { return }
            self.router.open(feature: id, from: self)
        }

        orderCard.onTap = { [weak self] in
            guard let self else { return }
            self.router.open(feature: .orders, from: self)
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
