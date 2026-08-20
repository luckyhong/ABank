//
//  LoanRepaymentFilterViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class LoanRepaymentFilterViewController: BaseViewController {

    var onConfirm: ((LoanRepaymentFilter) -> Void)?

    private var filter: LoanRepaymentFilter
    private var activeSheet: LoanRepaymentDatePickerSheet?

    private let timeTitleLabel = UILabel()
    private let startDateButton = LoanRepaymentDateFieldButton()
    private let endDateButton = LoanRepaymentDateFieldButton()
    private let dashLabel = UILabel()

    private let orderTitleLabel = UILabel()
    private let nearToFarButton = LoanRepaymentSortChipButton()
    private let farToNearButton = LoanRepaymentSortChipButton()

    private let footerView = UIView()
    private let resetButton = UIButton(type: .system)
    private let confirmButton = UIButton(type: .system)

    private let accent = UIColor.abankOrange

    init(filter: LoanRepaymentFilter) {
        self.filter = filter
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "筛选"
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.tintColor = .abankTextPrimary
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
    }

    override func setupUI() {
        view.backgroundColor = .white

        timeTitleLabel.text = "交易时间"
        timeTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        timeTitleLabel.textColor = .abankTextPrimary

        dashLabel.text = "-"
        dashLabel.font = .systemFont(ofSize: 14)
        dashLabel.textColor = .abankTextTertiary
        dashLabel.textAlignment = .center

        orderTitleLabel.text = "时间顺序"
        orderTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        orderTitleLabel.textColor = .abankTextPrimary

        nearToFarButton.setTitle("由近及远")
        farToNearButton.setTitle("由远及近")
        nearToFarButton.addTarget(self, action: #selector(nearToFarTapped), for: .touchUpInside)
        farToNearButton.addTarget(self, action: #selector(farToNearTapped), for: .touchUpInside)

        startDateButton.addTarget(self, action: #selector(startDateTapped), for: .touchUpInside)
        endDateButton.addTarget(self, action: #selector(endDateTapped), for: .touchUpInside)

        footerView.backgroundColor = .white
        let footerDivider = UIView()
        footerDivider.backgroundColor = .abankSeparator
        let midDivider = UIView()
        midDivider.backgroundColor = .abankSeparator

        resetButton.setTitle("重置", for: .normal)
        resetButton.setTitleColor(accent, for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        resetButton.backgroundColor = .white
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)

        confirmButton.setTitle("确定", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        confirmButton.backgroundColor = accent
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        view.addSubview(timeTitleLabel)
        view.addSubview(startDateButton)
        view.addSubview(dashLabel)
        view.addSubview(endDateButton)
        view.addSubview(orderTitleLabel)
        view.addSubview(nearToFarButton)
        view.addSubview(farToNearButton)
        view.addSubview(footerView)
        footerView.addSubview(resetButton)
        footerView.addSubview(confirmButton)
        footerView.addSubview(footerDivider)
        footerView.addSubview(midDivider)

        timeTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.equalToSuperview().offset(16)
        }
        startDateButton.snp.makeConstraints { make in
            make.top.equalTo(timeTitleLabel.snp.bottom).offset(14)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(40)
        }
        dashLabel.snp.makeConstraints { make in
            make.centerY.equalTo(startDateButton)
            make.leading.equalTo(startDateButton.snp.trailing).offset(10)
            make.width.equalTo(12)
        }
        endDateButton.snp.makeConstraints { make in
            make.centerY.height.equalTo(startDateButton)
            make.leading.equalTo(dashLabel.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-16)
            make.width.equalTo(startDateButton)
        }
        orderTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(startDateButton.snp.bottom).offset(28)
            make.leading.equalToSuperview().offset(16)
        }
        nearToFarButton.snp.makeConstraints { make in
            make.top.equalTo(orderTitleLabel.snp.bottom).offset(14)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(36)
            make.width.equalTo(farToNearButton)
        }
        farToNearButton.snp.makeConstraints { make in
            make.centerY.height.equalTo(nearToFarButton)
            make.leading.equalTo(nearToFarButton.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-16)
        }

        footerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        resetButton.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
            make.height.equalTo(50)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        confirmButton.snp.makeConstraints { make in
            make.trailing.top.equalToSuperview()
            make.leading.equalTo(resetButton.snp.trailing)
            make.height.equalTo(50)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        footerDivider.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(0.5)
        }
        midDivider.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalTo(resetButton)
            make.centerX.equalToSuperview()
            make.width.equalTo(0.5)
        }

        refreshUI()
    }

    private func refreshUI() {
        startDateButton.setDateText(filter.startDate)
        endDateButton.setDateText(filter.endDate)
        nearToFarButton.setSelected(filter.sortOrder == .nearToFar)
        farToNearButton.setSelected(filter.sortOrder == .farToNear)
    }

    @objc private func nearToFarTapped() {
        filter.sortOrder = .nearToFar
        refreshUI()
    }

    @objc private func farToNearTapped() {
        filter.sortOrder = .farToNear
        refreshUI()
    }

    @objc private func startDateTapped() {
        presentDatePicker(current: filter.startDate, title: "开始日期") { [weak self] date in
            guard let self else { return }
            let text = LoanRepaymentFilter.string(from: date)
            self.filter.startDate = text
            if self.filter.endDate < text {
                self.filter.endDate = text
            }
            self.refreshUI()
        }
    }

    @objc private func endDateTapped() {
        presentDatePicker(current: filter.endDate, title: "结束日期") { [weak self] date in
            guard let self else { return }
            let text = LoanRepaymentFilter.string(from: date)
            self.filter.endDate = text
            if self.filter.startDate > text {
                self.filter.startDate = text
            }
            self.refreshUI()
        }
    }

    private func presentDatePicker(current: String, title: String, onPick: @escaping (Date) -> Void) {
        activeSheet?.removeFromSuperview()
        let sheet = LoanRepaymentDatePickerSheet()
        let date = LoanRepaymentFilter.date(from: current) ?? Date()
        sheet.onConfirm = { [weak self] picked in
            self?.activeSheet = nil
            onPick(picked)
        }
        sheet.onCancel = { [weak self] in
            self?.activeSheet = nil
        }
        let host = navigationController?.view ?? view!
        sheet.present(in: host, date: date, title: title)
        activeSheet = sheet
    }

    @objc private func resetTapped() {
        filter.applyCustom(
            start: "2025-08-20",
            end: "2026-08-20",
            sortOrder: .nearToFar
        )
        refreshUI()
    }

    @objc private func confirmTapped() {
        filter.quickRange = .custom
        onConfirm?(filter)
        dismiss(animated: true)
    }

    @objc private func backTapped() {
        dismiss(animated: true)
    }
}

// MARK: - Subviews

private final class LoanRepaymentDateFieldButton: UIControl {

    private let valueLabel = UILabel()
    private let arrowView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 20
        layer.borderWidth = 0.5
        layer.borderColor = UIColor(red: 220 / 255, green: 220 / 255, blue: 220 / 255, alpha: 1).cgColor

        valueLabel.font = .systemFont(ofSize: 14)
        valueLabel.textColor = .abankTextPrimary

        let config = UIImage.SymbolConfiguration(pointSize: 8, weight: .bold)
        arrowView.image = UIImage(systemName: "triangle.fill", withConfiguration: config)
        arrowView.tintColor = UIColor(red: 170 / 255, green: 170 / 255, blue: 170 / 255, alpha: 1)
        arrowView.transform = CGAffineTransform(rotationAngle: .pi)
        arrowView.contentMode = .scaleAspectFit

        addSubview(valueLabel)
        addSubview(arrowView)
        valueLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(arrowView.snp.leading).offset(-8)
        }
        arrowView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.size.equalTo(8)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setDateText(_ text: String) {
        valueLabel.text = text
    }
}

private final class LoanRepaymentSortChipButton: UIControl {

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 18
        layer.borderWidth = 0.5
        clipsToBounds = true

        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textAlignment = .center
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        setSelected(false)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }

    func setSelected(_ selected: Bool) {
        if selected {
            backgroundColor = .abankOrange
            layer.borderColor = UIColor.abankOrange.cgColor
            titleLabel.textColor = .white
        } else {
            backgroundColor = .white
            layer.borderColor = UIColor(red: 220 / 255, green: 220 / 255, blue: 220 / 255, alpha: 1).cgColor
            titleLabel.textColor = .abankTextTertiary
        }
    }
}
