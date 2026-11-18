import UIKit

struct LifeBannerItem: Equatable {
    let title: String
    let subtitle: String
    let actionTitle: String
    let backgroundColor: UIColor
    let accentColor: UIColor
    let artworkName: String
    let route: AppRoute
}

struct LifeGridItem {
    let title: String
    var imageName: String? = nil
    let systemIcon: String
    let tintColor: UIColor
    var featureID: FeatureID? = nil
    var route: AppRoute? = nil
}

struct LifeActivityCard: Equatable {
    let title: String
    let subtitle: String
    let backgroundColor: UIColor
    let artworkName: String
}

struct LifeFeedItem: Equatable {
    let title: String
    let subtitle: String
    let imageBackground: UIColor
    let imageAspectRatio: CGFloat
    let artworkName: String
    var route: AppRoute? = nil
}

struct LifePageData {
    let city: String
    let searchPlaceholders: [String]
    let banners: [LifeBannerItem]
    let gridPages: [[LifeGridItem]]
    let colorfulFeatured: LifeActivityCard
    let colorfulSides: [LifeActivityCard]
    let promoBanner: LifeActivityCard
    let feedItems: [LifeFeedItem]
}
