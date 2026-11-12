//
//  HeroBannerView.swift
//  ABank
//

import UIKit
import SnapKit

final class HeroBannerView: UIView {
    var onItemTapped: ((Int) -> Void)?

    private let collectionView: UICollectionView
    private let pageControl = UIPageControl()
    private let adTag = AdTagLabel()
    private var items: [HomeHeroBannerItem] = []
    private var timer: Timer?
    private var currentIndex = 0

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        timer?.invalidate()
    }

    func configure(with items: [HomeHeroBannerItem]) {
        self.items = items
        pageControl.numberOfPages = items.count
        pageControl.isHidden = items.count <= 1
        adTag.isHidden = !(items.first?.isAd ?? false)
        collectionView.reloadData()
        restartTimer()
    }

    private func setupUI() {
        backgroundColor = .clear
        clipsToBounds = true

        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(HeroBannerCell.self, forCellWithReuseIdentifier: HeroBannerCell.reuseId)

        pageControl.currentPageIndicatorTintColor = .white
        pageControl.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.45)
        pageControl.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)

        addSubview(collectionView)
        addSubview(pageControl)
        addSubview(adTag)

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(148)
        }
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-28)
        }
        adTag.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-28)
        }
    }

    private func restartTimer() {
        timer?.invalidate()
        guard items.count > 1 else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { [weak self] _ in
            self?.scrollToNext()
        }
    }

    private func scrollToNext() {
        guard items.count > 1 else { return }
        currentIndex = (currentIndex + 1) % items.count
        collectionView.scrollToItem(at: IndexPath(item: currentIndex, section: 0), at: .centeredHorizontally, animated: true)
        pageControl.currentPage = currentIndex
        adTag.isHidden = !items[currentIndex].isAd
    }
}

extension HeroBannerView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HeroBannerCell.reuseId, for: indexPath) as! HeroBannerCell
        cell.configure(with: items[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) { onItemTapped?(indexPath.item) }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / max(scrollView.bounds.width, 1)))
        currentIndex = page
        pageControl.currentPage = page
        if items.indices.contains(page) {
            adTag.isHidden = !items[page].isAd
        }
        restartTimer()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        timer?.invalidate()
    }
}

private final class HeroBannerCell: UICollectionViewCell {
    static let reuseId = "HeroBannerCell"
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFit
        contentView.addSubview(imageView); contentView.addSubview(titleLabel)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 16, right: 16)) }
        titleLabel.font = .preferredFont(forTextStyle: .title2); titleLabel.numberOfLines = 0
        titleLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(20) }
        isAccessibilityElement = true; accessibilityTraits = .button
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(with item: HomeHeroBannerItem) {
        imageView.image = item.imageName.flatMap { UIImage(named: $0) }
        titleLabel.text = item.title + "\n" + item.subtitle
        titleLabel.isHidden = imageView.image != nil
        accessibilityLabel = item.title + "，" + item.subtitle + "，" + item.actionTitle
    }
}
