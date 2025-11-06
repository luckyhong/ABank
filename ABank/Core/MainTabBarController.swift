//
//  MainTabBarController.swift
//  ABank
//
//  Created by 韩继宏 on 2025/10/27.
//

import UIKit
import SnapKit

class MainTabBarController: UITabBarController {
    
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
        
        // 添加顶部阴影线
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOpacity = 0.05
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -2)
        tabBar.layer.shadowRadius = 4
    }
    
    private func setupViewControllers() {
        // 首页
        let homeVC = HomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(
            title: "首页",
            image: UIImage(systemName: "house.fill"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        // 财富
        let wealthVC = WealthViewController()
        let wealthNav = UINavigationController(rootViewController: wealthVC)
        wealthNav.tabBarItem = UITabBarItem(
            title: "财富",
            image: UIImage(systemName: "chart.line.uptrend.xyaxis"),
            selectedImage: UIImage(systemName: "chart.line.uptrend.xyaxis")
        )

        // 生活
        let lifeVC = LifeViewController()
        let lifeNav = UINavigationController(rootViewController: lifeVC)
        lifeNav.tabBarItem = UITabBarItem(
            title: "生活",
            image: UIImage(systemName: "square.grid.2x2"),
            selectedImage: UIImage(systemName: "square.grid.2x2")
        )

        // 乡村振兴
        let ruralVC = RuralRevitalizationViewController()
        let ruralNav = UINavigationController(rootViewController: ruralVC)
        ruralNav.tabBarItem = UITabBarItem(
            title: "乡村振兴",
            image: UIImage(systemName: "leaf.fill"),
            selectedImage: UIImage(systemName: "leaf.fill")
        )

        // 我的
        let mineVC = MineViewController()
        let mineNav = UINavigationController(rootViewController: mineVC)
        mineNav.tabBarItem = UITabBarItem(
            title: "我的",
            image: UIImage(systemName: "person.fill"),
            selectedImage: UIImage(systemName: "person.fill")
        )

        viewControllers = [homeNav, wealthNav, lifeNav, ruralNav, mineNav]
    }
}

