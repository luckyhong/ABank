import UIKit
import SnapKit

final class CustomerLoginViewController: TransferFlowViewController {
    private let phone = TransferInputRow("手机号码", placeholder: "请输入已登记手机号", id: "login.phone", keyboard: .phonePad)
    private let code = TransferInputRow("验证码", placeholder: "请输入6位验证码", id: "login.code", keyboard: .numberPad)
    private let challenge = VerificationChallenge()
    private let errorLabel = UILabel()
    override func setupUI() {
        super.setupUI(); title = "登录"
        let brand = UIImageView(image: UIImage.abankAsset("abc_account_bank_logo", fallback: "building.columns"))
        brand.contentMode = .scaleAspectFit; brand.snp.makeConstraints { $0.height.equalTo(72) }
        contentStack.addArrangedSubview(brand)
        addNotice("欢迎回来，请验证已登记手机号后查看账户")
        phone.field.textContentType = .telephoneNumber
        code.field.textContentType = .oneTimeCode
        addGroup([phone, code])
        _ = addButton("获取验证码", id: "login.request", primary: false) { [weak self] in self?.requestCode() }
        errorLabel.textColor = .abankError; errorLabel.font = .preferredFont(forTextStyle: .subheadline); errorLabel.numberOfLines = 0
        contentStack.addArrangedSubview(errorLabel)
        _ = addButton("登录", id: "login.submit") { [weak self] in self?.signIn() }
        if SecuritySettingsStore.shared.settings.faceIDLoginEnabled {
            _ = addButton("面容 / 指纹登录", id: "login.biometric", primary: false) { [weak self] in
                LocalBiometricAccess.authenticate { [weak self] passed, message in
                    if passed { CustomerSessionStore.shared.signIn() }
                    else { self?.errorLabel.text = message ?? "请使用手机号验证" }
                }
            }
        }
        if SecuritySettingsStore.shared.settings.gestureLoginEnabled && GestureSessionVerifier.shared.isEnrolled {
            _ = addButton("手势登录", id: "login.gesture", primary: false) { [weak self] in
                self?.navigationController?.pushViewController(GestureAccessViewController(enrolling: false) { CustomerSessionStore.shared.signIn() }, animated: true)
            }
        }
    }
    private func requestCode() {
        view.endEditing(true)
        do {
            let number = phone.field.text ?? ""
            guard number == CustomerInfoStore.shared.load().mobile else { throw VerificationChallenge.Failure.phone }
            let value = try challenge.request(phone: number)
            Self.presentCode(value, from: self)
            errorLabel.text = nil
        } catch { errorLabel.text = error.localizedDescription }
    }
    private func signIn() {
        do {
            try challenge.verify(phone: phone.field.text ?? "", code: code.field.text ?? "")
            CustomerSessionStore.shared.signIn()
        } catch { errorLabel.text = error.localizedDescription }
    }
    static func presentCode(_ code: String, from controller: UIViewController) {
        let alert = UIAlertController(title: "验证码", message: code + "\n请在5分钟内完成验证", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "知道了", style: .default))
        controller.present(alert, animated: true)
    }
}
