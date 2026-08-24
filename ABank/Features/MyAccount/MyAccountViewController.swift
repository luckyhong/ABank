//
//  MyAccountViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class MyAccountViewController: BaseViewController {

    private let pageData: MyAccountPageData

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    private let contentView = UIView()

    private let debitCardView = MyAccountDebitCardView()
    private let creditAdView = MyAccountCreditAdView()
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

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = .abankBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        [debitCardView, creditAdView, openAccountButton].forEach { contentView.addSubview($0) }

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        debitCardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        creditAdView.snp.makeConstraints { make in
            make.top.equalTo(debitCardView.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        openAccountButton.snp.makeConstraints { make in
            make.top.equalTo(creditAdView.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.bottom.equalToSuperview().offset(-Spacing.xl)
        }

        if let card = pageData.debitCards.first {
            debitCardView.configure(with: card)
        }
        creditAdView.configure(imageName: pageData.creditAdImageName)

        debitCardView.onAction = { [weak self] action in
            self?.handle(action)
        }
        creditAdView.onAdTapped = { [weak self] in
            self?.handle(.creditAd)
        }
        openAccountButton.addTarget(self, action: #selector(openAccountTapped), for: .touchUpInside)
    }

    private func handle(_ action: MyAccountAction) {
        switch action {
        case .transfer:
            navigationController?.pushViewController(TransferViewController(), animated: true)
        case .queryDetail:
            let masked = pageData.debitCards.first?.maskedNumber ?? "6230 **** 8472"
            navigationController?.pushViewController(
                AccountDetailQueryViewController(maskedNumber: masked),
                animated: true
            )
        case .details:
            let detailData = MockDataProvider.shared.getDebitCardDetailPageData(
                card: pageData.debitCards.first
            )
            navigationController?.pushViewController(
                DebitCardDetailViewController(pageData: detailData),
                animated: true
            )
        default:
            showToast(action.rawValue)
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
