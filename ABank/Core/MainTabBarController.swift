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

    /// 桌面快捷操作：切到首页，关闭模态页，回到根页后打开目标页。
    func openFromShortcut(_ route: AppRoute) {
        selectedIndex = 0
        presentedViewController?.dismiss(animated: false)
        guard let nav = viewControllers?.first as? UINavigationController else { return }
        nav.popToRootViewController(animated: false)
        guard let root = nav.viewControllers.first else { return }
        AppRouter.shared.open(route, from: root)
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
            wrap(HomeViewController(), title: "首页", icon: "house.fill", asset: "home"),
            wrap(WealthViewController(), title: "财富", icon: "yensign.circle", asset: "wealth"),
            wrap(LifeViewController(), title: "生活", icon: "bag", asset: "life"),
            wrap(NewsViewController(), title: "资讯", icon: "globe", asset: "news"),
            wrap(MineViewController(), title: "我的", icon: "person", asset: "mine")
        ]
    }

    private func wrap(_ root: UIViewController, title: String, icon: String, asset: String) -> UINavigationController {
        let nav = ABankNavigationController(rootViewController: root)
        nav.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage.abankAsset("abc_tab_\(asset)_normal", fallback: icon),
            selectedImage: UIImage.abankAsset("abc_tab_\(asset)_selected", fallback: icon)
        )
        return nav
    }
}
