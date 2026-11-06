//
//  ABankNavigationController.swift
//  ABank
//
//  全局导航栏规范：统一外观、农行返回箭头、隐藏返回文字、按页面声明显隐导航栏，
//  并在页面自定义左侧按钮时保留右滑返回。页面只通过 navigationItem 定制外观，
//  不直接修改共享的 navigationBar，避免样式泄漏到后续页面。
//

import UIKit

final class ABankNavigationController: UINavigationController {

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        interactivePopGestureRecognizer?.delegate = self
        Self.applyStandardAppearance(to: navigationBar)
        // 根页面在首次显示前就确定导航栏显隐，避免启动时闪现。
        if let root = viewControllers.first {
            setNavigationBarHidden(Self.prefersHidden(root), animated: false)
        }
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        topViewController?.navigationItem.backButtonDisplayMode = .minimal
        super.pushViewController(viewController, animated: animated)
    }

    override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        viewControllers.dropLast().forEach { $0.navigationItem.backButtonDisplayMode = .minimal }
        super.setViewControllers(viewControllers, animated: animated)
    }

    /// 导航栏默认外观：白色不透明背景、无分隔阴影、标题 17pt 中粗、农行返回箭头。
    static func applyStandardAppearance(to bar: UINavigationBar) {
        let appearance = makeStandardAppearance()
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.compactAppearance = appearance
        bar.tintColor = .abankTextPrimary
        bar.prefersLargeTitles = false
    }

    /// 页面需要不同背景色时，在此基础上修改后赋给自己的 navigationItem。
    static func makeStandardAppearance(background: UIColor = .abankCardBackground) -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = background
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.abankTextPrimary,
            .font: UIFont.abankHeadline()
        ]
        if let back = UIImage.abankSystemBackIndicator {
            appearance.setBackIndicatorImage(back, transitionMaskImage: back)
        }
        return appearance
    }

    fileprivate static func prefersHidden(_ controller: UIViewController) -> Bool {
        (controller as? BaseViewController)?.prefersNavigationBarHidden ?? false
    }
}

// MARK: - 按页面声明切换导航栏显隐

extension ABankNavigationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController, animated: Bool) {
        setNavigationBarHidden(Self.prefersHidden(viewController), animated: animated)
        // 右滑返回中途取消时，恢复原页面的导航栏状态。
        transitionCoordinator?.notifyWhenInteractionChanges { [weak self] context in
            guard context.isCancelled,
                  let self,
                  let from = context.viewController(forKey: .from) else { return }
            self.setNavigationBarHidden(Self.prefersHidden(from), animated: false)
        }
    }
}

// MARK: - 自定义返回按钮时保留右滑返回

extension ABankNavigationController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === interactivePopGestureRecognizer else { return true }
        return viewControllers.count > 1 && transitionCoordinator == nil
    }
}

extension UIImage {
    /// 农行返回箭头（模板渲染，随导航栏 tint 着色）。
    static var abankBackIndicator: UIImage? {
        UIImage(named: "abc_nav_back")?.withRenderingMode(.alwaysTemplate)
    }

    /// 系统返回按钮用：系统指示器贴近屏幕边缘，右移 8pt 与自定义返回按钮的位置对齐。
    static var abankSystemBackIndicator: UIImage? {
        abankBackIndicator?.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0))
    }
}
