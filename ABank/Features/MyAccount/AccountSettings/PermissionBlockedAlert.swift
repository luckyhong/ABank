//
//  PermissionBlockedAlert.swift
//  ABank
//
//  交易权限关闭时的统一提示：说明哪项权限已关闭，并可直接去开启。
//

import UIKit

extension UIViewController {
    /// 是两种权限错误时弹窗并返回 true；其他错误返回 false，由调用方按原逻辑处理。
    @discardableResult
    func presentPermissionBlockedIfNeeded(_ error: Error, router: AppRouting) -> Bool {
        let message: String
        switch error {
        case let error as TransferError where error == .transferPermissionDisabled:
            message = error.localizedDescription
        case let error as PaymentError where error == .onlinePaymentDisabled:
            message = error.localizedDescription
        default:
            return false
        }
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "去开启", style: .default) { [weak self] _ in
            guard let self else { return }
            router.open(.accountPermissions(accountID: nil), from: self)
        })
        alert.view.accessibilityIdentifier = "permission.blocked"
        present(alert, animated: true)
        return true
    }
}
