import Foundation

@main struct EntryChecks {
    @MainActor static func main() throws {
        scanSamples()
        scanRejects()
        assistantIntents()
        assistantTieBreak()
        assistantSearchFallback()
        assistantFilters()
        assistantSensitive()
        assistantFallback()
        quickActions()
        widgetSnapshotRoundTrip()
        widgetSnapshotStore()
        try widgetSnapshotBuild()
        widgetLinks()
        plistUrlScheme()
        widgetWriterSkipsDuplicates()
        widgetFormat()
        widgetMonthRollover()
        print("Entry checks passed")
    }

    static func scanSamples() {
        precondition(ScanCodeParser.parse(ScanSample.payee.payload) == .payee(name: "欧梦瑶", bankName: "中国建设银行", account: "6217000000000593"))
        precondition(ScanCodeParser.parse(ScanSample.payee.payload).route == .transferToPayee(name: "欧梦瑶", bankName: "中国建设银行", account: "6217000000000593"))
        precondition(ScanCodeParser.parse(ScanSample.branch.payload) == .branch(branchID: "xa-fengdong", branchName: "西安沣东新城支行"))
        precondition(ScanCodeParser.parse(ScanSample.branch.payload).route == .takeTicket(branchID: "xa-fengdong"))
        precondition(ScanCodeParser.parse(ScanSample.bill.payload) == .bill(billAccountID: "bill.electric.home", title: "电费 · 家庭住宅"))
        precondition(ScanCodeParser.parse(ScanSample.bill.payload).route == .utilityBill(billAccountID: "bill.electric.home"))
        precondition(ScanCodeParser.parse(ScanSample.invalid.payload) == .unrecognized && ScanResult.unrecognized.route == nil)
        precondition(ScanCodeParser.parse("  " + ScanSample.branch.payload + "\n") != .unrecognized)
    }

    static func scanRejects() {
        let bad = [
            "", "ABANK|BRANCH|id=xa-fengdong", "ABANKDEMO|SHOP|id=1", "ABANKDEMO|BRANCH",
            "ABANKDEMO|BRANCH|id=", "ABANKDEMO|BRANCH|id=xa-fengdong|id=xa-gaoxin",
            "ABANKDEMO|BRANCH|id=nope", "ABANKDEMO|BRANCH|id=xa-self-dongguan",
            "ABANKDEMO|BILL|id=bill.nope", "ABANKDEMO|BILL|id=bill.gas.home|amount=1",
            "ABANKDEMO|PAY|name=欧梦瑶|bank=中国建设银行|acct=621700000000059",
            "ABANKDEMO|PAY|name=欧梦瑶|bank=中国建设银行|acct=62170000000005930000",
            "ABANKDEMO|PAY|name=欧梦瑶|bank=中国建设银行|acct=6217a00000000593",
            "ABANKDEMO|PAY|name=欧梦瑶|bank=中国建设银行|acct=６２１７000000000593",
            "ABANKDEMO|PAY|name=欧梦瑶|bank=中国建设银行|acct=6217000000000593|amount=100",
            "ABANKDEMO|PAY|name=|bank=中国建设银行|acct=6217000000000593",
            "ABANKDEMO|PAY|name=欧=瑶|bank=中国建设银行|acct=6217000000000593",
            "ABANKDEMO|PAY|name=\(String(repeating: "欧", count: 21))|bank=中国建设银行|acct=6217000000000593",
            "ABANKDEMO|PAY|bank=中国建设银行|acct=6217000000000593"
        ]
        for text in bad { precondition(ScanCodeParser.parse(text) == .unrecognized, text) }
    }

    static func first(_ s: String) -> FeatureID? { AssistantEngine.reply(to: s)?.features.first }

    static func assistantIntents() {
        let cases: [(String, FeatureID)] = [
            ("怎么转账", .transfer), ("查余额", .myAccount), ("提前还款", .loan), ("附近网点", .branchQuery),
            ("交电费", .lifePayment), ("话费充值", .mobileRecharge), ("理财收益", .wealthProduct),
            ("积分怎么用", .benefits), ("网上支付", .accountPermissions), ("登录密码", .securityCenter),
            ("二维码", .scan), ("我的订单", .orders),
            ("　转账？　", .transfer), ("ＡＢＣ转账", .transfer)
        ]
        for (input, id) in cases { precondition(first(input) == id, input) }
    }

    static func assistantTieBreak() {
        precondition(first("转账余额") == .transfer)
        precondition(first("开通转账") == .accountPermissions)
    }

    static func assistantSearchFallback() {
        let r = AssistantEngine.reply(to: "电子回单")!
        precondition(r.features.first == .receipts && r.text == "为您找到以下功能：" && !r.isSensitiveWarning)
    }

    static func assistantFilters() {
        let inputs = AssistantEngine.quickQuestions + ["转账", "余额", "贷款", "网点", "缴费", "充值", "理财", "积分", "交易权限", "登录", "扫码", "订单", "信用卡", "存款"]
        for input in inputs {
            let r = AssistantEngine.reply(to: input)!
            precondition(r.features.count <= 3 && r.features.allSatisfy { FeatureCatalog.descriptor($0).isAvailable }, input)
        }
    }

    static func assistantSensitive() {
        for input in ["我的卡号 6230 1234 5678", "验证码123456", "６２３０１２"] {
            let r = AssistantEngine.reply(to: input)!
            precondition(r.isSensitiveWarning && r.features.isEmpty && !r.text.contains("123456") && !r.text.contains("6230"), input)
        }
        precondition(AssistantEngine.reply(to: "12345")?.isSensitiveWarning == false)
    }

    static func assistantFallback() {
        let r = AssistantEngine.reply(to: "今天天气怎么样")!
        precondition(r.text == "没找到相关内容，换个说法试试，或看看这些常用功能：" && r.features == [.transfer, .incomeExpense, .branchQuery])
        precondition(AssistantEngine.reply(to: "  \n ") == nil && AssistantEngine.reply(to: "？！") == nil)
    }

    static func quickActions() {
        precondition(QuickAction.route(forType: "com.abank.shortcut.scan") == .scan)
        precondition(QuickAction.route(forType: "com.abank.shortcut.transfer") == .transfer(payerAccountID: nil))
        precondition(QuickAction.route(forType: "com.abank.shortcut.incomeExpense") == .incomeExpense(accountID: nil))
        precondition(QuickAction.route(forType: "com.abank.shortcut.assistant") == .assistant)
        precondition(QuickAction.route(forType: "") == nil && QuickAction.route(forType: "com.abank.shortcut.pay") == nil)
        let plist = NSDictionary(contentsOfFile: "ABank/Info.plist")!
        let items = plist["UIApplicationShortcutItems"] as! [[String: Any]]
        let types = items.compactMap { $0["UIApplicationShortcutItemType"] as? String }
        precondition(items.count == 4 && types.count == 4 && types.allSatisfy { QuickAction.route(forType: $0) != nil })
    }

    static func widgetSnapshotRoundTrip() {
        let s = WidgetSnapshot(balanceInCents: 151_966, monthIncomeInCents: 0, monthExpenseInCents: 12_300, month: "2026-11", updatedAt: "2026-11-08 20:00:00")
        precondition(WidgetSnapshot.decode(s.encoded()) == s)
        precondition(WidgetSnapshot.decode(nil) == nil && WidgetSnapshot.decode(Data()) == nil)
        precondition(WidgetSnapshot.decode(Data("{\"balanceInCents\":1}".utf8)) == nil)
        precondition(WidgetSnapshot.decode(Data("not json".utf8)) == nil)
        let keys = Set((try! JSONSerialization.jsonObject(with: s.encoded()) as! [String: Any]).keys)
        precondition(keys == ["balanceInCents", "monthIncomeInCents", "monthExpenseInCents", "month", "updatedAt"])
    }

    static func widgetSnapshotStore() {
        let name = "abank.test.widget.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let store = WidgetSnapshotStore(defaults: defaults)
        precondition(store.load() == nil)
        let a = WidgetSnapshot(balanceInCents: 100, monthIncomeInCents: 1, monthExpenseInCents: 2, month: "2026-11", updatedAt: "x")
        store.save(a); precondition(store.load() == a)
        var b = a; b.balanceInCents = 200
        store.save(b); precondition(store.load() == b)
        precondition(WidgetSnapshotStore(defaults: nil).load() == nil)
        WidgetSnapshotStore(defaults: nil).save(a)
    }

    @MainActor static func withStore(_ body: (FinanceLedgerStore, UserDefaults) throws -> Void) rethrows {
        let suite = "ABank.EntryChecks." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let dates = BankingDateContext(now: { ISO8601DateFormatter().date(from: "2026-11-08T02:00:00Z")! })
        let store = FinanceLedgerStore(defaults: defaults, dates: dates)
        _ = store.load()
        try body(store, defaults)
    }

    @MainActor static func widgetSnapshotBuild() throws {
        try withStore { store, _ in
            let snap = store.widgetSnapshot()!
            let account = store.account(id: FinanceLedgerRecord.defaultAccountId)!
            precondition(snap.balanceInCents == TransferMoney.cents(from: account.balance)!)
            let flow = store.analysis(query: IncomeExpenseQuery(dateMode: .month(store.dates.currentMonth))).summary
            precondition(snap.monthIncomeInCents == TransferMoney.cents(from: flow.income)!)
            precondition(snap.monthExpenseInCents == TransferMoney.cents(from: flow.expense)!)
            precondition(snap.month == "2026-11" && snap.updatedAt.count == 19, snap.month)
            let draft = TransferDraft(payerAccountID: FinanceLedgerRecord.defaultAccountId, method: .account, recipientName: "演示客户",
                                      bankName: "中国建设银行", destination: "6217000000000593", amountInCents: 100, note: "")
            _ = try store.submitTransfer(draft: draft, requestID: "w1")
            precondition(store.widgetSnapshot()!.balanceInCents == snap.balanceInCents - 100)
            // 没有默认账户时不生成快照
            var record = store.load()
            let old = record.accounts[0]
            record.accounts[0] = LedgerAccount(id: "other", tailNumber: old.tailNumber, currency: old.currency, balance: old.balance, openingBalance: old.openingBalance)
            precondition(store.save(record))
            precondition(store.widgetSnapshot() == nil)
        }
    }

    static func widgetLinks() {
        let expected: [(WidgetLink.Target, AppRoute)] = [
            (.account, .myAccount), (.scan, .scan),
            (.transfer, .transfer(payerAccountID: nil)), (.incomeExpense, .incomeExpense(accountID: nil))
        ]
        for (target, route) in expected {
            let url = WidgetLink.url(for: target)
            precondition(url.absoluteString == "abank://widget/\(target.rawValue)")
            precondition(WidgetLink.route(for: url) == route)
        }
        let bad = ["abank://widget/", "abank://widget", "abank://widget/unknown", "abank://widget/scan/extra",
                   "abank://widget/scan?x=1", "abank://widget/scan#f", "ABANK://widget/scan", "abank://WIDGET/scan",
                   "http://widget/scan", "abank://other/scan", "abank:///scan", "abank://widget/Scan"]
        for text in bad { precondition(URL(string: text).flatMap(WidgetLink.route(for:)) == nil, text) }
    }

    static func plistUrlScheme() {
        let plist = NSDictionary(contentsOfFile: "ABank/Info.plist")!
        let types = plist["CFBundleURLTypes"] as! [[String: Any]]
        let schemes = types.flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
        precondition(schemes == ["abank"])
    }

    static func widgetWriterSkipsDuplicates() {
        let name = "abank.test.widgetsync.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        var reloads = 0
        var sync = WidgetSnapshotSync(store: WidgetSnapshotStore(defaults: defaults), reload: { reloads += 1 })
        let a = WidgetSnapshot(balanceInCents: 1, monthIncomeInCents: 0, monthExpenseInCents: 0, month: "2026-11", updatedAt: "t1")
        sync.sync(nil); precondition(reloads == 0)
        sync.sync(a); precondition(reloads == 1)
        var later = a; later.updatedAt = "t2"
        sync.sync(later); precondition(reloads == 1)
        var changed = a; changed.balanceInCents = 2
        sync.sync(changed); precondition(reloads == 2)
        precondition(WidgetSnapshotStore(defaults: defaults).load()?.balanceInCents == 2)
        var reloads2 = 0
        var restarted = WidgetSnapshotSync(store: WidgetSnapshotStore(defaults: defaults), reload: { reloads2 += 1 })
        restarted.sync(changed); precondition(reloads2 == 0)
    }

    static func widgetFormat() {
        precondition(WidgetFormat.money(123_456) == "¥1,234.56")
        precondition(WidgetFormat.money(0) == "¥0.00" && WidgetFormat.money(5) == "¥0.05")
        precondition(WidgetFormat.money(-1_230) == "-¥12.30")
        precondition(WidgetFormat.money(10_000_000_000) == "¥100,000,000.00")
        precondition(WidgetFormat.time("2026-11-08 20:05:09") == "20:05" && WidgetFormat.time("") == "--:--" && WidgetFormat.time("x") == "--:--")
    }

    static func widgetMonthRollover() {
        let s = WidgetSnapshot(balanceInCents: 500, monthIncomeInCents: 700, monthExpenseInCents: 900, month: "2026-10", updatedAt: "2026-10-31 20:00:00")
        let same = s.monthlyFlow(inMonth: "2026-10")
        precondition(same.income == 700 && same.expense == 900)
        let stale = s.monthlyFlow(inMonth: "2026-11")
        precondition(stale.income == 0 && stale.expense == 0)
        // 北京时间：UTC 2026-10-31 17:00 已是 11 月 1 日
        let utc1700 = ISO8601DateFormatter().date(from: "2026-10-31T17:00:00Z")!
        precondition(WidgetFormat.beijingMonth(utc1700) == "2026-11")
        let utc1559 = ISO8601DateFormatter().date(from: "2026-10-31T15:59:00Z")!
        precondition(WidgetFormat.beijingMonth(utc1559) == "2026-10")
    }
}
