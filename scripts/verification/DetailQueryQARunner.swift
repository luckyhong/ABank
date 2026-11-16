import UIKit

@MainActor enum DetailQueryQARunner {
    static let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("DetailQA")
    static var checks: [[String: Any]] = []
    static func check(_ name: String, _ pass: Bool) { checks.append(["name": name, "passed": pass]) }
    static func all(_ view: UIView) -> [UIView] { [view] + view.subviews.flatMap(all) }
    static func wait() async { try? await Task.sleep(nanoseconds: 600_000_000) }
    static func capture(_ name: String, window: UIWindow) async {
        await wait(); window.layoutIfNeeded()
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in window.drawHierarchy(in: window.bounds, afterScreenUpdates: true) }
        try? image.pngData()?.write(to: folder.appendingPathComponent(name + ".png"))
    }
    static func screen(_ vc: UIViewController, nav: UINavigationController, name: String, window: UIWindow) async {
        nav.setViewControllers([UIViewController(), vc], animated: false)
        await capture(name, window: window)
    }
    static func run(window: UIWindow) async {
        try? FileManager.default.removeItem(at: folder)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        window.overrideUserInterfaceStyle = .light
        UserDefaults.standard.removeObject(forKey: "abank.financeLedger.record.v8")
        let ledger = FinanceLedgerStore.shared
        let seed = ledger.load()
        check("38 rows, no duplicate debit", seed.transactions.count == 38 && seed.accounts[0].balance == 5269.23)
        let nav = ABankNavigationController(rootViewController: UIViewController()); window.rootViewController = nav
        let new = seed.transactions.first { $0.id == "fixture-2026-11-16-transfer-to-ou" }!
        let original = seed.transactions.first { $0.id == "fixture-2026-11-10-transfer-out" }!
        let first = AccountDetailQueryDetailViewController(transaction: original)
        await screen(first, nav: nav, name: "01-nov10-detail", window: window)
        check("original 10000 amount and ledger balance", all(first.view).compactMap { ($0 as? UILabel)?.text }.contains("-10,000.00") && all(first.view).compactMap { ($0 as? UILabel)?.text }.contains("8269.23"))
        let detail = AccountDetailQueryDetailViewController(transaction: new)
        await screen(detail, nav: nav, name: "02-nov16-detail", window: window)
        let expected = ["交易时间":"2026-11-16 10:45", "交易摘要":"转支", "对方户名":"欧梦瑶", "对方账户":"6217****0593", "收款银行":"建设银行", "交易类型":"转账", "交易渠道":"掌上银行", "本次余额":"5269.23", "交易附言":"---"]
        for (key, value) in expected {
            let label = all(detail.view).first { $0.accessibilityIdentifier == "accountDetail.value." + key } as? UILabel
            check("detail " + key, label?.text == value && !label!.bounds.isEmpty)
        }
        check("no wrong summary labels", !all(detail.view).compactMap { ($0 as? UILabel)?.text }.contains { $0.contains("转给欧") || $0.contains("转出（欧）") })
        let query = AccountDetailQueryViewController()
        await screen(query, nav: nav, name: "03-query-currency-arrow", window: window)
        if let button = all(query.view).first(where: { $0.accessibilityIdentifier == "accountQuery.currency" }) as? UIButton {
            check("44pt currency touch target", button.bounds.height >= 44)
            check("semantic chevron decodes", button.configuration?.image != nil)
            check("chevron is open wide V", (button.configuration?.image?.size.width ?? 0) > (button.configuration?.image?.size.height ?? 100))
            button.sendActions(for: .touchUpInside)
            await capture("04-currency-picker", window: window)
            check("currency picker opens", (query.presentedViewController as? UIAlertController)?.title == "选择币种")
            query.dismiss(animated: false); await wait()
        } else { check("currency control exists", false) }
        let large = AccountDetailQueryDetailViewController(transaction: new)
        nav.setViewControllers([UIViewController(), large], animated: false)
        nav.setOverrideTraitCollection(UITraitCollection(preferredContentSizeCategory: .accessibilityLarge), forChild: large)
        await capture("05-detail-large-text", window: window)
        check("large text bank still represented", all(large.view).compactMap { ($0 as? UILabel)?.text }.contains("建设银行"))
        nav.setOverrideTraitCollection(nil, forChild: large)
        window.overrideUserInterfaceStyle = .dark
        await screen(AccountDetailQueryDetailViewController(transaction: new), nav: nav, name: "06-detail-dark-appearance", window: window)
        window.overrideUserInterfaceStyle = .light
        var missing = LedgerTransaction(id: "unknown-qa", accountId: new.accountId, date: new.date, time: new.time, title: "转支", direction: .expense, amount: 1, balanceAfter: 5269.23, iconKey: "", categoryId: "transfer_out")
        missing.channel = ""
        let empty = AccountDetailQueryDetailViewController(transaction: missing)
        await screen(empty, nav: nav, name: "07-unknown-fields", window: window)
        check("unknown bank stays unknown", (all(empty.view).first { $0.accessibilityIdentifier == "accountDetail.value.收款银行" } as? UILabel)?.text == "---")
        var root = seed
        let index = root.transactions.firstIndex { $0.id == new.id }!
        root.transactions[index].counterpartyName = String(repeating: "长姓名", count: 12)
        root.transactions[index].counterpartyBank = String(repeating: "银行名称", count: 10)
        _ = ledger.save(root)
        await screen(AccountDetailQueryDetailViewController(transaction: root.transactions[index]), nav: nav, name: "08-long-fields", window: window)
        _ = ledger.save(seed)
        await screen(AccountDetailQueryDetailViewController(transaction: new), nav: nav, name: "09-final-detail", window: window)
        check("financial history unchanged after UI", ledger.load() == seed)
        try? JSONSerialization.data(withJSONObject: checks, options: [.prettyPrinted,.sortedKeys]).write(to: folder.appendingPathComponent("results.json"))
    }
}
