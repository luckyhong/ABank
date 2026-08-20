//
//  MineMonthlyFlowCardView.swift
//  ABank
//

import UIKit
import SnapKit

final class MineMonthlyFlowCardView: UIView {

    var onTap: (() -> Void)?
    var onBillTapped: (() -> Void)?
    var onEyeTapped: (() -> Void)?

    private let card = UIView()
    private let header = MineCardHeaderView(title: "本月收支", showsEye: true)
    private let metrics = MineFinanceMetricView()
    private let ratioBar = MineRatioBarView()
    private let separator = UIView()
    private let billRow = UIControl()
    private let billSectionLabel = UILabel()
    private let billNoticeLabel = UILabel()
    private let billBadge = UIView()
    private let billChevron = UIImageView(image: UIImage(systemName: "chevron.right"))

    private var isAmountVisible = true
    private var data: MineMonthlyFlow?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with data: MineMonthlyFlow) {
        self.data = data
        updateAmounts()
        billSectionLabel.text = data.billSectionTitle
        billNoticeLabel.text = data.billNotice
        billBadge.isHidden = !data.hasBillBadge
        let total = data.expense + data.income
        let ratio = total > 0 ? data.expense / total : 0.5
        ratioBar.configure(leftRatio: ratio)
    }

    func setAmountVisible(_ visible: Bool) {
        isAmountVisible = visible
        header.setAmountVisible(visible)
        updateAmounts()
    }

    private func updateAmounts() {
        guard let data else { return }
        metrics.configure(
            leftTitle: "支出",
            leftAmount: data.expense.abankCurrencyString(hidden: !isAmountVisible),
            rightTitle: "收入",
            rightAmount: data.income.abankCurrencyString(hidden: !isAmountVisible)
        )
    }

    private func setupUI() {
        card.backgroundColor = .abankCardBackground
        card.layer.cornerRadius = CornerRadius.lg
        card.addShadow(color: .black, opacity: 0.06, offset: CGSize(width: 0, height: 2), radius: 8)

        separator.backgroundColor = .abankSeparator
        billSectionLabel.font = .systemFont(ofSize: 13)
        billSectionLabel.textColor = .abankTextSecondary
        billNoticeLabel.font = .systemFont(ofSize: 13)
        billNoticeLabel.textColor = .abankTextSecondary
        billBadge.backgroundColor = .abankBadge
        billBadge.layer.cornerRadius = 3
        billChevron.tintColor = .abankTextTertiary
        billChevron.contentMode = .scaleAspectFit
        billRow.addTarget(self, action: #selector(billTapped), for: .touchUpInside)

        header.onTap = { [weak self] in self?.onTap?() }
        header.onEyeTapped = { [weak self] in
            self?.isAmountVisible.toggle()
            self?.header.setAmountVisible(self?.isAmountVisible ?? true)
            self?.updateAmounts()
            self?.onEyeTapped?()
        }

        addSubview(card)
        [header, metrics, ratioBar, separator, billRow].forEach { card.addSubview($0) }
        [billSectionLabel, billNoticeLabel, billBadge, billChevron].forEach { billRow.addSubview($0) }

        card.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        metrics.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(Spacing.md)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        ratioBar.snp.makeConstraints { make in
            make.top.equalTo(metrics.snp.bottom).offset(Spacing.md)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        separator.snp.makeConstraints { make in
            make.top.equalTo(ratioBar.snp.bottom).offset(Spacing.md)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.height.equalTo(0.5)
        }
        billRow.snp.makeConstraints { make in
            make.top.equalTo(separator.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(44)
        }
        billSectionLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.centerY.equalToSuperview()
        }
        billChevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.centerY.equalToSuperview()
            make.size.equalTo(12)
        }
        billBadge.snp.makeConstraints { make in
            make.trailing.equalTo(billChevron.snp.leading).offset(-4)
            make.centerY.equalToSuperview()
            make.size.equalTo(6)
        }
        billNoticeLabel.snp.makeConstraints { make in
            make.trailing.equalTo(billBadge.snp.leading).offset(-4)
            make.centerY.equalToSuperview()
        }
    }

    @objc private func billTapped() { onBillTapped?() }
}
