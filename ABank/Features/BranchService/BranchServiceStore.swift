//
//  BranchServiceStore.swift
//  ABank
//
//  取号与预约记录的本地持久化。每次修改前按当前时间重新校验规则；只有写入成功才更新内存
//  并发通知。数据无法解码时视为空，原数据保留到下一次成功保存。状态均在读取时推算。
//

import Foundation

nonisolated struct BranchServiceRecords: Codable, Equatable {
    var tickets: [QueueTicket]
    var reservations: [BranchReservation]

    static let empty = BranchServiceRecords(tickets: [], reservations: [])
}

final class BranchServiceStore {
    static let shared = BranchServiceStore()
    static let storageKey = "abank.branchServices.v1"
    static let didChangeNotification = Notification.Name("ABank.branchServicesDidChange")

    private let defaults: UserDefaults
    private let notificationCenter: NotificationCenter
    private let dates: BankingDateContext
    private let dataWriter: ((Data) throws -> Void)?
    private var records: BranchServiceRecords

    init(defaults: UserDefaults = .standard,
         notificationCenter: NotificationCenter = .default,
         dates: BankingDateContext = .system,
         dataWriter: ((Data) throws -> Void)? = nil) {
        self.defaults = defaults
        self.notificationCenter = notificationCenter
        self.dates = dates
        self.dataWriter = dataWriter
        if let data = defaults.data(forKey: Self.storageKey),
           let stored = try? JSONDecoder().decode(BranchServiceRecords.self, from: data) {
            records = stored
        } else {
            records = .empty
        }
    }

    // MARK: - 读取

    var tickets: [QueueTicket] { records.tickets.sorted { $0.takenAt > $1.takenAt } }
    var reservations: [BranchReservation] { records.reservations.sorted { $0.createdAt > $1.createdAt } }
    var activeTicket: QueueTicket? { tickets.first { status(of: $0).isActive } }

    func ticket(id: String) -> QueueTicket? { records.tickets.first { $0.id == id } }
    func reservation(id: String) -> BranchReservation? { records.reservations.first { $0.id == id } }

    func status(of ticket: QueueTicket) -> QueueTicketStatus {
        BranchSchedule.status(of: ticket, at: dates.now, dates: dates)
    }

    func status(of reservation: BranchReservation) -> ReservationStatus {
        BranchSchedule.status(of: reservation, at: dates.now, dates: dates)
    }

    func queueAhead(branchID: String, business: BranchBusiness) -> Int {
        BranchSchedule.queueAhead(branchID: branchID, business: business, at: dates.now, dates: dates)
    }

    // MARK: - 取号

    @discardableResult
    func takeTicket(branchID: String, business: BranchBusiness) throws -> QueueTicket {
        let now = dates.now
        guard let branch = BranchCatalog.branch(id: branchID), business.allowsTicket,
              branch.businesses.contains(business) else { throw BranchServiceError.businessNotSupported }
        guard activeTicket == nil else { throw BranchServiceError.activeTicketExists }
        guard BranchSchedule.openState(of: branch, at: now, dates: dates).allowsTicket else {
            throw BranchServiceError.branchNotOpen
        }
        let ahead = BranchSchedule.queueAhead(branchID: branchID, business: business, at: now, dates: dates)
        let ticket = QueueTicket(
            id: UUID().uuidString, branchID: branchID, business: business,
            number: BranchSchedule.ticketNumber(branch: branch, business: business, at: now, ahead: ahead, dates: dates),
            takenAt: now, aheadAtTaking: ahead, cancelledAt: nil
        )
        var updated = records
        updated.tickets.append(ticket)
        try commit(updated)
        return ticket
    }

    func cancelTicket(id: String) throws {
        guard let index = records.tickets.firstIndex(where: { $0.id == id }),
              status(of: records.tickets[index]).isActive else { throw BranchServiceError.notCancellable }
        var updated = records
        updated.tickets[index].cancelledAt = dates.now
        try commit(updated)
    }

    // MARK: - 预约

    @discardableResult
    func reserve(branchID: String, business: BranchBusiness, day: Date,
                 slotStartMinute: Int, quantity: Int?) throws -> BranchReservation {
        guard let branch = BranchCatalog.branch(id: branchID), business.allowsReservation,
              branch.businesses.contains(business) else { throw BranchServiceError.businessNotSupported }
        if business.requiresQuantity {
            guard let quantity, BranchBusiness.coinQuantityRange.contains(quantity) else {
                throw BranchServiceError.invalidQuantity
            }
        }
        guard !reservations.contains(where: { $0.business == business && status(of: $0) == .pending }) else {
            throw BranchServiceError.duplicateReservation
        }
        let dayStart = dates.calendar.startOfDay(for: day)
        guard BranchSchedule.reservableDays(for: branch, dates: dates).contains(dayStart),
              BranchSchedule.slots(for: branch, on: dayStart, dates: dates)
                .contains(where: { $0.startMinute == slotStartMinute && $0.isAvailable }) else {
            throw BranchServiceError.slotUnavailable
        }
        let id = UUID().uuidString
        let reservation = BranchReservation(
            id: id, branchID: branchID, business: business, date: dayStart, slotStartMinute: slotStartMinute,
            quantity: business.requiresQuantity ? quantity : nil,
            code: BranchSchedule.reservationCode(seed: id), createdAt: dates.now, cancelledAt: nil
        )
        var updated = records
        updated.reservations.append(reservation)
        try commit(updated)
        return reservation
    }

    func cancelReservation(id: String) throws {
        guard let index = records.reservations.firstIndex(where: { $0.id == id }),
              status(of: records.reservations[index]) == .pending else { throw BranchServiceError.notCancellable }
        var updated = records
        updated.reservations[index].cancelledAt = dates.now
        try commit(updated)
    }

    // MARK: - 持久化

    private func commit(_ updated: BranchServiceRecords) throws {
        do {
            let data = try JSONEncoder().encode(updated)
            if let dataWriter {
                try dataWriter(data)
            } else {
                defaults.set(data, forKey: Self.storageKey)
            }
        } catch {
            throw BranchServiceError.saveFailed
        }
        records = updated
        notificationCenter.post(name: Self.didChangeNotification, object: self)
    }
}
