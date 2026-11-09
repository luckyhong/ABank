//
//  LoanListViews.swift
//  ABank
//
//  M9b 贷款二级页共用：滚动列表页基类与列表行。
//

import UIKit
import SnapKit

/// 贷款列表类页面：返回按钮 + 滚动纵向列表，账本变化时由子类 `reloadContent()` 重建。
class LoanStackPageViewController: BankingDataViewController {
    let stack = UIStackView()
    private let pageTitle: String

    init(title: String) {
        self.pageTitle = title
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = pageTitle
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.abankBackIndicator, style: .plain, target: self, action: #selector(popPage)
        )
    }

    override func setupUI() {
        view.backgroundColor = .abankBackground
        stack.axis = .vertical
        stack.spacing = 0
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        stack.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(UIEdgeInsets(top: 8, left: 0, bottom: 32, right: 0))
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        refreshBankingData()
    }

    override func refreshBankingData() {
        guard isViewLoaded else { return }
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        reloadContent()
    }

    /// 子类往 `stack` 中添加内容。
    func reloadContent() {}

    func addEmpty(_ text: String) {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 15)
        label.textColor = .abankTextTertiary
        label.textAlignment = .center
        label.accessibilityIdentifier = "loan.empty"
        label.snp.makeConstraints { $0.height.equalTo(160) }
        stack.addArrangedSubview(label)
    }

    func addSectionGap() {
        let gap = UIView()
        gap.snp.makeConstraints { $0.height.equalTo(8) }
        stack.addArrangedSubview(gap)
    }

    @objc func popPage() {
        navigationController?.popViewController(animated: true)
    }
}

/// 白底列表行：标题 + 右侧状态/按钮，第二行说明；整行可点。
final class LoanListRowView: UIControl {
    var onTap: (() -> Void)?

    init(title: String, trailing: String?, detail: String, actionTitle: String? = nil, showsChevron: Bool = false) {
        super.init(frame: .zero)
        backgroundColor = .white

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .abankTextPrimary

        let detailLabel = UILabel()
        detailLabel.text = detail
        detailLabel.font = .systemFont(ofSize: 13)
        detailLabel.textColor = .abankTextSecondary
        detailLabel.numberOfLines = 0

        let trailingLabel = UILabel()
        trailingLabel.text = trailing
        trailingLabel.font = .systemFont(ofSize: 14)
        trailingLabel.textColor = .abankOrange
        trailingLabel.textAlignment = .right
        trailingLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let text = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        text.axis = .vertical
        text.spacing = 6
        text.isUserInteractionEnabled = false

        addSubview(text)
        addSubview(trailingLabel)
        trailingLabel.isUserInteractionEnabled = false

        var rightAnchorView: UIView = trailingLabel
        if let actionTitle {
            let button = UIButton(type: .system)
            button.setTitle(actionTitle, for: .normal)
            button.setTitleColor(.abankOrange, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14)
            button.layer.borderColor = UIColor.abankOrange.cgColor
            button.layer.borderWidth = 0.5
            button.layer.cornerRadius = 14
            button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
            button.addTarget(self, action: #selector(tapped), for: .touchUpInside)
            addSubview(button)
            button.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-16)
                make.centerY.equalToSuperview()
                make.height.equalTo(28)
            }
            rightAnchorView = button
            trailingLabel.isHidden = true
        } else if showsChevron {
            let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
            chevron.tintColor = .abankTextTertiary
            chevron.contentMode = .scaleAspectFit
            addSubview(chevron)
            chevron.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-16)
                make.centerY.equalToSuperview()
                make.size.equalTo(CGSize(width: 8, height: 14))
            }
            trailingLabel.snp.makeConstraints { make in
                make.trailing.equalTo(chevron.snp.leading).offset(-8)
                make.centerY.equalTo(titleLabel)
            }
        }
        if actionTitle == nil && !showsChevron {
            trailingLabel.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-16)
                make.centerY.equalTo(titleLabel)
            }
        }
        text.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.bottom.equalToSuperview().inset(14)
            make.trailing.lessThanOrEqualTo(rightAnchorView.snp.leading).offset(-12)
        }

        let line = UIView()
        line.backgroundColor = .abankSeparator
        addSubview(line)
        line.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func tapped() { onTap?() }
}
