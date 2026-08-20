//
//  NewsTabViews.swift
//  ABank
//

import UIKit
import SnapKit

// MARK: - 推荐 / 关注

final class NewsPrimaryTabsView: UIView {

    var onTabChanged: ((NewsPrimaryTab) -> Void)?

    private let stack = UIStackView()
    private var buttons: [UIButton] = []
    private var selectedTab: NewsPrimaryTab = .recommend
    private let indicator = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func select(_ tab: NewsPrimaryTab, animated: Bool = true) {
        selectedTab = tab
        updateSelection(animated: animated)
    }

    private func setupUI() {
        backgroundColor = .white

        stack.axis = .horizontal
        stack.distribution = .fill
        stack.spacing = 28
        stack.alignment = .center

        for tab in NewsPrimaryTab.allCases {
            let button = UIButton(type: .system)
            button.setTitle(tab.title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
            button.setTitleColor(.abankTextSecondary, for: .normal)
            button.tag = tab.rawValue
            button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            buttons.append(button)
            stack.addArrangedSubview(button)
        }

        indicator.backgroundColor = .abankPrimary
        indicator.layer.cornerRadius = 1.5

        addSubview(stack)
        addSubview(indicator)

        stack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.top.equalToSuperview()
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-4)
        }
        indicator.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(3)
            make.width.equalTo(28)
        }

        updateSelection(animated: false)
    }

    private func updateSelection(animated: Bool) {
        for button in buttons {
            let isSelected = button.tag == selectedTab.rawValue
            button.titleLabel?.font = .systemFont(ofSize: isSelected ? 18 : 17, weight: isSelected ? .semibold : .regular)
            button.setTitleColor(isSelected ? .abankTextPrimary : .abankTextSecondary, for: .normal)
        }

        guard let selectedButton = buttons.first(where: { $0.tag == selectedTab.rawValue }) else { return }
        let updateBlock = {
            self.indicator.snp.remakeConstraints { make in
                make.bottom.equalToSuperview()
                make.height.equalTo(3)
                make.width.equalTo(28)
                make.centerX.equalTo(selectedButton)
            }
            self.layoutIfNeeded()
        }
        if animated {
            UIView.animate(withDuration: 0.22, animations: updateBlock)
        } else {
            updateBlock()
        }
    }

    @objc private func tabTapped(_ sender: UIButton) {
        guard let tab = NewsPrimaryTab(rawValue: sender.tag), tab != selectedTab else { return }
        selectedTab = tab
        updateSelection(animated: true)
        onTabChanged?(tab)
    }
}

// MARK: - 分类标签

final class NewsCategoryTabsView: UIView {

    var onCategoryChanged: ((Int, String) -> Void)?
    var onMoreTapped: (() -> Void)?

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let moreButton = UIButton(type: .system)
    private var categoryButtons: [UIButton] = []
    private var categories: [String] = []
    private var selectedIndex = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(categories: [String], selectedIndex: Int = 0) {
        let categoriesChanged = categories != self.categories
        self.categories = categories
        self.selectedIndex = selectedIndex
        if categoriesChanged || categoryButtons.isEmpty {
            rebuildButtons()
        } else {
            updateSelection()
        }
    }

    private func setupUI() {
        backgroundColor = .white
        scrollView.showsHorizontalScrollIndicator = false

        stack.axis = .horizontal
        stack.spacing = 20
        stack.alignment = .center

        moreButton.setImage(UIImage(systemName: "line.3.horizontal"), for: .normal)
        moreButton.tintColor = .abankTextPrimary
        moreButton.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)

        addSubview(scrollView)
        addSubview(moreButton)
        scrollView.addSubview(stack)

        scrollView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.trailing.equalTo(moreButton.snp.leading).offset(-8)
            make.top.equalToSuperview()
            make.height.equalTo(32)
        }
        moreButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.centerY.equalTo(scrollView)
            make.size.equalTo(24)
        }
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
    }

    private func rebuildButtons() {
        stack.arrangedSubviews.forEach { view in
            stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        categoryButtons.removeAll()

        for (index, title) in categories.enumerated() {
            let container = UIView()
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.tag = index
            button.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)

            let underline = UIView()
            underline.backgroundColor = .abankPrimary
            underline.layer.cornerRadius = 1
            underline.tag = 1000 + index
            underline.isHidden = index != selectedIndex

            container.addSubview(button)
            container.addSubview(underline)
            button.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
            }
            underline.snp.makeConstraints { make in
                make.top.equalTo(button.snp.bottom).offset(2)
                make.centerX.equalTo(button)
                make.width.equalTo(20)
                make.height.equalTo(2)
                make.bottom.equalToSuperview()
            }

            categoryButtons.append(button)
            stack.addArrangedSubview(container)
        }
        updateSelection()
    }

    private func updateSelection() {
        for button in categoryButtons {
            let isSelected = button.tag == selectedIndex
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: isSelected ? .semibold : .regular)
            button.setTitleColor(isSelected ? .abankPrimary : .abankTextSecondary, for: .normal)
            button.superview?.viewWithTag(1000 + button.tag)?.isHidden = !isSelected
        }
    }

    @objc private func categoryTapped(_ sender: UIButton) {
        guard sender.tag != selectedIndex else { return }
        selectedIndex = sender.tag
        updateSelection()
        onCategoryChanged?(selectedIndex, categories[selectedIndex])
    }

    @objc private func moreTapped() { onMoreTapped?() }
}
