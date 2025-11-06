//
//  HomeViewController.swift
//  ABank
//
//  Created by 韩继宏 on 2025/10/27.
//

import UIKit
import SnapKit

class HomeViewController: BaseViewController {
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let contentView = UIView()
    
    // MARK: - 账户卡片
    private let accountCardView = AccountCardView()
    
    // MARK: - 快捷功能
    private let quickActionsView = QuickActionsView()
    
    // MARK: - 公告栏
    private let noticeView = NoticeView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func setupNavigationBar() {
        title = "首页"
        navigationController?.navigationBar.prefersLargeTitles = false
        
        // 右侧消息按钮
        let messageButton = UIBarButtonItem(
            image: UIImage(systemName: "bell"),
            style: .plain,
            target: self,
            action: #selector(messageButtonTapped)
        )
        navigationItem.rightBarButtonItem = messageButton
    }
    
    override func setupUI() {
        view.backgroundColor = .abankBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(accountCardView)
        contentView.addSubview(quickActionsView)
        contentView.addSubview(noticeView)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        accountCardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Spacing.md)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        
        quickActionsView.snp.makeConstraints { make in
            make.top.equalTo(accountCardView.snp.bottom).offset(Spacing.lg)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        
        noticeView.snp.makeConstraints { make in
            make.top.equalTo(quickActionsView.snp.bottom).offset(Spacing.lg)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.bottom.equalToSuperview().offset(-Spacing.lg)
        }
    }
    
    @objc private func messageButtonTapped() {
        // TODO: 跳转到消息中心
        print("消息中心")
    }
}

