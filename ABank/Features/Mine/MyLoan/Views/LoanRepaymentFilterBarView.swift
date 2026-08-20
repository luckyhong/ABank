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

    func configure(range: LoanRepaymentQuickRange) {
        threeMonthsButton.setSelected(range == .threeMonths)
        oneYearButton.setSelected(range == .oneYear)
        filterButton.setSelected(range == .custom)
        filterButton.setTitle(range == .custom ? "已筛选" : "筛选", showsChevron: true)
    }

    private func setupUI() {
        backgroundColor = UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1)

        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 12
        stackView.distribution = .fill

        threeMonthsButton.setTitle("近三月", showsChevron: false)
        oneYearButton.setTitle("近一年", showsChevron: false)
        filterButton.setTitle("筛选", showsChevron: true)

        threeMonthsButton.addTarget(self, action: #selector(threeMonthsTapped), for: .touchUpInside)
        oneYearButton.addTarget(self, action: #selector(oneYearTapped), for: .touchUpInside)
        filterButton.addTarget(self, action: #selector(filterTapped), for: .touchUpInside)

        addSubview(stackView)
        [threeMonthsButton, oneYearButton, filterButton].forEach { stackView.addArrangedSubview($0) }

        stackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(32)
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 52)
    }

    @objc private func threeMonthsTapped() { onThreeMonthsTapped?() }
    @objc private func oneYearTapped() { onOneYearTapped?() }
    @objc private func filterTapped() { onFilterTapped?() }
}

private final class LoanRepaymentPillButton: UIControl {

    private let titleLabel = UILabel()
    private let chevronView = UIImageView()
    private let contentStack = UIStackView()
    private var showsChevron = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 16
        layer.borderWidth = 0.5
        clipsToBounds = true

        titleLabel.font = .systemFont(ofSize: 13)
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
            make.center.equalToSuperview()
        }
        chevronView.snp.makeConstraints { make in
            make.size.equalTo(7)
        }
        snp.makeConstraints { make in
            make.height.equalTo(32)
        }
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setSelected(false)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var intrinsicContentSize: CGSize {
        let titleWidth = titleLabel.intrinsicContentSize.width
        let chevronWidth: CGFloat = showsChevron ? 11 : 0
        return CGSize(width: 24 + titleWidth + chevronWidth, height: 32)
    }

    func setTitle(_ title: String, showsChevron: Bool) {
        titleLabel.text = title
        self.showsChevron = showsChevron
        chevronView.isHidden = !showsChevron
        invalidateIntrinsicContentSize()
    }

    func setSelected(_ selected: Bool) {
        if selected {
            backgroundColor = .abankTeal
            layer.borderColor = UIColor.abankTeal.cgColor
            titleLabel.textColor = .white
            chevronView.tintColor = .white
        } else {
            backgroundColor = .white
            layer.borderColor = UIColor(red: 220 / 255, green: 220 / 255, blue: 220 / 255, alpha: 1).cgColor
            titleLabel.textColor = .abankTextSecondary
            chevronView.tintColor = UIColor(red: 170 / 255, green: 170 / 255, blue: 170 / 255, alpha: 1)
        }
    }
}
