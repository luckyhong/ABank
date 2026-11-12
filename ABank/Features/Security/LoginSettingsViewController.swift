//
//  LoginSettingsViewController.swift
//  ABank
//
//  登录设置：本机生物识别与本次运行内的手势验证。
//

import UIKit

final class LoginSettingsViewController: SecurityFlowViewController, RouteHosting {
    private let faceIDRow = SecuritySwitchRow(title: "生物识别登录", subtitle: "使用本机面容或指纹快捷登录", id: "loginSettings.faceID")
    private let gestureRow = SecuritySwitchRow(title: "手势密码登录", subtitle: "绘制手势图案登录", id: "loginSettings.gesture")

    var hostedRoute: AppRoute? { .loginSettings }

    override func setupUI() {
        super.setupUI()
        title = "登录设置"
        faceIDRow.onChange = { [weak self] enabled in
            guard let self else { return }
            guard enabled else { self.handleSaveResult(self.security.setFaceIDLogin(false)) { self.faceIDRow.setOn(true, animated: true) }; return }
            LocalBiometricAccess.authenticate { [weak self] passed, message in
                guard let self else { return }
                if passed { self.handleSaveResult(self.security.setFaceIDLogin(true)) { self.faceIDRow.setOn(false, animated: true) } }
                else { self.faceIDRow.setOn(false, animated: true); self.showToast(message ?? "身份验证未完成") }
            }
        }
        gestureRow.onChange = { [weak self] enabled in
            guard let self else { return }
            if !enabled { GestureSessionVerifier.shared.clear(); self.handleSaveResult(self.security.setGestureLogin(false)) {}; return }
            self.gestureRow.setOn(false, animated: false)
            let controller = GestureAccessViewController(enrolling: true) { [weak self] in
                guard let self else { return }
                self.handleSaveResult(self.security.setGestureLogin(true)) { GestureSessionVerifier.shared.clear() }
                self.navigationController?.popViewController(animated: true)
            }
            self.navigationController?.pushViewController(controller, animated: true)
        }
        addGroup([faceIDRow, gestureRow])
        addNotice("关闭应用后请使用手机号重新验证，手势可在登录后重新设置")
    }

    override func refreshBankingData() {
        faceIDRow.setOn(security.settings.faceIDLoginEnabled, animated: false)
        gestureRow.setOn(security.settings.gestureLoginEnabled && GestureSessionVerifier.shared.isEnrolled, animated: false)
    }
}
