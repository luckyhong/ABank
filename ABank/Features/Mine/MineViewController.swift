//
//  MineViewController.swift
//  ABank
//
//  Created by 韩继宏 on 2025/10/27.
//

import UIKit
import SnapKit

class MineViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func setupUI() {
        view.backgroundColor = .abankBackground
        title = "我的"
        
        let label = UILabel()
        label.text = "个人中心功能开发中..."
        label.font = .abankHeadline()
        label.textColor = .abankTextSecondary
        label.textAlignment = .center
        
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

