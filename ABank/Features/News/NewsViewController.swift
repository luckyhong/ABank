//
//  NewsViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class NewsViewController: BaseViewController {

    override func setupUI() {
        view.backgroundColor = .abankBackground
        title = "资讯"

        let label = UILabel()
        label.text = "资讯频道开发中..."
        label.font = .abankHeadline()
        label.textColor = .abankTextSecondary
        label.textAlignment = .center
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
