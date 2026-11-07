//
//  BranchModels.swift
//  ABank
//
//  网点服务模型：城市、网点、营业时间、业务、取号与预约记录。仅依赖 Foundation，
//  便于数据检查脚本在 macOS 上编译。
//

import Foundation

nonisolated struct BranchCity: Equatable, Hashable {
    let id: String
    let name: String
}

nonisolated enum BranchBusiness: String, Codable, CaseIterable {
    case personalCash, personalNonCash, corporate, openCard, sameNumberReplace, commemorativeCoin

    static let ticketBusinesses: [BranchBusiness] = [.personalCash, .personalNonCash, .corporate]
    static let reservationBusinesses: [BranchBusiness] = [.personalNonCash, .openCard, .sameNumberReplace, .commemorativeCoin]
    static let coinQuantityRange = 1...20

    var title: String {
        switch self {
        case .personalCash: return "个人现金"
        case .personalNonCash: return "个人非现金"
        case .corporate: return "对公业务"
        case .openCard: return "我要开卡"
        case .sameNumberReplace: return "同号换卡"
        case .commemorativeCoin: return "纪念币兑换"
        }
    }

    var queuePrefix: String? {
        switch self {
        case .personalCash: return "A"
        case .personalNonCash: return "B"
        case .corporate: return "C"
        case .openCard, .sameNumberReplace, .commemorativeCoin: return nil
        }
    }

    var allowsTicket: Bool { Self.ticketBusinesses.contains(self) }
    var allowsReservation: Bool { Self.reservationBusinesses.contains(self) }
    var requiresQuantity: Bool { self == .commemorativeCoin }
}

/// 某天的营业时间，单位为自 0 点起的分钟数。
nonisolated struct DayHours: Equatable {
    let open: Int
    let close: Int
    let lunchStart: Int?
    let lunchEnd: Int?

    init(open: Int, close: Int, lunchStart: Int? = nil, lunchEnd: Int? = nil) {
        self.open = open
        self.close = close
        self.lunchStart = lunchStart
        self.lunchEnd = lunchEnd
    }

    func isLunch(minute: Int) -> Bool {
        guard let lunchStart, let lunchEnd else { return false }
        return minute >= lunchStart && minute < lunchEnd
    }
}

/// 按星期的营业时间。key 为 `Calendar` 的 weekday：1 = 周日 … 7 = 周六。
nonisolated struct BusinessHours: Equatable {
    let byWeekday: [Int: DayHours]
    let isAllDay: Bool

    func hours(onWeekday weekday: Int) -> DayHours? { byWeekday[weekday] }

    private static func days(_ weekdays: ClosedRange<Int>, _ hours: DayHours) -> [Int: DayHours] {
        Dictionary(uniqueKeysWithValues: weekdays.map { ($0, hours) })
    }

    /// 工作日 9:00–17:00，周末 9:30–16:00。
    static let weekdayAndWeekend = BusinessHours(
        byWeekday: days(2...6, DayHours(open: 540, close: 1020))
            .merging([1: DayHours(open: 570, close: 960), 7: DayHours(open: 570, close: 960)]) { $1 },
        isAllDay: false
    )

    /// 工作日 9:00–17:00，午休 12:00–13:30，周末休息。
    static let weekdayWithLunchWeekendClosed = BusinessHours(
        byWeekday: days(2...6, DayHours(open: 540, close: 1020, lunchStart: 720, lunchEnd: 810)),
        isAllDay: false
    )

    /// 每天 9:00–17:30。
    static let everyDayLong = BusinessHours(byWeekday: days(1...7, DayHours(open: 540, close: 1050)), isAllDay: false)

    /// 24 小时自助。
    static let allDaySelfService = BusinessHours(byWeekday: days(1...7, DayHours(open: 0, close: 1440)), isAllDay: true)
}

nonisolated enum BranchKind: Equatable {
    case full, selfService
}

nonisolated struct Branch: Equatable {
    let id: String
    let cityID: String
    let name: String
    let address: String
    let phone: String
    let distanceMeters: Int
    let kind: BranchKind
    let hours: BusinessHours
    let businesses: Set<BranchBusiness>
    let mapX: Double
    let mapY: Double

    var ticketBusinesses: [BranchBusiness] { BranchBusiness.ticketBusinesses.filter(businesses.contains) }
    var reservationBusinesses: [BranchBusiness] { BranchBusiness.reservationBusinesses.filter(businesses.contains) }
}

nonisolated enum BranchOpenState: Equatable {
    case open, lunchBreak, closed(nextOpen: Date?), selfService

    var title: String {
        switch self {
        case .open: return "营业中"
        case .lunchBreak: return "午休中"
        case .closed: return "休息中"
        case .selfService: return "自助 24 小时"
        }
    }

    var allowsTicket: Bool { self == .open }
}

nonisolated struct ReservationSlot: Equatable {
    let startMinute: Int
    let isAvailable: Bool

    var label: String {
        String(format: "%02d:%02d-%02d:%02d", startMinute / 60, startMinute % 60, (startMinute + 60) / 60, startMinute % 60)
    }
}

nonisolated struct QueueTicket: Codable, Equatable {
    let id: String
    let branchID: String
    let business: BranchBusiness
    let number: String
    let takenAt: Date
    let aheadAtTaking: Int
    var cancelledAt: Date?
}

nonisolated enum QueueTicketStatus: Equatable {
    case waiting(ahead: Int), almostCalled(ahead: Int), called, completed, cancelled, expired

    var title: String {
        switch self {
        case .waiting: return "等待中"
        case .almostCalled: return "即将叫号"
        case .called: return "已叫号"
        case .completed: return "已完成"
        case .cancelled: return "已取消"
        case .expired: return "已过期"
        }
    }

    var isActive: Bool {
        switch self {
        case .waiting, .almostCalled, .called: return true
        case .completed, .cancelled, .expired: return false
        }
    }

    var ahead: Int {
        switch self {
        case .waiting(let ahead), .almostCalled(let ahead): return ahead
        default: return 0
        }
    }
}

nonisolated struct BranchReservation: Codable, Equatable {
    let id: String
    let branchID: String
    let business: BranchBusiness
    /// 预约日期（上海时区当天 0 点）。
    let date: Date
    let slotStartMinute: Int
    let quantity: Int?
    let code: String
    let createdAt: Date
    var cancelledAt: Date?

    var slotLabel: String { ReservationSlot(startMinute: slotStartMinute, isAvailable: true).label }
}

nonisolated enum ReservationStatus: Equatable {
    case pending, cancelled, expired

    var title: String {
        switch self {
        case .pending: return "待办理"
        case .cancelled: return "已取消"
        case .expired: return "已过期"
        }
    }
}

nonisolated enum BranchServiceError: LocalizedError, Equatable {
    case activeTicketExists, branchNotOpen, businessNotSupported, duplicateReservation
    case slotUnavailable, invalidQuantity, notCancellable, saveFailed

    var errorDescription: String? {
        switch self {
        case .activeTicketExists: return "您已有一张有效号票"
        case .branchNotOpen: return "网点当前未营业，可预约其他时间"
        case .businessNotSupported: return "该网点暂不支持此业务"
        case .duplicateReservation: return "已有待办理的同类预约"
        case .slotUnavailable: return "该时段已不可预约"
        case .invalidQuantity: return "兑换数量需在 1–20 枚之间"
        case .notCancellable: return "该记录已无法取消"
        case .saveFailed: return "保存失败，请稍后重试"
        }
    }
}
