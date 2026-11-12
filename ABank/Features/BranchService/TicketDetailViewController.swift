//
//  TicketDetailViewController.swift
//  ABank
//
//  号票详情：大号码、状态、前方人数与预计等待；有效时可取消。每 30 秒重算显示，不写库。
//

import UIKit
import SnapKit

final class TicketDetailViewController: BranchFlowViewController, RouteHosting {
    private let ticketID: String
    private var timer: Timer?

    var hostedRoute: AppRoute? { .ticketDetail(ticketID: ticketID) }

    init(ticketID: String, cities: CitySelectionStore = .shared, services: BranchServiceStore = .shared,
         dates: BankingDateContext = .system) {
        self.ticketID = ticketID
        super.init(cities: cities, services: services, dates: dates)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "我的号票"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        timer?.invalidate()
        let timer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in self?.refreshBankingData() }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
    }

    override func refreshBankingData() {
        clearContent()
        guard let ticket = services.ticket(id: ticketID) else {
            addEmptyState("记录不存在", id: "ticketDetail.empty")
            return
        }
        let status = services.status(of: ticket)

        let number = UILabel()
        number.text = ticket.number
        number.font = .systemFont(ofSize: 48, weight: .bold)
        number.textColor = status.isActive ? .abankPrimary : .abankTextTertiary
        number.textAlignment = .center
        number.accessibilityIdentifier = "ticketDetail.number"
        let statusTag = BranchStatusTagView(ticketStatus: status)
        statusTag.accessibilityIdentifier = "ticketDetail.status"
        let statusRow = UIStackView(arrangedSubviews: [UIView(), statusTag, UIView()])
        statusRow.distribution = .equalCentering
        var header: [UIView] = [number, statusRow]
        switch status {
        case .waiting(let ahead), .almostCalled(let ahead):
            let wait = branchCaption("前方 \(ahead) 人 · 预计等待约 \(ahead * BranchSchedule.minutesPerPerson) 分钟")
            wait.textAlignment = .center
            wait.accessibilityIdentifier = "ticketDetail.ahead"
            header.append(wait)
        case .called:
            let called = branchCaption("请前往柜台办理", color: .abankOrangeDeep)
            called.textAlignment = .center
            header.append(called)
        default:
            break
        }
        addCard(header, spacing: Spacing.sm, insets: Spacing.lg)

        addCard([
            TransferInfoRow("业务", value: ticket.business.title),
            TransferInfoRow("网点", value: BranchCatalog.displayName(branchID: ticket.branchID)),
            TransferInfoRow("取号时间", value: dates.string(from: ticket.takenAt, format: "yyyy-MM-dd HH:mm")),
            TransferInfoRow("取号时前方", value: "\(ticket.aheadAtTaking) 人")
        ], spacing: 0, insets: 0)

        if status.isActive {
            _ = addButton("取消取号", id: "ticketDetail.cancel", primary: false) { [weak self] in
                self?.confirm("确定取消该号票？") { self?.cancel(ticket) }
            }
        }
        addNotice("号票状态按取号时间更新，每人约3分钟")
    }

    private func cancel(_ ticket: QueueTicket) {
        do {
            try services.cancelTicket(id: ticket.id)
            showToast("已取消取号")
        } catch {
            showError(error)
            refreshBankingData()
        }
    }
}
