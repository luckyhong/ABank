//
//  AccountDetailQueryFilterBarView.swift
//  ABank
//

import UIKit
import SnapKit

final class AccountDetailQueryFilterBarView: UIView {

    var onWeekTapped: (() -> Void)?
    var onMonthTapped: (() -> Void)?
    var onThreeMonthsTapped: (() -> Void)?
    var onFilterTapped: (() -> Void)?

    private let weekButton = AccountDetailQueryPillButton()
    private let monthButton = AccountDetailQueryPillButton()
    private let threeMonthsButton = AccountDetailQueryPillButton()
    private let filterButton = AccountDetailQueryPillButton()
    private let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(range: AccountDetailQuickRange, filterActive: Bool) {
        weekButton.setSelected(range == .week)
        monthButton.setSelected(range == .month)
        threeMonthsButton.setSelected(range == .threeMonths)
        filterButton.setSelected(filterActive || range == .custom)
        filterButton.setTitle(filterActive ? "已筛选" : "筛选", showsChevron: true)
    }

    private func setupUI() {
        backgroundColor = UIColor(red: 242 / 255, green: 242 / 255, blue: 242 / 255, alpha: 1)

        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 12
        stackView.distribution = .fillEqually

        weekButton.setTitle("近一周", showsChevron: false)
        monthButton.setTitle("近一月", showsChevron: false)
        threeMonthsButton.setTitle("近三月", showsChevron: false)
        filterButton.setTitle("筛选", showsChevron: true)

        weekButton.addTarget(self, action: #selector(weekTapped), for: .touchUpInside)
        monthButton.addTarget(self, action: #selector(monthTapped), for: .touchUpInside)
        threeMonthsButton.addTarget(self, action: #selector(threeMonthsTapped), for: .touchUpInside)
        filterButton.addTarget(self, action: #selector(filterTapped), for: .touchUpInside)

        addSubview(stackView)
        [weekButton, monthButton, threeMonthsButton].forEach { stackView.addArrangedSubview($0) }
        addSubview(filterButton)

        stackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(32)
            make.width.equalToSuperview().multipliedBy(0.66).priority(.high)
        }
        filterButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.equalTo(64)
            make.height.equalTo(32)
            make.leading.greaterThanOrEqualTo(stackView.snp.trailing).offset(12)
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 64)
    }

    @objc private func weekTapped() { onWeekTapped?() }
    @objc private func monthTapped() { onMonthTapped?() }
    @objc private func threeMonthsTapped() { onThreeMonthsTapped?() }
    @objc private func filterTapped() { onFilterTapped?() }
}

/// 明细查询筛选胶囊按钮（选中态为橙色，与贷款还款页的青绿胶囊区分）
final class AccountDetailQueryPillButton: UIControl {

    private let titleLabel = UILabel()
    private let chevronView = UIImageView()
    private let contentStack = UIStackView()
    private var showsChevron = false

    private let selectedColor = UIColor(red: 245 / 255, green: 166 / 255, blue: 35 / 255, alpha: 1)

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 16
        layer.borderWidth = 0
        clipsToBounds = true

        titleLabel.font = .systemFont(ofSize: 14)
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
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
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
            backgroundColor = selectedColor
            layer.borderColor = selectedColor.cgColor
            titleLabel.textColor = .white
            chevronView.tintColor = .white
        } else {
            backgroundColor = .white
            layer.borderColor = UIColor(red: 220 / 255, green: 220 / 255, blue: 220 / 255, alpha: 1).cgColor
            titleLabel.textColor = .abankTextPrimary
            chevronView.tintColor = UIColor(red: 170 / 255, green: 170 / 255, blue: 170 / 255, alpha: 1)
        }
    }
}
