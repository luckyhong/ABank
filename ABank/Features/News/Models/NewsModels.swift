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
    var storyID: String? = nil
    var imageURL: URL? = nil
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
    var storyID: String? = nil
    var imageURL: URL? = nil
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
    var isFollowed: Bool = false
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
    let date: String
    let thumbnailBackground: UIColor
    let iconTint: UIColor
    let thumbnailURL: URL?
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
}
