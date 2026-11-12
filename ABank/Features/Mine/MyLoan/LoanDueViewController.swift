//
//  LoanDueViewController.swift
//  ABank
//

import UIKit
import SnapKit

/// 本月应还 / 下月应还
final class LoanDueViewController: BankingDataViewController {

    private let period: LoanDuePeriod
    private var pageData: LoanDuePageData
    private var expandedIds: Set<String> = []

    private let amountLabel = UILabel()
    private let captionLabel = UILabel()
    private let headerContainer = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let tipLabel = UILabel()

    init(period: LoanDuePeriod) {
        self.period = period
        self.pageData = FinanceLedgerStore.shared.loanDuePageData(period: period)
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = period.title
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.abankBackIndicator,
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )

        if period == .thisMonth {
            let item = UIBarButtonItem(
                title: "下月应还",
                style: .plain,
                target: self,
                action: #selector(nextMonthTapped)
            )
            item.setTitleTextAttributes(
                [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.abankTextSecondary],
                for: .normal
            )
            item.setTitleTextAttributes(
                [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.abankTextSecondary],
                for: .highlighted
            )
            navigationItem.rightBarButtonItem = item
        }
    }

    override func setupUI() {
        let pageGray = UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1)
        view.backgroundColor = period == .thisMonth ? pageGray : .white

        headerContainer.backgroundColor = .white

        amountLabel.font = .systemFont(ofSize: 36, weight: .regular)
        amountLabel.textColor = .abankAmount
        amountLabel.textAlignment = .center

        captionLabel.font = .systemFont(ofSize: 13)
        captionLabel.textColor = .abankTextTertiary
        captionLabel.textAlignment = .center

        tipLabel.font = .systemFont(ofSize: 12)
        tipLabel.textColor = .abankTextTertiary
        tipLabel.numberOfLines = 0

        tableView.backgroundColor = period == .thisMonth ? pageGray : .white
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(LoanDueInstallmentCell.self, forCellReuseIdentifier: LoanDueInstallmentCell.reuseId)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
        tableView.showsVerticalScrollIndicator = false

        view.addSubview(headerContainer)
        headerContainer.addSubview(amountLabel)
        headerContainer.addSubview(captionLabel)
        view.addSubview(tableView)

        headerContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }
        amountLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(36)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        captionLabel.snp.makeConstraints { make in
            make.top.equalTo(amountLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-28)
        }

        let divider = UIView()
        divider.backgroundColor = pageGray
        view.addSubview(divider)
        divider.snp.makeConstraints { $0.top.equalTo(headerContainer.snp.bottom); $0.leading.trailing.equalToSuperview(); $0.height.equalTo(8) }
        tableView.snp.makeConstraints { $0.top.equalTo(divider.snp.bottom); $0.leading.trailing.bottom.equalToSuperview() }

        applyPageData()
    }

    override func refreshBankingData() { applyPageData() }

    private func rebuildFooter() {
        let width = UIScreen.main.bounds.width
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .abankTextTertiary
        label.numberOfLines = 0
        label.text = pageData.tip
        label.frame = CGRect(x: 16, y: 16, width: width - 32, height: 0)
        label.sizeToFit()
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: width, height: label.frame.height + 32))
        label.frame.origin = CGPoint(x: 16, y: 16)
        footer.addSubview(label)
        tableView.tableFooterView = footer
    }

    private func applyPageData() {
        pageData = FinanceLedgerStore.shared.loanDuePageData(period: period)
        amountLabel.text = pageData.totalAmount.abankPlainAmountString()
        captionLabel.text = period.amountCaption
        tipLabel.text = pageData.tip
        expandedIds.formIntersection(Set(pageData.installments.map(\.id)))
        rebuildFooter()
        let empty = UILabel()
        empty.text = "该月份暂无待还分期"
        empty.textAlignment = .center
        empty.textColor = .abankTextSecondary
        tableView.backgroundView = pageData.installments.isEmpty ? empty : nil
        tableView.reloadData()
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func nextMonthTapped() {
        let controller = LoanDueViewController(period: .nextMonth)
        navigationController?.pushViewController(controller, animated: true)
    }
}

extension LoanDueViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        pageData.installments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: LoanDueInstallmentCell.reuseId,
            for: indexPath
        ) as! LoanDueInstallmentCell
        let item = pageData.installments[indexPath.row]
        cell.configure(
            item: item,
            expanded: expandedIds.contains(item.id),
            isLast: indexPath.row == pageData.installments.count - 1
        )
        cell.onToggle = { [weak self] in
            guard let self else { return }
            if self.expandedIds.contains(item.id) {
                self.expandedIds.remove(item.id)
            } else {
                self.expandedIds.insert(item.id)
            }
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        return cell
    }
}
