import UIKit

extension UIImage {
    /// Use the imported artwork without losing its colors; SF Symbols remain a fallback.
    static func abankAsset(_ name: String, fallback: String,
                           renderingMode: UIImage.RenderingMode = .alwaysOriginal) -> UIImage? {
        if let image = UIImage(named: name) {
            return image.withRenderingMode(renderingMode)
        }
        return UIImage(systemName: fallback)
    }
}
