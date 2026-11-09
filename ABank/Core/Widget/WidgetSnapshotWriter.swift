//
//  WidgetSnapshotWriter.swift
//  ABank
//
//  账本每次变化后重建快照写入 App Group，并让 Widget 刷新。
//

import Foundation
import UIKit
#if canImport(WidgetKit)
import WidgetKit
#endif

@MainActor
final class WidgetSnapshotWriter {
    static let shared = WidgetSnapshotWriter()

    private var sync = WidgetSnapshotSync(store: WidgetSnapshotStore(), reload: {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    })
    private var started = false

    /// 幂等：启动时写一次，之后监听账本变化。
    func start() {
        guard !started else { return }
        started = true
        NotificationCenter.default.addObserver(
            self, selector: #selector(ledgerDidChange), name: .financeLedgerDidChange, object: nil
        )
        // 回到前台也同步一次：跨月或后台期间数据变化后，快照不会停在旧状态（内容不变则不刷新 Widget）。
        NotificationCenter.default.addObserver(
            self, selector: #selector(ledgerDidChange), name: UIApplication.willEnterForegroundNotification, object: nil
        )
        refresh()
    }

    @objc private func ledgerDidChange() { refresh() }

    private func refresh() {
        sync.sync(FinanceLedgerStore.shared.widgetSnapshot())
    }
}
