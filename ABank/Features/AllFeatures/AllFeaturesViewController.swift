//
//  AllFeaturesViewController.swift
//  ABank
//
//  全部功能：搜索、我的常用、最近使用与分类目录。
//

import UIKit
import SnapKit

final class AllFeaturesViewController: BaseViewController, RouteHosting {
    private enum Section: Equatable {
        case favorites
        case recents
        case category(FeatureCategory)
    }

    private let preferences: FeaturePreferencesStore
    private let initialKeyword: String?
    private var sections: [Section] = []
    private var searchResults: [FeatureDescriptor] = []
    private var preferencesObserver: NSObjectProtocol?
    private var isScrollingFromIndex = false

    private let searchBar = UISearchBar()
    private let indexView = FeatureCategoryIndexView()
    private lazy var browseView = makeCollectionView(layout: makeBrowseLayout())
    private lazy var resultsView = makeCollectionView(layout: makeResultsLayout())
    private let emptyLabel = UILabel()

    var hostedRoute: AppRoute? { .allFeatures(searchKeyword: initialKeyword) }

    init(searchKeyword: String? = nil, preferences: FeaturePreferencesStore = .shared) {
        let trimmed = searchKeyword?.trimmingCharacters(in: .whitespacesAndNewlines)
        initialKeyword = trimmed?.isEmpty == false ? trimmed : nil
        self.preferences = preferences
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        if let preferencesObserver { NotificationCenter.default.removeObserver(preferencesObserver) }
    }

    override func setupNavigationBar() {
        title = "全部功能"
        navigationController?.navigationBar.tintColor = .abankTextPrimary
    }

    override func setupUI() {
        view.backgroundColor = .abankCardBackground

        searchBar.placeholder = "搜索功能"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        searchBar.searchTextField.accessibilityIdentifier = "allFeatures.search"

        emptyLabel.text = "未找到相关功能"
        emptyLabel.font = .abankSubheadline()
        emptyLabel.textColor = .abankTextTertiary
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true

        view.addSubview(searchBar)
        view.addSubview(indexView)
        view.addSubview(browseView)
        view.addSubview(resultsView)
        view.addSubview(emptyLabel)

        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview().inset(Spacing.sm)
        }
        indexView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(Spacing.xs)
            make.leading.bottom.equalToSuperview()
            make.width.equalTo(84)
        }
        browseView.snp.makeConstraints { make in
            make.top.equalTo(indexView)
            make.leading.equalTo(indexView.snp.trailing)
            make.trailing.bottom.equalToSuperview()
        }
        resultsView.snp.makeConstraints { make in
            make.top.equalTo(indexView)
            make.leading.trailing.bottom.equalToSuperview()
        }
        emptyLabel.snp.makeConstraints { make in
            make.top.equalTo(resultsView).offset(Spacing.xxl)
            make.leading.trailing.equalToSuperview().inset(Spacing.lg)
        }
    }

    override func setupBindings() {
        indexView.onSelect = { [weak self] category in self?.scroll(to: category) }
        preferencesObserver = NotificationCenter.default.addObserver(
            forName: FeaturePreferencesStore.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.reloadBrowse() }

        reloadBrowse()
        if let initialKeyword {
            searchBar.text = initialKeyword
            applySearch(initialKeyword)
        } else {
            applySearch("")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        reloadBrowse()
    }

    // MARK: - Data

    private func reloadBrowse() {
        var updated: [Section] = [.favorites]
        if !preferences.recents.isEmpty { updated.append(.recents) }
        updated += FeatureCategory.allCases.map { .category($0) }
        sections = updated
        browseView.reloadData()
    }

    private func items(in section: Section) -> [FeatureDescriptor] {
        switch section {
        case .favorites: return preferences.favorites.map(FeatureCatalog.descriptor)
        case .recents: return preferences.recents.map(FeatureCatalog.descriptor)
        case .category(let category): return FeatureCatalog.features(in: category)
        }
    }

    private func applySearch(_ text: String) {
        let searching = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        searchResults = searching ? FeatureSearch.search(text) : []
        resultsView.reloadData()
        resultsView.isHidden = !searching
        emptyLabel.isHidden = !(searching && searchResults.isEmpty)
        browseView.isHidden = searching
        indexView.isHidden = searching
    }

    // MARK: - Index sync

    private func scroll(to category: FeatureCategory) {
        guard let sectionIndex = sections.firstIndex(of: .category(category)),
              let attributes = browseView.layoutAttributesForSupplementaryElement(
                ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: sectionIndex))
        else { return }
        let maxOffset = max(0, browseView.contentSize.height - browseView.bounds.height + browseView.adjustedContentInset.bottom)
        isScrollingFromIndex = true
        browseView.setContentOffset(CGPoint(x: 0, y: min(attributes.frame.minY, maxOffset)), animated: true)
    }

    private func syncIndexWithScroll() {
        let probe = browseView.contentOffset.y + 1
        var current = FeatureCategory.account
        for (index, section) in sections.enumerated() {
            guard case .category(let category) = section,
                  let attributes = browseView.layoutAttributesForSupplementaryElement(
                    ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: index))
            else { continue }
            if attributes.frame.minY <= probe { current = category }
        }
        indexView.setHighlighted(current)
    }

    // MARK: - Layout

    private func makeCollectionView(layout: UICollectionViewLayout) -> UICollectionView {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .abankCardBackground
        collectionView.keyboardDismissMode = .onDrag
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(FeatureGridCell.self, forCellWithReuseIdentifier: FeatureGridCell.reuseID)
        collectionView.register(FeatureMessageCell.self, forCellWithReuseIdentifier: FeatureMessageCell.reuseID)
        collectionView.register(FeatureSectionHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: FeatureSectionHeaderView.reuseID)
        return collectionView
    }

    private static func headerItem() -> NSCollectionLayoutBoundarySupplementaryItem {
        NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(36)),
            elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
    }

    private static func gridSection(columns: Int) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(
            widthDimension: .fractionalWidth(1 / CGFloat(columns)), heightDimension: .estimated(78)))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(78)),
            subitem: item, count: columns)
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 0, leading: 0, bottom: Spacing.sm, trailing: 0)
        section.boundarySupplementaryItems = [headerItem()]
        return section
    }

    private func makeBrowseLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] index, _ in
            guard let self, let section = self.sections[safe: index] else { return Self.gridSection(columns: 3) }
            switch section {
            case .favorites where self.preferences.favorites.isEmpty:
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(56)))
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(56)), subitems: [item])
                let layoutSection = NSCollectionLayoutSection(group: group)
                layoutSection.boundarySupplementaryItems = [Self.headerItem()]
                return layoutSection
            case .favorites, .recents:
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .absolute(68), heightDimension: .absolute(78)))
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: .init(widthDimension: .absolute(68), heightDimension: .absolute(78)), subitems: [item])
                let layoutSection = NSCollectionLayoutSection(group: group)
                layoutSection.orthogonalScrollingBehavior = .continuous
                layoutSection.contentInsets = .init(top: 0, leading: 0, bottom: Spacing.sm, trailing: 0)
                layoutSection.boundarySupplementaryItems = [Self.headerItem()]
                return layoutSection
            case .category:
                return Self.gridSection(columns: 3)
            }
        }
    }

    private func makeResultsLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in Self.gridSection(columns: 4) }
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension AllFeaturesViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        collectionView === resultsView ? 1 : sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === resultsView { return searchResults.count }
        guard let kind = sections[safe: section] else { return 0 }
        if kind == .favorites && preferences.favorites.isEmpty { return 1 }
        return items(in: kind).count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView === browseView, sections[safe: indexPath.section] == .favorites, preferences.favorites.isEmpty {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeatureMessageCell.reuseID, for: indexPath) as! FeatureMessageCell
            cell.configure("点击编辑添加常用功能")
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeatureGridCell.reuseID, for: indexPath) as! FeatureGridCell
        if let descriptor = descriptor(at: indexPath, in: collectionView) {
            cell.configure(descriptor, accessory: descriptor.isAvailable ? .none : .planned)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind, withReuseIdentifier: FeatureSectionHeaderView.reuseID, for: indexPath) as! FeatureSectionHeaderView
        if collectionView === resultsView {
            header.configure(title: "搜索结果")
            return header
        }
        switch sections[safe: indexPath.section] {
        case .favorites:
            header.configure(title: "我的常用", actionTitle: "编辑", identifier: "allFeatures.edit") { [weak self] in
                guard let self else { return }
                self.router.open(.editFavorites, from: self)
            }
        case .recents:
            header.configure(title: "最近使用")
        case .category(let category):
            header.configure(title: category.title)
        case nil:
            header.configure(title: "")
        }
        return header
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView === browseView, sections[safe: indexPath.section] == .favorites, preferences.favorites.isEmpty {
            router.open(.editFavorites, from: self)
            return
        }
        guard let descriptor = descriptor(at: indexPath, in: collectionView) else { return }
        searchBar.resignFirstResponder()
        router.open(feature: descriptor.id, from: self)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === browseView, !isScrollingFromIndex else { return }
        syncIndexWithScroll()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isScrollingFromIndex = false
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScrollingFromIndex = false
    }

    private func descriptor(at indexPath: IndexPath, in collectionView: UICollectionView) -> FeatureDescriptor? {
        if collectionView === resultsView { return searchResults[safe: indexPath.item] }
        guard let section = sections[safe: indexPath.section] else { return nil }
        return items(in: section)[safe: indexPath.item]
    }
}

// MARK: - UISearchBarDelegate

extension AllFeaturesViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applySearch(searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
