//
//  MyAccountViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class MyAccountViewController: BankingDataViewController {

    private var pageData: MyAccountPageData

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    private let contentView = UIView()

    private let debitCardStack = UIStackView()
    private let creditSection = UIStackView()
    private let creditAdView = MyAccountCreditAdView()
    private let creditSummary = UIControl()
    private let openAccountButton = MyAccountOpenAccountButton()

    init(pageData: MyAccountPageData = MockDataProvider.shared.getMyAccountPageData()) {
        self.pageData = pageData
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupNavigationBar() {
        title = "我的账户"


        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.abankBackIndicator,
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        let moreConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis", withConfiguration: moreConfig),
            style: .plain,
            target: self,
            action: #selector(moreTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = .abankTextSecondary
    }

    override func refreshBankingData() {
        pageData = MockDataProvider.shared.getMyAccountPageData()
        renderCards()
        renderCreditCard()
    }

    override func setupUI() {
        view.backgroundColor = UIColor(white: 0.97, alpha: 1)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        [debitCardStack, creditSection, openAccountButton].forEach { contentView.addSubview($0) }

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        debitCardStack.axis = .vertical
        debitCardStack.spacing = 20
        debitCardStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        creditSection.axis = .vertical
        creditSection.addArrangedSubview(creditAdView)
        creditSection.addArrangedSubview(creditSummary)
        creditSection.snp.makeConstraints { make in
            make.top.equalTo(debitCardStack.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        openAccountButton.snp.makeConstraints { make in
            make.top.equalTo(creditSection.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.bottom.equalToSuperview().offset(-Spacing.xl)
        }

        renderCards()
        creditAdView.configure(imageName: pageData.creditAdImageName)
        creditSummary.addAction(UIAction { [weak self] _ in guard let self else { return }; self.router.open(.creditCards, from: self) }, for: .touchUpInside)
        renderCreditCard()

        creditAdView.onAdTapped = { [weak self] in
            self?.handle(.creditAd)
        }
        openAccountButton.addTarget(self, action: #selector(openAccountTapped), for: .touchUpInside)
    }

    private func renderCreditCard() {
        creditSummary.subviews.forEach { $0.removeFromSuperview() }
        let card = FinanceLedgerStore.shared.load().creditCards.first
        creditAdView.isHidden = card != nil; creditSummary.isHidden = card == nil
        guard let card else { return }
        let content = BankingPageStyle.surface([BankingPageStyle.section("信用卡 · " + card.tail),
            BankingPageStyle.text("本期剩余应还 ¥ " + TransferMoney.text(card.remainingInCents), style: .title3),
            BankingPageStyle.text("到期还款日 " + card.dueDate + "　查看账单 ›", style: .subheadline, color: .abankTextSecondary)])
        content.isUserInteractionEnabled = false
        creditSummary.addSubview(content); content.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func renderCards() {
        debitCardStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for card in pageData.debitCards {
            let cardView = MyAccountDebitCardView()
            cardView.configure(with: card)
            cardView.onAction = { [weak self] action in self?.handle(action, card: card) }
            debitCardStack.addArrangedSubview(cardView)
        }
        if pageData.debitCards.isEmpty {
            let empty = UILabel()
            empty.text = "暂无可用账户"
            empty.textAlignment = .center
            debitCardStack.addArrangedSubview(empty)
        }
    }

    private func handle(_ action: MyAccountAction, card: MyAccountDebitCard? = nil) {
        switch action {
        case .setAlias:
            router.open(.accountAlias(accountID: card?.accountId), from: self)
        case .viewShare:
            router.open(.accountShare(accountID: card?.accountId), from: self)
        case .transfer:
            router.open(.transfer(payerAccountID: card?.accountId), from: self)
        case .queryDetail:
            router.open(.accountDetail(accountID: card?.accountId, maskedNumber: card?.maskedNumber), from: self)
        case .details:
            let detailData = MockDataProvider.shared.getDebitCardDetailPageData(
                card: card
            )
            navigationController?.pushViewController(
                DebitCardDetailViewController(pageData: detailData, accountId: card?.accountId ?? FinanceLedgerRecord.defaultAccountId),
                animated: true
            )
        case .flexibleWealth:
            if let card { router.open(.wealthAccount(accountID: card.accountId, productID: nil), from: self) }
            else { router.open(.wealthProducts, from: self) }
        case .more:
            router.open(.transferLimits, from: self)
        case .openElectronic:
            if FinanceLedgerStore.shared.load().accounts.contains(where: { $0.id.hasPrefix("electronic_") }) {
                showToast("电子账户已开通，可在账户列表查看")
                return
            }
            let alert = UIAlertController(title: "开通电子账户", message: "开通后可通过本人账户转账转入资金，账户余额与明细同步更新。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "确认开通", style: .default) { [weak self] _ in
                do {
                    _ = try FinanceLedgerStore.shared.openElectronicAccount()
                    self?.refreshBankingData()
                    self?.showToast("电子账户开通成功")
                } catch { self?.showToast(error.localizedDescription) }
            })
            present(alert, animated: true)
        case .creditAd:
            router.open(.creditCards, from: self)
        }
    }

    @objc private func openAccountTapped() {
        handle(.openElectronic)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func moreTapped() {
        handle(.more)
    }
}
