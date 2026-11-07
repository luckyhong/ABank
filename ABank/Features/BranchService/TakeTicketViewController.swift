//
//  TakeTicketViewController.swift
//  ABank
//
//  取号：选择业务，查看当前排队人数，确认后生成号票并以号票详情替换本页。
//

import UIKit
import SnapKit

final class TakeTicketViewController: BranchFlowViewController, RouteHosting {
    private let branchID: String
    private var business: BranchBusiness?

    var hostedRoute: AppRoute? { .takeTicket(branchID: branchID) }

    init(branchID: String, cities: CitySelectionStore = .shared, services: BranchServiceStore = .shared,
         dates: BankingDateContext = .system) {
        self.branchID = branchID
        super.init(cities: cities, services: services, dates: dates)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "网点取号"
    }

    override func refreshBankingData() {
        clearContent()
        guard let branch = BranchCatalog.branch(id: branchID) else {
            addEmptyState("网点不存在", id: "takeTicket.empty")
            return
        }
        let businesses = branch.ticketBusinesses
        if business == nil || !businesses.contains(business!) { business = businesses.first }
        let state = BranchSchedule.openState(of: branch, at: dates.now, dates: dates)

        addCard([
            branchTitleLine(branch.name, trailing: [BranchStatusTagView(state: state)]),
            branchCaption(branch.address)
        ], spacing: Spacing.xs)

        addSectionTitle("选择业务")
        let chips = BranchChipBar(titles: businesses.map { "\($0.queuePrefix ?? "") · \($0.title)" },
                                  selected: business.flatMap(businesses.firstIndex(of:)), idPrefix: "takeTicket.business")
        chips.onSelect = { [weak self] index in
            self?.business = businesses[index]
            self?.refreshBankingData()
        }
        contentStack.addArrangedSubview(chips)

        if let business {
            let ahead = services.queueAhead(branchID: branch.id, business: business)
            let label = branchCaption("当前前方约 \(ahead) 人，预计等待 \(ahead * BranchSchedule.minutesPerPerson) 分钟")
            label.accessibilityIdentifier = "takeTicket.ahead"
            addCard([label])
        }
        addNotice("取号后请留意叫号，叫号后 15 分钟内未办理视为完成（本机模拟）")
        let confirm = addButton("确认取号", id: "takeTicket.confirm") { [weak self] in self?.submit(branch) }
        confirm.isEnabled = business != nil && state.allowsTicket
        confirm.alpha = confirm.isEnabled ? 1 : 0.4
    }

    private func submit(_ branch: Branch) {
        guard let business else { return }
        do {
            let ticket = try services.takeTicket(branchID: branch.id, business: business)
            replaceSelf(with: TicketDetailViewController(ticketID: ticket.id, cities: cities, services: services, dates: dates))
        } catch BranchServiceError.activeTicketExists {
            if let active = services.activeTicket {
                let detail = TicketDetailViewController(ticketID: active.id, cities: cities, services: services, dates: dates)
                replaceSelf(with: detail)
                detail.loadViewIfNeeded()
                detail.showToast(BranchServiceError.activeTicketExists.errorDescription!)
            } else {
                showToast(BranchServiceError.activeTicketExists.errorDescription!)
            }
        } catch {
            showError(error)
            // 提交时营业状态可能已变化（如进入午休），重绘使状态与按钮同步。
            refreshBankingData()
        }
    }

    private func replaceSelf(with controller: UIViewController) {
        guard let nav = navigationController else { return }
        var stack = nav.viewControllers
        stack.removeAll { $0 === self }
        stack.append(controller)
        nav.setViewControllers(stack, animated: true)
    }
}
