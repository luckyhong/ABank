//
//  WealthFunctionGridView.swift
//  ABank
//

import UIKit
import SnapKit

final class WealthFunctionGridView: UIView {

    var onItemTapped: ((Int) -> Void)?

    private let stack = UIStackView()
    private let columns = 5
    private var items: [WealthGridItem] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with items: [WealthGridItem]) {
        self.items = items
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let rows = Int(ceil(Double(items.count) / Double(columns)))
        for row in 0..<rows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.alignment = .top
            stack.addArrangedSubview(rowStack)

            let start = row * columns
            let end = min(start + columns, items.count)
            for index in start..<end {
                rowStack.addArrangedSubview(makeCell(item: items[index], index: index))
            }
            if end - start < columns {
                for _ in 0..<(columns - (end - start)) {
                    rowStack.addArrangedSubview(UIView())
                }
            }
        }
    }

    private func setupUI() {
        stack.axis = .vertical
        stack.spacing = 18
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func makeCell(item: WealthGridItem, index: Int) -> UIView {
        let wrap = UIControl()
        wrap.tag = index
        wrap.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)

        let icon = UIImageView(image: UIImage(systemName: item.systemIcon))
        icon.tintColor = .abankTextPrimary
        icon.contentMode = .scaleAspectFit

        let title = UILabel()
        title.text = item.title
        title.font = .systemFont(ofSize: 12)
        title.textColor = .abankTextPrimary
        title.textAlignment = .center
        title.numberOfLines = 2

        wrap.addSubview(icon)
        wrap.addSubview(title)
        icon.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(2)
            make.centerX.equalToSuperview()
            make.size.equalTo(28)
        }
        title.snp.makeConstraints { make in
            make.top.equalTo(icon.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(2)
            make.bottom.equalToSuperview()
        }
        return wrap
    }

    @objc private func itemTapped(_ sender: UIControl) {
        onItemTapped?(sender.tag)
    }
}
