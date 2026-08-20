//
//  LifeServiceGridView.swift
//  ABank
//

import UIKit
import SnapKit

final class LifeServiceGridView: UIView {

    var onItemTapped: ((Int, Int) -> Void)?

    private let collectionView: UICollectionView
    private let pageControl = UIPageControl()
    private var pages: [[LifeGridItem]] = []
    private let columns = 5
    private let rows = 2

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with pages: [[LifeGridItem]]) {
        self.pages = pages
        pageControl.numberOfPages = pages.count
        pageControl.isHidden = pages.count <= 1
        collectionView.reloadData()
    }

    private func setupUI() {
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(LifeGridPageCell.self, forCellWithReuseIdentifier: LifeGridPageCell.reuseId)

        pageControl.currentPageIndicatorTintColor = .abankPrimary
        pageControl.pageIndicatorTintColor = UIColor.abankPrimary.withAlphaComponent(0.25)
        pageControl.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)

        addSubview(collectionView)
        addSubview(pageControl)
        collectionView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(148)
        }
        pageControl.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
}

extension LifeServiceGridView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        pages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LifeGridPageCell.reuseId, for: indexPath) as! LifeGridPageCell
        cell.configure(items: pages[indexPath.item], columns: columns, rows: rows) { [weak self] index in
            self?.onItemTapped?(indexPath.item, index)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / max(scrollView.bounds.width, 1)))
        pageControl.currentPage = page
    }
}

private final class LifeGridPageCell: UICollectionViewCell {
    static let reuseId = "LifeGridPageCell"
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        stack.axis = .vertical
        stack.spacing = 16
        stack.distribution = .fillEqually
        contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(items: [LifeGridItem], columns: Int, rows: Int, onTap: @escaping (Int) -> Void) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for row in 0..<rows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.alignment = .top
            stack.addArrangedSubview(rowStack)
            let start = row * columns
            let end = min(start + columns, items.count)
            for index in start..<end {
                rowStack.addArrangedSubview(makeCell(item: items[index], index: index, onTap: onTap))
            }
            if end - start < columns {
                for _ in 0..<(columns - (end - start)) {
                    rowStack.addArrangedSubview(UIView())
                }
            }
        }
    }

    private func makeCell(item: LifeGridItem, index: Int, onTap: @escaping (Int) -> Void) -> UIView {
        let wrap = UIControl()
        wrap.addAction(UIAction { _ in onTap(index) }, for: .touchUpInside)
        let icon = UIImageView(image: UIImage(systemName: item.systemIcon))
        icon.tintColor = item.tintColor
        icon.contentMode = .scaleAspectFit
        let title = UILabel()
        title.text = item.title
        title.font = .systemFont(ofSize: 12)
        title.textColor = .abankTextPrimary
        title.textAlignment = .center
        title.numberOfLines = 2
        wrap.addSubview(icon)
        wrap.addSubview(title)
        icon.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(28)
        }
        title.snp.makeConstraints { make in
            make.top.equalTo(icon.snp.bottom).offset(6)
            make.leading.trailing.bottom.equalToSuperview()
        }
        return wrap
    }
}
