import Foundation

@main struct BranchServiceChecks {
    @MainActor static func main() throws {
        catalog()
        openStates()
        slotsAndDays()
        shanghaiDayBoundary()
        ticketStatusProgression()
        numbersAndCodes()
        reservationStatus()
        print("Branch service checks passed")
    }

    // MARK: - 工具

    static let shanghai = BankingDateContext(now: { Date() })

    static func at(_ text: String) -> Date {
        guard let date = shanghai.date(from: text, format: "yyyy-MM-dd HH:mm") else {
            preconditionFailure("bad date \(text)")
        }
        return date
    }

    static func clock(_ text: String) -> BankingDateContext {
        let date = at(text)
        return BankingDateContext(now: { date })
    }

    static var lunchBranch: Branch {
        BranchCatalog.branches.first { $0.hours == .weekdayWithLunchWeekendClosed }!
    }

    static var selfServiceBranch: Branch {
        BranchCatalog.branches.first { $0.kind == .selfService }!
    }

    // MARK: - 目录

    static func catalog() {
        precondition(BranchCatalog.cities.count == 6, "cities")
        precondition(BranchCatalog.city(id: BranchCatalog.defaultCityID)?.name == "西安市")
        let ids = BranchCatalog.branches.map(\.id)
        precondition(Set(ids).count == ids.count, "branch ids unique")
        for city in BranchCatalog.cities {
            let list = BranchCatalog.branches(inCity: city.id)
            precondition((3...5).contains(list.count), "\(city.name) has \(list.count)")
            precondition(list.map(\.distanceMeters) == list.map(\.distanceMeters).sorted(), "sorted by distance")
            precondition(list.contains { $0.hours == .weekdayWithLunchWeekendClosed }, "\(city.name) lunch template")
        }
        for branch in BranchCatalog.branches {
            precondition(BranchCatalog.city(id: branch.cityID) != nil, "city of \(branch.id)")
            precondition((0...1).contains(branch.mapX) && (0...1).contains(branch.mapY), "map pos \(branch.id)")
            switch branch.kind {
            case .full:
                precondition(branch.businesses.contains { $0.allowsTicket }, "ticket business \(branch.id)")
            case .selfService:
                precondition(branch.businesses.isEmpty && branch.hours.isAllDay, "self service \(branch.id)")
            }
        }
        let selfServiceCount = BranchCatalog.branches.filter { $0.kind == .selfService }.count
        precondition((2...3).contains(selfServiceCount), "self service count \(selfServiceCount)")
        let xian = BranchCatalog.defaultBranch(inCity: "xian")
        precondition(xian.name == "西安沣东新城支行" && xian.distanceMeters == 2552)
        precondition(xian.address == "陕西省西安市沣东新城大明宫·沣东一路88号")
        precondition(BranchCatalog.displayName(branchID: "none") == "网点已停用")
        precondition(BranchCatalog.displayName(branchID: xian.id) == xian.name)

        precondition(BranchBusiness.ticketBusinesses == [.personalCash, .personalNonCash, .corporate])
        precondition(BranchBusiness.reservationBusinesses == [.personalNonCash, .openCard, .sameNumberReplace, .commemorativeCoin])
        precondition(BranchBusiness.personalCash.queuePrefix == "A" && BranchBusiness.corporate.queuePrefix == "C")
        precondition(BranchBusiness.openCard.queuePrefix == nil)
        precondition(BranchBusiness.commemorativeCoin.requiresQuantity && !BranchBusiness.openCard.requiresQuantity)
        precondition(BranchBusiness.commemorativeCoin.title == "纪念币兑换")
    }

    // MARK: - 营业状态

    static func openStates() {
        let branch = lunchBranch
        let dates = shanghai
        precondition(BranchSchedule.openState(of: branch, at: at("2026-11-06 10:00"), dates: dates) == .open)
        precondition(BranchSchedule.openState(of: branch, at: at("2026-11-06 12:30"), dates: dates) == .lunchBreak)
        precondition(BranchSchedule.openState(of: branch, at: at("2026-11-06 08:59"), dates: dates)
                     == .closed(nextOpen: at("2026-11-06 09:00")))
        precondition(BranchSchedule.openState(of: branch, at: at("2026-11-06 17:30"), dates: dates)
                     == .closed(nextOpen: at("2026-11-09 09:00")), "next open across weekend")
        precondition(BranchSchedule.openState(of: branch, at: at("2026-11-07 10:00"), dates: dates)
                     == .closed(nextOpen: at("2026-11-09 09:00")))
        precondition(BranchSchedule.openState(of: selfServiceBranch, at: at("2026-11-07 03:00"), dates: dates) == .selfService)
        precondition(BranchOpenState.open.allowsTicket && !BranchOpenState.lunchBreak.allowsTicket)
        precondition(BranchOpenState.lunchBreak.title == "午休中" && BranchOpenState.selfService.title == "自助 24 小时")
    }

    // MARK: - 可约日期与时段

    static func slotsAndDays() {
        let branch = lunchBranch
        let dates = clock("2026-11-06 10:20")
        let days = BranchSchedule.reservableDays(for: branch, dates: dates)
        let labels = days.map { dates.string(from: $0) }
        precondition(labels == ["2026-11-06", "2026-11-09", "2026-11-10", "2026-11-11", "2026-11-12"], "\(labels)")
        precondition(days.first == at("2026-11-06 00:00"))

        let today = BranchSchedule.slots(for: branch, on: days[0], dates: dates)
        let starts = today.map(\.startMinute)
        precondition(starts == [540, 600, 660, 840, 900, 960], "lunch slots removed: \(starts)")
        precondition(!today[0].isAvailable && !today[1].isAvailable, "past slots disabled")
        precondition(today[0].label == "09:00-10:00")
        precondition(today == BranchSchedule.slots(for: branch, on: days[0], dates: dates), "deterministic")
        precondition(BranchSchedule.slots(for: branch, on: at("2026-11-07 00:00"), dates: dates).isEmpty, "closed day")

        let early = clock("2026-11-01 00:01")
        var total = 0, full = 0
        for candidate in BranchCatalog.branches where candidate.kind == .full {
            for day in BranchSchedule.reservableDays(for: candidate, dates: early) {
                let slots = BranchSchedule.slots(for: candidate, on: day, dates: early)
                total += slots.count
                full += slots.filter { !$0.isAvailable }.count
            }
        }
        let ratio = Double(full) / Double(total)
        precondition((0.05...0.4).contains(ratio), "full ratio \(ratio)")
    }

    static func shanghaiDayBoundary() {
        let utc = ISO8601DateFormatter().date(from: "2026-11-05T23:30:00Z")!
        let dates = BankingDateContext(now: { utc })
        let days = BranchSchedule.reservableDays(for: lunchBranch, dates: dates)
        precondition(days.first == at("2026-11-06 00:00"), "shanghai day")
    }

    // MARK: - 排队状态

    static func ticket(ahead: Int, at text: String, cancelled: Date? = nil) -> QueueTicket {
        QueueTicket(id: "t", branchID: lunchBranch.id, business: .personalCash, number: "A001",
                    takenAt: at(text), aheadAtTaking: ahead, cancelledAt: cancelled)
    }

    static func ticketStatusProgression() {
        let dates = shanghai
        let t = ticket(ahead: 5, at: "2026-11-06 10:00")
        func status(_ text: String) -> QueueTicketStatus { BranchSchedule.status(of: t, at: at(text), dates: dates) }
        precondition(status("2026-11-06 10:00") == .waiting(ahead: 5))
        precondition(status("2026-11-06 10:09") == .almostCalled(ahead: 2))
        precondition(status("2026-11-06 10:15") == .called)
        precondition(status("2026-11-06 10:29") == .called)
        precondition(status("2026-11-06 10:30") == .completed)
        precondition(status("2026-11-06 10:00").isActive && !status("2026-11-06 10:30").isActive)

        let cancelled = ticket(ahead: 5, at: "2026-11-06 10:00", cancelled: at("2026-11-06 10:01"))
        precondition(BranchSchedule.status(of: cancelled, at: at("2026-11-06 10:02"), dates: dates) == .cancelled)

        let late = ticket(ahead: 9, at: "2026-11-06 23:50")
        precondition(BranchSchedule.status(of: late, at: at("2026-11-06 23:59"), dates: dates).isActive)
        precondition(BranchSchedule.status(of: late, at: at("2026-11-07 00:00"), dates: dates) == .expired)
        precondition(QueueTicketStatus.almostCalled(ahead: 1).title == "即将叫号")
    }

    static func numbersAndCodes() {
        let dates = shanghai
        let branch = lunchBranch
        let time = at("2026-11-06 10:00")
        let ahead = BranchSchedule.queueAhead(branchID: branch.id, business: .personalCash, at: time, dates: dates)
        precondition((2...9).contains(ahead))
        precondition(ahead == BranchSchedule.queueAhead(branchID: branch.id, business: .personalCash, at: time, dates: dates))
        for business in BranchBusiness.ticketBusinesses {
            let number = BranchSchedule.ticketNumber(branch: branch, business: business, at: time, ahead: 4, dates: dates)
            precondition(number.range(of: "^[ABC]\\d{3}$", options: .regularExpression) != nil, number)
            precondition(number.hasPrefix(business.queuePrefix!))
        }
        // 开门 9:00，10:00 取号：60 / 3 + 4 + 1 = 25
        precondition(BranchSchedule.ticketNumber(branch: branch, business: .personalCash, at: time, ahead: 4, dates: dates) == "A025")
        let code = BranchSchedule.reservationCode(seed: "abc")
        precondition(code.count == 8 && code.allSatisfy(\.isNumber) && code == BranchSchedule.reservationCode(seed: "abc"))
        precondition(BranchSchedule.reservationCode(seed: "abd") != code)
        precondition(BranchSchedule.stableHash("a", "b") == BranchSchedule.stableHash("a", "b"))
    }

    static func reservationStatus() {
        let dates = shanghai
        var r = BranchReservation(id: "r", branchID: lunchBranch.id, business: .openCard,
                                  date: at("2026-11-06 00:00"), slotStartMinute: 600, quantity: nil,
                                  code: "12345678", createdAt: at("2026-11-06 08:00"), cancelledAt: nil)
        precondition(BranchSchedule.status(of: r, at: at("2026-11-06 10:59"), dates: dates) == .pending)
        precondition(BranchSchedule.status(of: r, at: at("2026-11-06 11:00"), dates: dates) == .expired)
        r.cancelledAt = at("2026-11-06 09:00")
        precondition(BranchSchedule.status(of: r, at: at("2026-11-06 09:30"), dates: dates) == .cancelled)
        precondition(ReservationStatus.pending.title == "待办理")
    }
}
