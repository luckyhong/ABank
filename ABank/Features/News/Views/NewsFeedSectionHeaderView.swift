//
//  NewsFeedSectionHeaderView.swift
//  ABank
//

import UIKit
import SnapKit

/// Feed 区域吸顶头部：其他标签 + 分类 Tab
final class NewsFeedSectionHeaderView: UIView {

    var onCategoryChanged: ((Int, String) -> Void)?
    var onMoreTapped: (() -> Void)?
    var onOtherTapped: (() -> Void)?

    private let otherButton = UIButton(type: .system)
    private let categoryTabs = NewsCategoryTabsView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(categories: [String], selectedIndex: Int, showsOtherChip: Bool = false) {
        categoryTabs.configure(categories: categories, selectedIndex: selectedIndex)
        otherButton.isHidden = !showsOtherChip
        categoryTabs.snp.remakeConstraints { make in
            if showsOtherChip {
                make.top.equalTo(otherButton.snp.bottom).offset(4)
            } else {
                make.top.equalToSuperview()
            }
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(36)
        }
    }

    private func setupUI() {
        backgroundColor = .white

        otherButton.setTitle("其他", for: .normal)
        otherButton.titleLabel?.font = .systemFont(ofSize: 14)
        otherButton.setTitleColor(UIColor(red: 0.25, green: 0.55, blue: 0.95, alpha: 1), for: .normal)
        otherButton.layer.cornerRadius = 18
        otherButton.layer.borderWidth = 0.8
        otherButton.layer.borderColor = UIColor(red: 0.55, green: 0.75, blue: 0.95, alpha: 1).cgColor
        otherButton.backgroundColor = UIColor(red: 0.96, green: 0.98, blue: 1.0, alpha: 1)
        otherButton.isHidden = true
        otherButton.addTarget(self, action: #selector(otherTapped), for: .touchUpInside)

        categoryTabs.onCategoryChanged = { [weak self] index, name in
            self?.onCategoryChanged?(index, name)
        }
        categoryTabs.onMoreTapped = { [weak self] in
            self?.onMoreTapped?()
        }

        addSubview(otherButton)
        addSubview(categoryTabs)

        otherButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.height.equalTo(36)
        }
        categoryTabs.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(36)
        }

    }

    static func preferredHeight(showsOtherChip: Bool) -> CGFloat {
        let otherHeight: CGFloat = showsOtherChip ? 44 : 0
        return otherHeight + 36
    }

    @objc private func otherTapped() { onOtherTapped?() }
}
