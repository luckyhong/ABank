//
//  TransferViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class TransferViewController: BankingDataViewController {

    private let store: FinanceLedgerStore
    private let preferredPayerAccountID: String?
    private var pageData: TransferPageData
    private var partners: [TransferPartner]
    private var isFunctionExpanded = true
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
    private let recentDivider = UIView()

    init(pageData: TransferPageData = MockDataProvider.shared.getTransferPageData(),
         payerAccountID: String? = nil, store: FinanceLedgerStore? = nil) {
        self.store = store ?? .shared
        self.preferredPayerAccountID = payerAccountID
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

    override func refreshBankingData() {
        let expanded = Set(partners.filter(\.isExpanded).map(\.id))
        var refreshed = pageData.recentPartners
        for record in store.transferRecords().reversed() where record.status == .succeeded {
            if let index = refreshed.firstIndex(where: { partner in
                partner.name == record.recipientName && partner.accounts.contains(where: {
                    $0.maskedNumber == record.maskedDestination && $0.bankName == record.bankName
                })
            }) {
                let partner = refreshed.remove(at: index)
                refreshed.insert(TransferPartner(id: partner.id, name: partner.name,
                    avatarSystemIcon: partner.avatarSystemIcon, avatarTintHex: partner.avatarTintHex,
                    accounts: partner.accounts, lastTransferDate: String(record.createdAt.prefix(10)),
                    isExpanded: expanded.contains(partner.id), avatarImageName: partner.avatarImageName), at: 0)
            } else {
                let recipient = record.reusableRecipient
                refreshed.insert(TransferPartner(id: recipient.id, name: recipient.name,
                    avatarSystemIcon: nil, avatarTintHex: nil,
                    accounts: [TransferAccount(id: recipient.id, bankName: recipient.bankName,
                        maskedNumber: recipient.maskedDestination, bankColorHex: "009882", bankSymbol: "转")],
                    lastTransferDate: String(record.createdAt.prefix(10)), isExpanded: false), at: 0)
            }
        }
        for i in refreshed.indices { refreshed[i].isExpanded = expanded.contains(refreshed[i].id) }
        partners = refreshed
        recentSection.configure(partners: partners)
    }

    private func openRecipient(id: String) {
        guard let recipient = try? store.recipient(for: TransferDraft(
            payerAccountID: preferredPayerAccountID ?? "", savedRecipientID: id)) else {
            showToast("演示伙伴暂不可用，请手动填写")
            return
        }
        openForm(recipient: recipient)
    }

    private func openForm(method: TransferMethod = .account, recipient: TransferRecipient? = nil) {
        navigationController?.pushViewController(TransferFormViewController(method: method,
            payerAccountID: preferredPayerAccountID, recipient: recipient, store: store), animated: true)
    }

    override func setupUI() {
        view.backgroundColor = .white

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        [noticeBanner, primaryCard, functionGrid, recentDivider, recentSection].forEach {
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
        recentDivider.backgroundColor = UIColor(white: 0.97, alpha: 1)
        recentDivider.snp.makeConstraints { make in
            make.top.equalTo(functionGrid.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(10)
        }
        recentSection.snp.makeConstraints { make in
            make.top.equalTo(recentDivider.snp.bottom)
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
            guard let self, self.pageData.primaryActions.indices.contains(index) else { return }
            if index == 0 || index == 1 { self.openForm(method: index == 0 ? .account : .phone) }
        }
        primaryCard.onSecondaryTapped = { [weak self] index in
            guard let self, self.pageData.secondaryActions.indices.contains(index) else { return }
            let controller: UIViewController = index == 0
                ? TransferRecordsViewController(store: self.store) : TransferLimitsViewController(store: self.store)
            self.navigationController?.pushViewController(controller, animated: true)
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
            guard let self else { return }
            let picker = TransferRecipientsViewController(store: self.store)
            picker.onSelect = { [weak self] recipient in
                self?.navigationController?.popViewController(animated: false)
                self?.openForm(recipient: recipient)
            }
            self.navigationController?.pushViewController(picker, animated: true)
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
            openRecipient(id: account.id)
        }
    }

    private func handleAccountTapped(partnerIndex: Int, accountIndex: Int) {
        guard partners.indices.contains(partnerIndex),
              partners[partnerIndex].accounts.indices.contains(accountIndex) else { return }
        let partner = partners[partnerIndex]
        let account = partner.accounts[accountIndex]
        openRecipient(id: account.id)
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
        let image = systemName == "headphones"
            ? UIImage.abankAsset("abc_account_toolbar_service", fallback: systemName, pointSize: 22)
            : UIImage(systemName: systemName, withConfiguration: UIImage.SymbolConfiguration(pointSize: pointSize, weight: .regular))
        button.setImage(image, for: .normal)
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
