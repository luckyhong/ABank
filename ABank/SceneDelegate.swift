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

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

