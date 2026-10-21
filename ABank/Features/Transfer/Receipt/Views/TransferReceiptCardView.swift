import UIKit
import SnapKit

/// 回单卡片：页面展示与分享图片共用同一视图，模拟标记与水印始终可见；不使用任何银行印章。
final class TransferReceiptCardView: UIView {
    private let contentStack = UIStackView()
    private let watermark = TransferReceiptWatermarkView()

    init(receipt: TransferReceipt) {
        super.init(frame: .zero)
        backgroundColor = .white
        layer.cornerRadius = CornerRadius.md
        clipsToBounds = true
        accessibilityIdentifier = "receipt.card"

        let titleLabel = UILabel()
        titleLabel.text = "电子回单"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .abankTextPrimary
        titleLabel.textAlignment = .center

        let markLabel = UILabel()
        markLabel.text = "  \(TransferReceipt.simulationMark)  "
        markLabel.font = .systemFont(ofSize: 12, weight: .medium)
        markLabel.textColor = .abankOrangeDeep
        markLabel.layer.borderColor = UIColor.abankOrangeDeep.cgColor
        markLabel.layer.borderWidth = 1
        markLabel.layer.cornerRadius = 4
        markLabel.accessibilityIdentifier = "receipt.simulationMark"
        let markRow = UIStackView(arrangedSubviews: [markLabel])
        markRow.alignment = .center
        markRow.axis = .vertical

        let amountLabel = UILabel()
        amountLabel.text = receipt.amountText
        amountLabel.font = .systemFont(ofSize: 28, weight: .semibold)
        amountLabel.textColor = .abankTextPrimary
        amountLabel.textAlignment = .center
        amountLabel.adjustsFontSizeToFitWidth = true
        amountLabel.minimumScaleFactor = 0.5
        amountLabel.accessibilityIdentifier = "receipt.amount"

        let wordsLabel = UILabel()
        wordsLabel.text = "人民币" + receipt.amountInWords
        wordsLabel.font = .systemFont(ofSize: 13)
        wordsLabel.textColor = .abankTextSecondary
        wordsLabel.textAlignment = .center
        wordsLabel.numberOfLines = 0
        wordsLabel.accessibilityIdentifier = "receipt.amountInWords"

        contentStack.axis = .vertical
        contentStack.spacing = 0
        [titleLabel, markRow, amountLabel, wordsLabel].forEach { contentStack.addArrangedSubview($0) }
        contentStack.setCustomSpacing(10, after: titleLabel)
        contentStack.setCustomSpacing(18, after: markRow)
        contentStack.setCustomSpacing(6, after: amountLabel)
        contentStack.setCustomSpacing(16, after: wordsLabel)

        contentStack.addArrangedSubview(Self.divider())
        let rows: [(String, String)] = [
            ("交易状态", receipt.statusText),
            ("交易时间", receipt.createdAt),
            ("回单编号", receipt.receiptNumber),
            ("付款账户", "\(receipt.payerLabel)\n\(receipt.payerMaskedCard)"),
            ("收款人", receipt.payeeName),
            (receipt.method == .account ? "收款账号" : "收款手机号", receipt.payeeMaskedDestination),
            ("收款银行", receipt.payeeBank),
            ("转账方式", receipt.method.title),
            ("附言", receipt.note.isEmpty ? "无" : receipt.note),
            ("交易渠道", "本机模拟")
        ]
        rows.forEach { contentStack.addArrangedSubview(Self.row(title: $0.0, value: $0.1)) }
        contentStack.addArrangedSubview(Self.divider())

        let disclaimer = UILabel()
        disclaimer.text = TransferReceipt.disclaimer
        disclaimer.font = .systemFont(ofSize: 11)
        disclaimer.textColor = .abankTextTertiary
        disclaimer.numberOfLines = 0
        contentStack.setCustomSpacing(12, after: contentStack.arrangedSubviews.last!)
        contentStack.addArrangedSubview(disclaimer)

        addSubview(contentStack)
        addSubview(watermark)
        contentStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 20, left: 18, bottom: 18, right: 18)) }
        watermark.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// 生成分享用图片，尺寸取当前布局。
    func renderImage() -> UIImage {
        layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        return UIGraphicsImageRenderer(bounds: bounds, format: format).image { context in
            if window == nil || !drawHierarchy(in: bounds, afterScreenUpdates: true) {
                layer.render(in: context.cgContext)
            }
        }
    }

    private static func row(title: String, value: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .abankTextSecondary
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14)
        valueLabel.textColor = .abankTextPrimary
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 0
        valueLabel.accessibilityIdentifier = "receipt.value.\(title)"
        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.spacing = 16
        stack.alignment = .top
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        return stack
    }

    private static func divider() -> UIView {
        let line = UIView()
        line.backgroundColor = .abankSeparator
        line.snp.makeConstraints { $0.height.equalTo(0.5) }
        return line
    }
}

/// 斜向重复的「模拟交易」浅色水印。
private final class TransferReceiptWatermarkView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        contentMode = .redraw
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
            .foregroundColor: UIColor.abankOrangeDeep.withAlphaComponent(0.07)
        ]
        let text = "模拟交易" as NSString
        let size = text.size(withAttributes: attributes)
        context.saveGState()
        context.translateBy(x: bounds.midX, y: bounds.midY)
        context.rotate(by: -.pi / 6)
        let span = max(bounds.width, bounds.height)
        var y = -span
        while y < span {
            var x = -span
            while x < span {
                text.draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
                x += size.width + 48
            }
            y += size.height + 56
        }
        context.restoreGState()
    }
}
