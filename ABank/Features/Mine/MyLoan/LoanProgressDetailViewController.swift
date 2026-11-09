//
//  LoanProgressDetailViewController.swift
//  ABank
//
//  办理进度详情：竖向时间线 + 业务字段；提前还款显示与结果页相同的前后对比。
//

import UIKit
import SnapKit

final class LoanProgressDetailViewController: LoanStackPageViewController {
    private let item: LoanProgressItem
    private let store: FinanceLedgerStore

    init(item: LoanProgressItem, store: FinanceLedgerStore = .shared) {
        self.item = item
        self.store = store
        super.init(title: "办理进度")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func reloadContent() {
        let header = LoanListRowView(title: item.title, trailing: item.status, detail: item.loanName)
        header.isUserInteractionEnabled = false
        stack.addArrangedSubview(header)
        stack.addArrangedSubview(LoanTimelineView(steps: item.steps))
        addSectionGap()

        var rows: [(String, String)] = []
        if let record = item.record {
            rows.append(("合同号", record.contractNumber))
            rows.append(("业务编号", record.businessNo))
            switch record.kind {
            case .prepayment:
                rows += record.prepaymentComparisonRows(store: store)
            case .settlementCertificate:
                rows.append(("证明编号", record.certificateNo ?? "--"))
                rows.append(("申请时间", record.createdAt))
            }
        } else {
            rows.append(("办理状态", item.status))
            rows.append(("办理时间", item.time))
        }
        let section = UIStackView()
        section.axis = .vertical
        section.backgroundColor = .white
        for (index, row) in rows.enumerated() {
            section.addArrangedSubview(LoanInfoRowView(title: row.0, value: row.1, showsSeparator: index < rows.count - 1))
        }
        stack.addArrangedSubview(section)
    }
}

/// 竖向时间线：圆点 + 连线 + 标题 + 时间。
final class LoanTimelineView: UIView {
    init(steps: [LoanProgressStep]) {
        super.init(frame: .zero)
        backgroundColor = .white
        let column = UIStackView()
        column.axis = .vertical
        addSubview(column)
        column.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 16)) }

        for (index, step) in steps.enumerated() {
            let row = UIView()
            let dot = UIView()
            dot.backgroundColor = .abankOrange
            dot.layer.cornerRadius = 5
            let line = UIView()
            line.backgroundColor = UIColor.abankOrange.withAlphaComponent(0.35)
            line.isHidden = index == steps.count - 1
            let title = UILabel()
            title.text = step.title
            title.font = .systemFont(ofSize: 15)
            title.textColor = .abankTextPrimary
            let time = UILabel()
            time.text = step.time
            time.font = .systemFont(ofSize: 12)
            time.textColor = .abankTextTertiary

            [line, dot, title, time].forEach(row.addSubview)
            dot.snp.makeConstraints { make in
                make.leading.equalToSuperview()
                make.centerY.equalTo(title)
                make.size.equalTo(10)
            }
            line.snp.makeConstraints { make in
                make.centerX.equalTo(dot)
                make.top.equalTo(dot.snp.bottom)
                make.bottom.equalToSuperview()
                make.width.equalTo(1)
            }
            title.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.leading.equalTo(dot.snp.trailing).offset(12)
                make.trailing.lessThanOrEqualToSuperview()
            }
            time.snp.makeConstraints { make in
                make.top.equalTo(title.snp.bottom).offset(4)
                make.leading.equalTo(title)
                make.bottom.equalToSuperview().offset(-16)
            }
            column.addArrangedSubview(row)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
