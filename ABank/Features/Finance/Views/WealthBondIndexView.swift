//
//  WealthBondIndexView.swift
//  ABank
//

import UIKit
import SnapKit

final class WealthBondIndexView: UIView {

    var onTap: (() -> Void)?

    private let header = WealthSectionHeaderView(title: "债券指数")
    private let card = UIView()
    private let nameLabel = UILabel()
    private let yieldLabel = UILabel()
    private let yieldTitle = UILabel()
    private let indexLabel = UILabel()
    private let indexTitle = UILabel()
    private let dateLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with index: WealthBondIndex) {
        nameLabel.text = index.name
        yieldLabel.text = index.yieldRate
        yieldTitle.text = index.yieldLabel
        indexLabel.text = index.indexValue
        indexTitle.text = index.indexLabel
        dateLabel.text = index.asOfDate
    }

    private func setupUI() {
        header.onTap = { [weak self] in self?.onTap?() }

        card.backgroundColor = .abankCardBackground
        card.layer.cornerRadius = CornerRadius.lg
        card.addShadow(color: .black, opacity: 0.06, offset: CGSize(width: 0, height: 2), radius: 8)

        nameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = .abankTextPrimary
        nameLabel.numberOfLines = 2

        yieldLabel.font = .systemFont(ofSize: 22, weight: .bold)
        yieldLabel.textColor = .abankHighlight
        yieldTitle.font = .systemFont(ofSize: 11)
        yieldTitle.textColor = .abankTextTertiary

        indexLabel.font = .systemFont(ofSize: 22, weight: .bold)
        indexLabel.textColor = .abankTextPrimary
        indexTitle.font = .systemFont(ofSize: 11)
        indexTitle.textColor = .abankTextTertiary

        dateLabel.font = .systemFont(ofSize: 11)
        dateLabel.textColor = .abankTextTertiary
        dateLabel.textAlignment = .right

        addSubview(header)
        addSubview(card)
        [nameLabel, yieldLabel, yieldTitle, indexLabel, indexTitle, dateLabel].forEach {
            card.addSubview($0)
        }

        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        card.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }
        nameLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(Spacing.md)
        }
        yieldLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(Spacing.md)
        }
        yieldTitle.snp.makeConstraints { make in
            make.top.equalTo(yieldLabel.snp.bottom).offset(4)
            make.leading.equalTo(yieldLabel)
        }
        indexLabel.snp.makeConstraints { make in
            make.top.equalTo(yieldLabel)
            make.leading.equalTo(card.snp.centerX).offset(-20)
        }
        indexTitle.snp.makeConstraints { make in
            make.top.equalTo(indexLabel.snp.bottom).offset(4)
            make.leading.equalTo(indexLabel)
        }
        dateLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.bottom.equalToSuperview().offset(-Spacing.md)
            make.top.greaterThanOrEqualTo(yieldTitle.snp.bottom).offset(12)
        }
    }
}
