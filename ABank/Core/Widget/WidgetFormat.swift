//
//  WidgetFormat.swift
//  ABank
//
//  Widget 金额与时间格式化：整数运算，不依赖区域设置。App 与 Widget 扩展共用。
//

import Foundation

enum WidgetFormat {
    /// 123456 → ¥1,234.56；负数 -¥12.30。
    static func money(_ cents: Int64) -> String {
        let magnitude = cents.magnitude
        let yuan = String(magnitude / 100)
        var grouped = ""
        for (index, char) in yuan.reversed().enumerated() {
            if index > 0, index % 3 == 0 { grouped.append(",") }
            grouped.append(char)
        }
        let fraction = magnitude % 100
        let text = "¥\(String(grouped.reversed())).\(fraction < 10 ? "0" : "")\(fraction)"
        return cents < 0 ? "-" + text : text
    }

    /// "yyyy-MM-dd HH:mm:ss" → "HH:mm"；格式不符返回 "--:--"。
    static func time(_ updatedAt: String) -> String {
        let parts = updatedAt.split(separator: " ")
        guard parts.count == 2 else { return "--:--" }
        let clock = parts[1].split(separator: ":")
        guard clock.count == 3, clock[0].count == 2, clock[1].count == 2 else { return "--:--" }
        return "\(clock[0]):\(clock[1])"
    }
}
