//
//  LifeModels.swift
//  ABank
//

import UIKit

struct LifeBannerItem {
    let title: String
    let subtitle: String
    let actionTitle: String
    let backgroundColor: UIColor
    let accentColor: UIColor
    let systemIcon: String
    let isAd: Bool
}

struct LifeGridItem {
    let title: String
    let systemIcon: String
    let tintColor: UIColor
}

struct LifeActivityCard {
    let title: String
    let subtitle: String
    let backgroundColor: UIColor
    let systemIcon: String
    let isAd: Bool
}

struct LifePromoBanner {
    let title: String
    let subtitle: String
    let backgroundColor: UIColor
    let systemIcon: String
    let isAd: Bool
}

struct LifeFeedItem {
    let title: String
    let subtitle: String
    let imageBackground: UIColor
    let imageHeight: CGFloat
    let systemIcon: String
    let iconTint: UIColor
    let isAd: Bool
}

struct LifePageData {
    let city: String
    let searchPlaceholders: [String]
    let banners: [LifeBannerItem]
    let gridPages: [[LifeGridItem]]
    let colorfulFeatured: LifeActivityCard
    let colorfulSides: [LifeActivityCard]
    let promoBanner: LifePromoBanner
    let feedItems: [LifeFeedItem]
    let loadFinishedText: String
}
