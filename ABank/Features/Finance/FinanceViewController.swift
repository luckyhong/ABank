//
//  FinanceViewController.swift
//  ABank
//
//  Created by 韩继宏 on 2025/10/27.
//

import UIKit
import SnapKit

class WealthViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func setupUI() {
        view.backgroundColor = .abankBackground
        title = "财富"
        
        let label = UILabel()
        label.text = "财富功能开发中..."
        label.font = .abankHeadline()
        label.textColor = .abankTextSecondary
        label.textAlignment = .center
        
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

