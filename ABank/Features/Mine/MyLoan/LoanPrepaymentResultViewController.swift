//
//  LoanPrepaymentResultViewController.swift
//  ABank
//
//  提前还款成功结果页：展示办理记录中保存的前后对比，不再读取可能已变化的合同。
//

import UIKit
import SnapKit

final class LoanPrepaymentResultViewController: BaseViewController {

    private let record: LoanServiceRecord
    private let store: FinanceLedgerStore
    private let actionStack = UIStackView()

    init(record: LoanServiceRecord, store: FinanceLedgerStore = .shared) {
        self.record = record
        self.store = store
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "提前还款结果"
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.abankBackIndicator,
            style: .plain,
            target: self,
            action: #selector(backToLoan)
        )
    }

    override func setupUI() {
        view.backgroundColor = .white

        let icon = UIImageView(image: UIImage.abankAsset("abc_transfer_result_success", fallback: "checkmark.circle.fill"))
        icon.tintColor = .abankOrange
        icon.contentMode = .scaleAspectFit
        icon.snp.makeConstraints { $0.height.equalTo(60) }

        let banner = UILabel()
        banner.text = "提前还款成功（模拟交易）"
        banner.font = .systemFont(ofSize: 20, weight: .medium)
        banner.textColor = .abankTextPrimary
        banner.textAlignment = .center
        banner.accessibilityIdentifier = "loan.prepay.result.status"

        let header = UIStackView(arrangedSubviews: [icon, banner])
        header.axis = .vertical
        header.spacing = 12
        header.isLayoutMarginsRelativeArrangement = true
        header.layoutMargins = UIEdgeInsets(top: 28, left: 16, bottom: 24, right: 16)

        let rowsStack = UIStackView()
        rowsStack.axis = .vertical
        let rows = resultRows()
        for (index, row) in rows.enumerated() {
            rowsStack.addArrangedSubview(LoanInfoRowView(title: row.0, value: row.1, showsSeparator: index < rows.count - 1))
        }

        actionStack.axis = .vertical
        actionStack.spacing = 12
        actionStack.isLayoutMarginsRelativeArrangement = true
        actionStack.layoutMargins = UIEdgeInsets(top: 24, left: 16, bottom: 0, right: 16)
        let back = UIButton(type: .system)
        back.setTitle("返回我的贷款", for: .normal)
        back.setTitleColor(.white, for: .normal)
        back.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        back.backgroundColor = .abankOrange
        back.layer.cornerRadius = 22
        back.accessibilityIdentifier = "loan.prepay.result.back"
        back.addTarget(self, action: #selector(backToLoan), for: .touchUpInside)
        back.snp.makeConstraints { $0.height.equalTo(44) }
        actionStack.addArrangedSubview(back)
        let progress = UIButton(type: .system)
        progress.setTitle("查看办理进度", for: .normal)
        progress.setTitleColor(.abankOrange, for: .normal)
        progress.titleLabel?.font = .systemFont(ofSize: 16)
        progress.accessibilityIdentifier = "loan.prepay.result.progress"
        progress.addTarget(self, action: #selector(showProgress), for: .touchUpInside)
        progress.snp.makeConstraints { $0.height.equalTo(44) }
        actionStack.addArrangedSubview(progress)

        let column = UIStackView(arrangedSubviews: [header, rowsStack, actionStack])
        column.axis = .vertical

        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.addSubview(column)
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        column.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(UIEdgeInsets(top: 0, left: 0, bottom: 32, right: 0))
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
    }

    private func resultRows() -> [(String, String)] {
        record.prepaymentComparisonRows(store: store) + [("办理时间", record.createdAt), ("业务编号", record.businessNo)]
    }

    @objc private func showProgress() {
        guard let item = store.loanProgressItems().first(where: { $0.record?.id == record.id }) else {
            return showToast("暂未查到办理进度")
        }
        navigationController?.pushViewController(LoanProgressDetailViewController(item: item, store: store), animated: true)
    }

    @objc private func backToLoan() {
        guard let nav = navigationController else { return }
        if let loan = nav.viewControllers.last(where: { $0 is MyLoanViewController }) {
            nav.popToViewController(loan, animated: true)
        } else {
            nav.popToRootViewController(animated: true)
        }
    }
}

extension LoanServiceRecord {
    /// 提前还款的前后对比行：结果页与办理进度详情共用，全部取自办理时保存的记录。
    func prepaymentComparisonRows(store: FinanceLedgerStore) -> [(String, String)] {
        func money(_ cents: Int64?) -> String { cents.map { TransferMoney.text($0) } ?? "--" }
        var rows: [(String, String)] = [
            ("还款金额", "\(money(amountInCents))元"),
            ("还款方式", method?.title ?? "--"),
            ("未还本金", "\(money(principalBefore)) → \(money(principalAfter))")
        ]
        if method == .reduceInstallment {
            rows.append(("每期还款额", "\(money(installmentBefore)) → \(money(installmentAfter))"))
        } else {
            rows.append(("剩余期数", "\(termsBefore.map(String.init) ?? "--") → \(termsAfter.map(String.init) ?? "--")"))
        }
        rows.append(("贷款到期日", maturityAfter.map(LoanAmortization.maturityText) ?? "--"))
        rows.append(("付款账户", accountID.flatMap { store.account(id: $0)?.cardLabel } ?? "--"))
        return rows
    }
}
