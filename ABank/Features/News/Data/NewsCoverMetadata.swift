import Foundation

/// Only accept the publisher's video-list entry whose path matches this story.
/// Do not use unrelated recommended images, advertising banners, or page logos.
nonisolated enum NewsCoverMetadata {
    static func image(in data: Data, articleURL: URL) -> URL? {
        guard data.count <= 1_000_000 else { return nil }
        let html = String(decoding: data, as: UTF8.self)
        guard let regex = try? NSRegularExpression(pattern: "vList\\.push\\(['\"]([^\\r\\n]+?)['\"]\\)") else { return nil }
        for match in regex.matches(in: html, range: NSRange(html.startIndex..., in: html)) {
            guard let range = Range(match.range(at: 1), in: html) else { continue }
            let fields = html[range].split(separator: "|", omittingEmptySubsequences: false)
            guard fields.count == 3,
                  let linked = URL(string: String(fields[2]), relativeTo: articleURL), linked.path == articleURL.path,
                  let image = NewsRSSParser.safeURL(String(fields[1])) else { continue }
            return image
        }
        return nil
    }
}
