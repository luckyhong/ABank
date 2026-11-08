//
//  LoanCertificateViewController.swift
//  ABank
//
//  模拟贷款结清证明：正文、证明编号、出具日期，带“模拟证明，仅供演示”水印与模拟印章；可分享文字。
//

import UIKit
import SnapKit

extension SettledLoan {
    /// 证明正文；借款人姓名由调用方脱敏后传入。
    func certificateText(borrower: String) -> String {
        "借款人 \(borrower) 于 \(LoanAmortization.maturityText(startDate)) 向本行借款 "
            + "\(TransferMoney.amount(amountInCents).abankPlainAmountString()) 元（合同号 \(contractNumber)），"
            + "已于 \(LoanAmortization.maturityText(settledDate)) 全部结清。"
    }
}

final class LoanCertificateViewController: BaseViewController {
    private let loan: SettledLoan
    private let record: LoanServiceRecord

    init(loan: SettledLoan, record: LoanServiceRecord) {
        self.loan = loan
        self.record = record
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var bodyText: String {
        loan.certificateText(borrower: AccountHolderName.masked(CustomerInfoStore.shared.load().name))
    }

    private var issueDate: String {
        LoanAmortization.maturityText(String(record.createdAt.prefix(10)))
    }

    override func setupNavigationBar() {
        title = "结清证明"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.abankBackIndicator, style: .plain, target: self, action: #selector(backTapped)
        )
        let share = UIBarButtonItem(title: "分享", style: .plain, target: self, action: #selector(shareTapped))
        share.accessibilityIdentifier = "loan.certificate.share"
        navigationItem.rightBarButtonItem = share
    }

    override func setupUI() {
        view.backgroundColor = .abankBackground

        let paper = UIView()
        paper.backgroundColor = .white
        paper.layer.cornerRadius = 8
        paper.clipsToBounds = true

        let heading = UILabel()
        heading.text = "贷款结清证明"
        heading.font = .systemFont(ofSize: 20, weight: .semibold)
        heading.textColor = .abankTextPrimary
        heading.textAlignment = .center

        let body = UILabel()
        body.text = bodyText
        body.font = .systemFont(ofSize: 15)
        body.textColor = .abankTextPrimary
        body.numberOfLines = 0
        body.accessibilityIdentifier = "loan.certificate.body"

        let fields = UILabel()
        fields.text = "证明编号：\(record.certificateNo ?? "--")\n出具日期：\(issueDate)"
        fields.font = .systemFont(ofSize: 13)
        fields.textColor = .abankTextSecondary
        fields.numberOfLines = 0

        let watermark = UILabel()
        watermark.text = "模拟证明，仅供演示"
        watermark.font = .systemFont(ofSize: 28, weight: .bold)
        watermark.textColor = UIColor.abankTextTertiary.withAlphaComponent(0.18)
        watermark.transform = CGAffineTransform(rotationAngle: -.pi / 8)
        watermark.isAccessibilityElement = false

        let seal = UILabel()
        seal.text = "ABank\n模拟"
        seal.numberOfLines = 2
        seal.textAlignment = .center
        seal.font = .systemFont(ofSize: 14, weight: .bold)
        seal.textColor = .systemRed
        seal.layer.borderColor = UIColor.systemRed.cgColor
        seal.layer.borderWidth = 2
        seal.layer.cornerRadius = 40
        seal.alpha = 0.8
        seal.transform = CGAffineTransform(rotationAngle: -.pi / 12)

        [heading, body, fields, seal, watermark].forEach(paper.addSubview)
        view.addSubview(paper)

        paper.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        heading.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        body.snp.makeConstraints { make in
            make.top.equalTo(heading.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        fields.snp.makeConstraints { make in
            make.top.equalTo(body.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(20)
            make.trailing.lessThanOrEqualTo(seal.snp.leading).offset(-8)
        }
        seal.snp.makeConstraints { make in
            make.top.equalTo(body.snp.bottom).offset(16)
            make.trailing.equalToSuperview().offset(-24)
            make.size.equalTo(80)
            make.bottom.equalToSuperview().offset(-28)
        }
        watermark.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func shareTapped() {
        let text = "贷款结清证明（模拟证明，仅供演示）\n\(bodyText)\n证明编号：\(record.certificateNo ?? "--")"
        let controller = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        controller.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(controller, animated: true)
    }
}
