//
//  PromoBannerView.swift
//  ABank
//
//  Created by 韩继宏 on 2025/11/06.
//

import UIKit
import SnapKit

struct PromoBannerItem {
    let imageURL: URL?
    let localImageName: String?
    
    init(imageURL: URL) {
        self.imageURL = imageURL
        self.localImageName = nil
    }
    
    init(localImageName: String) {
        self.localImageName = localImageName
        self.imageURL = nil
    }
}

final class PromoBannerView: UIView {
    private let collectionView: UICollectionView
    private let pageControl = UIPageControl()
    private var items: [PromoBannerItem] = []
    private var autoScrollTimer: Timer?
    private var currentIndex: Int = 0
    
    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    deinit {
        autoScrollTimer?.invalidate()
    }
    
    func configure(with items: [PromoBannerItem]) {
        self.items = items
        pageControl.numberOfPages = items.count
        pageControl.isHidden = items.count <= 1
        collectionView.reloadData()
        resetAutoScroll()
    }
    
    private func setupUI() {
        layer.cornerRadius = 12
        layer.masksToBounds = true
        backgroundColor = .abankCardBackground
        
        collectionView.register(PromoBannerCell.self, forCellWithReuseIdentifier: PromoBannerCell.reuseIdentifier)
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(160)
        }
        
        pageControl.currentPageIndicatorTintColor = .abankPrimary
        pageControl.pageIndicatorTintColor = UIColor.abankTextTertiary.withAlphaComponent(0.3)
        pageControl.addTarget(self, action: #selector(pageControlChanged(_:)), for: .valueChanged)
        addSubview(pageControl)
        pageControl.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-Spacing.sm)
            make.centerX.equalToSuperview()
        }
    }
    
    private func resetAutoScroll() {
        autoScrollTimer?.invalidate()
        guard items.count > 1 else { return }
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.scrollToNext()
        }
    }
    
    private func scrollToNext() {
        guard items.count > 1 else { return }
        currentIndex = (currentIndex + 1) % items.count
        let indexPath = IndexPath(item: currentIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        pageControl.currentPage = currentIndex
    }
    
    @objc private func pageControlChanged(_ sender: UIPageControl) {
        let index = sender.currentPage
        currentIndex = index
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        resetAutoScroll()
    }
}

extension PromoBannerView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PromoBannerCell.reuseIdentifier, for: indexPath) as? PromoBannerCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: items[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        autoScrollTimer?.invalidate()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / max(scrollView.bounds.width, 1)))
        currentIndex = page
        pageControl.currentPage = page
        resetAutoScroll()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / max(scrollView.bounds.width, 1)))
        currentIndex = page
        pageControl.currentPage = page
    }
}


