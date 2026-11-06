//
//  AppRoute.swift
//  ABank
//
//  类型化路由：同一功能无论从哪个入口进入都使用相同路由。
//  仅依赖 Foundation，便于数据检查脚本在 macOS 上编译。
//

import Foundation

enum AppRoute: Equatable {
    case myAccount
    case debitCardDetail
    case transfer(payerAccountID: String?)
    case transferForm(method: TransferMethod)
    case transferRecords
    case transferLimits
    case transferReceipts
    case accountDetail(accountID: String?, maskedNumber: String?)
    case incomeExpense(accountID: String?)
    case ledgerAnalysis
    case ledgerSearch
    case assetLiability
    case myLoan
    case customerInfo
    case allFeatures(searchKeyword: String?)
    case editFavorites
    case comingSoon(FeatureID)
}
