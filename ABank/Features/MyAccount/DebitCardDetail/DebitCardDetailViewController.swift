//
//  DebitCardDetailViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class DebitCardDetailViewController: BaseViewController {

    private let pageData: DebitCardDetailPageData

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    private let contentView = UIView()

    private let infoCardView = DebitCardDetailInfoCardView()
    private let balanceSectionView = DebitCardDetailBalanceSectionView()

    init(pageData: DebitCardDetailPageData = MockDataProvider.shared.getDebitCardDetailPageData()) {
        self.pageData = pageData
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "借记卡详情"
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
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
            ["账户别名", "账户限额", "交易权限"].forEach { item in
                alert.addAction(UIAlertAction(title: item, style: .default) { [weak self] _ in
                    self?.showToast(item)
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
