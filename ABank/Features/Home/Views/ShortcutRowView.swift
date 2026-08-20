//
//  ShortcutRowView.swift
//  ABank
//
//  Created by 韩继宏 on 2025/11/06.
//

import UIKit
import SnapKit

final class ShortcutRowView: UIView {

    var onItemTapped: ((Int) -> Void)?

    private let container = UIView()
    private let stack = UIStackView()
    private var items: [HomeShortcutItem] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with items: [HomeShortcutItem]) {
        self.items = items
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, item) in items.enumerated() {
            let cell = makeCell(item: item, index: index)
            stack.addArrangedSubview(cell)
        }
    }

    private func setupUI() {
        container.backgroundColor = .abankCardBackground
        container.layer.cornerRadius = CornerRadius.lg
        container.addShadow(color: .black, opacity: 0.08, offset: CGSize(width: 0, height: 4), radius: 10)

        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually

        addSubview(container)
        container.addSubview(stack)

        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(92)
        }
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 6, bottom: 14, right: 6))
        }
    }

    private func makeCell(item: HomeShortcutItem, index: Int) -> UIView {
        let wrap = UIControl()
        wrap.tag = index
        wrap.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)

        let iconBox = UIView()
        iconBox.backgroundColor = item.backgroundColor
        iconBox.layer.cornerRadius = 12

        let icon = UIImageView(image: UIImage(systemName: item.systemIcon))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit

        let title = UILabel()
        title.text = item.title
        title.font = .systemFont(ofSize: 12)
        title.textColor = .abankTextPrimary
        title.textAlignment = .center

        wrap.addSubview(iconBox)
        wrap.addSubview(title)
        iconBox.addSubview(icon)

        iconBox.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.size.equalTo(42)
        }
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(20)
        }
        title.snp.makeConstraints { make in
            make.top.equalTo(iconBox.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview()
        }
        return wrap
    }

    @objc private func itemTapped(_ sender: UIControl) {
        onItemTapped?(sender.tag)
    }
}
