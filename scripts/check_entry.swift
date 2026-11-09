import Foundation

@main struct EntryChecks {
    @MainActor static func main() throws {
        scanSamples()
        scanRejects()
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
}
