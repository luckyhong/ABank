//
//  LoanUsageRecordsViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class LoanUsageRecordsViewController: BaseViewController {

    private let contractId: String
    private var records: [LoanUsageRecord] = []
    private var expandedIds: Set<String> = []
    private var page = 0
    private var hasMore = true
    private var isLoadingMore = false

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let footerLabel = UILabel()

    init(contractId: String) {
        self.contractId = contractId
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "使用记录"
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.tintColor = .abankTextPrimary
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
    }

    override func setupUI() {
        view.backgroundColor = .white

        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(LoanUsageRecordCell.self, forCellReuseIdentifier: LoanUsageRecordCell.reuseId)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.showsVerticalScrollIndicator = false

        footerLabel.text = "上滑刷新更多"
        footerLabel.font = .systemFont(ofSize: 13)
        footerLabel.textColor = .abankTextTertiary
        footerLabel.textAlignment = .center

        let footer = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 56))
        let leftLine = UIView()
        let rightLine = UIView()
        leftLine.backgroundColor = .abankSeparator
        rightLine.backgroundColor = .abankSeparator
        footer.addSubview(leftLine)
        footer.addSubview(rightLine)
        footer.addSubview(footerLabel)
        footerLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        leftLine.snp.makeConstraints { make in
            make.centerY.equalTo(footerLabel)
            make.trailing.equalTo(footerLabel.snp.leading).offset(-12)
            make.width.equalTo(40)
            make.height.equalTo(0.5)
        }
        rightLine.snp.makeConstraints { make in
            make.centerY.equalTo(footerLabel)
            make.leading.equalTo(footerLabel.snp.trailing).offset(12)
            make.width.equalTo(40)
            make.height.equalTo(0.5)
        }
        tableView.tableFooterView = footer

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 截图默认展开第二项
        loadInitial()
    }

    private func loadInitial() {
        page = 0
        hasMore = true
        records = []
        let first = FinanceLedgerStore.shared.loanUsageRecordsPageData(
            contractId: contractId,
            page: 0,
            pageSize: 10
        )
        records = first.records
        hasMore = first.hasMore
        page = 1
        expandedIds.removeAll()
        updateFooter()
        tableView.reloadData()
    }

    private func loadMoreIfNeeded() {
        guard hasMore, !isLoadingMore else { return }
        isLoadingMore = true
        footerLabel.text = "加载中..."

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self else { return }
            let next = FinanceLedgerStore.shared.loanUsageRecordsPageData(
                contractId: self.contractId,
                page: self.page,
                pageSize: 10
            )
            self.records.append(contentsOf: next.records)
            self.hasMore = next.hasMore
            self.page += 1
            self.isLoadingMore = false
            self.updateFooter()
            self.tableView.reloadData()
            if next.records.isEmpty {
                self.showToast("没有更多记录")
            }
        }
    }

    private func updateFooter() {
        footerLabel.text = hasMore ? "上滑刷新更多" : "没有更多了"
    }

    private func toggleExpand(id: String) {
        if expandedIds.contains(id) {
            expandedIds.remove(id)
        } else {
            expandedIds.insert(id)
        }
        tableView.reloadData()
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}

extension LoanUsageRecordsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        records.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: LoanUsageRecordCell.reuseId,
            for: indexPath
        ) as! LoanUsageRecordCell
        let record = records[indexPath.row]
        cell.configure(
            record: record,
            expanded: expandedIds.contains(record.id),
            isLast: indexPath.row == records.count - 1
        )
        cell.onToggle = { [weak self] in
            self?.toggleExpand(id: record.id)
        }
        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        if offsetY > contentHeight - height - 40 {
            loadMoreIfNeeded()
        }
    }
}
