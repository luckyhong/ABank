import UIKit
import SnapKit

/// Preserve the label's layout and spoken text while displaying bundled artwork.
enum NewsResourceArtwork {
    static func apply(_ name: String, to label: UILabel) {
        guard let image = UIImage(named: name) else { return }
        label.attributedText = nil
        label.textColor = .clear
        let artwork = UIImageView(image: image)
        artwork.contentMode = .scaleAspectFit
        artwork.isUserInteractionEnabled = false
        artwork.isAccessibilityElement = false
        label.addSubview(artwork)
        artwork.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}
