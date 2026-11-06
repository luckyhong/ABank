//
//  FeatureDescriptor+UI.swift
//  ABank
//

import UIKit

extension FeatureDescriptor {
    /// 优先使用农行切图，缺失时回退系统图标。
    func iconImage(pointSize: CGFloat? = nil) -> UIImage? {
        UIImage.abankAsset(imageName ?? "", fallback: systemIcon, pointSize: pointSize)
    }
}
