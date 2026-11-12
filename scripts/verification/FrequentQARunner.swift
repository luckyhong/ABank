import UIKit
import PDFKit
import CoreImage

@MainActor enum FrequentQARunner {
    static var checks: [[String: Any]] = []
    static let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("FrequentQA")
    static func check(_ name: String, _ passed: Bool) { checks.append(["name": name, "passed": passed]) }
    static func pause() async { try? await Task.sleep(nanoseconds: 380_000_000) }
    static func children(_ view: UIView) -> [UIView] { [view] + view.subviews.flatMap(children) }
    static func texts(_ view: UIView) -> [String] { guard !view.isHidden else { return [] }; return ((view as? UILabel)?.text.map { [$0] } ?? []) + view.subviews.flatMap(texts) }
    static func capture(_ name: String, window: UIWindow) async {
        await pause(); window.layoutIfNeeded()
        let img = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in window.drawHierarchy(in: window.bounds, afterScreenUpdates: true) }
        try? img.pngData()?.write(to: folder.appendingPathComponent(name + ".png"))
        check(name + " has content", !texts(window).isEmpty)
        check(name + " copy", !texts(window).contains { $0.contains("模拟") || $0.contains("测试") || $0.contains("123456") })
    }
    static func screen(_ vc: UIViewController, nav: UINavigationController, name: String, window: UIWindow) async {
        nav.setViewControllers([vc], animated: false); await capture(name, window: window)
    }
    static func field(_ id: String, in view: UIView) -> UITextField? { children(view).first { $0.accessibilityIdentifier == id } as? UITextField }
    static func control(_ id: String, in view: UIView) -> UIControl? { children(view).first { $0.accessibilityIdentifier == id } as? UIControl }
    static func run(window: UIWindow) async {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try? FileManager.default.removeItem(at: folder.appendingPathComponent("results.json"))
        UserDefaults.standard.removeObject(forKey: "abank.financeLedger.record.v8")
        UserDefaults.standard.removeObject(forKey: "abank.messages.read.v1")
        let ledger = FinanceLedgerStore.shared
        _ = ledger.load()
        let tab = MainTabBarController(); window.rootViewController = tab
        for (index, name) in [(0,"01-home"),(1,"02-wealth"),(2,"03-life"),(4,"04-mine")] {
            tab.selectedIndex = index; await capture(name, window: window)
        }
        check("all default favorites available", FeatureCatalog.defaultFavorites.allSatisfy { FeatureCatalog.descriptor($0).isAvailable })
        let nav = ABankNavigationController(rootViewController: MyAccountViewController()); window.rootViewController = nav
        do {
            await capture("05-account", window: window)
            let initial = ledger.load()
            check("37 confirmed transactions", initial.transactions.count == 37)
            let electronic = try ledger.openElectronicAccount()
            let own = ledger.transferRecipients().first { $0.linkedAccountID == electronic.id }!
            let transfer = try ledger.submitTransfer(draft: TransferDraft(payerAccountID: FinanceLedgerRecord.defaultAccountId, savedRecipientID: own.id, amountInCents: 100_000, note: "本人账户资金转入"), requestID: "qa-fund")
            check("internal transfer assets", ledger.totalAssets() == 8269.23)
            await capture("06-two-accounts", window: window)
            await screen(IncomeExpenseViewController(), nav: nav, name: "07-income", window: window)
            await screen(LedgerAnalysisViewController(query: .init()), nav: nav, name: "08-analysis", window: window)
            await screen(LedgerAnalysisViewController(query: .init(dateMode: .month("2030-01"))), nav: nav, name: "09-empty-analysis", window: window)
            await screen(TransferReceiptDetailViewController(recordID: transfer.id), nav: nav, name: "10-receipt", window: window)
            let pdf = BankReceiptView.pdf(record: transfer)
            try pdf.write(to: folder.appendingPathComponent("receipt.pdf"))
            let doc = PDFDocument(data: pdf)
            check("PDF receipt one valid page", doc?.pageCount == 1 && pdf.count > 1000)
            if let page = doc?.page(at: 0) { try? page.thumbnail(of: CGSize(width: 595, height: 842), for: .mediaBox).pngData()?.write(to: folder.appendingPathComponent("10b-receipt-pdf.png")) }
            await screen(TransferReceiptsViewController(), nav: nav, name: "11-receipts", window: window)
            let messages = MessagesViewController()
            await screen(messages, nav: nav, name: "12-messages", window: window)
            let count = BankMessageStore.shared.unreadCount()
            let first = BankMessageStore.shared.messages().first!
            BankMessageStore.shared.markRead([first]); messages.refreshBankingData()
            check("message read state", BankMessageStore.shared.unreadCount() == count - 1)
            await screen(BankMessageDetailViewController(message: first), nav: nav, name: "13-message-detail", window: window)
            await screen(AppSettingsViewController(), nav: nav, name: "14-settings", window: window)
            _ = try RiskAssessmentStore.shared.submit(answers: [3,3,3,3,3])
            await screen(WealthProductListViewController(accountID: electronic.id), nav: nav, name: "15-products", window: window)
            await screen(WealthProductDetailViewController(productID: "w.shishifu", accountID: electronic.id), nav: nav, name: "16-product-detail", window: window)
            let purchase = WealthPurchaseViewController(productID: "w.shishifu", accountID: electronic.id)
            await screen(purchase, nav: nav, name: "17-wealth-purchase", window: window)
            check("wealth payer preserved", texts(purchase.view).contains { $0.contains(electronic.tailNumber) })
            let mainBalance = ledger.account(id: FinanceLedgerRecord.defaultAccountId)!.balance
            let order = try ledger.submitWealthPurchase(productID: "w.shishifu", amountInCents: 10_000, requestID: "qa-wealth", accountID: electronic.id)
            check("wealth uses selected account", order.accountID == electronic.id && ledger.account(id: FinanceLedgerRecord.defaultAccountId)?.balance == mainBalance)
            await screen(WealthOrderDetailViewController(orderID: order.id, justPurchased: true), nav: nav, name: "18-wealth-order", window: window)
            await screen(WealthHoldingsViewController(), nav: nav, name: "19-holdings", window: window)
            await screen(LifePaymentViewController(), nav: nav, name: "20-bills", window: window)
            let bill = UtilityBillViewController(billAccountID: PaymentCatalog.billAccounts[0].id)
            await screen(bill, nav: nav, name: "21-bill-detail", window: window)
            let past = try ledger.utilityBill(account: PaymentCatalog.billAccounts[0], period: ledger.dates.previousMonth)
            check("bill breakdown exact", past.calculatedChargeInCents == past.amountInCents)
            await screen(MobileRechargeViewController(), nav: nav, name: "22-recharge", window: window)
            await screen(MobileRechargeConfirmViewController(phone: "13800008000", faceInCents: 2_000), nav: nav, name: "23-recharge-confirm", window: window)
            let recharge = try ledger.submitMobileRecharge(phone: "13800008000", faceInCents: 2_000, couponID: nil, requestID: "qa-recharge", accountID: electronic.id)
            check("recharge payer correct", recharge.accountID == electronic.id)
            await screen(PaymentOrderDetailViewController(orderID: recharge.id, justPaid: true), nav: nav, name: "24-payment-result", window: window)
            let editor = ManualEntryViewController()
            await screen(editor, nav: nav, name: "25-entry", window: window)
            field("entry.title", in: editor.view)?.text = "午餐"
            field("entry.amount", in: editor.view)?.text = "35.00"
            control("entry.save", in: editor.view)?.sendActions(for: .touchUpInside)
            let manual = ledger.load().transactions.first(where: \.isManual)!
            check("manual save one row", ledger.load().transactions.filter(\.isManual).count == 1)
            await screen(IncomeExpenseDetailViewController(transaction: manual), nav: nav, name: "26-entry-detail", window: window)
            await screen(MyLoanViewController(), nav: nav, name: "27-loans", window: window)
            await screen(LoanDueViewController(period: .nextMonth), nav: nav, name: "28-loan-due", window: window)
            await screen(DepositsViewController(), nav: nav, name: "29-deposits-empty", window: window)
            if let row = children(nav.topViewController!.view).first(where: { $0.accessibilityIdentifier == "deposit_3m" }) as? BenefitsRow { row.onTap?(); await capture("29b-deposit-purchase", window: window) }
            let deposited = try ledger.openDeposit(productID: "deposit_3m", amount: 10_000, accountID: electronic.id, requestID: "qa-deposit")
            await screen(DepositDetailViewController(id: deposited.id), nav: nav, name: "30-deposit-detail", window: window)
            await screen(CreditCardsViewController(), nav: nav, name: "31-credit-empty", window: window)
            let card = try ledger.addCreditCard()
            await screen(CreditCardsViewController(), nav: nav, name: "32-credit-bill", window: window)
            let expense = ledger.monthlyFlow(for: String(card.statementDate.prefix(7))).expense
            _ = try ledger.repayCreditCard(id: card.id, amount: card.minimumInCents, accountID: electronic.id, requestID: "qa-credit")
            check("credit repayment excluded from flow", ledger.monthlyFlow(for: String(card.statementDate.prefix(7))).expense == expense)
            await screen(CreditCardsViewController(), nav: nav, name: "33-credit-repaid", window: window)
            await screen(MyAccountViewController(), nav: nav, name: "34-account-with-credit", window: window)
            await screen(AssetLiabilityViewController(), nav: nav, name: "35-assets", window: window)
            await screen(SecurityCenterViewController(), nav: nav, name: "36-security", window: window)
            await screen(LoginSettingsViewController(), nav: nav, name: "37-login-settings", window: window)
            await screen(ModifyMobileViewController(), nav: nav, name: "38-mobile", window: window)
            await screen(GestureAccessViewController(enrolling: true) {}, nav: nav, name: "39-gesture", window: window)
            await screen(ScanViewController(), nav: nav, name: "40-scan", window: window)
            await screen(BenefitsCenterViewController(), nav: nav, name: "41-benefits", window: window)
            await screen(BranchListViewController(), nav: nav, name: "42-branches", window: window)
            await screen(AllFeaturesViewController(), nav: nav, name: "43-all-features", window: window)
            await screen(NewsViewController(), nav: nav, name: "44-news", window: window)
            let enlarged = LedgerAnalysisViewController(query: .init())
            nav.setViewControllers([enlarged], animated: false)
            nav.setOverrideTraitCollection(UITraitCollection(preferredContentSizeCategory: .accessibilityLarge), forChild: enlarged)
            await capture("45-analysis-large-text", window: window)
            let ids = Set(initial.transactions.map(\.id))
            check("37 reference transactions preserved", ledger.load().transactions.filter { ids.contains($0.id) } == initial.transactions)
            await screen(TransferFormViewController(payerAccountID: electronic.id), nav: nav, name: "47-transfer-form", window: window)
            let confirmDraft = TransferDraft(payerAccountID: FinanceLedgerRecord.defaultAccountId, savedRecipientID: own.id, amountInCents: 100, note: "转入电子账户")
            await screen(TransferConfirmViewController(draft: confirmDraft), nav: nav, name: "48-transfer-confirm", window: window)
            await screen(TransferResultViewController(record: transfer), nav: nav, name: "49-transfer-result", window: window)
            await screen(AccountPermissionsViewController(accountID: electronic.id), nav: nav, name: "50-account-permissions", window: window)
            await screen(AccountShareViewController(accountID: electronic.id), nav: nav, name: "51-account-share", window: window)
            await screen(DebitCardDetailViewController(), nav: nav, name: "52-card-detail", window: window)
            await screen(LoginDevicesViewController(), nav: nav, name: "53-devices", window: window)
            await screen(LoginDeviceDetailViewController(deviceID: "current-iphone"), nav: nav, name: "54-device-detail", window: window)
            await screen(LifeOfferViewController(title: "优惠专区", subtitle: "精选生活权益"), nav: nav, name: "55-life-offer", window: window)
            let filtered = WealthProductListViewController(); nav.setViewControllers([filtered], animated: false); await pause()
            if let search = children(filtered.view).first(where: { $0 is UISearchBar }) as? UISearchBar { search.text = "时付"; search.delegate?.searchBar?(search, textDidChange: "时付") }
            await capture("56-wealth-search", window: window)
            let payload = ScanSample.allCases[0].payload
            let generator = CIFilter(name: "CIQRCodeGenerator")!; generator.setValue(payload.data(using: .utf8), forKey: "inputMessage")
            let output = generator.outputImage!.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
            let qr = UIImage(cgImage: CIContext().createCGImage(output, from: output.extent)!).pngData()!
            check("actual image QR recognition", try ScanImageReader.text(in: qr) == payload)
            let scan = ScanViewController(); await screen(scan, nav: nav, name: "57-scan-start", window: window)
            scan.handleScannedText(try ScanImageReader.text(in: qr)); await capture("58-scan-result", window: window)
            check("scan never submits payment", ledger.load().transferRecords.count == 1)
            CustomerSessionStore.shared.signOut()
            check("logout persisted", !CustomerSessionStore.shared.isSignedIn)
            await capture("46-login", window: window)
            if let scene = window.windowScene, let delegate = scene.delegate as? SceneDelegate {
                let item = UIApplicationShortcutItem(type: "com.abank.shortcut.scan", localizedTitle: "快捷操作")
                var handled = false
                delegate.windowScene(scene, performActionFor: item) { handled = $0 }
                check("signed-out warm shortcut accepted", handled)
            }
            CustomerSessionStore.shared.signIn()
            check("login restored", CustomerSessionStore.shared.isSignedIn)
            check("7 service assets decode", ["abc_statement_monthly", "abc_statement_receipt", "abc_ledger_credit_repayment", "abc_ledger_fund", "abc_home_bill_banner", "abc_home_beans_banner", "abc_home_life_banner"].allSatisfy { UIImage(named: $0) != nil })
        } catch { checks.append(["passed": false, "error": error.localizedDescription]) }
        try? JSONSerialization.data(withJSONObject: checks, options: [.prettyPrinted,.sortedKeys]).write(to: folder.appendingPathComponent("results.json"))
    }
}
