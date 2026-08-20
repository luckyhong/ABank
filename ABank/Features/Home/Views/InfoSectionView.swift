//
//  InfoSectionView.swift
//  ABank
//

import UIKit
import SnapKit

final class InfoSectionView: UIView {

    private let header = SectionHeaderView(title: "资讯")
    private let marketCard = UIView()
    private let videoCard = UIView()
    private let marketTitle = UILabel()
    private let marketSourceIcon = UIView()
    private let marketSource = UILabel()
    private let marketSummary = UILabel()
    private let marketArt = UIImageView(image: UIImage(systemName: "chart.bar.fill"))
    private let videoTag = UILabel()
    private let videoTitle = UILabel()
    private let videoThumb = UIView()
    private let videoHeadline = UILabel()
    private let videoCaption = UILabel()
    private let videoPageControl = UIPageControl()
    private var videos: [HomeInfoVideoItem] = []
    private var videoIndex = 0
    private var timer: Timer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        timer?.invalidate()
    }

    func configure(market: HomeInfoMarketItem, videos: [HomeInfoVideoItem]) {
        marketTitle.text = market.title
        marketSource.text = market.source
        marketSummary.text = market.summary
        self.videos = videos
        videoPageControl.numberOfPages = videos.count
        videoPageControl.isHidden = videos.count <= 1
        applyVideo(at: 0)
        restartTimer()
    }

    private func setupUI() {
        marketCard.backgroundColor = UIColor(red: 1.0, green: 0.96, blue: 0.93, alpha: 1)
        marketCard.layer.cornerRadius = CornerRadius.md
        videoCard.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.96, alpha: 1)
        videoCard.layer.cornerRadius = CornerRadius.md

        marketTitle.font = .systemFont(ofSize: 16, weight: .bold)
        marketTitle.textColor = .abankOrangeDeep
        marketSource.font = .systemFont(ofSize: 11, weight: .medium)
        marketSource.textColor = .abankTextSecondary
        marketSourceIcon.backgroundColor = UIColor.abankOrange.withAlphaComponent(0.15)
        marketSourceIcon.layer.cornerRadius = 8
        let sourceGlyph = UIImageView(image: UIImage(systemName: "newspaper.fill"))
        sourceGlyph.tintColor = .abankOrange
        sourceGlyph.contentMode = .scaleAspectFit
        marketSourceIcon.addSubview(sourceGlyph)
        sourceGlyph.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(10)
        }
        marketSummary.font = .systemFont(ofSize: 12)
        marketSummary.textColor = .abankTextPrimary
        marketSummary.numberOfLines = 3
        marketArt.tintColor = .abankOrange
        marketArt.contentMode = .scaleAspectFit

        videoTag.text = "视频"
        videoTag.font = .systemFont(ofSize: 10, weight: .bold)
        videoTag.textColor = .white
        videoTag.backgroundColor = .abankOrangeDeep
        videoTag.textAlignment = .center
        videoTag.layer.cornerRadius = 3
        videoTag.layer.masksToBounds = true

        videoTitle.font = .systemFont(ofSize: 14, weight: .semibold)
        videoTitle.textColor = .abankTextPrimary
        videoThumb.backgroundColor = UIColor(red: 0.35, green: 0.28, blue: 0.15, alpha: 1)
        videoThumb.layer.cornerRadius = 8
        videoHeadline.font = .systemFont(ofSize: 13, weight: .bold)
        videoHeadline.textColor = .white
        videoHeadline.numberOfLines = 2
        videoCaption.font = .systemFont(ofSize: 11)
        videoCaption.textColor = .abankTextSecondary
        videoCaption.numberOfLines = 2
        videoPageControl.transform = CGAffineTransform(scaleX: 0.55, y: 0.55)
        videoPageControl.currentPageIndicatorTintColor = .abankTextSecondary
        videoPageControl.pageIndicatorTintColor = UIColor.abankTextTertiary.withAlphaComponent(0.35)

        addSubview(header)
        addSubview(marketCard)
        addSubview(videoCard)
        [marketTitle, marketSourceIcon, marketSource, marketSummary, marketArt].forEach { marketCard.addSubview($0) }
        [videoTag, videoTitle, videoThumb, videoCaption, videoPageControl].forEach { videoCard.addSubview($0) }
        videoThumb.addSubview(videoHeadline)

        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(24)
        }
        marketCard.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(12)
            make.leading.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.48)
            make.height.equalTo(168)
        }
        videoCard.snp.makeConstraints { make in
            make.top.bottom.equalTo(marketCard)
            make.trailing.equalToSuperview()
            make.leading.equalTo(marketCard.snp.trailing).offset(8)
        }

        marketTitle.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(12)
        }
        marketSourceIcon.snp.makeConstraints { make in
            make.top.equalTo(marketTitle.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(12)
            make.size.equalTo(16)
        }
        marketSource.snp.makeConstraints { make in
            make.centerY.equalTo(marketSourceIcon)
            make.leading.equalTo(marketSourceIcon.snp.trailing).offset(4)
            make.trailing.lessThanOrEqualToSuperview().offset(-12)
        }
        marketSummary.snp.makeConstraints { make in
            make.top.equalTo(marketSource.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
        }
        marketArt.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(12)
            make.size.equalTo(36)
        }

        videoTag.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(10)
            make.width.equalTo(30)
            make.height.equalTo(16)
        }
        videoTitle.snp.makeConstraints { make in
            make.leading.equalTo(videoTag.snp.trailing).offset(6)
            make.centerY.equalTo(videoTag)
            make.trailing.equalToSuperview().offset(-8)
        }
        videoThumb.snp.makeConstraints { make in
            make.top.equalTo(videoTag.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(10)
            make.height.equalTo(72)
        }
        videoHeadline.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
        videoCaption.snp.makeConstraints { make in
            make.top.equalTo(videoThumb.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(10)
        }
        videoPageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-2)
        }
    }

    private func applyVideo(at index: Int) {
        guard videos.indices.contains(index) else { return }
        videoIndex = index
        let item = videos[index]
        videoTitle.text = item.title
        videoHeadline.text = item.headline
        videoCaption.text = item.caption
        videoPageControl.currentPage = index
    }

    private func restartTimer() {
        timer?.invalidate()
        guard videos.count > 1 else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let next = (self.videoIndex + 1) % self.videos.count
            self.applyVideo(at: next)
        }
    }
}
