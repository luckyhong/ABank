//
//  CityPickerViewController.swift
//  ABank
//
//  统一城市选择：生活 Tab 与网点列表共用。选中保存成功后返回。
//

import UIKit
import SnapKit

final class CityPickerViewController: BranchFlowViewController, RouteHosting {
    var hostedRoute: AppRoute? { .cityPicker }

    override func setupUI() {
        super.setupUI()
        title = "选择城市"
    }

    override func refreshBankingData() {
        clearContent()
        let current = cities.currentCity
        addCard([
            branchCaption("当前城市"),
            branchTitleLine(current.name, font: .abankHeadline(), trailing: [locationIcon()])
        ], spacing: Spacing.xs)
        addSectionTitle("全部城市")

        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = Spacing.sm
        let columns = 3
        for start in stride(from: 0, to: BranchCatalog.cities.count, by: columns) {
            let row = UIStackView()
            row.spacing = Spacing.sm
            row.distribution = .fillEqually
            for index in start..<(start + columns) {
                guard index < BranchCatalog.cities.count else {
                    row.addArrangedSubview(UIView())
                    continue
                }
                let city = BranchCatalog.cities[index]
                row.addArrangedSubview(cityButton(city, selected: city == current))
            }
            grid.addArrangedSubview(row)
        }
        contentStack.addArrangedSubview(grid)
        addNotice("城市用于网点查询、取号预约及生活频道展示（本机模拟数据）")
    }

    private func locationIcon() -> UIView {
        let icon = UIImageView(image: UIImage(systemName: "location.fill"))
        icon.tintColor = .abankPrimary
        icon.snp.makeConstraints { $0.size.equalTo(16) }
        return icon
    }

    private func cityButton(_ city: BranchCity, selected: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(city.name, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: selected ? .medium : .regular)
        button.setTitleColor(selected ? .white : .abankTextPrimary, for: .normal)
        button.backgroundColor = selected ? .abankPrimary : .abankCardBackground
        button.layer.cornerRadius = 8
        button.accessibilityIdentifier = "cityPicker.\(city.id)"
        if selected { button.accessibilityTraits.insert(.selected) }
        button.snp.makeConstraints { $0.height.equalTo(44) }
        button.addAction(UIAction { [weak self] _ in self?.select(city) }, for: .touchUpInside)
        return button
    }

    private func select(_ city: BranchCity) {
        guard cities.select(cityID: city.id) else {
            showToast(BranchServiceError.saveFailed.errorDescription!)
            return
        }
        navigationController?.popViewController(animated: true)
    }
}
