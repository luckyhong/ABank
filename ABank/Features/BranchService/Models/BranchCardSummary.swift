//
//  BranchCardSummary.swift
//  ABank
//
//  首页“网点服务”与“我的”“我的网点”卡片展示的当前城市默认网点摘要。
//

import Foundation

nonisolated struct BranchCardSummary: Equatable {
    let branchID: String
    let name: String
    let status: String
    let distanceText: String
    let address: String

    static func make(cityID: String, at time: Date, dates: BankingDateContext) -> BranchCardSummary {
        let branch = BranchCatalog.defaultBranch(inCity: cityID)
        return BranchCardSummary(
            branchID: branch.id,
            name: branch.name,
            status: BranchSchedule.openState(of: branch, at: time, dates: dates).title,
            distanceText: "\(branch.distanceMeters)米",
            address: branch.address
        )
    }
}
