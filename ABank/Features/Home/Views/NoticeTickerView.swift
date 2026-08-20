//
//  NoticeTickerView.swift
//  ABank
//

import UIKit
import SnapKit

final class NoticeTickerView: UIView {

    var onItemTapped: ((HomeNoticeItem) -> Void)?

    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        stack.axis = .vertical
        stack.spacing = 12
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with notices: [HomeNoticeItem]) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        notices.forEach { stack.addArrangedSubview(makeRow(item: $0)) }
    }

    private func makeRow(item: HomeNoticeItem) -> UIView {
        let wrap = UIControl()
        wrap.addAction(UIAction { [weak self] _ in
            self?.onItemTapped?(item)
        }, for: .touchUpInside)

        let tagLabel = UILabel()
        tagLabel.text = item.tag
        tagLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        tagLabel.textColor = .abankOrange

        let textLabel = UILabel()
        textLabel.text = item.text
        textLabel.font = .systemFont(ofSize: 13)
        textLabel.textColor = .abankTextPrimary
        textLabel.lineBreakMode = .byTruncatingTail

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = .abankTextTertiary
        arrow.contentMode = .scaleAspectFit

        wrap.addSubview(tagLabel)
        wrap.addSubview(textLabel)
        wrap.addSubview(arrow)

        tagLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(32)
        }
        arrow.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(10)
        }
        textLabel.snp.makeConstraints { make in
            make.leading.equalTo(tagLabel.snp.trailing).offset(8)
            make.trailing.equalTo(arrow.snp.leading).offset(-8)
            make.top.bottom.equalToSuperview()
            make.height.equalTo(20)
        }
        return wrap
    }
}
