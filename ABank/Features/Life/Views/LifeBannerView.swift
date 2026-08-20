//
//  LifeBannerView.swift
//  ABank
//

import UIKit
import SnapKit

final class LifeBannerView: UIView {

    private let collectionView: UICollectionView
    private let pageControl = UIPageControl()
    private var items: [LifeBannerItem] = []
    private var timer: Timer?
    private var currentIndex = 0

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { timer?.invalidate() }

    func configure(with items: [LifeBannerItem]) {
        self.items = items
        pageControl.numberOfPages = items.count
        pageControl.isHidden = items.count <= 1
        collectionView.reloadData()
        restartTimer()
    }

    private func setupUI() {
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(LifeBannerCell.self, forCellWithReuseIdentifier: LifeBannerCell.reuseId)
        collectionView.layer.cornerRadius = CornerRadius.lg
        collectionView.clipsToBounds = true

        pageControl.currentPageIndicatorTintColor = .abankOrange
        pageControl.pageIndicatorTintColor = UIColor.abankOrange.withAlphaComponent(0.3)
        pageControl.transform = CGAffineTransform(scaleX: 0.65, y: 0.65)

        addSubview(collectionView)
        addSubview(pageControl)
        collectionView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(130)
            make.bottom.equalToSuperview()
        }
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(collectionView.snp.bottom).offset(-6)
        }
    }

    private func restartTimer() {
        timer?.invalidate()
        guard items.count > 1 else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            guard let self, self.items.count > 1 else { return }
            self.currentIndex = (self.currentIndex + 1) % self.items.count
            self.collectionView.scrollToItem(
                at: IndexPath(item: self.currentIndex, section: 0),
                at: .centeredHorizontally,
                animated: true
            )
            self.pageControl.currentPage = self.currentIndex
        }
    }
}

extension LifeBannerView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LifeBannerCell.reuseId, for: indexPath) as! LifeBannerCell
        cell.configure(with: items[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        currentIndex = Int(round(scrollView.contentOffset.x / max(scrollView.bounds.width, 1)))
        pageControl.currentPage = currentIndex
        restartTimer()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        timer?.invalidate()
    }
}

private final class LifeBannerCell: UICollectionViewCell {
    static let reuseId = "LifeBannerCell"

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let actionButton = UILabel()
    private let iconView = UIImageView()
    private let adTag = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        subtitleLabel.font = .systemFont(ofSize: 14)
        actionButton.font = .systemFont(ofSize: 12, weight: .medium)
        actionButton.textAlignment = .center
        actionButton.layer.cornerRadius = 14
        actionButton.clipsToBounds = true
        iconView.contentMode = .scaleAspectFit
        adTag.text = "【广告】"
        adTag.font = .systemFont(ofSize: 9)
        adTag.textColor = .abankTextTertiary
        [titleLabel, subtitleLabel, actionButton, iconView, adTag].forEach { contentView.addSubview($0) }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(24)
            make.trailing.lessThanOrEqualTo(iconView.snp.leading).offset(-8)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
        }
        actionButton.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(subtitleLabel.snp.bottom).offset(10)
            make.height.equalTo(28)
            make.width.greaterThanOrEqualTo(96)
        }
        iconView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(56)
        }
        adTag.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(8)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with item: LifeBannerItem) {
        contentView.backgroundColor = item.backgroundColor
        titleLabel.text = item.title
        titleLabel.textColor = item.accentColor
        subtitleLabel.text = item.subtitle
        subtitleLabel.textColor = item.accentColor
        actionButton.text = item.actionTitle
        actionButton.textColor = item.accentColor
        actionButton.backgroundColor = UIColor.white.withAlphaComponent(0.85)
        actionButton.layer.borderWidth = 0.6
        actionButton.layer.borderColor = item.accentColor.cgColor
        iconView.image = UIImage(systemName: item.systemIcon)
        iconView.tintColor = item.accentColor.withAlphaComponent(0.85)
        adTag.isHidden = !item.isAd
    }
}
