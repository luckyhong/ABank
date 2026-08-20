//
//  LoanRepaymentTabBarView.swift
//  ABank
//

import UIKit
import SnapKit

final class LoanRepaymentTabBarView: UIView {

    var onTabChanged: ((LoanRepaymentTab) -> Void)?

    private let planButton = UIButton(type: .system)
    private let detailButton = UIButton(type: .system)
    private let underline = UIView()
    private let bottomLine = UIView()
    private var selectedTab: LoanRepaymentTab = .detail

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        applySelection(animated: false)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(tab: LoanRepaymentTab) {
        selectedTab = tab
        applySelection(animated: false)
    }

    private func setupUI() {
        backgroundColor = .white
        bottomLine.backgroundColor = .abankSeparator
        underline.backgroundColor = .abankTeal
        underline.layer.cornerRadius = 1

        configure(button: planButton, title: "还款计划")
        configure(button: detailButton, title: "还款明细")
        planButton.addTarget(self, action: #selector(planTapped), for: .touchUpInside)
        detailButton.addTarget(self, action: #selector(detailTapped), for: .touchUpInside)

        addSubview(planButton)
        addSubview(detailButton)
        addSubview(bottomLine)
        addSubview(underline)

        planButton.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
        }
        detailButton.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
        }
        bottomLine.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        underline.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(2)
            make.width.equalTo(56)
            make.centerX.equalTo(detailButton)
        }
    }

    private func configure(button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.abankTextPrimary, for: .normal)
    }

    private func applySelection(animated: Bool) {
        let planSelected = selectedTab == .plan
        planButton.setTitleColor(planSelected ? .abankTeal : .abankTextPrimary, for: .normal)
        detailButton.setTitleColor(planSelected ? .abankTextPrimary : .abankTeal, for: .normal)

        let updates = {
            self.underline.snp.remakeConstraints { make in
                make.bottom.equalToSuperview()
                make.height.equalTo(2)
                make.width.equalTo(56)
                make.centerX.equalTo(planSelected ? self.planButton : self.detailButton)
            }
            self.layoutIfNeeded()
        }
        if animated {
            UIView.animate(withDuration: 0.22, animations: updates)
        } else {
            updates()
        }
    }

    @objc private func planTapped() {
        guard selectedTab != .plan else { return }
        selectedTab = .plan
        applySelection(animated: true)
        onTabChanged?(.plan)
    }

    @objc private func detailTapped() {
        guard selectedTab != .detail else { return }
        selectedTab = .detail
        applySelection(animated: true)
        onTabChanged?(.detail)
    }
}
