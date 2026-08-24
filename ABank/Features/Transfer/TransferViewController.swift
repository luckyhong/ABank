//
//  TransferViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class TransferViewController: BaseViewController {

    private var pageData: TransferPageData
    private var partners: [TransferPartner]
    private var isFunctionExpanded = false
    private var isNoticeHidden = false

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    private let contentView = UIView()

    private let noticeBanner = TransferNoticeBannerView()
    private let primaryCard = TransferPrimaryCardView()
    private let functionGrid = TransferFunctionGridView()
    private let recentSection = TransferRecentSectionView()

    init(pageData: TransferPageData = MockDataProvider.shared.getTransferPageData()) {
        self.pageData = pageData
        self.partners = pageData.recentPartners
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupNavigationBar() {
        title = "转账"
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.tintColor = .abankTextPrimary

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.abankTextPrimary,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance

        navigationItem.leftBarButtonItem = makeIconItem(
            systemName: "chevron.left",
            action: #selector(backTapped),
            pointSize: 19
        )
        navigationItem.rightBarButtonItem = makeIconItem(
            systemName: "headphones",
            action: #selector(serviceTapped),
            pointSize: 18
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = .abankBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        [noticeBanner, primaryCard, functionGrid, recentSection].forEach {
            contentView.addSubview($0)
        }

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        noticeBanner.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        primaryCard.snp.makeConstraints { make in
            make.top.equalTo(noticeBanner.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        functionGrid.snp.makeConstraints { make in
            make.top.equalTo(primaryCard.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
        }
        recentSection.snp.makeConstraints { make in
            make.top.equalTo(functionGrid.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-24)
        }

        applyPageData()
        bindActions()
    }

    private func applyPageData() {
        noticeBanner.configure(text: pageData.noticeText)
        noticeBanner.isHidden = isNoticeHidden
        primaryCard.configure(
            primary: pageData.primaryActions,
            secondary: pageData.secondaryActions
        )
        functionGrid.configure(items: pageData.functionItems, expanded: isFunctionExpanded)
        recentSection.configure(partners: partners)
        updatePrimaryCardTopConstraint()
    }

    private func updatePrimaryCardTopConstraint() {
        primaryCard.snp.remakeConstraints { make in
            if isNoticeHidden {
                make.top.equalToSuperview().offset(12)
            } else {
                make.top.equalTo(noticeBanner.snp.bottom).offset(12)
            }
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
    }

    private func bindActions() {
        noticeBanner.onClose = { [weak self] in
            guard let self else { return }
            self.isNoticeHidden = true
            self.noticeBanner.isHidden = true
            self.updatePrimaryCardTopConstraint()
            UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
        }
        noticeBanner.onTapped = { [weak self] in
            self?.showToast("警惕高息理财陷阱")
        }

        primaryCard.onPrimaryTapped = { [weak self] index in
            guard let self, let item = self.pageData.primaryActions[safe: index] else { return }
            self.showToast(item.title)
        }
        primaryCard.onSecondaryTapped = { [weak self] index in
            guard let self, let item = self.pageData.secondaryActions[safe: index] else { return }
            self.showToast(item.title)
        }

        functionGrid.onItemTapped = { [weak self] index in
            guard let self, let item = self.pageData.functionItems[safe: index] else { return }
            self.showToast(item.title)
        }
        functionGrid.onToggleExpand = { [weak self] in
            guard let self else { return }
            self.isFunctionExpanded.toggle()
            self.functionGrid.configure(
                items: self.pageData.functionItems,
                expanded: self.isFunctionExpanded
            )
            UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
        }

        recentSection.onAllPartnersTapped = { [weak self] in
            self?.showToast("全部转账伙伴")
        }
        recentSection.onPartnerHeaderTapped = { [weak self] index in
            self?.handlePartnerHeaderTapped(at: index)
        }
        recentSection.onAccountTapped = { [weak self] partnerIndex, accountIndex in
            self?.handleAccountTapped(partnerIndex: partnerIndex, accountIndex: accountIndex)
        }
    }

    private func handlePartnerHeaderTapped(at index: Int) {
        guard partners.indices.contains(index) else { return }
        var partner = partners[index]
        if partner.isMultiAccount {
            partner.isExpanded.toggle()
            // 展开当前时收起其他多账户
            if partner.isExpanded {
                for i in partners.indices where i != index && partners[i].isMultiAccount {
                    partners[i].isExpanded = false
                }
            }
            partners[index] = partner
            recentSection.configure(partners: partners)
            UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
        } else if let account = partner.accounts.first {
            showToast("向\(partner.name)转账 · \(account.bankName)")
        }
    }

    private func handleAccountTapped(partnerIndex: Int, accountIndex: Int) {
        guard partners.indices.contains(partnerIndex),
              partners[partnerIndex].accounts.indices.contains(accountIndex) else { return }
        let partner = partners[partnerIndex]
        let account = partner.accounts[accountIndex]
        showToast("向\(partner.name)转账 · \(account.bankName)(\(account.maskedNumber))")
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func serviceTapped() {
        showToast("正在为您接入在线客服")
    }

    private func makeIconItem(
        systemName: String,
        action: Selector,
        pointSize: CGFloat
    ) -> UIBarButtonItem {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.tintColor = .abankTextPrimary
        button.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        button.addTarget(self, action: action, for: .touchUpInside)
        return UIBarButtonItem(customView: button)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
