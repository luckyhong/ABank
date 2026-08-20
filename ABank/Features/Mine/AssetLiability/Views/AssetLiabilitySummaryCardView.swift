//
//  AssetLiabilitySummaryCardView.swift
//  ABank
//

import UIKit
import SnapKit

final class AssetLiabilitySummaryCardView: UIView {

    var onTabChanged: ((AssetLiabilityTab) -> Void)?
    var onWealthCheckupTapped: (() -> Void)?

    private let card = UIView()
    private let assetsColumn = UIControl()
    private let liabilitiesColumn = UIControl()
    private let footerSeparator = UIView()
    private let footerRow = UIView()
    private let timestampLabel = UILabel()
    private let wealthCheckupButton = UIButton(type: .system)

    private let assetsAmountLabel = UILabel()
    private let liabilitiesAmountLabel = UILabel()
    private let assetsTitleLabel = UILabel()
    private let liabilitiesTitleLabel = UILabel()
    private let assetsUnderline = UIView()
    private let liabilitiesUnderline = UIView()

    private var selectedTab: AssetLiabilityTab = .assets

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(totalAssets: Double, totalLiabilities: Double, timestamp: String, selectedTab: AssetLiabilityTab) {
        self.selectedTab = selectedTab
        assetsAmountLabel.text = totalAssets.abankPlainAmountString()
        liabilitiesAmountLabel.text = totalLiabilities.abankPlainAmountString()
        timestampLabel.text = "数据截至：\(timestamp)"
        updateTabAppearance()
    }

    func setSelectedTab(_ tab: AssetLiabilityTab) {
        selectedTab = tab
        updateTabAppearance()
    }

    private func setupUI() {
        card.backgroundColor = .white
        card.layer.cornerRadius = CornerRadius.md
        card.addShadow(color: .black, opacity: 0.06, offset: CGSize(width: 0, height: 2), radius: 8)

        [assetsAmountLabel, liabilitiesAmountLabel].forEach {
            $0.font = .systemFont(ofSize: 26, weight: .bold)
            $0.textColor = .abankTextPrimary
            $0.adjustsFontSizeToFitWidth = true
            $0.minimumScaleFactor = 0.65
        }
        liabilitiesAmountLabel.textAlignment = .right

        assetsTitleLabel.text = "总资产 (元)"
        liabilitiesTitleLabel.text = "总负债 (元)"
        [assetsTitleLabel, liabilitiesTitleLabel].forEach {
            $0.font = .systemFont(ofSize: 13)
            $0.textColor = .abankTextSecondary
        }
        liabilitiesTitleLabel.textAlignment = .right

        assetsUnderline.backgroundColor = UIColor(red: 255 / 255, green: 165 / 255, blue: 0 / 255, alpha: 1)
        liabilitiesUnderline.backgroundColor = .abankTeal
        [assetsUnderline, liabilitiesUnderline].forEach {
            $0.layer.cornerRadius = 1.5
        }

        assetsColumn.addTarget(self, action: #selector(assetsTapped), for: .touchUpInside)
        liabilitiesColumn.addTarget(self, action: #selector(liabilitiesTapped), for: .touchUpInside)

        footerSeparator.backgroundColor = .abankSeparator

        timestampLabel.font = .systemFont(ofSize: 11)
        timestampLabel.textColor = .abankTextTertiary

        let checkupConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .medium)
        wealthCheckupButton.setImage(UIImage(systemName: "circle.hexagongrid.fill", withConfiguration: checkupConfig), for: .normal)
        wealthCheckupButton.setTitle(" 财富体检", for: .normal)
        wealthCheckupButton.titleLabel?.font = .systemFont(ofSize: 12)
        wealthCheckupButton.tintColor = .abankTeal
        wealthCheckupButton.setTitleColor(.abankTextSecondary, for: .normal)
        wealthCheckupButton.backgroundColor = .white
        wealthCheckupButton.layer.cornerRadius = 14
        wealthCheckupButton.layer.borderWidth = 0.5
        wealthCheckupButton.layer.borderColor = UIColor(red: 220 / 255, green: 220 / 255, blue: 220 / 255, alpha: 1).cgColor
        wealthCheckupButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 12)
        wealthCheckupButton.addTarget(self, action: #selector(wealthCheckupTapped), for: .touchUpInside)

        addSubview(card)
        card.addSubview(assetsColumn)
        card.addSubview(liabilitiesColumn)
        card.addSubview(footerSeparator)
        card.addSubview(footerRow)
        footerRow.addSubview(timestampLabel)
        footerRow.addSubview(wealthCheckupButton)

        buildColumn(
            column: assetsColumn,
            amountLabel: assetsAmountLabel,
            titleLabel: assetsTitleLabel,
            underline: assetsUnderline,
            alignment: .leading
        )
        buildColumn(
            column: liabilitiesColumn,
            amountLabel: liabilitiesAmountLabel,
            titleLabel: liabilitiesTitleLabel,
            underline: liabilitiesUnderline,
            alignment: .trailing
        )

        card.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        assetsColumn.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(Spacing.md)
            make.trailing.equalTo(card.snp.centerX).offset(-6)
        }
        liabilitiesColumn.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(Spacing.md)
            make.leading.equalTo(card.snp.centerX).offset(6)
        }
        footerSeparator.snp.makeConstraints { make in
            make.top.equalTo(assetsColumn.snp.bottom).offset(Spacing.md)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.height.equalTo(0.5)
        }
        footerRow.snp.makeConstraints { make in
            make.top.equalTo(footerSeparator.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.bottom.equalToSuperview().offset(-Spacing.md)
            make.height.equalTo(28)
        }
        timestampLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        wealthCheckupButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.height.equalTo(28)
        }
    }

    private enum ColumnAlignment {
        case leading, trailing
    }

    private func buildColumn(
        column: UIControl,
        amountLabel: UILabel,
        titleLabel: UILabel,
        underline: UIView,
        alignment: ColumnAlignment
    ) {
        column.addSubview(amountLabel)
        column.addSubview(titleLabel)
        column.addSubview(underline)

        amountLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            if alignment == .leading {
                make.leading.equalToSuperview()
            } else {
                make.trailing.equalToSuperview()
            }
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(amountLabel.snp.bottom).offset(6)
            if alignment == .leading {
                make.leading.equalToSuperview()
            } else {
                make.trailing.equalToSuperview()
            }
        }
        underline.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
            make.leading.trailing.equalTo(titleLabel)
            make.height.equalTo(3)
            make.bottom.equalToSuperview()
        }
    }

    private func updateTabAppearance() {
        let isAssets = selectedTab == .assets
        assetsUnderline.isHidden = !isAssets
        liabilitiesUnderline.isHidden = isAssets
        assetsTitleLabel.textColor = isAssets ? .abankTextPrimary : .abankTextSecondary
        liabilitiesTitleLabel.textColor = isAssets ? .abankTextSecondary : .abankTextPrimary
        wealthCheckupButton.isHidden = !isAssets
    }

    @objc private func assetsTapped() {
        guard selectedTab != .assets else { return }
        selectedTab = .assets
        updateTabAppearance()
        onTabChanged?(.assets)
    }

    @objc private func liabilitiesTapped() {
        guard selectedTab != .liabilities else { return }
        selectedTab = .liabilities
        updateTabAppearance()
        onTabChanged?(.liabilities)
    }

    @objc private func wealthCheckupTapped() {
        onWealthCheckupTapped?()
    }
}
