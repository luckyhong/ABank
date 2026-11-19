import UIKit
import SnapKit

final class HeroBannerView: UIView {
    var onItemTapped: ((Int) -> Void)?
    var onPageChanged: ((HomeHeroBannerItem) -> Void)?

    private let collectionView: UICollectionView
    private let pageControl = UIPageControl()
    private let adTag = AdTagLabel()
    private var items: [HomeHeroBannerItem] = []
    private var timer: Timer?
    private var currentIndex = 0
    private var pageWidth: CGFloat = 0

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

    override func didMoveToWindow() {
        super.didMoveToWindow()
        restartTimer()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = collectionView.bounds.width
        guard width > 0, width != pageWidth else { return }
        pageWidth = width
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.layoutIfNeeded()
        collectionView.setContentOffset(CGPoint(x: CGFloat(currentIndex) * width, y: 0), animated: false)
    }

    func configure(with items: [HomeHeroBannerItem]) {
        self.items = items
        pageControl.numberOfPages = items.count
        pageControl.isHidden = items.count <= 1
        collectionView.reloadData()
        collectionView.setContentOffset(.zero, animated: false)
        applyPage(0)
        restartTimer()
    }

    private func setupUI() {
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(HeroBannerCell.self, forCellWithReuseIdentifier: HeroBannerCell.reuseId)

        pageControl.currentPageIndicatorTintColor = UIColor(white: 0.25, alpha: 0.90)
        pageControl.pageIndicatorTintColor = UIColor(white: 0.25, alpha: 0.27)
        pageControl.backgroundStyle = .minimal
        pageControl.transform = CGAffineTransform(scaleX: 0.76, y: 0.76)
        pageControl.allowsContinuousInteraction = false
        pageControl.accessibilityLabel = "首页推荐轮播"
        pageControl.addTarget(self, action: #selector(pageControlChanged), for: .valueChanged)

        addSubview(collectionView)
        addSubview(pageControl)
        addSubview(adTag)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(124)
        }
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(snp.bottom).offset(-23)
        }
        adTag.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(pageControl)
        }
    }

    private func restartTimer() {
        timer?.invalidate()
        timer = nil
        guard window != nil, items.count > 1 else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self, self.pageWidth > 0, !UIAccessibility.isReduceMotionEnabled,
                  !UIAccessibility.isVoiceOverRunning else { return }
            let visibleBounds = self.convert(self.bounds, to: self.window)
            guard let window = self.window, window.bounds.contains(CGPoint(x: visibleBounds.midX, y: visibleBounds.midY)) else { return }
            self.showPage((self.currentIndex + 1) % self.items.count)
        }
    }

    private func applyPage(_ index: Int) {
        guard items.indices.contains(index) else {
            adTag.isHidden = true
            currentIndex = 0
            return
        }
        currentIndex = index
        pageControl.currentPage = index
        adTag.isHidden = !items[index].isAd
        onPageChanged?(items[index])
    }

    private func showPage(_ index: Int) {
        guard items.indices.contains(index), pageWidth > 0 else { return }
        let animated = abs(index - currentIndex) == 1 && !UIAccessibility.isReduceMotionEnabled
        collectionView.setContentOffset(CGPoint(x: CGFloat(index) * pageWidth, y: 0), animated: animated)
        applyPage(index)
    }

    @objc private func pageControlChanged() {
        showPage(pageControl.currentPage)
        restartTimer()
    }

    private func finishSwipe() {
        guard pageWidth > 0 else { return }
        let page = Int(round(collectionView.contentOffset.x / pageWidth))
        applyPage(max(0, min(items.count - 1, page)))
        restartTimer()
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

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onItemTapped?(indexPath.item)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        timer?.invalidate()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { finishSwipe() }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        finishSwipe()
    }
}

private final class HeroBannerCell: UICollectionViewCell {
    static let reuseId = "HeroBannerCell"
    private let imageView = HeroArtworkView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.numberOfLines = 0
        titleLabel.textColor = .abankTextPrimary
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().inset(15)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(440)
            make.width.equalToSuperview().priority(999)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(20)
        }
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with item: HomeHeroBannerItem) {
        imageView.image = item.imageName.flatMap { UIImage(named: $0) }
        imageView.setNeedsLayout()
        titleLabel.text = item.title + "\n" + item.subtitle
        titleLabel.isHidden = imageView.image != nil
        accessibilityLabel = item.title + "，" + item.subtitle + "，" + item.actionTitle
    }
}

private final class HeroArtworkView: UIImageView {
    private let verticalMask = CAGradientLayer()
    private let horizontalMask = CAGradientLayer()

    init() {
        super.init(frame: .zero)
        contentMode = .scaleAspectFit
        let edgeColors = [UIColor.clear.cgColor, UIColor.black.cgColor,
                          UIColor.black.cgColor, UIColor.clear.cgColor]
        verticalMask.colors = edgeColors
        verticalMask.locations = [0, 0.12, 0.88, 1]
        horizontalMask.colors = edgeColors
        horizontalMask.locations = [0, 0.035, 0.965, 1]
        horizontalMask.startPoint = CGPoint(x: 0, y: 0.5)
        horizontalMask.endPoint = CGPoint(x: 1, y: 0.5)
        verticalMask.mask = horizontalMask
        layer.mask = verticalMask
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let image, image.size.width > 0, image.size.height > 0 else { return }
        let scale = min(bounds.width / image.size.width, bounds.height / image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        verticalMask.frame = CGRect(
            x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2,
            width: size.width, height: size.height
        )
        horizontalMask.frame = verticalMask.bounds
        CATransaction.commit()
    }
}
