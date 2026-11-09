//
//  ScanCode.swift
//  ABank
//
//  演示扫码：把固定格式的示例码解析为结果与路由。仅依赖 Foundation。
//

import Foundation

enum ScanResult: Equatable {
    case payee(name: String, bankName: String, account: String)
    case branch(branchID: String, branchName: String)
    case bill(billAccountID: String, title: String)
    case unrecognized

    var route: AppRoute? {
        switch self {
        case .payee(let name, let bankName, let account):
            return .transferToPayee(name: name, bankName: bankName, account: account)
        case .branch(let branchID, _):
            return .takeTicket(branchID: branchID)
        case .bill(let billAccountID, _):
            return .utilityBill(billAccountID: billAccountID)
        case .unrecognized:
            return nil
        }
    }
}

enum ScanSample: CaseIterable {
    case payee, branch, bill, invalid

    var title: String {
        switch self {
        case .payee: return "个人收款码"
        case .branch: return "网点取号码"
        case .bill: return "电费缴费码"
        case .invalid: return "无效码"
        }
    }

    var payload: String {
        switch self {
        case .payee: return "ABANKDEMO|PAY|name=欧梦瑶|bank=中国建设银行|acct=6217000000000593"
        case .branch: return "ABANKDEMO|BRANCH|id=xa-fengdong"
        case .bill: return "ABANKDEMO|BILL|id=bill.electric.home"
        case .invalid: return "https://example.com/pay?amount=100"
        }
    }
}

enum ScanCodeParser {
    private static let prefix = "ABANKDEMO"

    static func parse(_ text: String) -> ScanResult {
        let parts = text.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "|")
        guard parts.count >= 2, parts[0] == prefix else { return .unrecognized }
        var fields: [String: String] = [:]
        for part in parts.dropFirst(2) {
            let pair = part.components(separatedBy: "=")
            guard pair.count == 2, !pair[0].isEmpty, !pair[1].isEmpty, fields[pair[0]] == nil else { return .unrecognized }
            fields[pair[0]] = pair[1]
        }
        switch parts[1] {
        case "PAY":
            guard Set(fields.keys) == ["name", "bank", "acct"],
                  let name = fields["name"], let bank = fields["bank"], let acct = fields["acct"],
                  name.count <= 20,
                  acct.range(of: "^[0-9]{16,19}$", options: .regularExpression) != nil else { return .unrecognized }
            return .payee(name: name, bankName: bank, account: acct)
        case "BRANCH":
            guard Set(fields.keys) == ["id"], let id = fields["id"],
                  let branch = BranchCatalog.branch(id: id), branch.kind == .full else { return .unrecognized }
            return .branch(branchID: id, branchName: branch.name)
        case "BILL":
            guard Set(fields.keys) == ["id"], let id = fields["id"],
                  let account = PaymentCatalog.billAccount(id: id) else { return .unrecognized }
            return .bill(billAccountID: id, title: "\(account.kind.title) · \(account.name)")
        default:
            return .unrecognized
        }
    }
}
