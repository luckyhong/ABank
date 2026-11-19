//
//  WealthModels.swift
//  ABank
//

import UIKit

struct WealthGridItem {
    let title: String
    let imageName: String
    let systemIcon: String
    var featureID: FeatureID? = nil
}

struct WealthGreeting {
    let message: String
    let loginTitle: String
}

struct WealthHotspot {
    let tag: String
    let headline: String
}

struct WealthProductTab {
    let title: String
    let product: WealthProduct
}

struct WealthDepositItem {
    let name: String
    let rate: String
    let rateLabel: String
    let term: String
    let minPurchase: String
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
    let greeting: WealthGreeting
    let gridItems: [WealthGridItem]
    let hotspot: WealthHotspot
    let productTabs: [WealthProductTab]
    let spareMoneyProduct: WealthProduct?
    let steadyProducts: [WealthProduct]
    let studyBanner: WealthStudyBanner
    let studyCards: [WealthStudyCard]
}
