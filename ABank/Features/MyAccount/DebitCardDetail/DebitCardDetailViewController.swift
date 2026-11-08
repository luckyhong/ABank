//
//  DebitCardDetailViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class DebitCardDetailViewController: BankingDataViewController {

    private let accountId: String
    private var pageData: DebitCardDetailPageData

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    private let contentView = UIView()

    private let infoCardView = DebitCardDetailInfoCardView()
    private let balanceSectionView = DebitCardDetailBalanceSectionView()

    init(pageData: DebitCardDetailPageData = MockDataProvider.shared.getDebitCardDetailPageData(),
         accountId: String = FinanceLedgerRecord.defaultAccountId) {
        self.accountId = accountId
        self.pageData = pageData
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "借记卡详情"


        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.abankBackIndicator,
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
    }

    override func refreshBankingData() {
        let account = FinanceLedgerStore.shared.load().accounts.first(where: { $0.id == accountId })
        let balance = account?.balance ?? 0
        infoCardView.setAlias(account?.alias)
        pageData.availableBalance = balance
        pageData.accountBalance = balance
        balanceSectionView.configure(with: pageData)
    }

    override func setupUI() {
        view.backgroundColor = .abankBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(infoCardView)
        contentView.addSubview(balanceSectionView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        infoCardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        balanceSectionView.snp.makeConstraints { make in
            make.top.equalTo(infoCardView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-24)
        }

        infoCardView.configure(with: pageData)
        balanceSectionView.configure(with: pageData)

        infoCardView.onAction = { [weak self] title in
            self?.handleAction(title)
        }
    }

    private func handleAction(_ title: String) {
        switch title {
        case "更多":
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let routes: [(String, AppRoute)] = [
                ("账户别名", .accountAlias(accountID: accountId)),
                ("账户限额", .transferLimits),
                ("交易权限", .accountPermissions(accountID: accountId))
            ]
            for (item, route) in routes {
                alert.addAction(UIAlertAction(title: item, style: .default) { [weak self] _ in
                    guard let self else { return }
                    self.router.open(route, from: self)
                })
            }
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            if let popover = alert.popoverPresentationController {
                popover.sourceView = infoCardView
                popover.sourceRect = infoCardView.bounds
            }
            present(alert, animated: true)
        default:
            showToast(title)
        }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}
