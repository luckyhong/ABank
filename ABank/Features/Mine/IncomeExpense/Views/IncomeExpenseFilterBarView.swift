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
    private let bottomLine = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(month: String, account: String) {
        monthButton.setTitle(month)
        accountButton.setTitle(account)
        filterButton.setTitle("筛选")
    }

    private func setupUI() {
        backgroundColor = .white
        bottomLine.backgroundColor = .abankSeparator

        addSubview(monthButton)
        addSubview(accountButton)
        addSubview(filterButton)
        addSubview(bottomLine)

        monthButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.top.bottom.equalToSuperview()
            make.height.equalTo(44)
        }
        accountButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
        filterButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.top.bottom.equalToSuperview()
        }
        bottomLine.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }

        monthButton.onTap = { [weak self] in self?.onMonthTapped?() }
        accountButton.onTap = { [weak self] in self?.onAccountTapped?() }
        filterButton.onTap = { [weak self] in self?.onFilterTapped?() }
    }
}

private final class IncomeExpenseFilterButton: UIControl {
    enum Alignment { case leading, center, trailing }

    var onTap: (() -> Void)?

    private let titleLabel = UILabel()
    private let arrowView = UIImageView()
    private let contentStack = UIStackView()

    init(alignment: Alignment) {
        super.init(frame: .zero)
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
            case .leading: make.leading.equalToSuperview()
            case .center: make.centerX.equalToSuperview()
            case .trailing: make.trailing.equalToSuperview()
            }
        }
        arrowView.snp.makeConstraints { make in
            make.size.equalTo(8)
        }
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setTitle(_ title: String) { titleLabel.text = title }

    @objc private func tapped() { onTap?() }
}
