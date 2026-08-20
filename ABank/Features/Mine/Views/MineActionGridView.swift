//
//  MineActionGridView.swift
//  ABank
//

import UIKit
import SnapKit

final class MineActionGridView: UIView {

    var onItemTapped: ((Int) -> Void)?

    private let stack = UIStackView()
    private let columns = 4
    private var items: [MineGridItem] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with items: [MineGridItem]) {
        self.items = items
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.distribution = .fillEqually
        rowStack.alignment = .top
        stack.addArrangedSubview(rowStack)

        for (index, item) in items.enumerated() {
            rowStack.addArrangedSubview(makeCell(item: item, index: index))
        }
        if items.count < columns {
            for _ in 0..<(columns - items.count) {
                rowStack.addArrangedSubview(UIView())
            }
        }
    }

    private func setupUI() {
        stack.axis = .vertical
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func makeCell(item: MineGridItem, index: Int) -> UIView {
        let wrap = UIControl()
        wrap.tag = index
        wrap.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)

        let icon = UIImageView(image: UIImage(systemName: item.systemIcon))
        icon.tintColor = .abankPrimary
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
            make.top.equalToSuperview()
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
