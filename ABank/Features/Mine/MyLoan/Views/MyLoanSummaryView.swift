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
        updateUnpaidDisplay()
        let eyeConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        let name = visible ? "eye" : "eye.slash"
        eyeButton.setImage(UIImage(systemName: name, withConfiguration: eyeConfig), for: .normal)
    }

    private func updateUnpaidDisplay() {
        unpaidAmountLabel.text = isAmountVisible ? unpaidAmount.abankPlainAmountString() : "****"
    }

    private func setupUI() {
        backgroundColor = .white

        monthlyDueAmountLabel.font = .systemFont(ofSize: 32, weight: .regular)
        monthlyDueAmountLabel.textColor = .abankAmount
        monthlyDueAmountLabel.textAlignment = .center

        monthlyDueTitleLabel.text = "本月应还(元)"
        monthlyDueTitleLabel.font = .systemFont(ofSize: 13)
        monthlyDueTitleLabel.textColor = .abankTextSecondary
        monthlyDueTitleLabel.textAlignment = .center

        repaymentButton.setTitle("应还详情", for: .normal)
        repaymentButton.setTitleColor(.white, for: .normal)
        repaymentButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        // 截图为偏浅的橙黄色
        repaymentButton.backgroundColor = UIColor(red: 255 / 255, green: 180 / 255, blue: 80 / 255, alpha: 1)
        repaymentButton.layer.cornerRadius = 13
        repaymentButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)
        repaymentButton.addTarget(self, action: #selector(repaymentTapped), for: .touchUpInside)

        unpaidAmountLabel.font = .systemFont(ofSize: 18, weight: .regular)
        unpaidAmountLabel.textColor = .abankAmount
        unpaidAmountLabel.textAlignment = .center

        unpaidTitleLabel.text = "未还本金总计(元)"
        unpaidTitleLabel.font = .systemFont(ofSize: 12)
        unpaidTitleLabel.textColor = .abankTextSecondary

        let eyeConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        eyeButton.setImage(UIImage(systemName: "eye", withConfiguration: eyeConfig), for: .normal)
        eyeButton.tintColor = .abankTextTertiary
        eyeButton.addTarget(self, action: #selector(eyeTapped), for: .touchUpInside)

        unpaidTitleRow.axis = .horizontal
        unpaidTitleRow.alignment = .center
        unpaidTitleRow.spacing = 4
        unpaidTitleRow.addArrangedSubview(unpaidTitleLabel)
        unpaidTitleRow.addArrangedSubview(eyeButton)

        availableAmountLabel.font = .systemFont(ofSize: 18, weight: .regular)
        availableAmountLabel.textColor = UIColor(red: 240 / 255, green: 170 / 255, blue: 70 / 255, alpha: 1)
        availableAmountLabel.textAlignment = .center

        availableTitleLabel.text = "可用额度(元)"
        availableTitleLabel.font = .systemFont(ofSize: 12)
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
            make.top.equalToSuperview().offset(24)
            make.centerX.equalToSuperview()
        }
        monthlyDueTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(monthlyDueAmountLabel.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
        }
        repaymentButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.centerY.equalTo(monthlyDueAmountLabel)
            make.height.equalTo(26)
        }
        unpaidColumn.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(monthlyDueTitleLabel.snp.bottom).offset(24)
            make.bottom.equalToSuperview().offset(-20)
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
    @objc private func eyeTapped() {
        isAmountVisible.toggle()
        setAmountVisible(isAmountVisible)
        onEyeTapped?()
    }
}
