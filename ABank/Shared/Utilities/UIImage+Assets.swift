import UIKit

extension UIImage {
    /// Use the imported artwork without losing its colors; SF Symbols remain a fallback.
    static func abankAsset(_ name: String, fallback: String,
                           renderingMode: UIImage.RenderingMode = .alwaysOriginal,
                           pointSize: CGFloat? = nil) -> UIImage? {
        if let image = UIImage(named: name) {
            guard let pointSize else { return image.withRenderingMode(renderingMode) }
            let size = CGSize(width: pointSize, height: pointSize)
            let ratio = min(pointSize / image.size.width, pointSize / image.size.height)
            let artworkSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
            let origin = CGPoint(x: (pointSize - artworkSize.width) / 2, y: (pointSize - artworkSize.height) / 2)
            let format = UIGraphicsImageRendererFormat()
            format.scale = image.scale
            return UIGraphicsImageRenderer(size: size, format: format).image { _ in
                image.draw(in: CGRect(origin: origin, size: artworkSize))
            }.withRenderingMode(renderingMode)
        }
        if let pointSize {
            return UIImage(systemName: fallback, withConfiguration: UIImage.SymbolConfiguration(pointSize: pointSize))
        }
        return UIImage(systemName: fallback)
    }
}
