//
//  BranchDetailViewController.swift
//  ABank
//
//  网点详情：示意图、状态、地址、电话、本周营业时间、支持业务，以及取号/预约入口。
//

import UIKit
import SnapKit

final class BranchDetailViewController: BranchFlowViewController, RouteHosting {
    private let branchID: String

    var hostedRoute: AppRoute? { .branchDetail(branchID: branchID) }

    init(branchID: String, cities: CitySelectionStore = .shared, services: BranchServiceStore = .shared,
         dates: BankingDateContext = .system) {
        self.branchID = branchID
        super.init(cities: cities, services: services, dates: dates)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "网点详情"
    }

    override func refreshBankingData() {
        clearContent()
        guard let branch = BranchCatalog.branch(id: branchID) else {
            addEmptyState("网点不存在", id: "branchDetail.empty")
            return
        }
        let now = dates.now
        let state = BranchSchedule.openState(of: branch, at: now, dates: dates)

        let map = BranchSketchMapView()
        map.configure(branches: [branch], highlightedID: branch.id)
        map.snp.makeConstraints { $0.height.equalTo(150) }
        contentStack.addArrangedSubview(map)

        var info: [UIView] = [
            branchTitleLine(branch.name, font: .abankHeadline(), trailing: [BranchStatusTagView(state: state)])
        ]
        if case .closed(let next?) = state {
            info.append(branchCaption("下次营业：" + dayLabel(next) + " " + dates.string(from: next, format: "HH:mm")))
        }
        info.append(branchCaption("距您约 " + branchDistanceText(branch.distanceMeters) + " · " + branch.address))
        let phone = UIButton(type: .system)
        phone.setTitle("☎︎ " + branch.phone, for: .normal)
        phone.titleLabel?.font = .abankBody()
        phone.contentHorizontalAlignment = .leading
        phone.setTitleColor(.abankTeal, for: .normal)
        phone.accessibilityIdentifier = "branchDetail.phone"
        phone.addAction(UIAction { [weak self] _ in self?.showToast("网点电话已显示，请使用电话应用联系") }, for: .touchUpInside)
        info.append(phone)
        addCard(info)

        addSectionTitle("营业时间")
        addCard([BusinessHoursTableView(hours: branch.hours,
                                        todayWeekday: dates.calendar.component(.weekday, from: now))])

        addSectionTitle("可办理业务")
        let businesses = BranchBusiness.allCases.filter(branch.businesses.contains)
        let tags = businesses.isEmpty
            ? [branchCaption("自助设备：存取款、转账、查询（不提供柜面业务）")]
            : [wrapTags(businesses.map(\.title))]
        addCard(tags)

        addActions(branch: branch, state: state)
    }

    private func wrapTags(_ titles: [String]) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Spacing.sm
        for start in stride(from: 0, to: titles.count, by: 3) {
            let row = UIStackView(arrangedSubviews: titles[start..<min(start + 3, titles.count)].map {
                BranchStatusTagView(text: $0, active: true)
            } + [UIView()])
            row.spacing = Spacing.sm
            stack.addArrangedSubview(row)
        }
        return stack
    }

    private func addActions(branch: Branch, state: BranchOpenState) {
        let canTicket = state.allowsTicket && !branch.ticketBusinesses.isEmpty
        if !canTicket {
            let reason = branch.kind == .selfService ? "自助网点不提供柜面取号" : BranchServiceError.branchNotOpen.errorDescription!
            let label = branchCaption(reason)
            label.accessibilityIdentifier = "branchDetail.ticketReason"
            contentStack.addArrangedSubview(label)
        }
        let ticket = addButton("取号", id: "branchDetail.takeTicket") { [weak self] in self?.takeTicket(branch) }
        ticket.isEnabled = canTicket
        ticket.alpha = canTicket ? 1 : 0.4
        let reserve = addButton("预约", id: "branchDetail.reserve", primary: false) { [weak self] in
            guard let self else { return }
            self.router.open(.branchReservation(business: nil, branchID: branch.id), from: self)
        }
        reserve.isEnabled = branch.kind == .full
        reserve.alpha = branch.kind == .full ? 1 : 0.4
    }

    private func takeTicket(_ branch: Branch) {
        if let active = services.activeTicket {
            router.open(.ticketDetail(ticketID: active.id), from: self)
            // 提示显示在推入的号票页上，否则会被新页面遮住。
            (navigationController?.topViewController as? BaseViewController)?
                .showToast(BranchServiceError.activeTicketExists.errorDescription!)
            return
        }
        router.open(.takeTicket(branchID: branch.id), from: self)
    }
}
