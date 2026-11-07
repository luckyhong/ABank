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
        cityStore()
        try takeTicketRules()
        try reserveRules()
        reserveRevalidatesAtSubmit()
        try cancelTwice()
        try persistence()
        try corruptRecordsKeepOriginal()
        unknownBranchName()
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

    // MARK: - Store 工具

    struct WriteFailure: Error {}

    final class Clock {
        var now: Date
        init(_ now: Date) { self.now = now }
        var context: BankingDateContext { BankingDateContext(now: { [unowned self] in self.now }) }
    }

    @MainActor static func withSuite(_ body: (UserDefaults) throws -> Void) rethrows {
        let suite = "ABank.BranchChecks." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        try body(defaults)
    }

    static func expect(_ expected: BranchServiceError, _ label: String, _ body: () throws -> Void) {
        do {
            try body()
            preconditionFailure("\(label): expected \(expected), got success")
        } catch let error as BranchServiceError {
            precondition(error == expected, "\(label): expected \(expected), got \(error)")
        } catch {
            preconditionFailure("\(label): unexpected \(error)")
        }
    }

    @MainActor static func counting(_ center: NotificationCenter, _ name: Notification.Name, _ body: () throws -> Void) rethrows -> Int {
        var count = 0
        let token = center.addObserver(forName: name, object: nil, queue: nil) { _ in count += 1 }
        defer { center.removeObserver(token) }
        try body()
        return count
    }

    static var fullBranch: Branch { BranchCatalog.branch(id: "xa-fengdong")! }

    /// 首个可约日期中的首个可用时段。
    static func firstAvailableSlot(_ branch: Branch, dates: BankingDateContext) -> (Date, Int) {
        for day in BranchSchedule.reservableDays(for: branch, dates: dates) {
            if let slot = BranchSchedule.slots(for: branch, on: day, dates: dates).first(where: \.isAvailable) {
                return (day, slot.startMinute)
            }
        }
        preconditionFailure("no slot")
    }

    // MARK: - CitySelectionStore

    @MainActor static func cityStore() {
        precondition(CitySelectionStore.storageKey == "abank.selectedCity.v1")
        withSuite { defaults in
            let center = NotificationCenter()
            let store = CitySelectionStore(defaults: defaults, notificationCenter: center)
            precondition(store.currentCity.id == "xian")
            let posts = counting(center, CitySelectionStore.didChangeNotification) {
                precondition(store.select(cityID: "beijing"))
                precondition(store.select(cityID: "beijing"))
                precondition(!store.select(cityID: "mars"))
            }
            precondition(posts == 1, "city posts \(posts)")
            precondition(store.currentCity.id == "beijing")
            precondition(CitySelectionStore(defaults: defaults).currentCity.id == "beijing")
            defaults.set(Data("garbage".utf8), forKey: CitySelectionStore.storageKey)
            precondition(CitySelectionStore(defaults: defaults).currentCity.id == "xian")
        }
        withSuite { defaults in
            let center = NotificationCenter()
            let store = CitySelectionStore(defaults: defaults, notificationCenter: center,
                                           dataWriter: { _ in throw WriteFailure() })
            let posts = counting(center, CitySelectionStore.didChangeNotification) {
                precondition(!store.select(cityID: "shanghai"))
            }
            precondition(posts == 0 && store.currentCity.id == "xian")
        }
    }

    // MARK: - 取号

    @MainActor static func takeTicketRules() throws {
        try withSuite { defaults in
            let clock = Clock(at("2026-11-06 10:00"))
            let store = BranchServiceStore(defaults: defaults, dates: clock.context)
            let ticket = try store.takeTicket(branchID: fullBranch.id, business: .personalCash)
            precondition(ticket.number.hasPrefix("A") && ticket.takenAt == clock.now)
            precondition(store.activeTicket == ticket && store.tickets == [ticket])
            precondition(store.status(of: ticket).isActive)
            expect(.activeTicketExists, "second ticket") { _ = try store.takeTicket(branchID: lunchBranch.id, business: .personalCash) }
            try store.cancelTicket(id: ticket.id)
            precondition(store.activeTicket == nil && store.status(of: store.tickets[0]) == .cancelled)

            clock.now = at("2026-11-06 12:30")
            expect(.branchNotOpen, "lunch") { _ = try store.takeTicket(branchID: lunchBranch.id, business: .personalCash) }
            expect(.businessNotSupported, "self service") { _ = try store.takeTicket(branchID: selfServiceBranch.id, business: .personalCash) }
            expect(.businessNotSupported, "open card ticket") { _ = try store.takeTicket(branchID: fullBranch.id, business: .openCard) }
            expect(.businessNotSupported, "unknown branch") { _ = try store.takeTicket(branchID: "gone", business: .personalCash) }
            clock.now = at("2026-11-06 10:01")
            let again = try store.takeTicket(branchID: fullBranch.id, business: .corporate)
            precondition(again.number.hasPrefix("C") && store.tickets.first == again && store.tickets.count == 2)
            precondition(store.queueAhead(branchID: fullBranch.id, business: .corporate) == again.aheadAtTaking)
        }
    }

    // MARK: - 预约

    @MainActor static func reserveRules() throws {
        try withSuite { defaults in
            let clock = Clock(at("2026-11-06 10:20"))
            let store = BranchServiceStore(defaults: defaults, dates: clock.context)
            let (day, start) = firstAvailableSlot(fullBranch, dates: clock.context)
            let r = try store.reserve(branchID: fullBranch.id, business: .openCard, day: day, slotStartMinute: start, quantity: 3)
            precondition(r.code.count == 8 && r.quantity == nil && store.reservations == [r])
            precondition(store.status(of: r) == .pending)
            expect(.duplicateReservation, "dup") {
                _ = try store.reserve(branchID: fullBranch.id, business: .openCard, day: day, slotStartMinute: start, quantity: nil)
            }
            _ = try store.reserve(branchID: fullBranch.id, business: .sameNumberReplace, day: day, slotStartMinute: start, quantity: nil)
            for bad in [0, 21, nil] as [Int?] {
                expect(.invalidQuantity, "coin \(String(describing: bad))") {
                    _ = try store.reserve(branchID: fullBranch.id, business: .commemorativeCoin, day: day, slotStartMinute: start, quantity: bad)
                }
            }
            let coin = try store.reserve(branchID: fullBranch.id, business: .commemorativeCoin, day: day, slotStartMinute: start, quantity: 20)
            precondition(coin.quantity == 20)
            expect(.businessNotSupported, "cash reservation") {
                _ = try store.reserve(branchID: fullBranch.id, business: .personalCash, day: day, slotStartMinute: start, quantity: nil)
            }
            expect(.businessNotSupported, "coin at no-coin branch") {
                _ = try store.reserve(branchID: lunchBranch.id, business: .commemorativeCoin, day: day, slotStartMinute: start, quantity: 1)
            }
            let today = at("2026-11-06 00:00")
            expect(.slotUnavailable, "past slot") {
                _ = try store.reserve(branchID: fullBranch.id, business: .personalNonCash, day: today, slotStartMinute: 540, quantity: nil)
            }
            expect(.slotUnavailable, "not a slot") {
                _ = try store.reserve(branchID: fullBranch.id, business: .personalNonCash, day: day, slotStartMinute: start + 30, quantity: nil)
            }
            expect(.slotUnavailable, "closed day") {
                _ = try store.reserve(branchID: lunchBranch.id, business: .personalNonCash, day: at("2026-11-07 00:00"), slotStartMinute: 600, quantity: nil)
            }
            expect(.slotUnavailable, "beyond 7 days") {
                _ = try store.reserve(branchID: fullBranch.id, business: .personalNonCash, day: at("2026-11-20 00:00"), slotStartMinute: 600, quantity: nil)
            }
            let fullSlot = BranchSchedule.reservableDays(for: fullBranch, dates: clock.context).lazy.compactMap { d in
                BranchSchedule.slots(for: fullBranch, on: d, dates: clock.context)
                    .first { !$0.isAvailable && d > today }.map { (d, $0.startMinute) }
            }.first!
            expect(.slotUnavailable, "full slot") {
                _ = try store.reserve(branchID: fullBranch.id, business: .personalNonCash, day: fullSlot.0, slotStartMinute: fullSlot.1, quantity: nil)
            }
            try store.cancelReservation(id: r.id)
            precondition(store.status(of: store.reservation(id: r.id)!) == .cancelled)
            _ = try store.reserve(branchID: fullBranch.id, business: .openCard, day: day, slotStartMinute: start, quantity: nil)
            precondition(store.reservations.count == 4)
        }
    }

    @MainActor static func reserveRevalidatesAtSubmit() {
        withSuite { defaults in
            let clock = Clock(at("2026-11-06 09:58"))
            let store = BranchServiceStore(defaults: defaults, dates: clock.context)
            let today = at("2026-11-06 00:00")
            let slot = BranchSchedule.slots(for: fullBranch, on: today, dates: clock.context).first { $0.startMinute == 600 }!
            precondition(slot.isAvailable, "10:00 slot must be open at 09:58")
            clock.now = at("2026-11-06 10:01")
            expect(.slotUnavailable, "revalidate") {
                _ = try store.reserve(branchID: fullBranch.id, business: .personalNonCash, day: today, slotStartMinute: 600, quantity: nil)
            }
        }
    }

    // MARK: - 取消

    @MainActor static func cancelTwice() throws {
        try withSuite { defaults in
            let center = NotificationCenter()
            let clock = Clock(at("2026-11-06 10:00"))
            let store = BranchServiceStore(defaults: defaults, notificationCenter: center, dates: clock.context)
            let first = try store.takeTicket(branchID: fullBranch.id, business: .personalCash)
            try store.cancelTicket(id: first.id)
            let second = try store.takeTicket(branchID: fullBranch.id, business: .personalNonCash)
            let (day, start) = firstAvailableSlot(fullBranch, dates: clock.context)
            let r = try store.reserve(branchID: fullBranch.id, business: .openCard, day: day, slotStartMinute: start, quantity: nil)
            clock.now = clock.now.addingTimeInterval(3 * 86_400)
            let posts = counting(center, BranchServiceStore.didChangeNotification) {
                expect(.notCancellable, "cancel twice") { try store.cancelTicket(id: first.id) }
                expect(.notCancellable, "completed ticket") { try store.cancelTicket(id: second.id) }
                expect(.notCancellable, "expired reservation") { try store.cancelReservation(id: r.id) }
                expect(.notCancellable, "missing ticket") { try store.cancelTicket(id: "none") }
                expect(.notCancellable, "missing reservation") { try store.cancelReservation(id: "none") }
            }
            precondition(posts == 0, "cancel posts \(posts)")
        }
    }

    // MARK: - 持久化

    @MainActor static func persistence() throws {
        try withSuite { defaults in
            precondition(BranchServiceStore.storageKey == "abank.branchServices.v1")
            let center = NotificationCenter()
            let clock = Clock(at("2026-11-06 10:00"))
            let store = BranchServiceStore(defaults: defaults, notificationCenter: center, dates: clock.context)
            let posts = try counting(center, BranchServiceStore.didChangeNotification) {
                _ = try store.takeTicket(branchID: fullBranch.id, business: .personalCash)
                let (day, start) = firstAvailableSlot(fullBranch, dates: clock.context)
                _ = try store.reserve(branchID: fullBranch.id, business: .commemorativeCoin, day: day, slotStartMinute: start, quantity: 5)
            }
            precondition(posts == 2)
            let reloaded = BranchServiceStore(defaults: defaults, dates: clock.context)
            precondition(reloaded.tickets == store.tickets && reloaded.reservations == store.reservations)
        }
        withSuite { defaults in
            let center = NotificationCenter()
            let clock = Clock(at("2026-11-06 10:00"))
            let store = BranchServiceStore(defaults: defaults, notificationCenter: center, dates: clock.context,
                                           dataWriter: { _ in throw WriteFailure() })
            let posts = counting(center, BranchServiceStore.didChangeNotification) {
                expect(.saveFailed, "write failure") { _ = try store.takeTicket(branchID: fullBranch.id, business: .personalCash) }
            }
            precondition(posts == 0 && store.tickets.isEmpty && store.activeTicket == nil)
        }
    }

    @MainActor static func corruptRecordsKeepOriginal() throws {
        try withSuite { defaults in
            let original = Data(#"{"tickets":[{"id":1}],"reservations":[]}"#.utf8)
            defaults.set(original, forKey: BranchServiceStore.storageKey)
            let clock = Clock(at("2026-11-06 10:00"))
            let store = BranchServiceStore(defaults: defaults, dates: clock.context)
            precondition(store.tickets.isEmpty && store.reservations.isEmpty)
            precondition(defaults.data(forKey: BranchServiceStore.storageKey) == original)
            _ = try store.takeTicket(branchID: fullBranch.id, business: .personalCash)
            precondition(defaults.data(forKey: BranchServiceStore.storageKey) != original)
            precondition(BranchServiceStore(defaults: defaults, dates: clock.context).tickets.count == 1)
        }
    }

    @MainActor static func unknownBranchName() {
        withSuite { defaults in
            let ticket = QueueTicket(id: "old", branchID: "gone", business: .personalCash, number: "A001",
                                     takenAt: at("2026-11-01 10:00"), aheadAtTaking: 3, cancelledAt: nil)
            let data = try! JSONEncoder().encode(BranchServiceRecords(tickets: [ticket], reservations: []))
            defaults.set(data, forKey: BranchServiceStore.storageKey)
            let store = BranchServiceStore(defaults: defaults, dates: clock("2026-11-06 10:00"))
            precondition(store.tickets == [ticket] && store.activeTicket == nil)
            precondition(BranchCatalog.displayName(branchID: store.tickets[0].branchID) == "网点已停用")
        }
    }
}
