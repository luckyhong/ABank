//
//  FavoriteFeaturesEditViewController.swift
//  ABank
//
//  编辑常用：删除、添加、长按拖拽排序；点“完成”才写入，“取消”不保存。
//

import UIKit
import SnapKit

final class FavoriteFeaturesEditViewController: BaseViewController, RouteHosting {
    private let preferences: FeaturePreferencesStore
    private var draft: FavoritesDraft
    private let categories = FeatureCategory.allCases

    var hostedRoute: AppRoute? { .editFavorites }

    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        view.backgroundColor = .abankCardBackground
        view.dataSource = self
        view.delegate = self
        view.dragDelegate = self
        view.dropDelegate = self
        view.dragInteractionEnabled = true
        view.register(FeatureGridCell.self, forCellWithReuseIdentifier: FeatureGridCell.reuseID)
        view.register(FeatureMessageCell.self, forCellWithReuseIdentifier: FeatureMessageCell.reuseID)
        view.register(FeatureSectionHeaderView.self,
                      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                      withReuseIdentifier: FeatureSectionHeaderView.reuseID)
        return view
    }()

    init(preferences: FeaturePreferencesStore = .shared) {
        self.preferences = preferences
        draft = FavoritesDraft(ids: preferences.favorites)
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "编辑常用"
        let cancel = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(cancelTapped))
        cancel.accessibilityIdentifier = "editFavorites.cancel"
        let done = UIBarButtonItem(title: "完成", style: .done, target: self, action: #selector(doneTapped))
        done.accessibilityIdentifier = "editFavorites.done"
        navigationItem.leftBarButtonItem = cancel
        navigationItem.rightBarButtonItem = done
        navigationItem.hidesBackButton = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = .abankCardBackground
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func doneTapped() {
        preferences.setFavorites(draft.ids)
        navigationController?.popViewController(animated: true)
    }

    private func toggle(_ id: FeatureID) {
        if draft.ids.contains(id) {
            draft.remove(id)
        } else if draft.add(id) == .full {
            showToast("最多添加 9 个常用功能")
            return
        }
        collectionView.reloadData()
    }

    // MARK: - Layout

    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] index, _ in
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(36)),
                elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
            if index == 0, self?.draft.ids.isEmpty == true {
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(56)))
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(56)), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.boundarySupplementaryItems = [header]
                return section
            }
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(0.25), heightDimension: .estimated(78)))
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(78)), subitem: item, count: 4)
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = .init(top: 0, leading: Spacing.sm, bottom: Spacing.sm, trailing: Spacing.sm)
            section.boundarySupplementaryItems = [header]
            return section
        }
    }
}

// MARK: - DataSource & Delegate

extension FavoriteFeaturesEditViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1 + categories.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 { return max(draft.ids.count, 1) }
        return FeatureCatalog.features(in: categories[section - 1]).count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 && draft.ids.isEmpty {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeatureMessageCell.reuseID, for: indexPath) as! FeatureMessageCell
            cell.configure("从下方添加常用功能")
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeatureGridCell.reuseID, for: indexPath) as! FeatureGridCell
        let descriptor = descriptor(at: indexPath)
        if indexPath.section == 0 {
            cell.configure(descriptor, accessory: .delete)
            cell.accessibilityIdentifier = "favorite.\(descriptor.id.rawValue)"
        } else {
            cell.configure(descriptor, accessory: draft.ids.contains(descriptor.id) ? .added : .add)
            cell.accessibilityIdentifier = "candidate.\(descriptor.id.rawValue)"
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind, withReuseIdentifier: FeatureSectionHeaderView.reuseID, for: indexPath) as! FeatureSectionHeaderView
        if indexPath.section == 0 {
            header.configure(title: "我的常用（\(draft.ids.count)/\(FeaturePreferencesStore.maxFavorites)）· 长按拖动排序")
        } else {
            header.configure(title: categories[indexPath.section - 1].title)
        }
        return header
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 && draft.ids.isEmpty { return }
        toggle(descriptor(at: indexPath).id)
    }

    private func descriptor(at indexPath: IndexPath) -> FeatureDescriptor {
        if indexPath.section == 0 { return FeatureCatalog.descriptor(draft.ids[indexPath.item]) }
        return FeatureCatalog.features(in: categories[indexPath.section - 1])[indexPath.item]
    }
}

// MARK: - Drag & Drop（仅常用区内部排序）

extension FavoriteFeaturesEditViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession,
                        at indexPath: IndexPath) -> [UIDragItem] {
        guard indexPath.section == 0, !draft.ids.isEmpty else { return [] }
        let id = draft.ids[indexPath.item]
        let item = UIDragItem(itemProvider: NSItemProvider(object: id.rawValue as NSString))
        item.localObject = id
        return [item]
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession,
                        withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard session.localDragSession != nil, destinationIndexPath?.section ?? 0 == 0 else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let item = coordinator.items.first,
              let source = item.sourceIndexPath, source.section == 0 else { return }
        let destination = coordinator.destinationIndexPath.map { $0.section == 0 ? $0.item : draft.ids.count - 1 }
            ?? draft.ids.count - 1
        draft.move(from: source.item, to: destination)
        let target = IndexPath(item: min(destination, draft.ids.count - 1), section: 0)
        collectionView.performBatchUpdates {
            collectionView.moveItem(at: source, to: target)
        }
        coordinator.drop(item.dragItem, toItemAt: target)
    }
}
