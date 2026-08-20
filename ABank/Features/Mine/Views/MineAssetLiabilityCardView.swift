//
//  MineAssetLiabilityCardView.swift
//  ABank
//

import UIKit
import SnapKit

final class MineAssetLiabilityCardView: UIView {

    var onTap: (() -> Void)?
    var onBillTapped: (() -> Void)?
    var onEyeTapped: (() -> Void)?

    private let card = UIView()
    private let header = MineCardHeaderView(title: "资产负债", showsEye: true)
    private let metrics = MineFinanceMetricView()
    private let separator = UIView()
    private let billRow = UIControl()
    private let billDot = UIView()
    private let billLabel = UILabel()
    private let billArrow = UILabel()

    private var isAmountVisible = true
    private var data: MineAssetLiability?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with data: MineAssetLiability) {
        self.data = data
        updateAmounts()
        billLabel.text = data.billNotice
    }

    func setAmountVisible(_ visible: Bool) {
        isAmountVisible = visible
        header.setAmountVisible(visible)
        updateAmounts()
    }

    private func updateAmounts() {
        guard let data else { return }
        metrics.configure(
            leftTitle: "我的资产",
            leftAmount: data.assets.abankCurrencyString(hidden: !isAmountVisible),
            rightTitle: "我的负债",
            rightAmount: data.liabilities.abankCurrencyString(hidden: !isAmountVisible)
        )
    }

    private func setupUI() {
        card.backgroundColor = .abankCardBackground
        card.layer.cornerRadius = CornerRadius.lg
        card.addShadow(color: .black, opacity: 0.06, offset: CGSize(width: 0, height: 2), radius: 8)

        separator.backgroundColor = .abankSeparator

        billDot.backgroundColor = .abankPrimary
        billDot.layer.cornerRadius = 3
        billLabel.font = .systemFont(ofSize: 13)
        billLabel.textColor = .abankTextSecondary
        billArrow.text = "»"
        billArrow.font = .systemFont(ofSize: 13)
        billArrow.textColor = .abankTextTertiary
        billRow.addTarget(self, action: #selector(billTapped), for: .touchUpInside)

        header.onTap = { [weak self] in self?.onTap?() }
        header.onEyeTapped = { [weak self] in
            self?.isAmountVisible.toggle()
            self?.header.setAmountVisible(self?.isAmountVisible ?? true)
            self?.updateAmounts()
            self?.onEyeTapped?()
        }

        addSubview(card)
        [header, metrics, separator, billRow].forEach { card.addSubview($0) }
        [billDot, billLabel, billArrow].forEach { billRow.addSubview($0) }

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
        separator.snp.makeConstraints { make in
            make.top.equalTo(metrics.snp.bottom).offset(Spacing.md)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.height.equalTo(0.5)
        }
        billRow.snp.makeConstraints { make in
            make.top.equalTo(separator.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(44)
        }
        billDot.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.centerY.equalToSuperview()
            make.size.equalTo(6)
        }
        billLabel.snp.makeConstraints { make in
            make.leading.equalTo(billDot.snp.trailing).offset(6)
            make.centerY.equalToSuperview()
        }
        billArrow.snp.makeConstraints { make in
            make.leading.equalTo(billLabel.snp.trailing).offset(4)
            make.centerY.equalToSuperview()
        }
    }

    @objc private func billTapped() { onBillTapped?() }
}
