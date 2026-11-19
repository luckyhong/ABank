import Foundation

/// 银行业务演示统一使用北京时间；注入时钟便于验证跨日、跨月及跨年。
nonisolated struct BankingDateContext {
    static let system = BankingDateContext()
    private let nowProvider: () -> Date

    init(now: @escaping () -> Date = { Date() }) {
        nowProvider = now
    }

    var now: Date { nowProvider() }

    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return calendar
    }

    var currentMonth: String { string(from: now, format: "yyyy-MM") }

    var previousMonth: String { string(from: previousMonthStart(relativeTo: now), format: "yyyy-MM") }

    var previousMonthTitle: String {
        let reference = now
        return monthTitle(for: previousMonthStart(relativeTo: reference), relativeTo: reference)
    }

    func previousMonthStart(relativeTo date: Date) -> Date {
        let start = calendar.dateInterval(of: .month, for: date)!.start
        return calendar.date(byAdding: .month, value: -1, to: start)!
    }

    func monthTitle(for month: Date, relativeTo reference: Date) -> String {
        let sameYear = calendar.component(.year, from: month) == calendar.component(.year, from: reference)
        return string(from: month, format: sameYear ? "M'月份'" : "yyyy'年'M'月份'")
    }

    func string(from date: Date, format: String = "yyyy-MM-dd") -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    func date(from text: String, format: String = "yyyy-MM-dd") -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = format
        formatter.isLenient = false
        guard let date = formatter.date(from: text), string(from: date, format: format) == text else { return nil }
        return date
    }
}
