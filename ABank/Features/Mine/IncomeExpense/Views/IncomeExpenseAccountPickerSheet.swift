//
//  IncomeExpenseAccountPickerSheet.swift
//  ABank
//

import UIKit
import SnapKit

final class IncomeExpenseAccountPickerSheet: UIView {

    var onSelect: ((IncomeExpenseAccountFilter) -> Void)?
    var onCancel: (() -> Void)?

    private let dimView = UIView()
    private let panel = UIView()
    private let closeButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let headerLine = UIView()
    private let stackView = UIStackView()

    private var selectedFilter: IncomeExpenseAccountFilter = .all
    private var options: [(filter: IncomeExpenseAccountFilter, title: String, icon: String)] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func present(
        in host: UIView,
        options: [(filter: IncomeExpenseAccountFilter, title: String, icon: String)],
        selected: IncomeExpenseAccountFilter
    ) {
        self.options = options
        self.selectedFilter = selected
        rebuildRows()

        frame = host.bounds
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.addSubview(self)
        layoutIfNeeded()
        panel.transform = CGAffineTransform(translationX: 0, y: panel.bounds.height + 40)
        dimView.alpha = 0
        UIView.animate(withDuration: 0.28, delay: 0, options: .curveEaseOut) {
            self.panel.transform = .identity
            self.dimView.alpha = 1
        }
    }

    private func setupUI() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeTapped)))

        panel.backgroundColor = .white
        panel.layer.cornerRadius = 14
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        panel.clipsToBounds = true

        let closeConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: closeConfig), for: .normal)
        closeButton.tintColor = .abankTextPrimary
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        titleLabel.text = "选择账户"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .abankTextPrimary
        titleLabel.textAlignment = .center

        headerLine.backgroundColor = .abankSeparator

        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 0

        addSubview(dimView)
        addSubview(panel)
        panel.addSubview(closeButton)
        panel.addSubview(titleLabel)
        panel.addSubview(headerLine)
        panel.addSubview(stackView)

        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        panel.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        closeButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
            make.size.equalTo(28)
        }
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(closeButton)
        }
        headerLine.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
        stackView.snp.makeConstraints { make in
            make.top.equalTo(headerLine.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-8)
        }
    }

    private func rebuildRows() {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for (index, option) in options.enumerated() {
            let row = IncomeExpenseAccountRowView()
            row.configure(
                title: option.title,
                iconName: option.icon,
                selected: option.filter == selectedFilter,
                showsSeparator: index < options.count - 1
            )
            let filter = option.filter
            row.onTap = { [weak self] in
                self?.handleSelect(filter)
            }
            stackView.addArrangedSubview(row)
            row.snp.makeConstraints { make in
                make.height.equalTo(56)
            }
        }
    }

    private func handleSelect(_ filter: IncomeExpenseAccountFilter) {
        selectedFilter = filter
        rebuildRows()
        let callback = onSelect
        dismiss {
            callback?(filter)
        }
    }

    @objc private func closeTapped() {
        dismiss()
        onCancel?()
    }

    private func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.22, animations: {
            self.panel.transform = CGAffineTransform(translationX: 0, y: self.panel.bounds.height + 40)
            self.dimView.alpha = 0
        }, completion: { _ in
            self.removeFromSuperview()
            completion?()
        })
    }
}

private final class IncomeExpenseAccountRowView: UIControl {
    var onTap: (() -> Void)?

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let checkView = UIImageView()
    private let separator = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, iconName: String, selected: Bool, showsSeparator: Bool) {
        titleLabel.text = title
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        iconView.image = UIImage(systemName: iconName, withConfiguration: iconConfig)
        iconView.tintColor = .abankTeal

        let checkConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        if selected {
            checkView.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: checkConfig)
            checkView.tintColor = .abankTeal
        } else {
            checkView.image = UIImage(systemName: "circle", withConfiguration: checkConfig)
            checkView.tintColor = UIColor(red: 200 / 255, green: 200 / 255, blue: 200 / 255, alpha: 1)
        }
        separator.isHidden = !showsSeparator
    }

    private func setupUI() {
        iconView.contentMode = .scaleAspectFit
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .abankTextPrimary
        checkView.contentMode = .scaleAspectFit
        separator.backgroundColor = .abankSeparator

        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(checkView)
        addSubview(separator)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(checkView.snp.leading).offset(-12)
        }
        checkView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(22)
        }
        separator.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    @objc private func tapped() { onTap?() }
}
