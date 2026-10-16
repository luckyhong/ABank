import Foundation

nonisolated final class NewsFixtureProtocol: URLProtocol {
    static let lock = NSLock()
    static var mode = 0
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lock.lock(); let mode = Self.mode; Self.lock.unlock()
        let name = request.url!.deletingPathExtension().lastPathComponent
        if mode == 2 || (mode == 1 && name != "finance") {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        let xml = """
        <rss><channel><item><title>\(name)-\(mode)</title><link>https://www.chinanews.com.cn/test/\(name).shtml</link><description>测试</description><pubDate>Fri, 16 Oct 2026 11:00:00 +0800</pubDate></item></channel></rss>
        """
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type":"application/xml"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(xml.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
    static func setMode(_ mode: Int) { lock.lock(); Self.mode = mode; lock.unlock() }
}

@main nonisolated struct NewsDataChecks {
    static func main() async throws {
        let now = ISO8601DateFormatter().date(from: "2026-10-16T04:00:00Z")!
        let xml = """
        <?xml version="1.0"?><rss><channel>
        <item><title>R&D 与 黄金 &amp; ETF</title><link>http://www.chinanews.com.cn/a.shtml#top</link><description><![CDATA[<p>摘要 &amp; 内容</p><img src="https://i2.chinanews.com.cn/a.jpg">]]></description><pubDate>Fri, 16 Oct 2026 11:00:00 +0800</pubDate></item>
        <item><title>重复</title><link>https://www.chinanews.com.cn/a.shtml</link><pubDate>Fri, 16 Oct 2026 11:00:00 +0800</pubDate></item>
        <item><title>不安全链接</title><link>javascript:alert(1)</link><pubDate>Fri, 16 Oct 2026 11:00:00 +0800</pubDate></item>
        <item><title>未来新闻</title><link>https://www.chinanews.com.cn/future.shtml</link><pubDate>Fri, 16 Oct 2027 11:00:00 +0800</pubDate></item>
        </channel></rss>
        """
        let parser = NewsRSSParser(channel: .finance, now: now)
        let stories = try parser.parse(Data(xml.utf8))
        precondition(stories.count == 1)
        precondition(stories[0].title == "R&D 与 黄金 & ETF")
        precondition(stories[0].summary == "摘要 & 内容")
        precondition(stories[0].imageURL?.absoluteString == "https://i2.chinanews.com.cn/a.jpg")
        precondition(stories[0].url?.scheme == "https" && stories[0].url?.fragment == nil)
        let repeated = try parser.parse(Data(xml.utf8))
        precondition(repeated.count == 1, "Parser reuse must reset state")
        do { _ = try parser.parse(Data("<html>error</html>".utf8)); fatalError("HTML accepted as RSS") } catch {}
        do { _ = try parser.parse(Data(repeating: 32, count: 2_000_001)); fatalError("Oversized feed accepted") } catch {}
        let metadata = Data("vList.push('推荐|https://image.chinanews.com/other.jpg|/other.shtml');vList.push('正文|https://image.chinanews.com/right.jpg|/a.shtml');".utf8)
        precondition(NewsCoverMetadata.image(in: metadata, articleURL: stories[0].url!)?.absoluteString == "https://image.chinanews.com/right.jpg")
        precondition(NewsCoverMetadata.image(in: metadata, articleURL: URL(string: "https://example.com/missing.shtml")!) == nil)
        let snapshot = NewsSnapshot(stories: stories, updatedAt: now, origin: .live, unavailableChannels: 0)
        precondition(snapshot.filtered(category: "黄金").count == 1)
        precondition(snapshot.filtered(category: "服务").isEmpty)
        let demo = NewsDemoContent.snapshot(now: now)
        precondition(demo.stories == NewsDemoContent.snapshot(now: now.addingTimeInterval(1)).stories)
        precondition(demo.stories.first?.id != NewsDemoContent.snapshot(now: now.addingTimeInterval(86400)).stories.first?.id)
        precondition(demo.stories.allSatisfy { $0.isDemo && $0.publishedAt == nil && $0.url == nil })
        print("PASS parser: entities, CDATA, duplicates, invalid URLs, future dates, invalid documents; categories and daily demo")

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("ABankNewsChecks-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = directory.appendingPathComponent("feeds.json")
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [NewsFixtureProtocol.self]
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let repository = NewsRepository(session: session, cacheURL: cache, now: now)
        NewsFixtureProtocol.setMode(0)
        let live = try await repository.load(now: now)
        precondition(live.origin == .live && live.stories.count == 4 && live.unavailableChannels == 0)
        NewsFixtureProtocol.setMode(1)
        let partial = try await repository.load(now: now.addingTimeInterval(60))
        precondition(partial.stories.count == 4 && partial.unavailableChannels == 3)
        precondition(partial.stories.contains { $0.title == "finance-1" })
        NewsFixtureProtocol.setMode(2)
        let persisted = NewsRepository(session: session, cacheURL: cache, now: now.addingTimeInterval(120))
        let offline = try await persisted.load(now: now.addingTimeInterval(120))
        precondition(offline.origin == .cache && offline.stories.count == 4)
        let expired = try await persisted.load(now: now.addingTimeInterval(8 * 86400))
        precondition(expired.origin == .demo)
        let canceled = Task { try await repository.load(now: now) }
        canceled.cancel()
        do { _ = try await canceled.value; fatalError("Canceled refresh completed") } catch is CancellationError {} catch { throw error }
        print("PASS repository: live, partial source failure, persisted offline cache, expiry, cancellation")

        for path in CommandLine.arguments.dropFirst() {
            let bytes = try Data(contentsOf: URL(fileURLWithPath: path))
            let items = try NewsRSSParser(channel: .finance, now: Date()).parse(bytes)
            precondition(!items.isEmpty)
            print("PASS live feed fixture: \(URL(fileURLWithPath: path).lastPathComponent) — \(items.count) items")
        }
    }
}
