//
//  LoanRepaymentFilterBarView.swift
//  ABank
//

import UIKit
import SnapKit

final class LoanRepaymentFilterBarView: UIView {

    var onThreeMonthsTapped: (() -> Void)?
    var onOneYearTapped: (() -> Void)?
    var onFilterTapped: (() -> Void)?

    private let threeMonthsButton = LoanRepaymentPillButton()
    private let oneYearButton = LoanRepaymentPillButton()
    private let filterButton = LoanRepaymentPillButton()
    private let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(range: LoanRepaymentQuickRange, tab: LoanRepaymentTab) {
        threeMonthsButton.setTitle(tab == .plan ? "未来三月" : "近三月", showsChevron: false)
        oneYearButton.setTitle(tab == .plan ? "未来一年" : "近一年", showsChevron: false)
        threeMonthsButton.setSelected(range == .threeMonths)
        oneYearButton.setSelected(range == .oneYear)
        filterButton.setSelected(range == .custom)
        filterButton.setTitle(range == .custom ? "已筛选" : "筛选", showsChevron: true)
    }

    private func setupUI() {
        backgroundColor = UIColor(red: 241.0 / 255, green: 242.0 / 255, blue: 243.0 / 255, alpha: 1)

        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 12
        stackView.distribution = .fillEqually

        threeMonthsButton.setTitle("近三月", showsChevron: false)
        oneYearButton.setTitle("近一年", showsChevron: false)
        filterButton.setTitle("筛选", showsChevron: true)

        threeMonthsButton.addTarget(self, action: #selector(threeMonthsTapped), for: .touchUpInside)
        oneYearButton.addTarget(self, action: #selector(oneYearTapped), for: .touchUpInside)
        filterButton.addTarget(self, action: #selector(filterTapped), for: .touchUpInside)

        addSubview(stackView)
        for button in [threeMonthsButton, oneYearButton, filterButton] {
            let slot = UIView()
            stackView.addArrangedSubview(slot)
            slot.addSubview(button)
            button.snp.makeConstraints { make in
                make.top.bottom.centerX.equalToSuperview()
                make.width.lessThanOrEqualToSuperview()
                make.width.equalTo(82).priority(999)
            }
        }

        threeMonthsButton.accessibilityIdentifier = "loan.repayment.range.three"
        oneYearButton.accessibilityIdentifier = "loan.repayment.range.year"
        filterButton.accessibilityIdentifier = "loan.repayment.range.custom"
        stackView.snp.makeConstraints { $0.edges.equalToSuperview().inset(Spacing.md) }
    }

    @objc private func threeMonthsTapped() { onThreeMonthsTapped?() }
    @objc private func oneYearTapped() { onOneYearTapped?() }
    @objc private func filterTapped() { onFilterTapped?() }
}

private final class LoanRepaymentPillButton: UIControl {

    private let capsule = UIView()
    private let titleLabel = UILabel()
    private let chevronView = UIImageView()
    private let contentStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        capsule.layer.cornerRadius = 16
        capsule.isUserInteractionEnabled = false
        addSubview(capsule)

        titleLabel.font = .preferredFont(forTextStyle: .subheadline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        isAccessibilityElement = true
        titleLabel.textAlignment = .center

        let config = UIImage.SymbolConfiguration(pointSize: 7, weight: .bold)
        chevronView.image = UIImage(systemName: "triangle.fill", withConfiguration: config)
        chevronView.transform = CGAffineTransform(rotationAngle: .pi)
        chevronView.contentMode = .scaleAspectFit

        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = 4
        contentStack.isUserInteractionEnabled = false
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(chevronView)

        addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().offset(6)
            make.bottom.lessThanOrEqualToSuperview().offset(-6)
        }
        capsule.snp.makeConstraints { make in
            make.leading.trailing.centerY.equalToSuperview()
            make.height.greaterThanOrEqualTo(contentStack).offset(8)
            make.height.equalTo(32).priority(999)
        }
        chevronView.snp.makeConstraints { make in
            make.size.equalTo(7)
        }
        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(44)
        }
        setSelected(false)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setTitle(_ title: String, showsChevron: Bool) {
        titleLabel.text = title
        accessibilityLabel = title
        chevronView.isHidden = !showsChevron
    }

    func setSelected(_ selected: Bool) {
        accessibilityTraits = selected ? [.button, .selected] : .button
        if selected {
            capsule.backgroundColor = .abankTeal
            titleLabel.textColor = .white
            chevronView.tintColor = .white
        } else {
            capsule.backgroundColor = .white
            titleLabel.textColor = .abankTextPrimary
            chevronView.tintColor = UIColor(red: 170 / 255, green: 170 / 255, blue: 170 / 255, alpha: 1)
        }
    }
}
