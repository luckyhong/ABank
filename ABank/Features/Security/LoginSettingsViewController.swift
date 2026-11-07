//
//  LoginSettingsViewController.swift
//  ABank
//
//  登录设置：面容 ID / 手势密码演示开关，只保存状态，不做真实验证。
//

import UIKit

final class LoginSettingsViewController: SecurityFlowViewController, RouteHosting {
    private let faceIDRow = SecuritySwitchRow(title: "面容 ID 登录", subtitle: "使用面容快速登录", id: "loginSettings.faceID")
    private let gestureRow = SecuritySwitchRow(title: "手势密码登录", subtitle: "绘制手势图案登录", id: "loginSettings.gesture")

    var hostedRoute: AppRoute? { .loginSettings }

    override func setupUI() {
        super.setupUI()
        title = "登录设置"
        faceIDRow.onChange = { [weak self] enabled in
            guard let self else { return }
            self.handleSaveResult(self.security.setFaceIDLogin(enabled)) { self.faceIDRow.setOn(!enabled, animated: true) }
        }
        gestureRow.onChange = { [weak self] enabled in
            guard let self else { return }
            self.handleSaveResult(self.security.setGestureLogin(enabled)) { self.gestureRow.setOn(!enabled, animated: true) }
        }
        addGroup([faceIDRow, gestureRow])
        addNotice("演示设置，不做真实验证")
    }

    override func refreshBankingData() {
        faceIDRow.setOn(security.settings.faceIDLoginEnabled, animated: false)
        gestureRow.setOn(security.settings.gestureLoginEnabled, animated: false)
    }
}
