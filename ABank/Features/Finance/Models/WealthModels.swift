//
//  WealthModels.swift
//  ABank
//

import UIKit

struct WealthGridItem {
    let title: String
    let systemIcon: String
}

struct WealthGreeting {
    let message: String
    let loginTitle: String
}

struct WealthHotspot {
    let tag: String
    let headline: String
}

struct WealthFeaturedProduct {
    let name: String
    let yieldRate: String
    let yieldLabel: String
    let yieldDateRange: String
    let riskLevel: String
    let riskLabel: String
    let holdingPeriod: String
    let holdingLabel: String
    let actionTitle: String
    let disclaimer: String
    let isAd: Bool
}

struct WealthProductTab {
    let title: String
    let product: WealthFeaturedProduct
}

struct WealthSpareMoneyFeatured {
    let title: String
    let tag: String
    let descriptions: [String]
    let yieldRate: String
    let yieldLabel: String
    let actionTitle: String
}

struct WealthSpareMoneySide {
    let title: String
    let tag: String
    let subtitle: String
    let yieldPrefix: String?
    let yieldRate: String
    let yieldLabel: String
}

struct WealthSteadyProduct {
    let name: String
    let yieldRate: String
    let yieldLabel: String
    let yieldDateRange: String
    let holdingPeriod: String
    let purchaseInfo: String
    let isHot: Bool
    let disclaimer: String?
}

struct WealthFundItem {
    let name: String
    let yieldRate: String
    let yieldLabel: String
    let category: String
    let isSelected: Bool
}

struct WealthDepositItem {
    let name: String
    let rate: String
    let rateLabel: String
    let term: String
    let minPurchase: String
}

struct WealthBondIndex {
    let name: String
    let yieldRate: String
    let yieldLabel: String
    let indexValue: String
    let indexLabel: String
    let asOfDate: String
}

struct WealthStudyBanner {
    let title: String
    let brand: String
    let isAd: Bool
}

struct WealthStudyCard {
    let title: String
    let backgroundColor: UIColor
    let actionTitle: String
}

struct WealthPageData {
    let searchPlaceholder: String
    let messageBadge: Int
    let greeting: WealthGreeting
    let gridItems: [WealthGridItem]
    let hotspot: WealthHotspot
    let productTabs: [WealthProductTab]
    let spareMoneyFeatured: WealthSpareMoneyFeatured
    let spareMoneySides: [WealthSpareMoneySide]
    let steadyProducts: [WealthSteadyProduct]
    let fundItems: [WealthFundItem]
    let depositItems: [WealthDepositItem]
    let bondIndex: WealthBondIndex
    let studyBanner: WealthStudyBanner
    let studyCards: [WealthStudyCard]
}
