import UIKit

/// 账本页面共同的刷新时机，不在页面间复制财务状态。
class BankingDataViewController: BaseViewController {
    private var midnightTimer: Timer?
    override func viewDidLoad() {
        super.viewDidLoad()
        for name in [Notification.Name.financeLedgerDidChange,
                     UIApplication.didBecomeActiveNotification,
                     UIApplication.significantTimeChangeNotification] {
            NotificationCenter.default.addObserver(self, selector: #selector(bankingDataDidChange), name: name, object: nil)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshBankingData()
        scheduleMidnightRefresh()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        midnightTimer?.invalidate()
        midnightTimer = nil
    }

    /// 子类刷新模型和展示，保持筛选、金额显隐及滚动状态。
    func refreshBankingData() {}

    @objc private func bankingDataDidChange() {
        guard isViewLoaded, view.window != nil else { return }
        refreshBankingData()
        scheduleMidnightRefresh()
    }

    private func scheduleMidnightRefresh() {
        midnightTimer?.invalidate()
        let dates = BankingDateContext.system
        let now = dates.now
        guard let tomorrow = dates.calendar.dateInterval(of: .day, for: now)?.end else { return }
        let timer = Timer(timeInterval: max(1, tomorrow.timeIntervalSince(now)), repeats: false) { [weak self] _ in
            self?.bankingDataDidChange()
        }
        RunLoop.main.add(timer, forMode: .common)
        midnightTimer = timer
    }

    deinit {
        midnightTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}
