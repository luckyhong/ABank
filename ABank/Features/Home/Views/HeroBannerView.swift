//
//  HeroBannerView.swift
//  ABank
//

import UIKit
import SnapKit

final class HeroBannerView: UIView {

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

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let actionLabel = UILabel()
    private let artContainer = UIView()
    private let phoneView = UIView()
    private let cardView = UIView()
    private let coin1 = UIView()
    private let coin2 = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .abankOrangeDeep
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        subtitleLabel.textColor = .abankOrangeDeep
        actionLabel.font = .systemFont(ofSize: 10, weight: .medium)
        actionLabel.textColor = .abankOrangeDeep
        actionLabel.backgroundColor = UIColor.white.withAlphaComponent(0.85)
        actionLabel.textAlignment = .center
        actionLabel.layer.cornerRadius = 10
        actionLabel.layer.masksToBounds = true
        actionLabel.layer.borderWidth = 0.6
        actionLabel.layer.borderColor = UIColor.abankOrangeDeep.cgColor

        phoneView.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        phoneView.layer.cornerRadius = 8
        cardView.backgroundColor = UIColor(red: 0.2, green: 0.55, blue: 0.95, alpha: 1)
        cardView.layer.cornerRadius = 4
        coin1.backgroundColor = UIColor(red: 1, green: 0.8, blue: 0.2, alpha: 1)
        coin1.layer.cornerRadius = 10
        coin2.backgroundColor = UIColor(red: 1, green: 0.72, blue: 0.15, alpha: 1)
        coin2.layer.cornerRadius = 8

        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(actionLabel)
        contentView.addSubview(artContainer)
        artContainer.addSubview(phoneView)
        artContainer.addSubview(cardView)
        artContainer.addSubview(coin1)
        artContainer.addSubview(coin2)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(28)
            make.trailing.lessThanOrEqualTo(artContainer.snp.leading).offset(-8)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
        }
        actionLabel.snp.makeConstraints { make in
            make.leading.equalTo(subtitleLabel.snp.trailing).offset(8)
            make.centerY.equalTo(subtitleLabel)
            make.height.equalTo(20)
            make.width.greaterThanOrEqualTo(76)
        }
        artContainer.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview().offset(-8)
            make.width.equalTo(110)
            make.height.equalTo(90)
        }
        phoneView.snp.makeConstraints { make in
            make.leading.bottom.equalToSuperview()
            make.width.equalTo(48)
            make.height.equalTo(72)
        }
        cardView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
            make.width.equalTo(54)
            make.height.equalTo(34)
        }
        coin1.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.trailing.equalToSuperview().offset(-18)
            make.size.equalTo(20)
        }
        coin2.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-6)
            make.trailing.equalToSuperview()
            make.size.equalTo(16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with item: HomeHeroBannerItem) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        actionLabel.text = item.actionTitle
    }
}
