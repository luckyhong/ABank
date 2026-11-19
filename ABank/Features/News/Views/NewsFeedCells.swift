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
    private let thumbIcon = NewsRemoteImageView()
    private let separator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with item: NewsArticleItem) {
        titleLabel.text = item.title
        metaLabel.text = "\(item.source)  \(item.date)"
        thumbView.backgroundColor = item.thumbnailBackground
        thumbIcon.load(item.thumbnailURL)
        let hasImage = item.thumbnailURL != nil
        thumbView.isHidden = !hasImage
        thumbView.snp.updateConstraints { $0.size.equalTo(CGSize(width: hasImage ? 108 : 0, height: hasImage ? 72 : 0)) }
        titleLabel.snp.updateConstraints { $0.trailing.equalTo(thumbView.snp.leading).offset(hasImage ? -12 : 0) }
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
        thumbIcon.contentMode = .scaleAspectFill
        thumbIcon.clipsToBounds = true

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
            // Single-line titles must still leave space around the fixed-height thumbnail.
            make.top.greaterThanOrEqualToSuperview().offset(14)
            make.bottom.lessThanOrEqualToSuperview().offset(-14)
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
            make.edges.equalToSuperview()
        }
        separator.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
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
