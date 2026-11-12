//
//  ComingSoonViewController.swift
//  ABank
//
//  未完成功能的统一落地页：只说明建设中与计划阶段，不提示任何业务结果。
//

import UIKit
import SnapKit

final class ComingSoonViewController: BaseViewController, RouteHosting {
    private let descriptor: FeatureDescriptor

    var hostedRoute: AppRoute? { .comingSoon(descriptor.id) }

    init(featureID: FeatureID) {
        descriptor = FeatureCatalog.descriptor(featureID)
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = descriptor.title
    }

    override func setupUI() {
        view.backgroundColor = .abankCardBackground

        let iconView = UIImageView(image: descriptor.iconImage(pointSize: 64))
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .abankPrimary

        let titleLabel = makeLabel(descriptor.title, font: .abankTitle3(), color: .abankTextPrimary)
        let messageLabel = makeLabel("该服务当前暂未开放", font: .abankSubheadline(), color: .abankTextSecondary)
        let stageLabel = makeLabel("可先查看已开通的账户、理财和生活服务", font: .abankCaptionMedium(), color: .abankPrimary)
        stageLabel.accessibilityIdentifier = "comingSoon.stage"
        let noteLabel = makeLabel("功能介绍", font: .abankCaption(), color: .abankTextTertiary)

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, messageLabel, stageLabel, noteLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = Spacing.sm
        stack.setCustomSpacing(Spacing.md, after: iconView)

        let backButton = UIButton(type: .system)
        backButton.setTitle("查看全部功能", for: .normal)
        backButton.setTitleColor(.white, for: .normal)
        backButton.titleLabel?.font = .abankHeadline()
        backButton.backgroundColor = .abankPrimary
        backButton.layer.cornerRadius = CornerRadius.md
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)

        view.addSubview(stack)
        view.addSubview(backButton)
        iconView.snp.makeConstraints { make in make.size.equalTo(64) }
        stack.snp.makeConstraints { make in
            make.centerY.equalTo(view.safeAreaLayoutGuide).offset(-Spacing.xl)
            make.leading.trailing.equalToSuperview().inset(Spacing.lg)
        }
        backButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Spacing.lg)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-Spacing.lg)
            make.height.equalTo(48)
        }
    }

    private func makeLabel(_ text: String, font: UIFont, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = color
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }

    @objc private func backTapped() {
        router.open(.allFeatures(searchKeyword: nil), from: self)
    }
}
