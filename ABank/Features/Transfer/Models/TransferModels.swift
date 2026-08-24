//
//  TransferModels.swift
//  ABank
//

import Foundation

struct TransferPageData {
    let noticeText: String
    let primaryActions: [TransferPrimaryAction]
    let secondaryActions: [TransferSecondaryAction]
    let functionItems: [TransferFunctionItem]
    let recentPartners: [TransferPartner]
}

struct TransferPrimaryAction {
    let title: String
    let systemIcon: String
    let badge: String?
}

struct TransferSecondaryAction {
    let title: String
    let systemIcon: String
}

struct TransferFunctionItem {
    let title: String
    let systemIcon: String
}

struct TransferAccount {
    let id: String
    let bankName: String
    let maskedNumber: String
    let bankColorHex: String
    let bankSymbol: String
}

struct TransferPartner {
    let id: String
    let name: String
    let avatarSystemIcon: String?
    let avatarTintHex: String?
    /// 单账户时直接展示；多账户时可展开
    let accounts: [TransferAccount]
    let lastTransferDate: String?
    var isExpanded: Bool

    var accountCount: Int { accounts.count }
    var isMultiAccount: Bool { accounts.count > 1 }

    var primarySubtitle: String? {
        guard let account = accounts.first else { return nil }
        return "\(account.bankName)(\(account.maskedNumber))"
    }
}
