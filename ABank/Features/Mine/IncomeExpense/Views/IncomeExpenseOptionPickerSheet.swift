//
//  IncomeExpenseOptionPickerSheet.swift
//  ABank
//

import UIKit
import SnapKit

final class IncomeExpenseOptionPickerSheet: UIView {

    var onSelect: ((String) -> Void)?
    var onCancel: (() -> Void)?

    private let dimView = UIView()
    private let panel = UIView()
    private let closeButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let headerLine = UIView()
    private let stackView = UIStackView()

    private var options: [(id: String, title: String)] = []
    private var selectedId: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func present(
        in host: UIView,
        title: String,
        options: [(id: String, title: String)],
        selectedId: String?
    ) {
        self.options = options
        self.selectedId = selectedId
        titleLabel.text = title
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

        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .abankTextPrimary
        titleLabel.textAlignment = .center

        headerLine.backgroundColor = .abankSeparator
        stackView.axis = .vertical
        stackView.alignment = .fill

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
            let row = UIButton(type: .system)
            row.contentHorizontalAlignment = .fill
            row.tag = index

            let title = UILabel()
            title.text = option.title
            title.font = .systemFont(ofSize: 16)
            title.textColor = .abankTextPrimary
            title.isUserInteractionEnabled = false

            let check = UIImageView()
            let checkConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            let selected = option.id == selectedId
            check.image = UIImage(
                systemName: selected ? "checkmark.circle.fill" : "circle",
                withConfiguration: checkConfig
            )
            check.tintColor = selected
                ? .abankTeal
                : UIColor(red: 200 / 255, green: 200 / 255, blue: 200 / 255, alpha: 1)
            check.isUserInteractionEnabled = false

            let separator = UIView()
            separator.backgroundColor = .abankSeparator
            separator.isHidden = index == options.count - 1
            separator.isUserInteractionEnabled = false

            row.addSubview(title)
            row.addSubview(check)
            row.addSubview(separator)
            title.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(16)
                make.centerY.equalToSuperview()
            }
            check.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-16)
                make.centerY.equalToSuperview()
                make.size.equalTo(22)
            }
            separator.snp.makeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
                make.height.equalTo(0.5)
            }
            row.addTarget(self, action: #selector(optionTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(row)
            row.snp.makeConstraints { make in
                make.height.equalTo(54)
            }
        }
    }

    @objc private func optionTapped(_ sender: UIButton) {
        guard options.indices.contains(sender.tag) else { return }
        let id = options[sender.tag].id
        let callback = onSelect
        dismiss {
            callback?(id)
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
