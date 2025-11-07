//
//  TopSearchBarView.swift
//  ABank
//
//  Created by 韩继宏 on 2025/11/06.
//

import UIKit
import SnapKit

enum TopSearchBarStyle {
    case light   // for colored/gradient background (icons/text are white)
    case dark    // for white background (icons/text are dark/primary)
}

final class TopSearchBarView: UIView {
    
    private let container = UIView()
    private let giftButton = UIButton(type: .system)
    private let searchContainer = UIView()
    private let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
    private let micIcon = UIImageView(image: UIImage(systemName: "mic"))
    private let searchLabel = UILabel()
    private let versionButton = UIButton(type: .system)
    private let serviceButton = UIButton(type: .system)
    private let messageButton = UIButton(type: .system)
    private var currentStyle: TopSearchBarStyle?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(44)
        }
        
        giftButton.setImage(UIImage(systemName: "gift.fill"), for: .normal)
        giftButton.tintColor = .white
        
        searchContainer.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        searchContainer.layer.cornerRadius = 18
        
        searchIcon.tintColor = .white
        micIcon.tintColor = .white
        
        searchLabel.text = "存金通"
        searchLabel.textColor = .white
        searchLabel.font = .systemFont(ofSize: 15)
        
        versionButton.setImage(UIImage(systemName: "doc.text"), for: .normal)
        serviceButton.setImage(UIImage(systemName: "headphones"), for: .normal)
        messageButton.setImage(UIImage(systemName: "envelope"), for: .normal)
        [versionButton, serviceButton, messageButton].forEach { $0.tintColor = .white }
        
        container.addSubview(giftButton)
        container.addSubview(searchContainer)
        container.addSubview(versionButton)
        container.addSubview(serviceButton)
        container.addSubview(messageButton)
        
        giftButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        messageButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        serviceButton.snp.makeConstraints { make in
            make.trailing.equalTo(messageButton.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        versionButton.snp.makeConstraints { make in
            make.trailing.equalTo(serviceButton.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        searchContainer.snp.makeConstraints { make in
            make.leading.equalTo(giftButton.snp.trailing).offset(12)
            make.trailing.equalTo(versionButton.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
        }
        
        searchContainer.addSubview(searchIcon)
        searchContainer.addSubview(searchLabel)
        searchContainer.addSubview(micIcon)
        
        searchIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }
        searchLabel.snp.makeConstraints { make in
            make.leading.equalTo(searchIcon.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
        }
        micIcon.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }
    }

    // MARK: - Style switching for scroll fading header
    func apply(style: TopSearchBarStyle) {
        if let currentStyle = currentStyle, currentStyle == style { return }
        currentStyle = style
        switch style {
        case .light:
            [giftButton, versionButton, serviceButton, messageButton].forEach { $0.tintColor = .white }
            searchIcon.tintColor = .white
            micIcon.tintColor = .white
            searchLabel.textColor = .white
            searchContainer.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        case .dark:
            let darkColor = UIColor.abankPrimary
            [giftButton, versionButton, serviceButton, messageButton].forEach { $0.tintColor = darkColor }
            searchIcon.tintColor = .abankTextSecondary
            micIcon.tintColor = .abankTextSecondary
            searchLabel.textColor = .abankTextSecondary
            searchContainer.backgroundColor = UIColor.abankSectionBackground
        }
    }
}


