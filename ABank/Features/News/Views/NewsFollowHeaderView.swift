//
//  NewsFollowHeaderView.swift
//  ABank
//

import UIKit
import SnapKit

/// 关注页内容：猜你想看、大家都在看、PK 话题
final class NewsFollowHeaderView: UIView {

    var onFollowAllTapped: (() -> Void)?
    var onFollowTapped: ((Int) -> Void)?
    var onTrendingTapped: ((Int) -> Void)?
    var onPKTapped: ((Bool) -> Void)?

    private let suggestionsCard = NewsFollowSuggestionsView()
    private let trendingCard = NewsTrendingListView()
    private let pkCard = NewsPKPollView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        suggestions: [NewsFollowSuggestion],
        trending: [NewsTrendingItem],
        poll: NewsPKPoll
    ) {
        suggestionsCard.configure(with: suggestions)
        trendingCard.configure(with: trending)
        pkCard.configure(with: poll)
    }

    private func setupUI() {
        backgroundColor = .abankBackground

        suggestionsCard.onFollowAllTapped = { [weak self] in self?.onFollowAllTapped?() }
        suggestionsCard.onFollowTapped = { [weak self] index in self?.onFollowTapped?(index) }
        trendingCard.onItemTapped = { [weak self] index in self?.onTrendingTapped?(index) }
        pkCard.onOptionTapped = { [weak self] isLeft in self?.onPKTapped?(isLeft) }

        [suggestionsCard, trendingCard, pkCard].forEach { addSubview($0) }

        suggestionsCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        trendingCard.snp.makeConstraints { make in
            make.top.equalTo(suggestionsCard.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        pkCard.snp.makeConstraints { make in
            make.top.equalTo(trendingCard.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.bottom.equalToSuperview().offset(-12)
        }
    }
}

// MARK: - 猜你想看

final class NewsFollowSuggestionsView: UIView {

    var onFollowAllTapped: (() -> Void)?
    var onFollowTapped: ((Int) -> Void)?

    private let titleLabel = UILabel()
    private let followAllButton = UIButton(type: .system)
    private let collectionView: UICollectionView
    private var items: [NewsFollowSuggestion] = []

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with items: [NewsFollowSuggestion]) {
        self.items = items
        collectionView.reloadData()
    }

    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = CornerRadius.md
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 6

        titleLabel.text = "猜你想看"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .abankTextPrimary

        followAllButton.setTitle("一键关注", for: .normal)
        followAllButton.titleLabel?.font = .systemFont(ofSize: 13)
        followAllButton.setTitleColor(.abankOrange, for: .normal)
        followAllButton.addTarget(self, action: #selector(followAllTapped), for: .touchUpInside)

        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(NewsFollowSuggestionCell.self, forCellWithReuseIdentifier: NewsFollowSuggestionCell.reuseId)

        addSubview(titleLabel)
        addSubview(followAllButton)
        addSubview(collectionView)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(12)
        }
        followAllButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-12)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(110)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    @objc private func followAllTapped() { onFollowAllTapped?() }
}

extension NewsFollowSuggestionsView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: NewsFollowSuggestionCell.reuseId,
            for: indexPath
        ) as! NewsFollowSuggestionCell
        cell.configure(with: items[indexPath.item])
        cell.onFollowTapped = { [weak self] in self?.onFollowTapped?(indexPath.item) }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 76, height: 110)
    }
}

private final class NewsFollowSuggestionCell: UICollectionViewCell {
    static let reuseId = "NewsFollowSuggestionCell"

    var onFollowTapped: (() -> Void)?

    private let avatarView = UIView()
    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let followButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        avatarView.layer.cornerRadius = 28
        avatarView.clipsToBounds = true
        iconView.contentMode = .scaleAspectFit

        nameLabel.font = .systemFont(ofSize: 11)
        nameLabel.textColor = .abankTextPrimary
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2

        followButton.setTitle("+关注", for: .normal)
        followButton.titleLabel?.font = .systemFont(ofSize: 11, weight: .medium)
        followButton.setTitleColor(.abankGold, for: .normal)
        followButton.layer.cornerRadius = 12
        followButton.layer.borderWidth = 0.8
        followButton.layer.borderColor = UIColor.abankGold.cgColor
        followButton.addTarget(self, action: #selector(followTapped), for: .touchUpInside)

        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(followButton)
        avatarView.addSubview(iconView)

        avatarView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(56)
        }
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(24)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview()
        }
        followButton.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
            make.width.equalTo(56)
            make.height.equalTo(24)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with item: NewsFollowSuggestion) {
        avatarView.backgroundColor = item.tintColor.withAlphaComponent(0.15)
        iconView.image = UIImage(systemName: item.systemIcon)
        iconView.tintColor = item.tintColor
        nameLabel.text = item.name
    }

    @objc private func followTapped() { onFollowTapped?() }
}

// MARK: - 大家都在看

final class NewsTrendingListView: UIView {

    var onItemTapped: ((Int) -> Void)?

    private let titleLabel = UILabel()
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with items: [NewsTrendingItem]) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, item) in items.enumerated() {
            let row = NewsTrendingRowView(title: item.title)
            row.tag = index
            row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(rowTapped(_:))))
            stack.addArrangedSubview(row)
        }
    }

    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = CornerRadius.md
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 6

        titleLabel.text = "大家都在看"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .abankTextPrimary

        stack.axis = .vertical
        stack.spacing = 0

        addSubview(titleLabel)
        addSubview(stack)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(12)
        }
        stack.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().offset(-8)
        }
    }

    @objc private func rowTapped(_ gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag else { return }
        onItemTapped?(tag)
    }
}

private final class NewsTrendingRowView: UIView {
    init(title: String) {
        super.init(frame: .zero)
        let flame = UIImageView(image: UIImage(systemName: "flame.fill"))
        flame.tintColor = .abankHighlight
        flame.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 15)
        label.textColor = .abankTextPrimary
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail

        addSubview(flame)
        addSubview(label)
        flame.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(14)
        }
        label.snp.makeConstraints { make in
            make.leading.equalTo(flame.snp.trailing).offset(8)
            make.trailing.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(10)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - PK 话题

final class NewsPKPollView: UIView {

    var onOptionTapped: ((Bool) -> Void)?

    private let questionLabel = UILabel()
    private let participantLabel = UILabel()
    private let leftButton = UIButton(type: .custom)
    private let rightButton = UIButton(type: .custom)
    private let pkBadge = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with poll: NewsPKPoll) {
        questionLabel.text = poll.question
        participantLabel.text = " \(poll.participantCount)人已参与"
        leftButton.setTitle(poll.leftOption, for: .normal)
        rightButton.setTitle(poll.rightOption, for: .normal)
    }

    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = CornerRadius.md
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 6

        questionLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        questionLabel.textColor = .abankTextPrimary
        questionLabel.numberOfLines = 0

        let personIcon = UIImageView(image: UIImage(systemName: "person.2.fill"))
        personIcon.tintColor = .abankTextTertiary
        personIcon.contentMode = .scaleAspectFit
        participantLabel.font = .systemFont(ofSize: 12)
        participantLabel.textColor = .abankTextTertiary

        leftButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        leftButton.setTitleColor(.white, for: .normal)
        leftButton.backgroundColor = UIColor(red: 0.90, green: 0.35, blue: 0.30, alpha: 1)
        leftButton.layer.cornerRadius = 20
        leftButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        leftButton.addTarget(self, action: #selector(leftTapped), for: .touchUpInside)

        rightButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        rightButton.setTitleColor(.white, for: .normal)
        rightButton.backgroundColor = UIColor(red: 0.25, green: 0.55, blue: 0.95, alpha: 1)
        rightButton.layer.cornerRadius = 20
        rightButton.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        rightButton.addTarget(self, action: #selector(rightTapped), for: .touchUpInside)

        pkBadge.text = "PK"
        pkBadge.font = .systemFont(ofSize: 11, weight: .bold)
        pkBadge.textColor = .white
        pkBadge.textAlignment = .center
        pkBadge.backgroundColor = UIColor(red: 0.35, green: 0.35, blue: 0.40, alpha: 1)
        pkBadge.layer.cornerRadius = 16
        pkBadge.clipsToBounds = true

        let participantRow = UIStackView(arrangedSubviews: [personIcon, participantLabel])
        participantRow.axis = .horizontal
        participantRow.spacing = 4
        participantRow.alignment = .center
        personIcon.snp.makeConstraints { make in
            make.size.equalTo(14)
        }

        let pkContainer = UIView()
        addSubview(questionLabel)
        addSubview(participantRow)
        addSubview(pkContainer)
        pkContainer.addSubview(leftButton)
        pkContainer.addSubview(rightButton)
        pkContainer.addSubview(pkBadge)

        questionLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
        }
        participantRow.snp.makeConstraints { make in
            make.top.equalTo(questionLabel.snp.bottom).offset(6)
            make.leading.equalToSuperview().offset(12)
        }
        pkContainer.snp.makeConstraints { make in
            make.top.equalTo(participantRow.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-12)
        }
        leftButton.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.equalTo(pkContainer.snp.centerX).offset(12)
        }
        rightButton.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
            make.leading.equalTo(pkContainer.snp.centerX).offset(-12)
        }
        pkBadge.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(32)
        }
    }

    @objc private func leftTapped() { onOptionTapped?(true) }
    @objc private func rightTapped() { onOptionTapped?(false) }
}
