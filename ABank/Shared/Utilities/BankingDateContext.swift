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

    var previousMonth: String {
        let start = calendar.dateInterval(of: .month, for: now)!.start
        return string(from: calendar.date(byAdding: .month, value: -1, to: start)!, format: "yyyy-MM")
    }

    var previousMonthTitle: String {
        let parts = previousMonth.split(separator: "-")
        let month = Int(parts[1])!
        return previousMonth.prefix(4) == currentMonth.prefix(4)
            ? "\(month)月份" : "\(parts[0])年\(month)月份"
    }

    /// yyyy-MM 月份平移；非法月份返回 nil。
    func month(_ month: String, offsetBy value: Int) -> String? {
        guard let start = date(from: month, format: "yyyy-MM"),
              let shifted = calendar.date(byAdding: .month, value: value, to: start) else { return nil }
        return string(from: shifted, format: "yyyy-MM")
    }

    /// 「2026年9月」形式的月份标题。
    func monthTitle(_ month: String) -> String {
        let parts = month.split(separator: "-")
        guard parts.count == 2, let number = Int(parts[1]) else { return month }
        return "\(parts[0])年\(number)月"
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
