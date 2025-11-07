//
//  PromoBannerCell.swift
//  ABank
//
//  Created by 韩继宏 on 2025/11/07.
//

import UIKit

final class PromoBannerCell: UICollectionViewCell {
    static let reuseIdentifier = "PromoBannerCell"
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = UIColor.orange.withAlphaComponent(0.2)
        return imageView
    }()
    
    private var currentTask: URLSessionDataTask?
    private static var imageCache = NSCache<NSURL, UIImage>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.md),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.md),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.md),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.md)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        currentTask?.cancel()
        currentTask = nil
        imageView.image = nil
    }
    
    func configure(with item: PromoBannerItem) {
        if let imageName = item.localImageName, let image = UIImage(named: imageName) {
            imageView.image = image
            return
        }
        if let url = item.imageURL {
            if let cached = PromoBannerCell.imageCache.object(forKey: url as NSURL) {
                imageView.image = cached
                return
            }
            currentTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let self = self, let data = data, let image = UIImage(data: data) else { return }
                PromoBannerCell.imageCache.setObject(image, forKey: url as NSURL)
                DispatchQueue.main.async {
                    self.imageView.image = image
                }
            }
            currentTask?.resume()
        }
    }
}


