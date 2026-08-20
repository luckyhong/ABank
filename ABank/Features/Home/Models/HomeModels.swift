//
//  HomeModels.swift
//  ABank
//

import UIKit

struct HomeShortcutItem {
    let title: String
    let systemIcon: String
    let backgroundColor: UIColor
}

struct HomeGridItem {
    let title: String
    let systemIcon: String
    let badge: String?
}

struct HomeNoticeItem {
    let tag: String
    let text: String
}

struct HomeHeroBannerItem {
    let title: String
    let subtitle: String
    let actionTitle: String
    let isAd: Bool
}

struct HomePromoBannerItem {
    let title: String
    let subtitle: String
    let tone: PromoTone

    enum PromoTone {
        case gold
        case peach
        case mint
    }
}

struct HomeWealthFeaturedItem {
    let title: String
    let tag: String
    let subtitle: String
    let highlightValue: String
    let highlightLabel: String
    let actionTitle: String
}

struct HomeWealthSideItem {
    let title: String
    let tag: String
    let subtitle: String
    let actionTitle: String
}

struct HomeMarketQuote {
    let name: String
    let value: String
}

struct HomeActivityFeaturedItem {
    let title: String
    let subtitle: String
    let isAd: Bool
}

struct HomeActivitySideItem {
    let title: String
    let subtitle: String
    let actionTitle: String
    let isAd: Bool
}

struct HomePensionServiceItem {
    let title: String
    let systemIcon: String
}

struct HomeBranchInfo {
    let name: String
    let status: String
    let distance: String
    let address: String
    let services: [HomeBranchServiceItem]
}

struct HomeBranchServiceItem {
    let title: String
    let systemIcon: String
}

struct HomeInfoMarketItem {
    let title: String
    let source: String
    let summary: String
}

struct HomeInfoVideoItem {
    let title: String
    let caption: String
    let headline: String
}

struct HomeConsumerProtectionItem {
    let title: String
    let subtitle: String
    let backgroundColor: UIColor
}

struct HomePageData {
    let searchPlaceholders: [String]
    let messageBadge: Int
    let heroBanners: [HomeHeroBannerItem]
    let shortcuts: [HomeShortcutItem]
    let gridItems: [HomeGridItem]
    let notices: [HomeNoticeItem]
    let promoBanners: [HomePromoBannerItem]
    let wealthFeatured: HomeWealthFeaturedItem
    let wealthSides: [HomeWealthSideItem]
    let marketQuotes: [HomeMarketQuote]
    let activityFeatured: HomeActivityFeaturedItem
    let activitySides: [HomeActivitySideItem]
    let pensionSlogan: String
    let pensionSubtitle: String
    let pensionServices: [HomePensionServiceItem]
    let branch: HomeBranchInfo
    let infoMarket: HomeInfoMarketItem
    let infoVideos: [HomeInfoVideoItem]
    let consumerProtection: [HomeConsumerProtectionItem]
}
