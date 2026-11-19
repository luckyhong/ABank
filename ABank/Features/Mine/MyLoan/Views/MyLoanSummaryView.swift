//
//  MyLoanSummaryView.swift
//  ABank
//

import UIKit
import SnapKit

final class MyLoanSummaryView: UIView {

    var onRepaymentDetailTapped: (() -> Void)?
    var onEyeTapped: (() -> Void)?

    private let monthlyDueAmountLabel = UILabel()
    private let monthlyDueTitleLabel = UILabel()
    private let repaymentButton = UIButton(type: .system)
    private let repaymentBadge = UIView()

    private let unpaidAmountLabel = UILabel()
    private let unpaidTitleRow = UIStackView()
    private let unpaidTitleLabel = UILabel()
    private let eyeButton = UIButton(type: .system)

    private let availableAmountLabel = UILabel()
    private let availableTitleLabel = UILabel()

    private var isAmountVisible = true
    private var unpaidAmount: Double = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(monthlyDue: Double, unpaidPrincipal: Double, availableLimit: Double) {
        unpaidAmount = unpaidPrincipal
        monthlyDueAmountLabel.text = monthlyDue.abankPlainAmountString()
        updateUnpaidDisplay()
        availableAmountLabel.text = availableLimit.abankPlainAmountString()
    }

    func setAmountVisible(_ visible: Bool) {
        isAmountVisible = visible
        eyeButton.accessibilityLabel = visible ? "隐藏未还本金" : "显示未还本金"
        updateUnpaidDisplay()

        let name = visible ? "eye" : "eye.slash"
        eyeButton.setImage(UIImage.abankAsset(isAmountVisible ? "abc_mine_detail_amount_eye_open" : "abc_mine_detail_amount_eye_closed", fallback: name, renderingMode: .alwaysTemplate, pointSize: 15), for: .normal)
    }

    private func updateUnpaidDisplay() {
        unpaidAmountLabel.text = isAmountVisible ? unpaidAmount.abankPlainAmountString() : "****"
    }

    private func setupUI() {
        backgroundColor = .white

        monthlyDueAmountLabel.font = UIFontMetrics(forTextStyle: .title1)
            .scaledFont(for: .monospacedDigitSystemFont(ofSize: 32, weight: .regular))
        monthlyDueAmountLabel.adjustsFontForContentSizeCategory = true
        monthlyDueAmountLabel.adjustsFontSizeToFitWidth = true
        monthlyDueAmountLabel.minimumScaleFactor = 0.6
        monthlyDueAmountLabel.textColor = .abankTextPrimary
        monthlyDueAmountLabel.textAlignment = .center

        monthlyDueTitleLabel.text = "本月应还(元)"
        monthlyDueTitleLabel.font = .systemFont(ofSize: 15)
        monthlyDueTitleLabel.textColor = .abankTextSecondary
        monthlyDueTitleLabel.textAlignment = .center

        repaymentButton.setTitle("应还详情", for: .normal)
        repaymentButton.setTitleColor(.white, for: .normal)
        repaymentButton.titleLabel?.font = UIFontMetrics(forTextStyle: .footnote)
            .scaledFont(for: .systemFont(ofSize: 15, weight: .medium))
        repaymentButton.titleLabel?.adjustsFontForContentSizeCategory = true
        repaymentButton.titleLabel?.adjustsFontSizeToFitWidth = true
        repaymentButton.titleLabel?.minimumScaleFactor = 0.68
        repaymentBadge.backgroundColor = UIColor(red: 1, green: 182.0 / 255, blue: 0, alpha: 1)
        repaymentBadge.layer.cornerRadius = 13
        repaymentBadge.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        repaymentBadge.isUserInteractionEnabled = false
        repaymentBadge.accessibilityIdentifier = "loan.overview.due.badge"
        repaymentButton.insertSubview(repaymentBadge, at: 0)
        repaymentBadge.snp.makeConstraints { make in
            make.leading.trailing.centerY.equalToSuperview()
            make.height.equalTo(26).priority(999)
            if let titleLabel = repaymentButton.titleLabel {
                make.height.greaterThanOrEqualTo(titleLabel.snp.height).offset(6)
            }
        }
        repaymentButton.accessibilityIdentifier = "loan.overview.due"
        repaymentButton.contentEdgeInsets = UIEdgeInsets(top: 7, left: 12, bottom: 7, right: 12)
        repaymentButton.addTarget(self, action: #selector(repaymentTapped), for: .touchUpInside)

        unpaidAmountLabel.font = .monospacedDigitSystemFont(ofSize: 20, weight: .regular)
        unpaidAmountLabel.textColor = .abankTextPrimary
        unpaidAmountLabel.textAlignment = .center

        unpaidTitleLabel.text = "未还本金总计(元)"
        unpaidTitleLabel.font = .systemFont(ofSize: 14)
        unpaidTitleLabel.textColor = .abankTextSecondary

        eyeButton.setImage(UIImage.abankAsset("abc_mine_detail_amount_eye_open", fallback: "eye", renderingMode: .alwaysTemplate, pointSize: 15), for: .normal)
        eyeButton.tintColor = .abankTextTertiary
        eyeButton.addTarget(self, action: #selector(eyeTapped), for: .touchUpInside)

        unpaidTitleRow.axis = .horizontal
        unpaidTitleRow.alignment = .center
        unpaidTitleRow.spacing = 4
        unpaidTitleRow.addArrangedSubview(unpaidTitleLabel)
        unpaidTitleRow.addArrangedSubview(eyeButton)

        availableAmountLabel.font = .monospacedDigitSystemFont(ofSize: 20, weight: .regular)
        availableAmountLabel.textColor = UIColor(red: 246.0 / 255, green: 193.0 / 255, blue: 36.0 / 255, alpha: 1)
        availableAmountLabel.textAlignment = .center
        availableAmountLabel.accessibilityIdentifier = "loan.overview.available.amount"

        availableTitleLabel.text = "可用额度(元)"
        availableTitleLabel.font = .systemFont(ofSize: 14)
        availableTitleLabel.textColor = .abankTextSecondary
        availableTitleLabel.textAlignment = .center

        let unpaidColumn = UIStackView(arrangedSubviews: [unpaidAmountLabel, unpaidTitleRow])
        unpaidColumn.axis = .vertical
        unpaidColumn.alignment = .center
        unpaidColumn.spacing = 6

        let availableColumn = UIStackView(arrangedSubviews: [availableAmountLabel, availableTitleLabel])
        availableColumn.axis = .vertical
        availableColumn.alignment = .center
        availableColumn.spacing = 6

        [monthlyDueAmountLabel, monthlyDueTitleLabel, repaymentButton, unpaidColumn, availableColumn]
            .forEach { addSubview($0) }

        monthlyDueAmountLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(Spacing.md)
            make.trailing.lessThanOrEqualTo(repaymentButton.snp.leading).offset(-Spacing.xs)
        }
        monthlyDueTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(monthlyDueAmountLabel.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
        }
        repaymentButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(monthlyDueAmountLabel)
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.30)
            make.height.greaterThanOrEqualTo(44)
        }
        unpaidColumn.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(monthlyDueTitleLabel.snp.bottom).offset(34)
            make.bottom.equalToSuperview().offset(-23)
            make.width.equalToSuperview().multipliedBy(0.5)
        }
        availableColumn.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(unpaidColumn)
            make.width.equalToSuperview().multipliedBy(0.5)
        }
        eyeButton.snp.makeConstraints { make in
            make.size.equalTo(18)
        }
    }

    @objc private func repaymentTapped() { onRepaymentDetailTapped?() }
    /// 可见性由页面根据全局隐私设置驱动，这里只上报点击
    @objc private func eyeTapped() { onEyeTapped?() }
}
