//
//  ABankWidget.swift
//  ABankWidget
//
//  模拟余额 Widget：读取 App 写入 App Group 的快照，点击经白名单链接回到 App。
//

import WidgetKit
import SwiftUI

struct BalanceEntry: TimelineEntry {
    let date: Date
    /// nil 表示 App 还没有同步过，显示“打开 App 同步”。
    let snapshot: WidgetSnapshot?
}

struct BalanceProvider: TimelineProvider {
    private static let sample = WidgetSnapshot(
        balanceInCents: 123_456, monthIncomeInCents: 0, monthExpenseInCents: 12_300,
        month: "2026-11", updatedAt: "2026-11-08 20:00:00"
    )

    func placeholder(in context: Context) -> BalanceEntry {
        BalanceEntry(date: Date(), snapshot: Self.sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (BalanceEntry) -> Void) {
        completion(BalanceEntry(date: Date(), snapshot: context.isPreview ? Self.sample : WidgetSnapshotStore().load()))
    }

    /// 数据变化由 App 调用 reloadAllTimelines，不做定时刷新。
    func getTimeline(in context: Context, completion: @escaping (Timeline<BalanceEntry>) -> Void) {
        completion(Timeline(entries: [BalanceEntry(date: Date(), snapshot: WidgetSnapshotStore().load())], policy: .never))
    }
}

@main
struct ABankBalanceWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ABankBalanceWidget", provider: BalanceProvider()) { entry in
            BalanceWidgetView(entry: entry)
        }
        .configurationDisplayName("模拟余额")
        .description("查看模拟余额与本月收支")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
