//
//  MainTabBarController.swift
//  ABank
//
//  Created by 韩继宏 on 2025/10/27.
//

import UIKit
import SnapKit

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupViewControllers()
    }

    private func setupTabBar() {
        tabBar.tintColor = .abankPrimary
        tabBar.unselectedItemTintColor = .abankTextTertiary
        tabBar.backgroundColor = .abankCardBackground
        tabBar.isTranslucent = false
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOpacity = 0.05
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -2)
        tabBar.layer.shadowRadius = 4
    }

    private func setupViewControllers() {
        viewControllers = [
            wrap(HomeViewController(), title: "首页", icon: "house.fill"),
            wrap(WealthViewController(), title: "财富", icon: "yensign.circle"),
            wrap(LifeViewController(), title: "生活", icon: "bag"),
            wrap(NewsViewController(), title: "资讯", icon: "globe"),
            wrap(MineViewController(), title: "我的", icon: "person")
        ]
    }

    private func wrap(_ root: UIViewController, title: String, icon: String) -> UINavigationController {
        let nav = UINavigationController(rootViewController: root)
        nav.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: icon),
            selectedImage: UIImage(systemName: icon)
        )
        return nav
    }
}
