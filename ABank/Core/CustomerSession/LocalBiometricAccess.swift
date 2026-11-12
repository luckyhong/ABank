import Foundation
import LocalAuthentication

@MainActor enum LocalBiometricAccess {
    static func authenticate(completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        var failure: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &failure) else {
            completion(false, "请先在系统设置中录入面容或指纹，也可以使用手机号验证"); return
        }
        context.localizedFallbackTitle = "使用手机号验证"
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "验证身份后登录ABank") { passed, error in
            Task { @MainActor in completion(passed, error?.localizedDescription) }
        }
    }
}
