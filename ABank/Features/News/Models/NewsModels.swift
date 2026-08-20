//
//  NewsModels.swift
//  ABank
//

import UIKit

enum NewsPrimaryTab: Int, CaseIterable {
    case recommend
    case follow

    var title: String {
        switch self {
        case .recommend: return "推荐"
        case .follow: return "关注"
        }
    }
}

struct NewsHeroBannerItem {
    let tag: String
    let title: String
    let subtitle: String
    let backgroundColor: UIColor
    let accentColor: UIColor
    let systemIcon: String
}

struct NewsFlashItem {
    let time: String
    let headline: String
}

struct NewsVideoItem {
    let title: String
    let overlayTitle: String
    let backgroundColor: UIColor
    let systemIcon: String
    let iconTint: UIColor
}

enum NewsHotBadge: String {
    case hot = "热"
    case new = "新"
}

struct NewsHotRankItem {
    let rank: Int
    let title: String
    let badge: NewsHotBadge?
}

struct NewsInteractiveTopic {
    let question: String
    let participantCount: Int
    let description: String
    let options: [String]
}

struct NewsFollowSuggestion {
    let name: String
    let systemIcon: String
    let tintColor: UIColor
}

struct NewsTrendingItem {
    let title: String
}

struct NewsPKPoll {
    let question: String
    let participantCount: Int
    let leftOption: String
    let rightOption: String
}

struct NewsArticleItem: Equatable {
    let id: String
    let title: String
    let source: String
    let readCount: Int
    let date: String
    let thumbnailBackground: UIColor
    let systemIcon: String
    let iconTint: UIColor
}

struct NewsFeedBannerItem: Equatable {
    let id: String
    let title: String
    let subtitle: String?
    let backgroundColor: UIColor
    let systemIcon: String
    let iconTint: UIColor
}

struct NewsFeedTopicItem: Equatable {
    let id: String
    let tag: String
    let title: String
    let bannerTitle: String
    let bannerSubtitle: String?
    let backgroundColor: UIColor
    let systemIcon: String
    let iconTint: UIColor
}

struct NewsFeedStripItem: Equatable {
    let id: String
    let brand: String
    let headline: String
    let brandColor: UIColor
}

struct NewsFeedVideoItem: Equatable {
    let id: String
    let title: String
    let backgroundColor: UIColor
    let systemIcon: String
    let iconTint: UIColor
}

enum NewsFeedEntry: Equatable {
    case article(NewsArticleItem)
    case banner(NewsFeedBannerItem)
    case topic(NewsFeedTopicItem)
    case video(NewsFeedVideoItem)
    case strip(NewsFeedStripItem)

    var id: String {
        switch self {
        case .article(let item): return item.id
        case .banner(let item): return item.id
        case .topic(let item): return item.id
        case .video(let item): return item.id
        case .strip(let item): return item.id
        }
    }
}

struct NewsPageData {
    let searchPlaceholders: [String]
    let messageBadge: Int
    let categories: [String]
    let heroBanners: [NewsHeroBannerItem]
    let flashNews: NewsFlashItem
    let hotVideos: [NewsVideoItem]
    let hotRankItems: [NewsHotRankItem]
    let interactiveTopic: NewsInteractiveTopic
    let followSuggestions: [NewsFollowSuggestion]
    let trendingItems: [NewsTrendingItem]
    let pkPoll: NewsPKPoll
    let initialFeed: [NewsFeedEntry]
    let totalFeedPages: Int
}

struct NewsFeedPageResult {
    let items: [NewsFeedEntry]
    let hasMore: Bool
}
