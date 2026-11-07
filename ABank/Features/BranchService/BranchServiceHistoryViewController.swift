//
//  BranchServiceHistoryViewController.swift
//  ABank
//
//  网点服务记录：取号与预约两段，倒序；有效记录可取消（需确认），取消后保留在列表中。
//

import UIKit
import SnapKit

final class BranchServiceHistoryViewController: BranchFlowViewController, RouteHosting {
    private var segment = 0

    var hostedRoute: AppRoute? { .branchServiceHistory }

    override func setupUI() {
        super.setupUI()
        title = "我的记录"
    }

    override func refreshBankingData() {
        clearContent()
        let control = UISegmentedControl(items: ["取号", "预约"])
        control.selectedSegmentIndex = segment
        control.accessibilityIdentifier = "branchHistory.segment"
        control.addAction(UIAction { [weak self, weak control] _ in
            self?.segment = control?.selectedSegmentIndex ?? 0
            self?.refreshBankingData()
        }, for: .valueChanged)
        contentStack.addArrangedSubview(control)
        segment == 0 ? addTickets() : addReservations()
    }

    private func addTickets() {
        let tickets = services.tickets
        guard !tickets.isEmpty else {
            addEmptyState("暂无记录", id: "branchHistory.empty")
            return
        }
        for ticket in tickets {
            let status = services.status(of: ticket)
            let row = recordCard(
                id: "branchHistory.ticket.\(ticket.id)",
                title: ticket.number + " · " + ticket.business.title,
                tag: BranchStatusTagView(ticketStatus: status),
                lines: [BranchCatalog.displayName(branchID: ticket.branchID),
                        "取号时间 " + dates.string(from: ticket.takenAt, format: "yyyy-MM-dd HH:mm")],
                cancelTitle: status.isActive ? "取消取号" : nil
            ) { [weak self] in
                self?.confirm("确定取消该号票？") { self?.perform { try self?.services.cancelTicket(id: ticket.id) } }
            }
            row.onTap = { [weak self] in
                guard let self else { return }
                self.router.open(.ticketDetail(ticketID: ticket.id), from: self)
            }
            contentStack.addArrangedSubview(row)
        }
    }

    private func addReservations() {
        let reservations = services.reservations
        guard !reservations.isEmpty else {
            addEmptyState("暂无记录", id: "branchHistory.empty")
            return
        }
        for reservation in reservations {
            let status = services.status(of: reservation)
            var lines = [BranchCatalog.displayName(branchID: reservation.branchID),
                         dayLabel(reservation.date) + " " + reservation.slotLabel,
                         "预约码 " + reservation.code]
            if let quantity = reservation.quantity { lines.append("兑换数量 \(quantity) 枚") }
            let row = recordCard(
                id: "branchHistory.reservation.\(reservation.id)",
                title: reservation.business.title,
                tag: BranchStatusTagView(reservationStatus: status),
                lines: lines,
                cancelTitle: status == .pending ? "取消预约" : nil
            ) { [weak self] in
                self?.confirm("确定取消该预约？") { self?.perform { try self?.services.cancelReservation(id: reservation.id) } }
            }
            contentStack.addArrangedSubview(row)
        }
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
            showToast("已取消")
        } catch {
            showError(error)
            refreshBankingData()
        }
    }

    private func recordCard(id: String, title: String, tag: UIView, lines: [String],
                            cancelTitle: String?, onCancel: @escaping () -> Void) -> HistoryRecordCard {
        HistoryRecordCard(id: id, title: title, tag: tag, lines: lines, cancelTitle: cancelTitle, onCancel: onCancel)
    }
}

/// 记录卡片：标题 + 状态，若干说明行，可选取消按钮。
final class HistoryRecordCard: UIControl {
    var onTap: (() -> Void)?

    init(id: String, title: String, tag: UIView, lines: [String], cancelTitle: String?, onCancel: @escaping () -> Void) {
        super.init(frame: .zero)
        backgroundColor = .abankCardBackground
        layer.cornerRadius = 10
        accessibilityIdentifier = id
        let labels = UIStackView(arrangedSubviews: [branchTitleLine(title, trailing: [tag])] + lines.map { branchCaption($0) })
        labels.axis = .vertical
        labels.spacing = Spacing.xs
        labels.isUserInteractionEnabled = false
        let stack = UIStackView(arrangedSubviews: [labels])
        stack.axis = .vertical
        stack.spacing = Spacing.sm
        stack.alignment = .fill
        if let cancelTitle {
            let cancel = UIButton(type: .system)
            cancel.setTitle(cancelTitle, for: .normal)
            cancel.titleLabel?.font = .abankCaptionMedium()
            cancel.setTitleColor(.abankOrangeDeep, for: .normal)
            cancel.contentHorizontalAlignment = .trailing
            cancel.accessibilityIdentifier = id + ".cancel"
            cancel.addAction(UIAction { _ in onCancel() }, for: .touchUpInside)
            stack.addArrangedSubview(cancel)
        }
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(Spacing.md) }
        addAction(UIAction { [weak self] _ in self?.onTap?() }, for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
