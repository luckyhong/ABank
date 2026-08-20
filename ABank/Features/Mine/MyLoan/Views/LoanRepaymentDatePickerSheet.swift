//
//  LoanRepaymentDatePickerSheet.swift
//  ABank
//

import UIKit
import SnapKit

final class LoanRepaymentDatePickerSheet: UIView {

    var onConfirm: ((Date) -> Void)?
    var onCancel: (() -> Void)?

    private let dimView = UIView()
    private let panel = UIView()
    private let cancelButton = UIButton(type: .system)
    private let confirmButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let picker = UIDatePicker()
    private let accent = UIColor.abankOrange

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func present(in host: UIView, date: Date, title: String) {
        titleLabel.text = title
        picker.date = date
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
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancelTapped)))

        panel.backgroundColor = .white
        panel.layer.cornerRadius = 12
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        panel.clipsToBounds = true

        cancelButton.setTitle("取消", for: .normal)
        cancelButton.setTitleColor(.abankTextPrimary, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        confirmButton.setTitle("确定", for: .normal)
        confirmButton.setTitleColor(accent, for: .normal)
        confirmButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .abankTextPrimary
        titleLabel.textAlignment = .center

        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.locale = Locale(identifier: "zh_CN")

        addSubview(dimView)
        addSubview(panel)
        panel.addSubview(cancelButton)
        panel.addSubview(confirmButton)
        panel.addSubview(titleLabel)
        panel.addSubview(picker)

        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        panel.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        cancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(14)
            make.height.equalTo(28)
        }
        confirmButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(cancelButton)
            make.height.equalTo(28)
        }
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(cancelButton)
            make.centerX.equalToSuperview()
        }
        picker.snp.makeConstraints { make in
            make.top.equalTo(cancelButton.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-8)
            make.height.equalTo(216)
        }
    }

    @objc private func cancelTapped() {
        dismiss { self.onCancel?() }
    }

    @objc private func confirmTapped() {
        let date = picker.date
        dismiss { self.onConfirm?(date) }
    }

    private func dismiss(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.22, animations: {
            self.panel.transform = CGAffineTransform(translationX: 0, y: self.panel.bounds.height + 40)
            self.dimView.alpha = 0
        }) { _ in
            self.removeFromSuperview()
            completion()
        }
    }
}
