import Foundation

@MainActor final class CustomerSessionStore {
    static let shared = CustomerSessionStore()
    static let didChange = Notification.Name("ABank.customerSessionDidChange")
    private let defaults: UserDefaults
    private let dates: BankingDateContext
    private let key = "abank.customerSession.signedIn"
    init(defaults: UserDefaults = .standard, dates: BankingDateContext = .system) {
        self.defaults = defaults; self.dates = dates
    }
    // Existing installations begin in the already-signed-in customer view.
    var isSignedIn: Bool { defaults.object(forKey: key) as? Bool ?? true }
    var lastLogin: String { defaults.string(forKey: key + ".date") ?? "" }
    func signIn() {
        defaults.set(dates.string(from: dates.now, format: "yyyy-MM-dd HH:mm:ss"), forKey: key + ".date")
        defaults.set(true, forKey: key)
        NotificationCenter.default.post(name: Self.didChange, object: self)
    }
    func signOut() {
        defaults.set(false, forKey: key)
        NotificationCenter.default.post(name: Self.didChange, object: self)
    }
}

/// Codes are memory-only, bound to the requested phone, with expiry, throttling and attempt limits.
@MainActor final class VerificationChallenge {
    enum Failure: LocalizedError {
        case phone, cooldown(Int), notRequested, expired, incorrect(Int), locked
        var errorDescription: String? {
            switch self {
            case .phone: return "请输入有效的11位手机号码"
            case .cooldown(let seconds): return "请在\(seconds)秒后重新获取"
            case .notRequested: return "请先获取该手机号的验证码"
            case .expired: return "验证码已过期，请重新获取"
            case .incorrect(let remaining): return "验证码不正确，还可尝试\(remaining)次"
            case .locked: return "尝试次数已用完，请重新获取验证码"
            }
        }
    }
    private let clock: () -> Date
    private let codeProvider: () -> String
    private var phone: String?
    private var code: String?
    private var issuedAt: Date?
    private var attempts = 0
    init(clock: @escaping () -> Date = { Date() }, codeProvider: @escaping () -> String = { String(format: "%06d", Int.random(in: 0...999_999)) }) {
        self.clock = clock; self.codeProvider = codeProvider
    }
    var resendSeconds: Int { issuedAt.map { max(0, Int(ceil(60 - clock().timeIntervalSince($0)))) } ?? 0 }
    func request(phone: String) throws -> String {
        guard PaymentRules.isValidPhone(phone) else { throw Failure.phone }
        guard resendSeconds == 0 else { throw Failure.cooldown(resendSeconds) }
        self.phone = phone; code = codeProvider(); issuedAt = clock(); attempts = 0
        return code!
    }
    func verify(phone: String, code: String) throws {
        guard self.phone == phone, let expected = self.code, let issuedAt else { throw Failure.notRequested }
        guard clock().timeIntervalSince(issuedAt) >= 0, clock().timeIntervalSince(issuedAt) < 300 else { throw Failure.expired }
        guard attempts < 5 else { throw Failure.locked }
        guard expected == code else { attempts += 1; throw attempts == 5 ? Failure.locked : Failure.incorrect(5 - attempts) }
        self.code = nil
    }
}
