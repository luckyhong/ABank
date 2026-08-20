//
//  NewsRecommendHeaderView.swift
//  ABank
//

import UIKit
import SnapKit

/// 推荐页顶部区域：轮播、7x24 快讯、热门视频、资讯热榜、互动话题
final class NewsRecommendHeaderView: UIView {

    private let heroBanner = NewsHeroBannerView()
    private let flashNews = NewsFlashNewsView()
    private let hotVideosHeader = SectionHeaderView(title: "热门视频")
    private let hotVideos = NewsHotVideosView()
    private let hotListHeader = SectionHeaderView(title: "资讯热榜")
    private let hotList = NewsHotListView()
    private let topicCard = NewsInteractiveTopicView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        banners: [NewsHeroBannerItem],
        flash: NewsFlashItem,
        videos: [NewsVideoItem],
        hotItems: [NewsHotRankItem],
        topic: NewsInteractiveTopic
    ) {
        heroBanner.configure(with: banners)
        flashNews.configure(with: flash)
        hotVideos.configure(with: videos)
        hotList.configure(with: hotItems)
        topicCard.configure(with: topic)
    }

    var onHotListTapped: (() -> Void)? {
        get { hotListHeader.onTap }
        set { hotListHeader.onTap = newValue }
    }

    var onHotVideosTapped: (() -> Void)? {
        get { hotVideosHeader.onTap }
        set { hotVideosHeader.onTap = newValue }
    }

    var onVideoTapped: ((Int) -> Void)? {
        get { hotVideos.onItemTapped }
        set { hotVideos.onItemTapped = newValue }
    }

    var onTopicOptionTapped: ((Int) -> Void)? {
        get { topicCard.onOptionTapped }
        set { topicCard.onOptionTapped = newValue }
    }

    private func setupUI() {
        backgroundColor = .white

        [heroBanner, flashNews, hotVideosHeader, hotVideos, hotListHeader, hotList, topicCard]
            .forEach { addSubview($0) }

        heroBanner.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        flashNews.snp.makeConstraints { make in
            make.top.equalTo(heroBanner.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        hotVideosHeader.snp.makeConstraints { make in
            make.top.equalTo(flashNews.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.height.equalTo(22)
        }
        hotVideos.snp.makeConstraints { make in
            make.top.equalTo(hotVideosHeader.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
        }
        hotListHeader.snp.makeConstraints { make in
            make.top.equalTo(hotVideos.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.height.equalTo(24)
        }
        hotList.snp.makeConstraints { make in
            make.top.equalTo(hotListHeader.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        topicCard.snp.makeConstraints { make in
            make.top.equalTo(hotList.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.bottom.equalToSuperview()
        }
    }
}

// MARK: - Hero Banner

final class NewsHeroBannerView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private let collectionView: UICollectionView
    private let pageControl = UIPageControl()
    private var items: [NewsHeroBannerItem] = []
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

    func configure(with items: [NewsHeroBannerItem]) {
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
        collectionView.register(NewsHeroBannerCell.self, forCellWithReuseIdentifier: NewsHeroBannerCell.reuseId)
        collectionView.layer.cornerRadius = CornerRadius.lg
        collectionView.clipsToBounds = true

        pageControl.currentPageIndicatorTintColor = UIColor(white: 0.35, alpha: 1)
        pageControl.pageIndicatorTintColor = UIColor(white: 0.82, alpha: 1)
        pageControl.transform = CGAffineTransform(scaleX: 0.55, y: 0.55)

        addSubview(collectionView)
        addSubview(pageControl)
        collectionView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(176)
        }
        pageControl.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.height.equalTo(10)
            make.bottom.equalToSuperview()
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

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: NewsHeroBannerCell.reuseId,
            for: indexPath
        ) as! NewsHeroBannerCell
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

private final class NewsHeroBannerCell: UICollectionViewCell {
    static let reuseId = "NewsHeroBannerCell"

    private let gradientLayer = CAGradientLayer()
    private let artContainer = UIView()
    private let houseIcon = UIImageView()
    private let coinLarge = UIView()
    private let coinSmall = UIView()
    private let tagLabel = UILabel()
    private let titleLabel = UILabel()
    private let bottomBar = UIView()
    private let subtitleLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.clipsToBounds = true
        gradientLayer.startPoint = CGPoint(x: 0.15, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.9, y: 1)
        contentView.layer.insertSublayer(gradientLayer, at: 0)

        houseIcon.image = UIImage(systemName: "house.fill")
        houseIcon.tintColor = UIColor(red: 0.92, green: 0.95, blue: 1.0, alpha: 0.95)
        houseIcon.contentMode = .scaleAspectFit

        coinLarge.backgroundColor = UIColor(red: 0.98, green: 0.78, blue: 0.28, alpha: 1)
        coinLarge.layer.cornerRadius = 18
        coinLarge.layer.borderWidth = 2
        coinLarge.layer.borderColor = UIColor(red: 0.90, green: 0.62, blue: 0.12, alpha: 1).cgColor

        coinSmall.backgroundColor = UIColor(red: 0.98, green: 0.84, blue: 0.38, alpha: 1)
        coinSmall.layer.cornerRadius = 12
        coinSmall.layer.borderWidth = 1.5
        coinSmall.layer.borderColor = UIColor(red: 0.90, green: 0.68, blue: 0.18, alpha: 1).cgColor

        tagLabel.font = .systemFont(ofSize: 11, weight: .medium)
        tagLabel.textColor = .white
        tagLabel.textAlignment = .center
        tagLabel.backgroundColor = UIColor(red: 1.0, green: 0.52, blue: 0.18, alpha: 1)
        tagLabel.layer.cornerRadius = 4
        tagLabel.clipsToBounds = true

        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 1

        bottomBar.backgroundColor = UIColor(white: 0.12, alpha: 0.38)

        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .white
        subtitleLabel.numberOfLines = 1
        subtitleLabel.lineBreakMode = .byTruncatingTail

        chevron.tintColor = UIColor.white.withAlphaComponent(0.9)
        chevron.contentMode = .scaleAspectFit

        contentView.addSubview(artContainer)
        artContainer.addSubview(houseIcon)
        artContainer.addSubview(coinLarge)
        artContainer.addSubview(coinSmall)
        contentView.addSubview(tagLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(bottomBar)
        bottomBar.addSubview(subtitleLabel)
        bottomBar.addSubview(chevron)

        artContainer.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.top.equalToSuperview().offset(18)
            make.width.equalTo(120)
            make.height.equalTo(108)
        }
        houseIcon.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(-8)
            make.top.equalToSuperview()
            make.size.equalTo(72)
        }
        coinLarge.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.bottom.equalToSuperview().offset(-8)
            make.size.equalTo(36)
        }
        coinSmall.snp.makeConstraints { make in
            make.trailing.equalTo(coinLarge.snp.leading).offset(8)
            make.bottom.equalToSuperview().offset(-4)
            make.size.equalTo(24)
        }
        tagLabel.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(14)
            make.height.equalTo(22)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.top.equalTo(tagLabel.snp.bottom).offset(12)
            make.trailing.lessThanOrEqualTo(artContainer.snp.leading).offset(8)
        }
        bottomBar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(34)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(chevron.snp.leading).offset(-6)
        }
        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.size.equalTo(11)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = contentView.bounds
    }

    func configure(with item: NewsHeroBannerItem) {
        gradientLayer.colors = [
            item.backgroundColor.cgColor,
            item.backgroundColor.withAlphaComponent(0.85).cgColor,
            UIColor(red: 0.55, green: 0.78, blue: 0.95, alpha: 1).cgColor
        ]
        tagLabel.text = "  \(item.tag)  "
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        houseIcon.image = UIImage(systemName: item.systemIcon)
    }
}

// MARK: - 7x24 快讯

final class NewsFlashNewsView: UIView {

    private let timeLabel = UILabel()
    private let headlineLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with item: NewsFlashItem) {
        timeLabel.text = item.time
        headlineLabel.text = item.headline
    }

    private func setupUI() {
        backgroundColor = .clear

        let logoLabel = UILabel()
        let logo = NSMutableAttributedString()
        logo.append(NSAttributedString(
            string: "7x24",
            attributes: [
                .font: UIFont.systemFont(ofSize: 15, weight: .heavy),
                .foregroundColor: UIColor(red: 0.92, green: 0.55, blue: 0.12, alpha: 1)
            ]
        ))
        logo.append(NSAttributedString(
            string: " 快讯",
            attributes: [
                .font: UIFont.systemFont(ofSize: 15, weight: .heavy),
                .foregroundColor: UIColor.abankTextPrimary
            ]
        ))
        logoLabel.attributedText = logo

        timeLabel.font = .systemFont(ofSize: 13)
        timeLabel.textColor = .abankTextSecondary

        headlineLabel.font = .systemFont(ofSize: 13)
        headlineLabel.textColor = .abankTextPrimary
        headlineLabel.numberOfLines = 1
        headlineLabel.lineBreakMode = .byTruncatingTail

        addSubview(logoLabel)
        addSubview(timeLabel)
        addSubview(headlineLabel)

        logoLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        timeLabel.snp.makeConstraints { make in
            make.leading.equalTo(logoLabel.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
        }
        headlineLabel.snp.makeConstraints { make in
            make.leading.equalTo(timeLabel.snp.trailing).offset(6)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        snp.makeConstraints { make in
            make.height.equalTo(40)
        }
    }
}

// MARK: - 热门视频

final class NewsHotVideosView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    var onItemTapped: ((Int) -> Void)?

    private let collectionView: UICollectionView
    private var items: [NewsVideoItem] = []

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: Spacing.md, bottom: 0, right: Spacing.md)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with items: [NewsVideoItem]) {
        self.items = items
        collectionView.reloadData()
    }

    private func setupUI() {
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(NewsVideoCell.self, forCellWithReuseIdentifier: NewsVideoCell.reuseId)
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(156)
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewsVideoCell.reuseId, for: indexPath) as! NewsVideoCell
        cell.configure(with: items[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 152, height: 156)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onItemTapped?(indexPath.item)
    }
}

private final class NewsVideoCell: UICollectionViewCell {
    static let reuseId = "NewsVideoCell"

    private let thumbView = UIView()
    private let overlayBar = UIView()
    private let overlayLabel = UILabel()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        thumbView.layer.cornerRadius = CornerRadius.sm
        thumbView.clipsToBounds = true

        overlayBar.backgroundColor = UIColor(red: 0.08, green: 0.62, blue: 0.52, alpha: 0.92)

        overlayLabel.font = .systemFont(ofSize: 12, weight: .medium)
        overlayLabel.textColor = .white
        overlayLabel.numberOfLines = 1
        overlayLabel.lineBreakMode = .byTruncatingTail

        iconView.contentMode = .scaleAspectFit

        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.textColor = .abankTextPrimary
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail

        contentView.addSubview(thumbView)
        contentView.addSubview(titleLabel)
        thumbView.addSubview(iconView)
        thumbView.addSubview(overlayBar)
        overlayBar.addSubview(overlayLabel)

        thumbView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(118)
        }
        iconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-10)
            make.size.equalTo(42)
        }
        overlayBar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        overlayLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 7, left: 8, bottom: 7, right: 8))
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(thumbView.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with item: NewsVideoItem) {
        thumbView.backgroundColor = item.backgroundColor
        overlayLabel.text = item.overlayTitle
        overlayBar.isHidden = item.overlayTitle.isEmpty
        iconView.image = UIImage(systemName: item.systemIcon)
        iconView.tintColor = item.iconTint
        titleLabel.text = item.title
    }
}

// MARK: - 资讯热榜

final class NewsHotListView: UIView {

    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with items: [NewsHotRankItem]) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for item in items {
            stack.addArrangedSubview(NewsHotRankRowView(item: item))
        }
    }

    private func setupUI() {
        backgroundColor = .clear

        stack.axis = .vertical
        stack.spacing = 0
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

private final class NewsHotRankRowView: UIView {
    init(item: NewsHotRankItem) {
        super.init(frame: .zero)
        setup(with: item)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup(with item: NewsHotRankItem) {
        let rankLabel = UILabel()
        rankLabel.text = "\(item.rank)"
        rankLabel.font = .systemFont(ofSize: 16, weight: .bold)
        rankLabel.textAlignment = .center
        switch item.rank {
        case 1: rankLabel.textColor = UIColor(red: 0.92, green: 0.25, blue: 0.35, alpha: 1)
        case 2: rankLabel.textColor = .abankOrange
        default: rankLabel.textColor = UIColor(red: 0.85, green: 0.55, blue: 0.20, alpha: 1)
        }

        addSubview(rankLabel)
        if item.rank == 1 {
            let flame = UIImageView(image: UIImage(systemName: "flame.fill"))
            flame.tintColor = rankLabel.textColor
            flame.contentMode = .scaleAspectFit
            addSubview(flame)
            flame.snp.makeConstraints { make in
                make.leading.equalToSuperview()
                make.centerY.equalToSuperview()
                make.size.equalTo(14)
            }
            rankLabel.snp.makeConstraints { make in
                make.leading.equalTo(flame.snp.trailing).offset(2)
                make.centerY.equalToSuperview()
                make.width.equalTo(16)
            }
        } else {
            rankLabel.snp.makeConstraints { make in
                make.leading.equalToSuperview()
                make.centerY.equalToSuperview()
                make.width.equalTo(20)
            }
        }

        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.textColor = .abankTextPrimary
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            if item.rank == 1 {
                make.leading.equalToSuperview().offset(32)
            } else {
                make.leading.equalTo(rankLabel.snp.trailing).offset(8)
            }
            make.centerY.equalToSuperview()
        }

        if let badge = item.badge {
            let badgeLabel = UILabel()
            badgeLabel.text = badge.rawValue
            badgeLabel.font = .systemFont(ofSize: 10, weight: .bold)
            badgeLabel.textColor = .white
            badgeLabel.textAlignment = .center
            badgeLabel.backgroundColor = badge == .hot ? .abankHighlight : UIColor(red: 1.0, green: 0.72, blue: 0.20, alpha: 1)
            badgeLabel.layer.cornerRadius = 3
            badgeLabel.clipsToBounds = true
            addSubview(badgeLabel)
            titleLabel.snp.makeConstraints { make in
                make.trailing.lessThanOrEqualTo(badgeLabel.snp.leading).offset(-6)
            }
            badgeLabel.snp.makeConstraints { make in
                make.trailing.equalToSuperview()
                make.centerY.equalToSuperview()
                make.width.equalTo(16)
                make.height.equalTo(16)
            }
        } else {
            titleLabel.snp.makeConstraints { make in
                make.trailing.equalToSuperview()
            }
        }

        snp.makeConstraints { make in
            make.height.equalTo(44)
        }
    }
}

// MARK: - 互动话题

final class NewsInteractiveTopicView: UIView {

    var onOptionTapped: ((Int) -> Void)?

    private let header = SectionHeaderView(title: "互动话题")
    private let questionLabel = UILabel()
    private let participantLabel = UILabel()
    private let descLabel = UILabel()
    private let optionsStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with topic: NewsInteractiveTopic) {
        questionLabel.text = topic.question
        participantLabel.text = " \(topic.participantCount)人已参与"
        descLabel.text = topic.description

        optionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, option) in topic.options.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(option, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13)
            button.setTitleColor(.abankTextPrimary, for: .normal)
            button.backgroundColor = .white
            button.layer.cornerRadius = CornerRadius.sm
            button.layer.borderWidth = 0.6
            button.layer.borderColor = UIColor(red: 0.78, green: 0.82, blue: 0.88, alpha: 1).cgColor
            button.tag = index
            button.addTarget(self, action: #selector(optionTapped(_:)), for: .touchUpInside)
            optionsStack.addArrangedSubview(button)
            button.snp.makeConstraints { make in
                make.height.equalTo(36)
            }
        }
    }

    private func setupUI() {
        backgroundColor = .white

        let flameIcon = UIImageView(image: UIImage(systemName: "flame.fill"))
        flameIcon.tintColor = .abankHighlight
        flameIcon.contentMode = .scaleAspectFit
        header.addAccessory(flameIcon)
        flameIcon.snp.makeConstraints { make in
            make.size.equalTo(14)
        }

        questionLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        questionLabel.textColor = .abankTextPrimary
        questionLabel.numberOfLines = 0

        let personIcon = UIImageView(image: UIImage(systemName: "person.2.fill"))
        personIcon.tintColor = .abankTextTertiary
        personIcon.contentMode = .scaleAspectFit
        participantLabel.font = .systemFont(ofSize: 12)
        participantLabel.textColor = .abankTextTertiary

        descLabel.font = .systemFont(ofSize: 13)
        descLabel.textColor = .abankTextSecondary
        descLabel.numberOfLines = 0

        optionsStack.axis = .vertical
        optionsStack.spacing = 8

        let participantRow = UIStackView(arrangedSubviews: [personIcon, participantLabel])
        participantRow.axis = .horizontal
        participantRow.spacing = 4
        participantRow.alignment = .center
        personIcon.snp.makeConstraints { make in
            make.size.equalTo(14)
        }

        let bodyContainer = UIView()
        bodyContainer.backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1)
        bodyContainer.layer.cornerRadius = CornerRadius.sm

        addSubview(header)
        addSubview(questionLabel)
        addSubview(participantRow)
        addSubview(bodyContainer)
        bodyContainer.addSubview(descLabel)
        bodyContainer.addSubview(optionsStack)

        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(24)
        }
        questionLabel.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
        }
        participantRow.snp.makeConstraints { make in
            make.top.equalTo(questionLabel.snp.bottom).offset(6)
            make.leading.equalToSuperview().offset(12)
        }
        bodyContainer.snp.makeConstraints { make in
            make.top.equalTo(participantRow.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
        descLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
        }
        optionsStack.snp.makeConstraints { make in
            make.top.equalTo(descLabel.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }
    }

    @objc private func optionTapped(_ sender: UIButton) {
        onOptionTapped?(sender.tag)
    }
}
