//
//  MyLoanActionGridView.swift
//  ABank
//

import UIKit
import SnapKit

final class MyLoanActionGridView: UIView {

    var onItemTapped: ((Int) -> Void)?

    private let items: [(title: String, icon: String)] = [
        ("待办任务", "shippingbox"),
        ("进度查询", "doc.text.magnifyingglass"),
        ("贷款续贷", "arrow.triangle.2.circlepath"),
        ("结清证明", "checkmark.rectangle.portrait")
    ]

    private let topLine = UIView()
    private let bottomLine = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        backgroundColor = .white
        topLine.backgroundColor = .abankSeparator
        bottomLine.backgroundColor = .abankSeparator

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually

        items.enumerated().forEach { index, item in
            let button = MyLoanActionItemView(title: item.title, icon: item.icon)
            button.onTap = { [weak self] in self?.onItemTapped?(index) }
            stack.addArrangedSubview(button)
        }

        addSubview(topLine)
        addSubview(stack)
        addSubview(bottomLine)

        topLine.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
        stack.snp.makeConstraints { make in
            make.top.equalTo(topLine.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(62)
            make.bottom.equalTo(bottomLine.snp.top).offset(-14)
        }
        bottomLine.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
}

private final class MyLoanActionItemView: UIControl {
    var onTap: (() -> Void)?

    init(title: String, icon: String) {
        super.init(frame: .zero)
        let config = UIImage.SymbolConfiguration(pointSize: 26, weight: .light)
        let iconView = UIImageView(image: UIImage(systemName: icon, withConfiguration: config))
        iconView.tintColor = UIColor(red: 50 / 255, green: 175 / 255, blue: 160 / 255, alpha: 1)
        iconView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 12)
        label.textColor = .abankTextPrimary
        label.textAlignment = .center

        addSubview(iconView)
        addSubview(label)
        iconView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(30)
        }
        label.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    @objc private func tapped() { onTap?() }
}
