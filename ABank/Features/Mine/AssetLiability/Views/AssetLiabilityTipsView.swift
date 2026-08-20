//
//  AssetLiabilityTipsView.swift
//  ABank
//

import UIKit
import SnapKit

final class AssetLiabilityTipsView: UIView {

    var onPhoneTapped: (() -> Void)?

    private let titleLabel = UILabel()
    private let contentLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(tips: [String]) {
        let attributed = NSMutableAttributedString()
        let bodyFont = UIFont.systemFont(ofSize: 12)
        let bodyColor = UIColor(red: 153 / 255, green: 153 / 255, blue: 153 / 255, alpha: 1)
        let phoneColor = UIColor.abankTeal

        tips.enumerated().forEach { index, tip in
            let prefix = "\(index + 1). "
            let paragraph = NSMutableAttributedString(
                string: prefix,
                attributes: [.font: bodyFont, .foregroundColor: bodyColor]
            )
            appendTipText(tip, to: paragraph, bodyFont: bodyFont, bodyColor: bodyColor, phoneColor: phoneColor)
            if index < tips.count - 1 {
                paragraph.append(NSAttributedString(string: "\n"))
            }
            attributed.append(paragraph)
        }

        let style = NSMutableParagraphStyle()
        style.lineSpacing = 2
        style.paragraphSpacing = 0
        attributed.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: attributed.length))
        contentLabel.attributedText = attributed
    }

    private func appendTipText(
        _ tip: String,
        to paragraph: NSMutableAttributedString,
        bodyFont: UIFont,
        bodyColor: UIColor,
        phoneColor: UIColor
    ) {
        guard tip.contains("95599") else {
            paragraph.append(NSAttributedString(string: tip, attributes: [.font: bodyFont, .foregroundColor: bodyColor]))
            return
        }
        let parts = tip.components(separatedBy: "95599")
        if let first = parts.first {
            paragraph.append(NSAttributedString(string: first, attributes: [.font: bodyFont, .foregroundColor: bodyColor]))
        }
        paragraph.append(NSAttributedString(
            string: "95599",
            attributes: [.font: bodyFont, .foregroundColor: phoneColor, .link: URL(string: "tel:95599")!]
        ))
        if parts.count > 1 {
            paragraph.append(NSAttributedString(string: parts[1], attributes: [.font: bodyFont, .foregroundColor: bodyColor]))
        }
    }

    private func setupUI() {
        titleLabel.text = "温馨提示："
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.textColor = UIColor(red: 130 / 255, green: 130 / 255, blue: 130 / 255, alpha: 1)

        contentLabel.numberOfLines = 0
        contentLabel.isUserInteractionEnabled = true
        contentLabel.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(contentTapped(_:)))
        )

        addSubview(titleLabel)
        addSubview(contentLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    @objc private func contentTapped(_ gesture: UITapGestureRecognizer) {
        guard let label = gesture.view as? UILabel,
              let attributed = label.attributedText else { return }
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: label.bounds.size)
        let textStorage = NSTextStorage(attributedString: attributed)
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = label.numberOfLines
        textContainer.lineBreakMode = label.lineBreakMode

        let location = gesture.location(in: label)
        let index = layoutManager.characterIndex(
            for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil
        )
        attributed.enumerateAttribute(.link, in: NSRange(location: 0, length: attributed.length)) { value, range, _ in
            if let url = value as? URL, NSLocationInRange(index, range), url.scheme == "tel" {
                onPhoneTapped?()
            }
        }
    }
}
