//
//  WidgetViews.swift
//  ABankWidget
//
//  小号/中号视图。不使用 iOS 16+ API（背景用 .background）。
//

import WidgetKit
import SwiftUI

private let brandOrange = Color(red: 1, green: 149 / 255, blue: 0)

struct BalanceWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BalanceEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                if family == .systemMedium { MediumContent(snapshot: snapshot) } else { SmallContent(snapshot: snapshot) }
            } else {
                EmptyContent()
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white)
        .widgetURL(WidgetLink.url(for: .account))
    }
}

private struct SimulatedTag: View {
    var body: some View {
        Text("模拟数据")
            .font(.system(size: 10))
            .foregroundColor(brandOrange)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(brandOrange.opacity(0.12))
            .cornerRadius(4)
    }
}

private struct BalanceBlock: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("借记卡余额").font(.system(size: 12)).foregroundColor(.gray)
                Spacer(minLength: 4)
                SimulatedTag()
            }
            Text(WidgetFormat.money(snapshot.balanceInCents))
                .font(.system(size: 22, weight: .semibold))
                .minimumScaleFactor(0.6).lineLimit(1)
            Spacer(minLength: 0)
            Text("更新于 \(WidgetFormat.time(snapshot.updatedAt))").font(.system(size: 10)).foregroundColor(.gray)
        }
    }
}

private struct SmallContent: View {
    let snapshot: WidgetSnapshot
    var body: some View { BalanceBlock(snapshot: snapshot) }
}

private struct MediumContent: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        let flow = snapshot.monthlyFlow(inMonth: WidgetFormat.beijingMonth(Date()))
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                BalanceBlock(snapshot: snapshot)
                VStack(alignment: .leading, spacing: 4) {
                    flowRow("本月收入", flow.income)
                    flowRow("本月支出", flow.expense)
                }
                .frame(maxWidth: 110, alignment: .leading)
            }
            HStack(spacing: 8) {
                entryLink("扫一扫", "qrcode.viewfinder", .scan)
                entryLink("转账", "arrow.left.arrow.right", .transfer)
                entryLink("收支明细", "list.bullet.rectangle", .incomeExpense)
            }
        }
    }

    private func flowRow(_ title: String, _ cents: Int64) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title).font(.system(size: 10)).foregroundColor(.gray)
            Text(WidgetFormat.money(cents)).font(.system(size: 13, weight: .medium)).lineLimit(1).minimumScaleFactor(0.6)
        }
    }

    private func entryLink(_ title: String, _ icon: String, _ target: WidgetLink.Target) -> some View {
        Link(destination: WidgetLink.url(for: target)) {
            HStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 11))
                Text(title).font(.system(size: 11)).lineLimit(1)
            }
            .foregroundColor(brandOrange)
            .frame(maxWidth: .infinity, minHeight: 26)
            .background(brandOrange.opacity(0.12))
            .cornerRadius(13)
        }
    }
}

private struct EmptyContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("模拟余额").font(.system(size: 14, weight: .medium))
            Spacer(minLength: 0)
            Text("打开 App 同步").font(.system(size: 13)).foregroundColor(.gray)
        }
    }
}
