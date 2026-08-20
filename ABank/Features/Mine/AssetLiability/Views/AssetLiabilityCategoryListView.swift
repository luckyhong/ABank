//
//  AssetLiabilityCategoryListView.swift
//  ABank
//

import UIKit
import SnapKit

final class AssetLiabilityCategoryListView: UIView {

    var onCategoryTapped: ((Int) -> Void)?
    var onItemTapped: ((Int, Int) -> Void)?
    var onItemMenuTapped: ((Int, Int) -> Void)?

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(categories: [AssetLiabilityCategory]) {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        categories.enumerated().forEach { index, category in
            stackView.addArrangedSubview(makeCategorySection(category: category, categoryIndex: index))
        }
    }

    private func makeCategorySection(category: AssetLiabilityCategory, categoryIndex: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = .white

        let header = AssetLiabilityCategoryHeaderView()
        header.configure(title: category.title, amount: category.totalAmount)
        header.onTap = { [weak self] in self?.onCategoryTapped?(categoryIndex) }

        container.addSubview(header)
        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        var previous: UIView = header
        category.items.enumerated().forEach { itemIndex, item in
            let row = AssetLiabilityItemRowView()
            row.configure(with: item, isLast: itemIndex == category.items.count - 1)
            row.onTap = { [weak self] in self?.onItemTapped?(categoryIndex, itemIndex) }
            row.onMenuTapped = { [weak self] in self?.onItemMenuTapped?(categoryIndex, itemIndex) }
            container.addSubview(row)
            row.snp.makeConstraints { make in
                make.top.equalTo(previous.snp.bottom)
                make.leading.trailing.equalToSuperview()
                if itemIndex == category.items.count - 1 {
                    make.bottom.equalToSuperview()
                }
            }
            previous = row
        }

        if category.items.isEmpty {
            header.snp.makeConstraints { make in make.bottom.equalToSuperview() }
        }
        return container
    }
}

// MARK: - Category Header

private final class AssetLiabilityCategoryHeaderView: UIControl {

    var onTap: (() -> Void)?

    private let titleLabel = UILabel()
    private let infoIcon = UIImageView()
    private let amountLabel = UILabel()
    private let arrowIcon = UIImageView()
    private let separator = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, amount: Double?) {
        titleLabel.text = title
        if let amount {
            amountLabel.text = amount.abankPlainAmountString()
            amountLabel.isHidden = false
        } else {
            amountLabel.isHidden = true
        }
    }

    private func setupUI() {
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .abankTextPrimary

        let infoConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        infoIcon.image = UIImage(systemName: "info.circle", withConfiguration: infoConfig)
        infoIcon.tintColor = UIColor(red: 190 / 255, green: 190 / 255, blue: 190 / 255, alpha: 1)
        infoIcon.contentMode = .scaleAspectFit

        amountLabel.font = .systemFont(ofSize: 16, weight: .medium)
        amountLabel.textColor = .abankTextPrimary

        let arrowConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        arrowIcon.image = UIImage(systemName: "chevron.right", withConfiguration: arrowConfig)
        arrowIcon.tintColor = UIColor(red: 200 / 255, green: 200 / 255, blue: 200 / 255, alpha: 1)
        arrowIcon.contentMode = .scaleAspectFit

        separator.backgroundColor = .abankSeparator

        [titleLabel, infoIcon, amountLabel, arrowIcon, separator].forEach { addSubview($0) }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.top.equalToSuperview().offset(15)
            make.bottom.equalToSuperview().offset(-15)
        }
        infoIcon.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(4)
            make.centerY.equalTo(titleLabel)
            make.size.equalTo(16)
        }
        arrowIcon.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.centerY.equalTo(titleLabel)
            make.size.equalTo(14)
        }
        amountLabel.snp.makeConstraints { make in
            make.trailing.equalTo(arrowIcon.snp.leading).offset(-6)
            make.centerY.equalTo(titleLabel)
        }
        separator.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    @objc private func tapped() { onTap?() }
}

// MARK: - Item Row

private final class AssetLiabilityItemRowView: UIControl {

    var onTap: (() -> Void)?
    var onMenuTapped: (() -> Void)?

    private let titleLabel = UILabel()
    private let amountLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let menuButton = UIButton(type: .system)
    private let separator = UIView()
    private let rightStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with item: AssetLiabilityItem, isLast: Bool) {
        let isLoanItem = item.subtitle != nil
        titleLabel.text = item.title
        titleLabel.font = .systemFont(ofSize: isLoanItem ? 15 : 14)
        titleLabel.textColor = isLoanItem ? .abankTextPrimary : .abankTextSecondary

        if item.showsCurrencySymbol {
            amountLabel.text = item.amount.abankCurrencyString()
        } else {
            amountLabel.text = item.amount.abankPlainAmountString()
        }
        amountLabel.font = .systemFont(ofSize: isLoanItem ? 16 : 15, weight: .medium)

        subtitleLabel.text = item.subtitle
        subtitleLabel.isHidden = item.subtitle == nil
        menuButton.isHidden = !item.showsMenu
        separator.isHidden = isLast

        rightStack.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            if item.showsMenu {
                make.trailing.equalTo(menuButton.snp.leading).offset(-6)
            } else {
                make.trailing.equalToSuperview().offset(-Spacing.md)
            }
        }

        snp.updateConstraints { make in
            make.height.greaterThanOrEqualTo(isLoanItem ? 60 : 50)
        }
    }

    private func setupUI() {
        amountLabel.textColor = .abankTextPrimary
        amountLabel.textAlignment = .right

        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .abankTextTertiary
        subtitleLabel.textAlignment = .right

        // 与上方分类行箭头同尺寸、同右对齐
        let menuConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        menuButton.setImage(UIImage(systemName: "ellipsis", withConfiguration: menuConfig), for: .normal)
        menuButton.tintColor = UIColor(red: 200 / 255, green: 200 / 255, blue: 200 / 255, alpha: 1)
        menuButton.transform = CGAffineTransform(rotationAngle: .pi / 2)
        menuButton.addTarget(self, action: #selector(menuTapped), for: .touchUpInside)

        rightStack.axis = .vertical
        rightStack.alignment = .trailing
        rightStack.spacing = 2
        rightStack.isUserInteractionEnabled = false
        rightStack.addArrangedSubview(amountLabel)
        rightStack.addArrangedSubview(subtitleLabel)

        separator.backgroundColor = .abankSeparator

        addSubview(titleLabel)
        addSubview(rightStack)
        addSubview(menuButton)
        addSubview(separator)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(rightStack.snp.leading).offset(-12)
        }
        menuButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.centerY.equalToSuperview()
            make.size.equalTo(14)
        }
        rightStack.snp.makeConstraints { make in
            make.trailing.equalTo(menuButton.snp.leading).offset(-6)
            make.centerY.equalToSuperview()
        }
        separator.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(50)
        }
    }

    @objc private func tapped() { onTap?() }
    @objc private func menuTapped() { onMenuTapped?() }
}
