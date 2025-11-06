//
//  LifeViewController.swift
//  ABank
//
//  Created by 韩继宏 on 2025/11/06.
//

import UIKit
import SnapKit

class LifeViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func setupUI() {
        view.backgroundColor = .abankBackground
        title = "生活"
        
        let label = UILabel()
        label.text = "生活服务开发中..."
        label.font = .abankHeadline()
        label.textColor = .abankTextSecondary
        label.textAlignment = .center
        
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}


