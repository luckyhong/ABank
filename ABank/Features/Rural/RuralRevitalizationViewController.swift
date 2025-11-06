//
//  RuralRevitalizationViewController.swift
//  ABank
//
//  Created by 韩继宏 on 2025/11/06.
//

import UIKit
import SnapKit

class RuralRevitalizationViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func setupUI() {
        view.backgroundColor = .abankBackground
        title = "乡村振兴"
        
        let label = UILabel()
        label.text = "乡村振兴专题开发中..."
        label.font = .abankHeadline()
        label.textColor = .abankTextSecondary
        label.textAlignment = .center
        
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}


