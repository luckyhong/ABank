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
}
