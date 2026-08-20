//
//  BaseViewController.swift
//  ABank
//
//  Created by 韩继宏 on 2025/11/06.
//

import UIKit
import SnapKit

/// 提供统一的生命周期模板、导航样式、加载与提示等通用能力
class BaseViewController: UIViewController {
    
    private lazy var loadingContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.isHidden = true
        return view
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        return indicator
    }()
    
    deinit {
        #if DEBUG
        print("\(type(of: self)) deinit")
        #endif
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .abankBackground
        configureNavigationAppearance()
        setupLoading()
        setupUI()
        setupNavigationBar()
        setupBindings()
    }
    
    // MARK: - 模板方法（子类按需重写）
    func setupUI() { }
    func setupBindings() { }
    func setupNavigationBar() { }
    
    // MARK: - 导航栏统一样式
    private func configureNavigationAppearance() {
        navigationController?.navigationBar.tintColor = .abankPrimary
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.abankTextPrimary,
            .font: UIFont.abankHeadline()
        ]
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    // MARK: - Loading
    private func setupLoading() {
        view.addSubview(loadingContainerView)
        loadingContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        loadingContainerView.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    func showLoading() {
        loadingContainerView.isHidden = false
        activityIndicator.startAnimating()
    }
    
    func hideLoading() {
        loadingContainerView.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    // MARK: - Toast（轻提示）
    func showToast(_ message: String, duration: TimeInterval = 2.0) {
        let label = PaddingLabel()
        label.text = message
        label.textColor = .white
        label.font = .abankCaptionMedium()
        label.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.numberOfLines = 0
        
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-Spacing.lg)
            make.leading.greaterThanOrEqualTo(view.snp.leading).offset(Spacing.lg)
            make.trailing.lessThanOrEqualTo(view.snp.trailing).offset(-Spacing.lg)
        }
        
        label.alpha = 0
        UIView.animate(withDuration: 0.2, animations: {
            label.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: duration, options: [], animations: {
                label.alpha = 0
            }) { _ in
                label.removeFromSuperview()
            }
        }
    }
}

// MARK: - 内部组件：带内边距的标签
private final class PaddingLabel: UILabel {
    private let insets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right,
                      height: size.height + insets.top + insets.bottom)
    }
}


