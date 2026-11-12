//
//  ReservationFormViewController.swift
//  ABank
//
//  网点预约：业务、网点、日期（7 天）、时段，纪念币另选数量。提交时由 Store 重新校验。
//

import UIKit
import SnapKit

final class ReservationFormViewController: BranchFlowViewController, RouteHosting {
    private let initialBusiness: BranchBusiness?
    private let initialBranchID: String?
    private var business: BranchBusiness
    private var branchID: String?
    private var day: Date?
    private var slotStart: Int?
    private var quantity = 1

    var hostedRoute: AppRoute? { .branchReservation(business: initialBusiness, branchID: initialBranchID) }

    init(business: BranchBusiness?, branchID: String?, cities: CitySelectionStore = .shared,
         services: BranchServiceStore = .shared, dates: BankingDateContext = .system) {
        initialBusiness = business
        initialBranchID = branchID
        self.business = business ?? .personalNonCash
        self.branchID = branchID
        super.init(cities: cities, services: services, dates: dates)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "网点预约"
    }

    /// 从网点详情进入时只列该网点支持的业务；否则列出全部预约业务。
    private var businessOptions: [BranchBusiness] {
        if let id = initialBranchID, let branch = BranchCatalog.branch(id: id) { return branch.reservationBusinesses }
        return BranchBusiness.reservationBusinesses
    }

    /// 可选网点：所选网点所在城市（默认当前城市）中支持该业务的网点。
    private var branchOptions: [Branch] {
        let cityID = branchID.flatMap(BranchCatalog.branch(id:))?.cityID ?? cities.currentCity.id
        return BranchCatalog.branches(inCity: cityID).filter { $0.businesses.contains(business) }
    }

    private func normalizeSelection() {
        let businesses = businessOptions
        if !businesses.contains(business), let first = businesses.first { business = first }
        let options = branchOptions
        if !options.contains(where: { $0.id == branchID }) {
            branchID = BranchCatalog.branches(inCity: cities.currentCity.id).first { $0.businesses.contains(business) }?.id
        }
        guard let branch = branchID.flatMap(BranchCatalog.branch(id:)) else {
            day = nil
            slotStart = nil
            return
        }
        let days = BranchSchedule.reservableDays(for: branch, dates: dates)
        if day == nil || !days.contains(day!) {
            day = days.first { d in BranchSchedule.slots(for: branch, on: d, dates: dates).contains(where: \.isAvailable) }
                ?? days.first
        }
        if let day, let start = slotStart,
           !BranchSchedule.slots(for: branch, on: day, dates: dates).contains(where: { $0.startMinute == start && $0.isAvailable }) {
            slotStart = nil
        }
    }

    override func refreshBankingData() {
        clearContent()
        normalizeSelection()
        let businesses = businessOptions
        guard !businesses.isEmpty else {
            addEmptyState("该网点暂不支持预约", id: "reservation.empty")
            return
        }

        addSectionTitle("预约业务")
        let businessChips = BranchChipBar(titles: businesses.map(\.title), selected: businesses.firstIndex(of: business),
                                          idPrefix: "reservation.business")
        businessChips.onSelect = { [weak self] index in
            self?.business = businesses[index]
            self?.slotStart = nil
            self?.refreshBankingData()
        }
        contentStack.addArrangedSubview(businessChips)

        guard let branch = branchID.flatMap(BranchCatalog.branch(id:)) else {
            addEmptyState("当前城市暂无可预约该业务的网点", id: "reservation.noBranch")
            return
        }

        let branchRow = BranchSelectRow(title: "预约网点", value: branch.name, id: "reservation.branch")
        branchRow.onTap = { [weak self] in self?.chooseBranch() }
        var cardViews: [UIView] = [branchRow, branchCaption(branch.address)]
        if business.requiresQuantity {
            let stepper = QuantityStepperRow(title: "兑换数量", value: quantity, range: BranchBusiness.coinQuantityRange)
            stepper.onChange = { [weak self] value in self?.quantity = value }
            cardViews.append(stepper)
        }
        addCard(cardViews)

        addSectionTitle("预约日期")
        let days = BranchSchedule.reservableDays(for: branch, dates: dates)
        let today = dates.calendar.startOfDay(for: dates.now)
        let dayTitles = days.map { d -> String in
            let prefix = d == today ? "今天" : String(dayLabel(d).suffix(2))
            return prefix + "\n" + dates.string(from: d, format: "MM/dd")
        }
        let dayChips = BranchChipBar(titles: dayTitles, selected: day.flatMap(days.firstIndex(of:)), idPrefix: "reservation.day")
        dayChips.onSelect = { [weak self] index in
            self?.day = days[index]
            self?.slotStart = nil
            self?.refreshBankingData()
        }
        contentStack.addArrangedSubview(dayChips)

        addSectionTitle("预约时段")
        let slots = day.map { BranchSchedule.slots(for: branch, on: $0, dates: dates) } ?? []
        if slots.contains(where: \.isAvailable) {
            let grid = ReservationSlotGridView(slots: slots, selected: slotStart)
            grid.onSelect = { [weak self] start in
                self?.slotStart = start
                self?.refreshBankingData()
            }
            contentStack.addArrangedSubview(grid)
        } else {
            addEmptyState("当天已无可预约时段，请选择其他日期", id: "reservation.noSlot")
        }

        addNotice("预约后请按时段到网点办理，可在“我的记录”中取消")
        let submit = addButton("提交预约", id: "reservation.submit") { [weak self] in self?.submit(branch) }
        submit.isEnabled = slotStart != nil
        submit.alpha = submit.isEnabled ? 1 : 0.4
    }

    private func chooseBranch() {
        let sheet = UIAlertController(title: "选择网点", message: nil, preferredStyle: .actionSheet)
        for branch in branchOptions {
            sheet.addAction(UIAlertAction(title: branch.name, style: .default) { [weak self] _ in
                guard let self, self.branchID != branch.id else { return }
                self.branchID = branch.id
                self.day = nil
                self.slotStart = nil
                self.refreshBankingData()
            })
        }
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        sheet.popoverPresentationController?.sourceView = view
        present(sheet, animated: true)
    }

    private func submit(_ branch: Branch) {
        guard let day, let slotStart else { return }
        do {
            let reservation = try services.reserve(branchID: branch.id, business: business, day: day,
                                                   slotStartMinute: slotStart, quantity: business.requiresQuantity ? quantity : nil)
            navigationController?.pushViewController(
                ReservationResultViewController(reservationID: reservation.id, cities: cities, services: services, dates: dates),
                animated: true
            )
        } catch BranchServiceError.slotUnavailable {
            showToast(BranchServiceError.slotUnavailable.errorDescription!)
            self.slotStart = nil
            refreshBankingData()
        } catch {
            showError(error)
        }
    }
}
