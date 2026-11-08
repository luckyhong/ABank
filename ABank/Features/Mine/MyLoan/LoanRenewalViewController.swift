//
//  LoanRenewalViewController.swift
//  ABank
//
//  贷款续贷：本期只做说明空态。
//

import UIKit
import SnapKit

final class LoanRenewalViewController: BaseViewController {

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        hidesBottomBarWhenPushed = true
    }

    convenience init() { self.init(nibName: nil, bundle: nil) }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "贷款续贷"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.abankBackIndicator, style: .plain, target: self, action: #selector(backTapped)
        )
    }

    override func setupUI() {
        view.backgroundColor = .white

        let icon = UIImageView(image: UIImage(systemName: "doc.text.magnifyingglass"))
        icon.tintColor = .abankTextTertiary
        icon.contentMode = .scaleAspectFit
        icon.snp.makeConstraints { $0.height.equalTo(64) }

        let title = UILabel()
        title.text = "暂无可续贷的贷款"
        title.font = .systemFont(ofSize: 18, weight: .medium)
        title.textColor = .abankTextPrimary
        title.textAlignment = .center
        title.accessibilityIdentifier = "loan.renewal.empty"

        let conditions = UILabel()
        conditions.text = "续贷需同时满足：\n· 贷款临近到期\n· 无逾期记录\n· 符合准入要求"
        conditions.font = .systemFont(ofSize: 14)
        conditions.textColor = .abankTextSecondary
        conditions.numberOfLines = 0

        let back = UIButton(type: .system)
        back.setTitle("返回", for: .normal)
        back.setTitleColor(.white, for: .normal)
        back.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        back.backgroundColor = .abankOrange
        back.layer.cornerRadius = 22
        back.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        back.snp.makeConstraints { $0.height.equalTo(44) }

        let column = UIStackView(arrangedSubviews: [icon, title, conditions, back])
        column.axis = .vertical
        column.spacing = 20
        column.setCustomSpacing(32, after: conditions)
        view.addSubview(column)
        column.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(72)
            make.leading.trailing.equalToSuperview().inset(40)
        }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}
