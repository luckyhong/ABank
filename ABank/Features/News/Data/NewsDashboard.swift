import UIKit

/// Adapt publisher metadata to the existing UI without synthetic market claims or metrics.
enum NewsDashboard {
    static let categories = ["热点", "服务", "三农", "基金", "黄金", "保险", "房产"]

    static func page(from snapshot: NewsSnapshot, followed: Set<String> = []) -> NewsPageData {
        let stories = snapshot.stories
        let finance = stories.filter { $0.channel == .finance }
        let lead = Array((finance.isEmpty ? stories.filter { $0.channel != .video } : finance).prefix(3))
        let videos = Array(stories.filter { $0.channel == .video }.prefix(4))
        let banners = lead.map { story -> NewsHeroBannerItem in
            var item = NewsHeroBannerItem(tag: story.isDemo ? "#每日知识" : "#最新资讯", title: story.title, subtitle: story.publisher + " · " + dateText(story.publishedAt), backgroundColor: .abankPrimaryDark, accentColor: .white, systemIcon: "newspaper")
            item.storyID = story.id
            item.imageURL = story.imageURL
            return item
        }
        let recent = snapshot.filtered(category: "热点")
        let first = recent.first
        let videoItems = videos.map { story -> NewsVideoItem in
            var item = NewsVideoItem(title: story.title, overlayTitle: "", backgroundColor: .abankSectionBackground, systemIcon: "play.rectangle", iconTint: .abankTextTertiary)
            item.storyID = story.id
            item.imageURL = story.imageURL
            return item
        }
        return NewsPageData(
            searchPlaceholders: ["搜索当前资讯", "基金", "黄金", "住房"], messageBadge: 0, categories: categories,
            heroBanners: banners, flashNews: NewsFlashItem(time: dateText(first?.publishedAt), headline: first?.title ?? "暂无资讯"),
            hotVideos: videoItems,
            hotRankItems: Array(recent.prefix(3)).enumerated().map { NewsHotRankItem(rank: $0.offset + 1, title: $0.element.title, badge: nil) },
            interactiveTopic: NewsInteractiveTopic(question: "今日想了解哪类金融知识？", participantCount: 0, description: "选择偏好，浏览相应资讯；仅保存在本机。", options: ["基金", "黄金", "房产"]),
            followSuggestions: [
                NewsFollowSuggestion(isFollowed: followed.contains("财经"), name: "财经资讯", systemIcon: "chart.bar", tintColor: .abankPrimary),
                NewsFollowSuggestion(isFollowed: followed.contains("服务"), name: "生活服务", systemIcon: "house", tintColor: .abankOrange),
                NewsFollowSuggestion(isFollowed: followed.contains("三农"), name: "三农观察", systemIcon: "leaf", tintColor: .abankTeal),
                NewsFollowSuggestion(isFollowed: followed.contains("房产"), name: "房产动态", systemIcon: "building.2", tintColor: .abankGold)
            ],
            trendingItems: Array(recent.prefix(3)).map { NewsTrendingItem(title: $0.title) },
            pkPoll: NewsPKPoll(question: "阅读偏好 · 今天更想看哪类内容？", participantCount: 0, leftOption: "财经资讯", rightOption: "生活服务"),
            initialFeed: Array(stories.prefix(20)).map { entry($0) }, totalFeedPages: max(1, (stories.count + 19) / 20)
        )
    }

    static func entry(_ story: NewsStory) -> NewsFeedEntry {
        var item = NewsArticleItem(id: story.id, title: story.title, source: story.publisher, readCount: 0, date: dateText(story.publishedAt), thumbnailBackground: .abankSectionBackground, systemIcon: "newspaper", iconTint: .abankTextTertiary)
        item.thumbnailURL = story.imageURL
        return .article(item)
    }

    static func dateText(_ date: Date?, now: Date = Date()) -> String {
        guard let date else { return "知识内容" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let sameDay = calendar.isDate(date, inSameDayAs: now)
        formatter.dateFormat = sameDay ? "HH:mm" : (calendar.isDate(date, equalTo: now, toGranularity: .year) ? "MM-dd HH:mm" : "yyyy-MM-dd")
        return formatter.string(from: date)
    }

    static func status(_ snapshot: NewsSnapshot) -> String {
        let stamp = dateText(snapshot.updatedAt)
        switch snapshot.origin {
        case .demo: return "离线学习示例 · 内容按日轮换 · 下拉重试"
        case .cache: return "离线缓存 · 上次更新 \(stamp) · 下拉重试"
        case .live:
            return "中国新闻网 · \(stamp)更新" + (snapshot.unavailableChannels > 0 ? " · 部分频道暂不可用" : " · 下拉刷新")
        }
    }
}
