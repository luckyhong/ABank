//
//  TransferFunctionGridView.swift
//  ABank
//

import UIKit
import SnapKit

final class TransferFunctionGridView: UIView {

    var onItemTapped: ((Int) -> Void)?
    var onToggleExpand: (() -> Void)?

    private let gridStack = UIStackView()
    private let toggleButton = UIButton(type: .system)
    private var items: [TransferFunctionItem] = []
    private var isExpanded = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(items: [TransferFunctionItem], expanded: Bool) {
        self.items = items
        self.isExpanded = expanded
        reloadGrid()
    }

    private func setupUI() {
        backgroundColor = .white

        gridStack.axis = .vertical
        gridStack.alignment = .fill
        gridStack.spacing = 20

        let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        toggleButton.setImage(UIImage(systemName: "chevron.down", withConfiguration: config), for: .normal)
        toggleButton.tintColor = .abankTextTertiary
        toggleButton.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)

        addSubview(gridStack)
        addSubview(toggleButton)

        gridStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(8)
        }
        toggleButton.snp.makeConstraints { make in
            make.top.equalTo(gridStack.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 44, height: 28))
            make.bottom.equalToSuperview().offset(-4)
        }
    }

    private func reloadGrid() {
        gridStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let visibleCount = isExpanded ? items.count : min(4, items.count)
        let visible = Array(items.prefix(visibleCount))
        let rows = stride(from: 0, to: visible.count, by: 4).map {
            Array(visible[$0..<min($0 + 4, visible.count)])
        }

        for (rowIndex, rowItems) in rows.enumerated() {
            let row = UIStackView()
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.alignment = .fill
            for (colIndex, item) in rowItems.enumerated() {
                let index = rowIndex * 4 + colIndex
                row.addArrangedSubview(makeItemView(item: item, index: index))
            }
            // 补齐空位保持等分
            while row.arrangedSubviews.count < 4 {
                row.addArrangedSubview(UIView())
            }
            gridStack.addArrangedSubview(row)
        }

        let symbol = isExpanded ? "chevron.up" : "chevron.down"
        let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        toggleButton.setImage(UIImage(systemName: symbol, withConfiguration: config), for: .normal)
        toggleButton.isHidden = items.count <= 4
    }

    private func makeItemView(item: TransferFunctionItem, index: Int) -> UIView {
        let control = UIControl()
        control.tag = index
        control.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)

        let iconBackground = UIView()
        iconBackground.isUserInteractionEnabled = false

        let icon = UIImageView()
        icon.image = UIImage.abankAsset(item.imageName ?? "", fallback: item.systemIcon)
        if item.imageName == "abc_transfer_multiple" {
            icon.transform = CGAffineTransform(scaleX: -1, y: 1)
        }
        icon.tintColor = .abankTeal
        icon.contentMode = .scaleAspectFit
        icon.isUserInteractionEnabled = false

        let title = UILabel()
        title.text = item.title
        title.font = .systemFont(ofSize: 14)
        title.textColor = .abankTextPrimary
        title.textAlignment = .center
        title.numberOfLines = 1
        title.isUserInteractionEnabled = false

        control.addSubview(iconBackground)
        iconBackground.addSubview(icon)
        control.addSubview(title)

        iconBackground.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.size.equalTo(36)
        }
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(32)
        }
        title.snp.makeConstraints { make in
            make.top.equalTo(iconBackground.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(2)
            make.bottom.equalToSuperview()
        }

        return control
    }

    @objc private func itemTapped(_ sender: UIControl) { onItemTapped?(sender.tag) }
    @objc private func toggleTapped() { onToggleExpand?() }
}
