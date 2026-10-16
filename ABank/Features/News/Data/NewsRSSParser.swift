import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

nonisolated final class NewsRSSParser: NSObject, XMLParserDelegate {
    private let channel: NewsChannel
    private let now: Date
    private var stories: [NewsStory] = []
    private var insideItem = false
    private var element = ""
    private var fields: [String: String] = [:]
    private var imageURL: URL?
    private var reachedRSS = false

    init(channel: NewsChannel, now: Date) {
        self.channel = channel
        self.now = now
    }

    func parse(_ data: Data) throws -> [NewsStory] {
        guard data.count <= 2_000_000 else { throw ParseError.invalidFeed }
        stories = []
        reachedRSS = false
        insideItem = false
        // Some public feeds contain literal ampersands (for example R&D).
        // Escape only invalid entity starts; preserve valid XML entities and CDATA.
        let normalized: Data
        if let text = String(data: data, encoding: .utf8) {
            let escaped = text.replacingOccurrences(of: "&(?!(?:amp|lt|gt|quot|apos|#\\d+|#x[0-9a-fA-F]+);)", with: "&amp;", options: .regularExpression)
            normalized = Data(escaped.utf8)
        } else { normalized = data }
        let parser = XMLParser(data: normalized)
        parser.shouldResolveExternalEntities = false
        parser.delegate = self
        guard parser.parse(), reachedRSS, !stories.isEmpty else { throw ParseError.invalidFeed }
        return stories
    }

    enum ParseError: Error { case invalidFeed }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {
        if elementName == "rss" { reachedRSS = true }
        if elementName == "item" {
            insideItem = true
            fields = [:]
            imageURL = nil
        }
        guard insideItem else { return }
        element = elementName
        if elementName == "media:thumbnail" || elementName == "media:content" || (elementName == "enclosure" && attributeDict["type"]?.hasPrefix("image/") == true) {
            imageURL = Self.safeURL(attributeDict["url"] ?? "") ?? imageURL
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if insideItem { fields[element, default: ""] += string }
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        if let value = String(data: CDATABlock, encoding: .utf8), insideItem { fields[element, default: ""] += value }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard elementName == "item" else { return }
        defer { insideItem = false }
        let title = Self.plainText(fields["title"] ?? "")
        guard !title.isEmpty, let url = Self.safeURL(fields["link"] ?? ""),
              let publishedAt = Self.date(fields["pubDate"] ?? ""), publishedAt <= now.addingTimeInterval(300) else { return }
        let description = fields["description"] ?? ""
        let story = NewsStory(id: url.absoluteString, title: String(title.prefix(220)), summary: String(Self.plainText(description).prefix(400)), publisher: "中国新闻网", channel: channel, publishedAt: publishedAt, url: url, imageURL: imageURL ?? Self.firstImage(in: description), isDemo: false)
        if !stories.contains(where: { $0.id == story.id }) { stories.append(story) }
    }

    static func safeURL(_ string: String) -> URL? {
        guard var components = URLComponents(string: string.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme),
              components.host != nil, components.user == nil, components.password == nil else { return nil }
        components.scheme = "https"
        components.fragment = nil
        return components.url
    }

    static func date(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for pattern in ["EEE, dd MMM yyyy HH:mm:ss Z", "EEE, d MMM yyyy HH:mm:ss Z", "yyyy-MM-dd HH:mm:ss"] {
            formatter.dateFormat = pattern
            formatter.timeZone = TimeZone(secondsFromGMT: 8 * 3600)
            if let date = formatter.date(from: string.trimmingCharacters(in: .whitespacesAndNewlines)) { return date }
        }
        return ISO8601DateFormatter().date(from: string)
    }

    static func plainText(_ text: String) -> String {
        let clean = text.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        let replacements = ["&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&#39;": "'", "&nbsp;": " "]
        let decoded = replacements.reduce(clean) { $0.replacingOccurrences(of: $1.key, with: $1.value) }
        return decoded.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func firstImage(in text: String) -> URL? {
        guard let regex = try? NSRegularExpression(pattern: "<img[^>]+src=[\"']([^\"']+)[\"']", options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return safeURL(String(text[range]))
    }
}
