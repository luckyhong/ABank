//
//  TransferViewController.swift
//  ABank
//
//  Created by 韩继宏 on 2025/10/27.
//

import UIKit
import SnapKit

class TransferViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func setupUI() {
        view.backgroundColor = .abankBackground
        title = "转账"
        
        let label = UILabel()
        label.text = "转账功能开发中..."
        label.font = .abankHeadline()
        label.textColor = .abankTextSecondary
        label.textAlignment = .center
        
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

