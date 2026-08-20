//
//  SectionHeaderView.swift
//  ABank
//

import UIKit
import SnapKit

final class SectionHeaderView: UIView {

    var onTap: (() -> Void)?

    private let titleLabel = UILabel()
    private let accessoryStack = UIStackView()
    private let chevronView = UIImageView(image: UIImage(systemName: "chevron.right"))

    init(title: String, showsChevron: Bool = true) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupUI(showsChevron: showsChevron)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addAccessory(_ view: UIView) {
        accessoryStack.insertArrangedSubview(view, at: 0)
    }

    private func setupUI(showsChevron: Bool) {
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .abankTextPrimary

        chevronView.tintColor = .abankTextTertiary
        chevronView.contentMode = .scaleAspectFit
        chevronView.isHidden = !showsChevron

        accessoryStack.axis = .horizontal
        accessoryStack.alignment = .center
        accessoryStack.spacing = Spacing.sm
        accessoryStack.addArrangedSubview(chevronView)

        addSubview(titleLabel)
        addSubview(accessoryStack)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
        accessoryStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(Spacing.sm)
        }
        chevronView.snp.makeConstraints { make in
            make.size.equalTo(12)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    @objc private func handleTap() {
        onTap?()
    }
}

final class AdTagLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        text = "【广告】"
        font = .systemFont(ofSize: 9)
        textColor = UIColor.abankTextTertiary.withAlphaComponent(0.85)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
