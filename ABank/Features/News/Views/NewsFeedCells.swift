//
//  NewsFeedCells.swift
//  ABank
//

import UIKit
import SnapKit

// MARK: - 标准资讯（左文右图）

final class NewsArticleCell: UITableViewCell {
    static let reuseId = "NewsArticleCell"

    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let thumbView = UIView()
    private let thumbIcon = UIImageView()
    private let separator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with item: NewsArticleItem) {
        titleLabel.text = item.title
        metaLabel.text = "\(item.source)  \(item.readCount)阅读  \(item.date)"
        thumbView.backgroundColor = item.thumbnailBackground
        thumbIcon.image = UIImage(systemName: item.systemIcon)
        thumbIcon.tintColor = item.iconTint
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .white
        contentView.backgroundColor = .white

        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .abankTextPrimary
        titleLabel.numberOfLines = 2

        metaLabel.font = .systemFont(ofSize: 12)
        metaLabel.textColor = .abankTextTertiary

        thumbView.layer.cornerRadius = CornerRadius.sm
        thumbView.clipsToBounds = true
        thumbIcon.contentMode = .scaleAspectFit

        separator.backgroundColor = .abankSeparator

        contentView.addSubview(titleLabel)
        contentView.addSubview(metaLabel)
        contentView.addSubview(thumbView)
        contentView.addSubview(separator)
        thumbView.addSubview(thumbIcon)

        thumbView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 108, height: 72))
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.trailing.equalTo(thumbView.snp.leading).offset(-12)
            make.top.equalToSuperview().offset(14)
        }
        metaLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.bottom.lessThanOrEqualToSuperview().offset(-14)
        }
        thumbIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(28)
        }
        separator.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
}

// MARK: - 信息流横幅

final class NewsFeedBannerCell: UITableViewCell {
    static let reuseId = "NewsFeedBannerCell"

    private let bannerView = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let separator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with item: NewsFeedBannerItem) {
        bannerView.backgroundColor = item.backgroundColor
        iconView.image = UIImage(systemName: item.systemIcon)
        iconView.tintColor = item.iconTint
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        subtitleLabel.isHidden = item.subtitle == nil
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .white
        contentView.backgroundColor = .white

        bannerView.layer.cornerRadius = CornerRadius.md
        bannerView.clipsToBounds = true
        iconView.contentMode = .scaleAspectFit

        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2

        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.9)

        separator.backgroundColor = .abankSeparator

        contentView.addSubview(bannerView)
        contentView.addSubview(separator)
        bannerView.addSubview(iconView)
        bannerView.addSubview(titleLabel)
        bannerView.addSubview(subtitleLabel)

        bannerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.height.equalTo(120)
            make.bottom.equalToSuperview().offset(-12)
        }
        iconView.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(12)
            make.size.equalTo(48)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(14)
            make.trailing.lessThanOrEqualTo(iconView.snp.leading).offset(-8)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.trailing.equalTo(titleLabel)
        }
        separator.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
}

// MARK: - 快讯条（金融界等）

final class NewsFeedStripCell: UITableViewCell {
    static let reuseId = "NewsFeedStripCell"

    private let brandLabel = UILabel()
    private let headlineLabel = UILabel()
    private let separator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with item: NewsFeedStripItem) {
        brandLabel.text = item.brand
        brandLabel.textColor = item.brandColor
        headlineLabel.text = item.headline
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .white
        contentView.backgroundColor = .white

        brandLabel.font = .systemFont(ofSize: 14, weight: .bold)
        headlineLabel.font = .systemFont(ofSize: 14)
        headlineLabel.textColor = .abankTextPrimary
        headlineLabel.numberOfLines = 1
        headlineLabel.lineBreakMode = .byTruncatingTail

        separator.backgroundColor = .abankSeparator

        contentView.addSubview(brandLabel)
        contentView.addSubview(headlineLabel)
        contentView.addSubview(separator)

        brandLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.centerY.equalToSuperview()
        }
        headlineLabel.snp.makeConstraints { make in
            make.leading.equalTo(brandLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.top.bottom.equalToSuperview().inset(12)
        }
        separator.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
}

// MARK: - 专题

final class NewsFeedTopicCell: UITableViewCell {
    static let reuseId = "NewsFeedTopicCell"

    private let tagLabel = UILabel()
    private let titleLabel = UILabel()
    private let bannerView = UIView()
    private let iconView = UIImageView()
    private let bannerTitle = UILabel()
    private let bannerSubtitle = UILabel()
    private let separator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with item: NewsFeedTopicItem) {
        tagLabel.text = item.tag
        titleLabel.text = item.title
        bannerView.backgroundColor = item.backgroundColor
        iconView.image = UIImage(systemName: item.systemIcon)
        iconView.tintColor = item.iconTint
        bannerTitle.text = item.bannerTitle
        bannerSubtitle.text = item.bannerSubtitle
        bannerSubtitle.isHidden = item.bannerSubtitle == nil
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .white
        contentView.backgroundColor = .white

        tagLabel.font = .systemFont(ofSize: 11, weight: .bold)
        tagLabel.textColor = UIColor(red: 0.55, green: 0.35, blue: 0.10, alpha: 1)
        tagLabel.backgroundColor = UIColor(red: 1.0, green: 0.94, blue: 0.78, alpha: 1)
        tagLabel.textAlignment = .center
        tagLabel.layer.cornerRadius = 3
        tagLabel.clipsToBounds = true

        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .abankTextPrimary
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail

        bannerView.layer.cornerRadius = CornerRadius.md
        bannerView.clipsToBounds = true
        iconView.contentMode = .scaleAspectFit
        bannerTitle.font = .systemFont(ofSize: 18, weight: .bold)
        bannerTitle.textColor = .white
        bannerTitle.numberOfLines = 2
        bannerSubtitle.font = .systemFont(ofSize: 13)
        bannerSubtitle.textColor = UIColor.white.withAlphaComponent(0.92)

        separator.backgroundColor = .abankSeparator

        contentView.addSubview(tagLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(bannerView)
        contentView.addSubview(separator)
        bannerView.addSubview(iconView)
        bannerView.addSubview(bannerTitle)
        bannerView.addSubview(bannerSubtitle)

        tagLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.top.equalToSuperview().offset(14)
            make.width.equalTo(32)
            make.height.equalTo(18)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(tagLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.centerY.equalTo(tagLabel)
        }
        bannerView.snp.makeConstraints { make in
            make.top.equalTo(tagLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.height.equalTo(120)
            make.bottom.equalToSuperview().offset(-12)
        }
        iconView.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(16)
            make.size.equalTo(44)
        }
        bannerTitle.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(iconView.snp.leading).offset(-8)
        }
        bannerSubtitle.snp.makeConstraints { make in
            make.leading.equalTo(bannerTitle)
            make.top.equalTo(bannerTitle.snp.bottom).offset(6)
            make.trailing.equalTo(bannerTitle)
        }
        separator.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
}

// MARK: - 视频

final class NewsFeedVideoCell: UITableViewCell {
    static let reuseId = "NewsFeedVideoCell"

    private let tagLabel = UILabel()
    private let titleLabel = UILabel()
    private let coverView = UIView()
    private let iconView = UIImageView()
    private let playIcon = UIImageView(image: UIImage(systemName: "play.circle.fill"))
    private let separator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with item: NewsFeedVideoItem) {
        titleLabel.text = item.title
        coverView.backgroundColor = item.backgroundColor
        iconView.image = UIImage(systemName: item.systemIcon)
        iconView.tintColor = item.iconTint
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .white
        contentView.backgroundColor = .white

        tagLabel.text = "视频"
        tagLabel.font = .systemFont(ofSize: 10, weight: .bold)
        tagLabel.textColor = UIColor(red: 0.20, green: 0.45, blue: 0.85, alpha: 1)
        tagLabel.backgroundColor = UIColor(red: 0.92, green: 0.96, blue: 1.0, alpha: 1)
        tagLabel.textAlignment = .center
        tagLabel.layer.cornerRadius = 3
        tagLabel.layer.borderWidth = 0.5
        tagLabel.layer.borderColor = UIColor(red: 0.55, green: 0.75, blue: 0.95, alpha: 1).cgColor
        tagLabel.clipsToBounds = true

        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .abankTextPrimary
        titleLabel.numberOfLines = 2

        coverView.layer.cornerRadius = CornerRadius.md
        coverView.clipsToBounds = true
        iconView.contentMode = .scaleAspectFit
        playIcon.tintColor = UIColor.white.withAlphaComponent(0.9)
        playIcon.contentMode = .scaleAspectFit

        separator.backgroundColor = .abankSeparator

        contentView.addSubview(tagLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(coverView)
        contentView.addSubview(separator)
        coverView.addSubview(iconView)
        coverView.addSubview(playIcon)

        tagLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.top.equalToSuperview().offset(14)
            make.width.equalTo(30)
            make.height.equalTo(18)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(tagLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.top.equalTo(tagLabel)
        }
        coverView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.height.equalTo(180)
            make.bottom.equalToSuperview().offset(-12)
        }
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(48)
        }
        playIcon.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(12)
            make.size.equalTo(32)
        }
        separator.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
}

// MARK: - 加载状态 Footer

final class NewsLoadMoreFooterView: UIView {

    enum State {
        case idle
        case loading
        case finished
    }

    private let indicator = UIActivityIndicatorView(style: .medium)
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(state: State) {
        switch state {
        case .idle:
            indicator.stopAnimating()
            label.text = "上拉加载更多"
        case .loading:
            indicator.startAnimating()
            label.text = "加载中..."
        case .finished:
            indicator.stopAnimating()
            label.text = "已经全部加载完毕"
        }
    }

    private func setupUI() {
        indicator.color = .abankTextTertiary
        label.font = .systemFont(ofSize: 13)
        label.textColor = .abankTextTertiary

        let stack = UIStackView(arrangedSubviews: [indicator, label])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
