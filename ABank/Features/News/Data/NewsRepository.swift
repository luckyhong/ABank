import Foundation

actor NewsRepository {
    private nonisolated struct CachedFeed: Codable {
        let channel: NewsChannel
        let fetchedAt: Date
        let stories: [NewsStory]
    }
    private nonisolated struct Cache: Codable {
        let version: Int
        let feeds: [CachedFeed]
    }
    private let session: URLSession
    private let cacheURL: URL
    private var feeds: [CachedFeed]
    private let cacheLifetime: TimeInterval = 7 * 86400

    init(session: URLSession = .shared, cacheURL: URL = NewsRepository.defaultCacheURL, now: Date = Date()) {
        self.session = session
        self.cacheURL = cacheURL
        self.feeds = Self.readCache(at: cacheURL, now: now)
    }

    static var defaultCacheURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ABankNews", isDirectory: true).appendingPathComponent("feeds-v1.json")
    }

    static func initialSnapshot(now: Date = Date()) -> NewsSnapshot {
        let feeds = readCache(at: defaultCacheURL, now: now)
        return snapshot(feeds, origin: .cache, failed: 0) ?? NewsDemoContent.snapshot(now: now)
    }

    func load(now: Date = Date()) async throws -> NewsSnapshot {
        let session = self.session
        let results = await withTaskGroup(of: (NewsChannel, [NewsStory]?).self) { group in
            for channel in NewsChannel.allCases {
                group.addTask {
                    do {
                        var request = URLRequest(url: channel.feedURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 12)
                        request.setValue("application/rss+xml, application/xml, text/xml", forHTTPHeaderField: "Accept")
                        let (data, response) = try await session.data(for: request)
                        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return (channel, nil) }
                        let stories = try NewsRSSParser(channel: channel, now: now).parse(data)
                        return (channel, Array(stories.prefix(80)))
                    } catch { return (channel, nil) }
                }
            }
            var values: [(NewsChannel, [NewsStory]?)] = []
            for await result in group { values.append(result) }
            return values
        }
        try Task.checkCancellation()
        var successes = 0
        feeds.removeAll { now.timeIntervalSince($0.fetchedAt) > cacheLifetime || $0.fetchedAt > now.addingTimeInterval(300) }
        for (channel, stories) in results {
            guard let stories, !stories.isEmpty else { continue }
            successes += 1
            let previous = Dictionary((feeds.first { $0.channel == channel }?.stories ?? []).map { ($0.id, $0.imageURL) }, uniquingKeysWith: { first, _ in first })
            let updated = stories.map { story -> NewsStory in
                var copy = story
                if copy.imageURL == nil { copy.imageURL = previous[story.id] ?? nil }
                return copy
            }
            feeds.removeAll { $0.channel == channel }
            feeds.append(CachedFeed(channel: channel, fetchedAt: now, stories: updated))
        }
        if successes > 0 { writeCache() }
        return Self.snapshot(feeds, origin: successes > 0 ? .live : .cache, failed: NewsChannel.allCases.count - successes)
            ?? NewsDemoContent.snapshot(now: now)
    }

    /// RSS is returned first. Optional covers are enriched afterward, at most four pages.
    func enrichVideoCovers(in snapshot: NewsSnapshot) async throws -> NewsSnapshot {
        let candidates = Array(snapshot.stories.filter { $0.channel == .video && $0.imageURL == nil && $0.url != nil }.prefix(4))
        guard !candidates.isEmpty else { return snapshot }
        let session = self.session
        let images = await withTaskGroup(of: (String, URL?).self) { group in
            for story in candidates {
                group.addTask {
                    guard let url = story.url else { return (story.id, nil) }
                    do {
                        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 6)
                        let (data, response) = try await session.data(for: request)
                        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return (story.id, nil) }
                        return (story.id, NewsCoverMetadata.image(in: data, articleURL: url))
                    } catch { return (story.id, nil) }
                }
            }
            var result: [String: URL] = [:]
            for await (id, url) in group { if let url { result[id] = url } }
            return result
        }
        try Task.checkCancellation()
        guard !images.isEmpty else { return snapshot }
        feeds = feeds.map { feed in
            CachedFeed(channel: feed.channel, fetchedAt: feed.fetchedAt, stories: feed.stories.map { story in
                var copy = story
                copy.imageURL = images[story.id] ?? story.imageURL
                return copy
            })
        }
        writeCache()
        let stories = snapshot.stories.map { story -> NewsStory in
            var copy = story
            copy.imageURL = images[story.id] ?? story.imageURL
            return copy
        }
        return NewsSnapshot(stories: stories, updatedAt: snapshot.updatedAt, origin: snapshot.origin, unavailableChannels: snapshot.unavailableChannels)
    }

    private func writeCache() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(Cache(version: 1, feeds: feeds)) else { return }
        try? FileManager.default.createDirectory(at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: cacheURL, options: .atomic)
    }

    private static func readCache(at url: URL, now: Date) -> [CachedFeed] {
        guard let data = try? Data(contentsOf: url), data.count <= 5_000_000 else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let cache = try? decoder.decode(Cache.self, from: data), cache.version == 1 else { return [] }
        return cache.feeds.filter { now.timeIntervalSince($0.fetchedAt) <= 7 * 86400 && $0.fetchedAt <= now.addingTimeInterval(300) }
    }

    private static func snapshot(_ feeds: [CachedFeed], origin: NewsSnapshot.Origin, failed: Int) -> NewsSnapshot? {
        var seen = Set<String>()
        var stories: [NewsStory] = []
        // Prefer the specific channel when a headline also appears in the rolling feed.
        for channel in [NewsChannel.video, .finance, .life, .general] {
            for feed in feeds where feed.channel == channel {
                for story in feed.stories where !story.isDemo && story.url != nil && seen.insert(story.id).inserted {
                    stories.append(story)
                }
            }
        }
        stories.sort {
            if $0.publishedAt == $1.publishedAt { return $0.id < $1.id }
            return ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast)
        }
        guard !stories.isEmpty, let fetchedAt = feeds.map(\.fetchedAt).max() else { return nil }
        return NewsSnapshot(stories: stories, updatedAt: fetchedAt, origin: origin, unavailableChannels: failed)
    }
}
