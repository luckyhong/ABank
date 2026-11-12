import UIKit
import SnapKit

/// An in-memory shortcut for the current application session; no gesture secret is persisted.
@MainActor final class GestureSessionVerifier {
    static let shared = GestureSessionVerifier()
    private var sequence: [Int]?
    var isEnrolled: Bool { sequence != nil }
    func enroll(_ sequence: [Int]) { self.sequence = sequence }
    func verify(_ sequence: [Int]) -> Bool { self.sequence == sequence }
    func clear() { sequence = nil }
}

final class GestureAccessViewController: BaseViewController {
    private let enrolling: Bool
    private let completion: () -> Void
    private let hint = BankingPageStyle.text("", style: .headline)
    private let pad = GesturePadView()
    private var first: [Int]?
    private var attempts = 0
    init(enrolling: Bool, completion: @escaping () -> Void) {
        self.enrolling = enrolling; self.completion = completion
        super.init(nibName: nil, bundle: nil); hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func setupUI() {
        title = enrolling ? "设置手势" : "手势登录"; view.backgroundColor = .white
        hint.text = enrolling ? "连接至少4个点，设置登录手势" : "请连接已设置的手势"
        hint.textAlignment = .center
        let confirm = UIButton(type: .system); confirm.setTitle(enrolling ? "下一步" : "验证", for: .normal); confirm.tintColor = .abankPrimaryDark
        confirm.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        confirm.accessibilityIdentifier = "gesture.confirm"
        confirm.addAction(UIAction { [weak self] _ in self?.confirm() }, for: .touchUpInside)
        let reset = UIButton(type: .system); reset.setTitle("重新绘制", for: .normal)
        reset.addAction(UIAction { [weak self] _ in self?.pad.reset() }, for: .touchUpInside)
        [hint, pad, confirm, reset].forEach { view.addSubview($0) }
        hint.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(36); $0.leading.trailing.equalToSuperview().inset(20) }
        pad.snp.makeConstraints { $0.top.equalTo(hint.snp.bottom).offset(28); $0.centerX.equalToSuperview(); $0.width.lessThanOrEqualTo(300); $0.width.equalTo(view.snp.width).offset(-64).priority(750); $0.height.equalTo(pad.snp.width) }
        confirm.snp.makeConstraints { $0.top.equalTo(pad.snp.bottom).offset(20); $0.centerX.equalToSuperview(); $0.height.greaterThanOrEqualTo(44) }
        reset.snp.makeConstraints { $0.top.equalTo(confirm.snp.bottom).offset(6); $0.centerX.equalToSuperview(); $0.height.greaterThanOrEqualTo(44) }
    }
    private func confirm() {
        let value = pad.sequence
        guard value.count >= 4 else { hint.text = "请至少连接4个不同的点"; return }
        if enrolling {
            guard let first else { self.first = value; hint.text = "请再次连接相同手势"; pad.reset(); return }
            guard first == value else { self.first = nil; hint.text = "两次手势不一致，请重新设置"; pad.reset(); return }
            GestureSessionVerifier.shared.enroll(value); completion()
        } else {
            attempts += 1
            guard GestureSessionVerifier.shared.verify(value) else {
                hint.text = attempts >= 5 ? "请返回使用手机号验证" : "手势不正确，请重试"
                pad.isUserInteractionEnabled = attempts < 5; pad.reset(); return
            }
            completion()
        }
    }
}

private final class GesturePadView: UIView {
    private(set) var sequence: [Int] = []
    private var buttons: [UIButton] = []
    private let pathLayer = CAShapeLayer()
    override init(frame: CGRect) {
        super.init(frame: frame)
        pathLayer.strokeColor = UIColor.abankPrimaryDark.cgColor; pathLayer.fillColor = UIColor.clear.cgColor; pathLayer.lineWidth = 3
        layer.addSublayer(pathLayer)
        for index in 0..<9 {
            let button = UIButton(type: .system); button.tag = index
            button.setImage(UIImage(systemName: "circle"), for: .normal); button.tintColor = .abankPrimaryDark
            button.accessibilityLabel = "第\(index + 1)个点"
            button.addAction(UIAction { [weak self] _ in self?.select(index) }, for: .touchUpInside)
            addSubview(button); buttons.append(button)
        }
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        gesture.maximumNumberOfTouches = 1
        addGestureRecognizer(gesture)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layoutSubviews() {
        super.layoutSubviews()
        let side = bounds.width / 3
        for (index, button) in buttons.enumerated() { button.frame = CGRect(x: CGFloat(index % 3) * side, y: CGFloat(index / 3) * side, width: side, height: side) }
        updatePath()
    }
    private func select(_ index: Int) {
        guard !sequence.contains(index) else { return }
        sequence.append(index); buttons[index].setImage(UIImage(systemName: "circle.fill"), for: .normal); updatePath()
    }
    private func updatePath() {
        let path = UIBezierPath()
        for (offset, index) in sequence.enumerated() { let point = buttons[index].center; if offset == 0 { path.move(to: point) } else { path.addLine(to: point) } }
        pathLayer.path = path.cgPath
    }
    func reset() { sequence = []; buttons.forEach { $0.setImage(UIImage(systemName: "circle"), for: .normal) }; updatePath() }
    @objc private func pan(_ gesture: UIPanGestureRecognizer) {
        guard gesture.state != .cancelled && gesture.state != .failed else { reset(); return }
        let point = gesture.location(in: self)
        if let index = buttons.firstIndex(where: { $0.frame.insetBy(dx: 10, dy: 10).contains(point) }) { select(index) }
    }
}
