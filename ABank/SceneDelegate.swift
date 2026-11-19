//
//  SceneDelegate.swift
//  ABank
//
//  Created by 韩继宏 on 2025/10/27.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var pendingRoute: AppRoute?
    private var fundSettlementTimer: Timer?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        let mainTabBarController = MainTabBarController()
        window?.rootViewController = CustomerSessionStore.shared.isSignedIn ? mainTabBarController : ABankNavigationController(rootViewController: CustomerLoginViewController())
        NotificationCenter.default.addObserver(self, selector: #selector(sessionDidChange), name: CustomerSessionStore.didChange, object: nil)
        window?.makeKeyAndVisible()

        // 快捷操作优先于链接；两者共用 pendingRoute，取出即清空，只打开一次。
        if let item = connectionOptions.shortcutItem {
            pendingRoute = QuickAction.route(forType: item.type)
        } else if let url = connectionOptions.urlContexts.first?.url {
            pendingRoute = WidgetLink.route(for: url)
        }
        if pendingRoute != nil && CustomerSessionStore.shared.isSignedIn {
            DispatchQueue.main.async { [weak self] in
                guard let self, let route = self.pendingRoute else { return }
                self.pendingRoute = nil
                mainTabBarController.openFromShortcut(route)
            }
        }
    }

    @objc private func sessionDidChange() {
        window?.rootViewController = CustomerSessionStore.shared.isSignedIn ? MainTabBarController() : ABankNavigationController(rootViewController: CustomerLoginViewController())
        if CustomerSessionStore.shared.isSignedIn, let route = pendingRoute, let tab = window?.rootViewController as? MainTabBarController {
            pendingRoute = nil
            DispatchQueue.main.async { tab.openFromShortcut(route) }
        }
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        guard let route = QuickAction.route(forType: shortcutItem.type) else { completionHandler(false); return }
        if let tabBar = window?.rootViewController as? MainTabBarController { tabBar.openFromShortcut(route) }
        else { pendingRoute = route }
        completionHandler(true)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url, let route = WidgetLink.route(for: url) else { return }
        if let tabBar = window?.rootViewController as? MainTabBarController { tabBar.openFromShortcut(route) }
        else { pendingRoute = route }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        NotificationCenter.default.removeObserver(self, name: UIApplication.significantTimeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(settleFundOrders),
            name: UIApplication.significantTimeChangeNotification, object: nil)
        settleFundOrders()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        fundSettlementTimer?.invalidate()
        fundSettlementTimer = nil
        NotificationCenter.default.removeObserver(self, name: UIApplication.significantTimeChangeNotification, object: nil)
    }

    @objc private func settleFundOrders() {
        fundSettlementTimer?.invalidate()
        let ledger = FinanceLedgerStore.shared
        let dates = ledger.dates
        let now = dates.now
        let nextRefresh: Date
        do {
            try ledger.settleDueFundOrders()
            guard let midnight = dates.calendar.dateInterval(of: .day, for: now)?.end else { return }
            nextRefresh = midnight
        } catch {
            // Keep the last persisted state and retry while the app is active.
            nextRefresh = now.addingTimeInterval(60)
        }
        let timer = Timer(timeInterval: max(1, nextRefresh.timeIntervalSince(now)), repeats: false) { [weak self] _ in
            self?.settleFundOrders()
        }
        RunLoop.main.add(timer, forMode: .common)
        fundSettlementTimer = timer
    }
}
