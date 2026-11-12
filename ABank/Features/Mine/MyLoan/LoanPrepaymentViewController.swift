//
//  LoanPrepaymentViewController.swift
//  ABank
//
//  提前还款（贷款详情入口）：输入金额与还款方式即时试算；确认后一次原子写入账本，成功替换为结果页。
//

import UIKit
import SnapKit

final class LoanPrepaymentViewController: BankingDataViewController {

    private let contractId: String
    private let store: FinanceLedgerStore
    private var preview: LoanPrepaymentPreview?
    private var isSubmitting = false

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let infoStack = UIStackView()
    private let payerStack = UIStackView()
    private let amountRow = TransferInputRow("还款金额", placeholder: "最低 100 元", id: "loan.prepay.amount", keyboard: .decimalPad)
    private let methodControl = UISegmentedControl(items: LoanRepaymentMethod.allCases.map(\.title))
    private let previewStack = UIStackView()
    private let messageLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    init(contractId: String, store: FinanceLedgerStore = .shared) {
        self.contractId = contractId
        self.store = store
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "提前还款"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.abankBackIndicator,
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
    }

    override func setupUI() {
        view.backgroundColor = .white

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive

        for stack in [infoStack, payerStack, previewStack] {
            stack.axis = .vertical
            stack.alignment = .fill
            stack.spacing = 0
        }

        amountRow.field.addTarget(self, action: #selector(inputChanged), for: .editingChanged)
        methodControl.selectedSegmentIndex = 0
        methodControl.accessibilityIdentifier = "loan.prepay.method"
        methodControl.addTarget(self, action: #selector(inputChanged), for: .valueChanged)
        let methodContainer = UIView()
        methodContainer.addSubview(methodControl)
        methodControl.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)) }

        messageLabel.font = .systemFont(ofSize: 13)
        messageLabel.textColor = .systemRed
        messageLabel.numberOfLines = 0
        messageLabel.accessibilityIdentifier = "loan.prepay.message"

        actionButton.setTitle("提前还款", for: .normal)
        actionButton.setTitleColor(.abankOrange, for: .normal)
        actionButton.setTitleColor(.abankTextTertiary, for: .disabled)
        actionButton.titleLabel?.font = .systemFont(ofSize: 16)
        actionButton.accessibilityIdentifier = "loan.prepay.submit"
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)

        let notice = UILabel()
        notice.text = "提前还款仅偿还本金"
        notice.font = .systemFont(ofSize: 12)
        notice.textColor = .abankTextTertiary
        notice.textAlignment = .center

        let column = UIStackView(arrangedSubviews: [
            infoStack, spacer(), payerStack, amountRow, methodContainer, previewStack,
            messageContainer(), spacer(), actionButton, notice
        ])
        column.axis = .vertical
        column.spacing = 0
        actionButton.snp.makeConstraints { $0.height.equalTo(52) }

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(column)
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        column.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-40)
        }

        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        refreshBankingData()
    }

    override func refreshBankingData() {
        guard isViewLoaded else { return }
        reloadInfo()
        reloadPayer()
        recalculate()
    }

    private var method: LoanRepaymentMethod {
        LoanRepaymentMethod.allCases[max(0, methodControl.selectedSegmentIndex)]
    }

    // MARK: - 展示

    private func reloadInfo() {
        clear(infoStack)
        guard let info = store.loanPrepaymentInfo(contractId: contractId) else { return }
        let rows: [(String, String, Bool)] = [
            ("贷款凭证号", info.voucherNumber, false),
            ("贷款合约号", info.contractNumber, false),
            ("贷款到期日", info.maturityDate, false),
            ("用款时间", info.usageDate, false),
            ("贷款年化利率", String(format: "%.1f%%", info.annualRatePercent), true),
            ("未还本金", "\(info.unpaidPrincipal.abankPlainAmountString())元", false)
        ]
        for (index, item) in rows.enumerated() {
            let row = LoanInfoRowView(title: item.0, value: item.1, showsInfo: item.2,
                                      showsSeparator: index < rows.count - 1)
            if item.2 {
                row.onInfoTapped = { [weak self] in self?.showToast("贷款年化利率说明") }
            }
            infoStack.addArrangedSubview(row)
        }
    }

    private func reloadPayer() {
        clear(payerStack)
        let account = store.account(id: FinanceLedgerRecord.defaultAccountId)
        payerStack.addArrangedSubview(LoanInfoRowView(title: "付款账户", value: account?.cardLabel ?? "--"))
        payerStack.addArrangedSubview(LoanInfoRowView(
            title: "可用余额", value: account.map { "\($0.balance.abankPlainAmountString())元" } ?? "--"))
    }

    @objc private func inputChanged() {
        recalculate()
    }

    private func recalculate() {
        clear(previewStack)
        preview = nil
        messageLabel.text = nil
        let text = (amountRow.field.text ?? "").trimmingCharacters(in: .whitespaces)
        defer { actionButton.isEnabled = preview != nil && !isSubmitting }
        guard !text.isEmpty else { return }
        do {
            let amount = try LoanRules.amount(text)
            let result = try store.previewPrepayment(contractID: contractId, amountInCents: amount, method: method)
            preview = result
            for row in previewRows(result) {
                previewStack.addArrangedSubview(LoanInfoRowView(title: row.0, value: row.1))
            }
        } catch {
            messageLabel.text = error.localizedDescription
        }
    }

    private func previewRows(_ result: LoanPrepaymentPreview) -> [(String, String)] {
        func money(_ cents: Int64) -> String { TransferMoney.amount(cents).abankPlainAmountString() }
        var rows = [("还款后未还本金", "\(money(result.principalAfter))元")]
        switch method {
        case .shortenTerm:
            rows.append(("剩余期数", "\(result.termsBefore) → \(result.termsAfter)"))
            rows.append(("末期还款额", "\(money(result.lastInstallmentBefore)) → \(money(result.lastInstallmentAfter))"))
            rows.append(("预计到期日", LoanAmortization.maturityText(result.maturityAfter)))
        case .reduceInstallment:
            rows.append(("每期还款额", "\(money(result.installmentBefore)) → \(money(result.installmentAfter))"))
        }
        return rows
    }

    // MARK: - 提交

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func actionTapped() {
        view.endEditing(true)
        guard let preview, !isSubmitting else { return }
        let method = self.method
        let payer = store.account(id: FinanceLedgerRecord.defaultAccountId)?.cardLabel ?? "--"
        let alert = UIAlertController(
            title: "确认提前还款",
            message: "还款金额 \(TransferMoney.amount(preview.amountInCents).abankPlainAmountString()) 元\n还款方式 \(method.title)\n付款账户 \(payer)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确认", style: .default) { [weak self] _ in
            self?.submit(preview: preview, method: method)
        })
        present(alert, animated: true)
    }

    private func submit(preview: LoanPrepaymentPreview, method: LoanRepaymentMethod) {
        isSubmitting = true
        actionButton.isEnabled = false
        // requestID 在本次确认时生成一次，重复点按不会重复扣款。
        let requestID = UUID().uuidString
        do {
            let record = try store.submitPrepayment(contractID: contractId, amountInCents: preview.amountInCents,
                                                    method: method, requestID: requestID, expected: preview)
            isSubmitting = false
            showResult(record)
        } catch LoanError.changed {
            isSubmitting = false
            refreshBankingData()
            showToast(LoanError.changed.localizedDescription)
        } catch {
            isSubmitting = false
            actionButton.isEnabled = self.preview != nil
            showToast(error.localizedDescription)
        }
    }

    private func showResult(_ record: LoanServiceRecord) {
        guard let nav = navigationController else { return }
        var stack = nav.viewControllers
        if let index = stack.firstIndex(of: self) { stack.remove(at: index) }
        stack.append(LoanPrepaymentResultViewController(record: record, store: store))
        nav.setViewControllers(stack, animated: true)
    }

    // MARK: - 辅助

    private func clear(_ stack: UIStackView) {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    private func spacer() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1)
        view.snp.makeConstraints { $0.height.equalTo(8) }
        return view
    }

    private func messageContainer() -> UIView {
        let container = UIView()
        container.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 8, right: 16)) }
        return container
    }
}
