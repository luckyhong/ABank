//
//  BranchSchedule.swift
//  ABank
//
//  营业状态、可约日期与时段、排队推算。全部为纯函数，时间来自注入的 BankingDateContext
//  （Asia/Shanghai）。确定性模拟使用 FNV-1a，避免 Swift hashValue 的启动随机化。
//

import Foundation

nonisolated enum BranchSchedule {
    static let minutesPerPerson = 3
    static let calledDurationMinutes = 15
    static let reservableDayCount = 7

    // MARK: - 稳定哈希

    static func stableHash(_ parts: String...) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in parts.joined(separator: "|").utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return hash
    }

    // MARK: - 时间工具

    private static func minuteOfDay(_ date: Date, dates: BankingDateContext) -> Int {
        let parts = dates.calendar.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    private static func weekday(_ date: Date, dates: BankingDateContext) -> Int {
        dates.calendar.component(.weekday, from: date)
    }

    private static func startOfDay(_ date: Date, dates: BankingDateContext) -> Date {
        dates.calendar.startOfDay(for: date)
    }

    private static func date(_ day: Date, addingMinutes minutes: Int, dates: BankingDateContext) -> Date {
        dates.calendar.date(byAdding: .minute, value: minutes, to: day)!
    }

    // MARK: - 营业状态

    static func openState(of branch: Branch, at time: Date, dates: BankingDateContext) -> BranchOpenState {
        if branch.hours.isAllDay { return .selfService }
        let minute = minuteOfDay(time, dates: dates)
        let today = startOfDay(time, dates: dates)
        if let hours = branch.hours.hours(onWeekday: weekday(time, dates: dates)) {
            if minute >= hours.open && minute < hours.close {
                return hours.isLunch(minute: minute) ? .lunchBreak : .open
            }
            if minute < hours.open {
                return .closed(nextOpen: date(today, addingMinutes: hours.open, dates: dates))
            }
        }
        for offset in 1...7 {
            let day = dates.calendar.date(byAdding: .day, value: offset, to: today)!
            if let hours = branch.hours.hours(onWeekday: weekday(day, dates: dates)) {
                return .closed(nextOpen: date(day, addingMinutes: hours.open, dates: dates))
            }
        }
        return .closed(nextOpen: nil)
    }

    // MARK: - 预约

    /// 今天起 7 个自然日中该网点营业的日子（上海时区 0 点）。自助网点不可预约。
    static func reservableDays(for branch: Branch, dates: BankingDateContext) -> [Date] {
        guard branch.kind == .full else { return [] }
        let today = startOfDay(dates.now, dates: dates)
        return (0..<reservableDayCount)
            .map { dates.calendar.date(byAdding: .day, value: $0, to: today)! }
            .filter { branch.hours.hours(onWeekday: weekday($0, dates: dates)) != nil }
    }

    /// 每小时一档：开门整点（向上取整）到关门前，排除与午休有交集的时段。
    static func slots(for branch: Branch, on day: Date, dates: BankingDateContext) -> [ReservationSlot] {
        guard branch.kind == .full,
              let hours = branch.hours.hours(onWeekday: weekday(day, dates: dates)) else { return [] }
        let dayStart = startOfDay(day, dates: dates)
        let dayText = dates.string(from: dayStart)
        var result: [ReservationSlot] = []
        var start = (hours.open + 59) / 60 * 60
        while start + 60 <= hours.close {
            let overlapsLunch: Bool = {
                guard let lunchStart = hours.lunchStart, let lunchEnd = hours.lunchEnd else { return false }
                return start < lunchEnd && start + 60 > lunchStart
            }()
            if !overlapsLunch {
                let begins = date(dayStart, addingMinutes: start, dates: dates)
                let isFull = stableHash(branch.id, dayText, String(start)) % 5 == 0
                result.append(ReservationSlot(startMinute: start, isAvailable: begins > dates.now && !isFull))
            }
            start += 60
        }
        return result
    }

    static func reservationCode(seed: String) -> String {
        String(format: "%08llu", stableHash("reservation", seed) % 100_000_000)
    }

    static func status(of reservation: BranchReservation, at time: Date, dates: BankingDateContext) -> ReservationStatus {
        if reservation.cancelledAt != nil { return .cancelled }
        let end = date(startOfDay(reservation.date, dates: dates),
                       addingMinutes: reservation.slotStartMinute + 60, dates: dates)
        return time >= end ? .expired : .pending
    }

    // MARK: - 排队

    /// 取号前方人数（2–9），按网点、业务、取号分钟确定。
    static func queueAhead(branchID: String, business: BranchBusiness, at time: Date, dates: BankingDateContext) -> Int {
        2 + Int(stableHash(branchID, business.rawValue, dates.string(from: time, format: "yyyy-MM-dd HH:mm")) % 8)
    }

    /// 号码数字 = 开门后已过分钟数 ÷ 3 + 前方人数 + 1，三位补零。
    static func ticketNumber(branch: Branch, business: BranchBusiness, at time: Date, ahead: Int,
                             dates: BankingDateContext) -> String {
        let open = branch.hours.hours(onWeekday: weekday(time, dates: dates))?.open ?? 0
        let issued = max(0, minuteOfDay(time, dates: dates) - open) / minutesPerPerson
        let value = min(999, issued + ahead + 1)
        return (business.queuePrefix ?? "") + String(format: "%03d", value)
    }

    static func status(of ticket: QueueTicket, at time: Date, dates: BankingDateContext) -> QueueTicketStatus {
        if ticket.cancelledAt != nil { return .cancelled }
        let elapsed = max(0, Int(time.timeIntervalSince(ticket.takenAt)) / 60)
        let calledAt = ticket.aheadAtTaking * minutesPerPerson
        let progress: QueueTicketStatus
        if elapsed >= calledAt + calledDurationMinutes {
            return .completed
        } else if elapsed >= calledAt {
            progress = .called
        } else {
            let remaining = ticket.aheadAtTaking - elapsed / minutesPerPerson
            progress = remaining >= 3 ? .waiting(ahead: remaining) : .almostCalled(ahead: remaining)
        }
        let nextDay = dates.calendar.date(byAdding: .day, value: 1, to: startOfDay(ticket.takenAt, dates: dates))!
        return time >= nextDay ? .expired : progress
    }
}
