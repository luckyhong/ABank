import UIKit
import ImageIO

/// Cancels reused requests and downsamples publisher thumbnails before caching.
final class NewsRemoteImageView: UIImageView {
    private static let cache: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.totalCostLimit = 16 * 1024 * 1024
        return cache
    }()
    private var request: URLSessionDataTask?
    private var generation = UUID()

    func load(_ url: URL?, placeholder: UIImage? = nil) {
        request?.cancel()
        generation = UUID()
        let token = generation
        image = placeholder
        guard let url = url.flatMap({ NewsRSSParser.safeURL($0.absoluteString) }) else { return }
        if let cached = Self.cache.object(forKey: url as NSURL) { image = cached; return }
        let query = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 10)
        request = URLSession.shared.dataTask(with: query) { [weak self] data, response, _ in
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  let data, data.count <= 8 * 1024 * 1024,
                  let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: 1000, kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary) else { return }
            let image = UIImage(cgImage: thumbnail)
            Self.cache.setObject(image, forKey: url as NSURL, cost: thumbnail.bytesPerRow * thumbnail.height)
            DispatchQueue.main.async {
                guard self?.generation == token else { return }
                self?.image = image
            }
        }
        request?.resume()
    }

    deinit { request?.cancel() }
}
