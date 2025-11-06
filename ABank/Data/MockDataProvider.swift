//
//  MockDataProvider.swift
//  ABank
//
//  Created by 韩继宏 on 2025/10/27.
//

import Foundation

/// 假数据提供者 - 模拟网络请求返回的数据
class MockDataProvider {
    
    static let shared = MockDataProvider()
    
    private init() {}
    
    // MARK: - 账户信息
    struct AccountInfo {
        let cardNumber: String
        let balance: Double
        let accountName: String
    }
    
    func getAccountInfo() -> AccountInfo {
        return AccountInfo(
            cardNumber: "6228480012345678901",
            balance: 12345.67,
            accountName: "张三"
        )
    }
    
    // MARK: - 交易记录
    struct Transaction {
        let id: String
        let title: String
        let amount: Double
        let date: Date
        let type: TransactionType
    }
    
    enum TransactionType {
        case income  // 收入
        case expense // 支出
    }
    
    func getTransactions(limit: Int = 20) -> [Transaction] {
        let transactions: [Transaction] = [
            Transaction(id: "1", title: "工资收入", amount: 8000.0, date: Date(), type: .income),
            Transaction(id: "2", title: "转账支出", amount: -500.0, date: Date().addingTimeInterval(-86400), type: .expense),
            Transaction(id: "3", title: "理财收益", amount: 120.5, date: Date().addingTimeInterval(-172800), type: .income),
            Transaction(id: "4", title: "消费支出", amount: -89.9, date: Date().addingTimeInterval(-259200), type: .expense)
        ]
        return Array(transactions.prefix(limit))
    }
}

