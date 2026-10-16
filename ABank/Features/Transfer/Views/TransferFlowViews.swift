import UIKit
import SnapKit

/// Shared typography and surfaces for locally reconstructed transfer subpages.
class TransferFlowViewController: BankingDataViewController {
    let scrollView = UIScrollView()
    let contentStack = UIStackView()

    override func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.tintColor = .abankTextPrimary
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [.foregroundColor: UIColor.abankTextPrimary,
                                          .font: UIFont.systemFont(ofSize: 17, weight: .semibold)]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationItem.backButtonTitle = ""
    }

    override func setupUI() {
        view.backgroundColor = .abankBackground
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
        contentStack.axis = .vertical
        contentStack.spacing = 12
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        scrollView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
        }
        contentStack.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide).inset(16)
            $0.width.equalTo(scrollView.frameLayoutGuide).offset(-32)
        }
    }

    func addNotice(_ text: String = "本机模拟 · 不发生真实资金交易") {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 13)
        label.textColor = .abankTextSecondary
        label.numberOfLines = 0
        contentStack.addArrangedSubview(label)
    }

    func addGroup(_ rows: [UIView]) {
        let stack = UIStackView(arrangedSubviews: rows)
        stack.axis = .vertical
        stack.backgroundColor = .white
        stack.layer.cornerRadius = 10
        stack.clipsToBounds = true
        contentStack.addArrangedSubview(stack)
    }

    func addButton(_ title: String, id: String, primary: Bool = true, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.setTitleColor(primary ? .white : .abankTeal, for: .normal)
        button.backgroundColor = primary ? .abankTeal : .white
        button.layer.cornerRadius = 8
        button.accessibilityIdentifier = id
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        button.snp.makeConstraints { $0.height.equalTo(48) }
        contentStack.addArrangedSubview(button)
        return button
    }

    func addError(_ error: Error) {
        let alert = UIAlertController(title: "请检查转账信息", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "知道了", style: .default))
        present(alert, animated: true)
    }
}

final class TransferInfoRow: UIView {
    let valueLabel = UILabel()
    init(_ title: String, value: String, image: String? = nil, emphasized: Bool = false) {
        super.init(frame: .zero)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.textColor = .abankTextSecondary
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: emphasized ? 23 : 16, weight: emphasized ? .medium : .regular)
        valueLabel.textColor = .abankTextPrimary
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 0
        valueLabel.accessibilityIdentifier = "transfer.value.\(title)"
        let horizontal = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        horizontal.spacing = 16
        horizontal.alignment = .center
        if let image {
            let icon = UIImageView(image: UIImage.abankAsset(image, fallback: "creditcard"))
            icon.contentMode = .scaleAspectFit
            icon.snp.makeConstraints { $0.size.equalTo(25) }
            horizontal.insertArrangedSubview(icon, at: 0)
        }
        addSubview(horizontal)
        horizontal.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(58) }
        let line = UIView()
        line.backgroundColor = .abankSeparator.withAlphaComponent(0.5)
        addSubview(line)
        line.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(16); $0.bottom.equalToSuperview(); $0.height.equalTo(0.5) }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class TransferInputRow: UIView {
    let field = UITextField()
    init(_ title: String, placeholder: String, id: String, keyboard: UIKeyboardType = .default) {
        super.init(frame: .zero)
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16)
        label.textColor = .abankTextPrimary
        addSubview(label)
        addSubview(field)
        label.snp.makeConstraints { $0.leading.equalToSuperview().offset(16); $0.centerY.equalToSuperview(); $0.width.equalTo(88) }
        field.font = .systemFont(ofSize: 16)
        field.textColor = .abankTextPrimary
        field.placeholder = placeholder
        field.keyboardType = keyboard
        field.autocorrectionType = .no
        field.accessibilityIdentifier = id
        field.clearButtonMode = .whileEditing
        field.adjustsFontSizeToFitWidth = true
        field.minimumFontSize = 12
        field.snp.makeConstraints { $0.leading.equalTo(label.snp.trailing).offset(8); $0.trailing.equalToSuperview().offset(-16); $0.top.bottom.equalToSuperview().inset(16) }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(60) }
        let line = UIView()
        line.backgroundColor = .abankSeparator.withAlphaComponent(0.5)
        addSubview(line)
        line.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(16); $0.bottom.equalToSuperview(); $0.height.equalTo(0.5) }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

enum TransferFlowNavigation {
    static func finish(_ controller: UIViewController) {
        guard let nav = controller.navigationController else { return }
        if let home = nav.viewControllers.first(where: { $0 is TransferViewController }) {
            nav.popToViewController(home, animated: true)
        } else { nav.popToRootViewController(animated: true) }
    }
}

final class TransferHistoryCell: UITableViewCell {
    private let nameLabel = UILabel()
    private let amountLabel = UILabel()
    private let detailLabel = UILabel()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        let icon = UIImageView(image: UIImage.abankAsset("abc_transfer_record", fallback: "doc.text"))
        icon.contentMode = .scaleAspectFit
        nameLabel.font = .systemFont(ofSize: 17)
        nameLabel.textColor = .abankTextPrimary
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        amountLabel.font = .systemFont(ofSize: 17, weight: .medium)
        amountLabel.textColor = .abankTextPrimary
        amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)
        detailLabel.font = .systemFont(ofSize: 13)
        detailLabel.numberOfLines = 2
        [icon, nameLabel, amountLabel, detailLabel].forEach { contentView.addSubview($0) }
        icon.snp.makeConstraints { $0.leading.equalToSuperview().offset(16); $0.centerY.equalToSuperview(); $0.size.equalTo(26) }
        nameLabel.snp.makeConstraints { $0.leading.equalTo(icon.snp.trailing).offset(12); $0.top.equalToSuperview().offset(12); $0.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-8) }
        amountLabel.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-8); $0.centerY.equalTo(nameLabel) }
        detailLabel.snp.makeConstraints { $0.leading.equalTo(nameLabel); $0.top.equalTo(nameLabel.snp.bottom).offset(5); $0.trailing.equalTo(amountLabel); $0.bottom.lessThanOrEqualToSuperview().offset(-10) }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(_ record: TransferRecord) {
        nameLabel.text = record.recipientName
        amountLabel.text = "¥ " + TransferMoney.amount(record.amountInCents).abankPlainAmountString()
        detailLabel.text = record.createdAt + "\n" + record.status.title
        detailLabel.textColor = record.status == .succeeded ? .abankTextSecondary : .abankOrangeDeep
    }
}
