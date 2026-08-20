//
//  IncomeExpenseFilterBarView.swift
//  ABank
//

import UIKit
import SnapKit

final class IncomeExpenseFilterBarView: UIView {

    var onMonthTapped: (() -> Void)?
    var onAccountTapped: (() -> Void)?
    var onFilterTapped: (() -> Void)?

    private let monthButton = IncomeExpenseFilterButton(alignment: .leading)
    private let accountButton = IncomeExpenseFilterButton(alignment: .center)
    private let filterButton = IncomeExpenseFilterButton(alignment: .trailing)
    private let stackView = UIStackView()
    private let bottomLine = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(month: String, account: String, filterActive: Bool = false) {
        monthButton.setTitle(month)
        accountButton.setTitle(account)
        filterButton.setTitle(filterActive ? "已筛选" : "筛选")
        filterButton.setHighlighted(filterActive)
    }

    private func setupUI() {
        backgroundColor = .white
        isUserInteractionEnabled = true
        bottomLine.backgroundColor = .abankSeparator

        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.isUserInteractionEnabled = true

        addSubview(stackView)
        stackView.addArrangedSubview(monthButton)
        stackView.addArrangedSubview(accountButton)
        stackView.addArrangedSubview(filterButton)
        addSubview(bottomLine)

        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.top.bottom.equalToSuperview()
            make.height.equalTo(44)
        }
        bottomLine.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }

        monthButton.addTarget(self, action: #selector(monthTapped), for: .touchUpInside)
        accountButton.addTarget(self, action: #selector(accountTapped), for: .touchUpInside)
        filterButton.addTarget(self, action: #selector(filterTapped), for: .touchUpInside)
    }

    @objc private func monthTapped() { onMonthTapped?() }
    @objc private func accountTapped() { onAccountTapped?() }
    @objc private func filterTapped() { onFilterTapped?() }
}

private final class IncomeExpenseFilterButton: UIControl {

    enum Alignment {
        case leading, center, trailing
    }

    private let titleLabel = UILabel()
    private let arrowView = UIImageView()
    private let contentStack = UIStackView()

    init(alignment: Alignment) {
        super.init(frame: .zero)
        isUserInteractionEnabled = true

        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.textColor = .abankTextPrimary

        let config = UIImage.SymbolConfiguration(pointSize: 8, weight: .bold)
        arrowView.image = UIImage(systemName: "triangle.fill", withConfiguration: config)
        arrowView.tintColor = UIColor(red: 170 / 255, green: 170 / 255, blue: 170 / 255, alpha: 1)
        arrowView.contentMode = .scaleAspectFit
        arrowView.transform = CGAffineTransform(rotationAngle: .pi)

        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = 4
        contentStack.isUserInteractionEnabled = false
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(arrowView)

        addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            switch alignment {
            case .leading:
                make.leading.equalToSuperview()
            case .center:
                make.centerX.equalToSuperview()
            case .trailing:
                make.trailing.equalToSuperview()
            }
        }
        arrowView.snp.makeConstraints { make in
            make.size.equalTo(8)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }

    func setHighlighted(_ highlighted: Bool) {
        titleLabel.textColor = highlighted ? .abankOrange : .abankTextPrimary
        arrowView.tintColor = highlighted
            ? .abankOrange
            : UIColor(red: 170 / 255, green: 170 / 255, blue: 170 / 255, alpha: 1)
    }
}
