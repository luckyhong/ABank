//
//  IncomeExpenseDetailViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class IncomeExpenseDetailViewController: BaseViewController {

    private let transactionId: String
    private var transaction: LedgerTransaction
    private var isDetailExpanded = false

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let headerIconBackground = UIView()
    private let headerIconView = UIImageView()
    private let headerTitleLabel = UILabel()
    private let amountLabel = UILabel()
    private let balanceLabel = UILabel()

    private let infoStack = UIStackView()
    private let expandButton = UIButton(type: .system)

    private let includeRow = IncomeExpenseDetailToggleRow(title: "计入收支")
    private let categoryRow = IncomeExpenseDetailSelectRow(title: "分类")
    private let ledgerRow = IncomeExpenseDetailSelectRow(title: "归属账本")
    private let settingsCard = UIView()

    private let noteTitleLabel = UILabel()
    private let noteField = UITextField()
    private let noteUnderline = UIView()

    private let accentOrange = UIColor(red: 220 / 255, green: 150 / 255, blue: 40 / 255, alpha: 1)
    private let sectionGapColor = UIColor(red: 245 / 255, green: 245 / 255, blue: 247 / 255, alpha: 1)

    private var primaryInfoRows: [IncomeExpenseDetailInfoRow] = []
    private var extraInfoRows: [IncomeExpenseDetailInfoRow] = []
    private weak var activeSheet: UIView?

    init(transaction: LedgerTransaction) {
        self.transactionId = transaction.id
        self.transaction = transaction
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "收支详情"
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.tintColor = .abankTextPrimary
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadTransaction()
    }

    override func setupUI() {
        view.backgroundColor = .white

        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .onDrag
        scrollView.showsVerticalScrollIndicator = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        setupHeader()
        setupInfoSection()
        setupSettingsSection()
        setupNoteSection()
        bindActions()
        applyTransaction()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ledgerDidChange),
            name: .financeLedgerDidChange,
            object: nil
        )

        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingTap))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Sections

    private func setupHeader() {
        headerIconBackground.layer.cornerRadius = 6
        headerIconBackground.clipsToBounds = true
        headerIconView.contentMode = .scaleAspectFit

        headerTitleLabel.font = .systemFont(ofSize: 15)
        headerTitleLabel.textColor = .abankTextPrimary
        headerTitleLabel.numberOfLines = 2
        headerTitleLabel.textAlignment = .center

        amountLabel.font = .systemFont(ofSize: 32, weight: .medium)
        amountLabel.textColor = .abankTextPrimary
        amountLabel.textAlignment = .center

        balanceLabel.font = .systemFont(ofSize: 13)
        balanceLabel.textColor = .abankTextTertiary
        balanceLabel.textAlignment = .center

        let titleRow = UIStackView(arrangedSubviews: [headerIconBackground, headerTitleLabel])
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 8

        contentView.addSubview(titleRow)
        contentView.addSubview(amountLabel)
        contentView.addSubview(balanceLabel)

        headerIconBackground.addSubview(headerIconView)
        headerIconBackground.snp.makeConstraints { make in
            make.size.equalTo(22)
        }
        headerIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(14)
        }

        titleRow.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
        }
        amountLabel.snp.makeConstraints { make in
            make.top.equalTo(titleRow.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        balanceLabel.snp.makeConstraints { make in
            make.top.equalTo(amountLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }
    }

    private func setupInfoSection() {
        infoStack.axis = .vertical
        infoStack.alignment = .fill
        infoStack.spacing = 0

        primaryInfoRows = [
            makeInfoRow(title: "交易时间"),
            makeInfoRow(title: "对方户名"),
            makeInfoRow(title: "对方账户"),
            makeInfoRow(title: "交易摘要"),
            makeInfoRow(title: "交易附言")
        ]
        extraInfoRows = [
            makeInfoRow(title: "交易卡号"),
            makeInfoRow(title: "交易类型")
        ]
        primaryInfoRows.forEach { infoStack.addArrangedSubview($0) }
        extraInfoRows.forEach {
            infoStack.addArrangedSubview($0)
            $0.isHidden = true
        }

        expandButton.setTitle("查看更多", for: .normal)
        expandButton.setTitleColor(accentOrange, for: .normal)
        expandButton.titleLabel?.font = .systemFont(ofSize: 14)
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 9, weight: .semibold)
        expandButton.setImage(UIImage(systemName: "chevron.down", withConfiguration: chevronConfig), for: .normal)
        expandButton.tintColor = accentOrange
        expandButton.semanticContentAttribute = .forceRightToLeft
        expandButton.imageEdgeInsets = UIEdgeInsets(top: 1, left: 4, bottom: 0, right: 0)
        expandButton.addTarget(self, action: #selector(expandTapped), for: .touchUpInside)

        contentView.addSubview(infoStack)
        contentView.addSubview(expandButton)

        infoStack.snp.makeConstraints { make in
            make.top.equalTo(balanceLabel.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        expandButton.snp.makeConstraints { make in
            make.top.equalTo(infoStack.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.height.equalTo(36)
        }
    }

    private func setupSettingsSection() {
        let topGap = makeGapView()
        settingsCard.backgroundColor = .white

        contentView.addSubview(topGap)
        contentView.addSubview(settingsCard)
        settingsCard.addSubview(includeRow)
        settingsCard.addSubview(categoryRow)
        settingsCard.addSubview(ledgerRow)

        topGap.snp.makeConstraints { make in
            make.top.equalTo(expandButton.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(10)
        }
        settingsCard.snp.makeConstraints { make in
            make.top.equalTo(topGap.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }
        includeRow.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(52)
        }
        categoryRow.snp.makeConstraints { make in
            make.top.equalTo(includeRow.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(52)
        }
        ledgerRow.snp.makeConstraints { make in
            make.top.equalTo(categoryRow.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(52)
        }
    }

    private func setupNoteSection() {
        let gap = makeGapView()
        let noteCard = UIView()
        noteCard.backgroundColor = .white

        noteTitleLabel.text = "备注"
        noteTitleLabel.font = .systemFont(ofSize: 15)
        noteTitleLabel.textColor = .abankTextPrimary

        noteField.placeholder = "记录点什么……"
        noteField.font = .systemFont(ofSize: 15)
        noteField.textColor = .abankTextPrimary
        noteField.clearButtonMode = .whileEditing
        noteField.returnKeyType = .done
        noteField.delegate = self
        noteField.addTarget(self, action: #selector(noteEditingEnded), for: .editingDidEnd)

        noteUnderline.backgroundColor = .abankSeparator

        contentView.addSubview(gap)
        contentView.addSubview(noteCard)
        noteCard.addSubview(noteTitleLabel)
        noteCard.addSubview(noteField)
        noteCard.addSubview(noteUnderline)

        gap.snp.makeConstraints { make in
            make.top.equalTo(settingsCard.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(10)
        }
        noteCard.snp.makeConstraints { make in
            make.top.equalTo(gap.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-40)
        }
        noteTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
        }
        noteField.snp.makeConstraints { make in
            make.top.equalTo(noteTitleLabel.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(36)
        }
        noteUnderline.snp.makeConstraints { make in
            make.top.equalTo(noteField.snp.bottom)
            make.leading.trailing.equalTo(noteField)
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview().offset(-20)
        }
    }

    private func makeGapView() -> UIView {
        let view = UIView()
        view.backgroundColor = sectionGapColor
        return view
    }

    private func makeInfoRow(title: String) -> IncomeExpenseDetailInfoRow {
        IncomeExpenseDetailInfoRow(title: title)
    }

    // MARK: - Bind / Apply

    private func bindActions() {
        includeRow.onToggle = { [weak self] isOn in
            guard let self else { return }
            FinanceLedgerStore.shared.updateTransactionDetail(id: self.transactionId, includeInFlow: isOn)
        }
        categoryRow.onTap = { [weak self] in self?.showCategoryPicker() }
        ledgerRow.onTap = { [weak self] in self?.showLedgerPicker() }
    }

    private func reloadTransaction() {
        guard let latest = FinanceLedgerStore.shared.transaction(id: transactionId) else { return }
        transaction = latest
        applyTransaction()
    }

    @objc private func ledgerDidChange() {
        reloadTransaction()
    }

    private func applyTransaction() {
        headerTitleLabel.text = transaction.title
        amountLabel.text = transaction.signedAmountText
        balanceLabel.text = "余额 ¥ \(transaction.balanceAfter.abankPlainAmountString())"

        let style = Self.iconStyle(for: transaction)
        headerIconBackground.backgroundColor = style.background
        let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        headerIconView.image = UIImage(systemName: style.symbol, withConfiguration: config)
        headerIconView.tintColor = style.tint

        primaryInfoRows[0].configure(value: transaction.datetimeText)
        primaryInfoRows[1].configure(value: transaction.counterpartyName)
        primaryInfoRows[2].configure(value: transaction.counterpartyAccount)
        primaryInfoRows[3].configure(value: transaction.summary)
        primaryInfoRows[4].configure(value: transaction.postscript)
        extraInfoRows[0].configure(value: transaction.cardNumber)
        extraInfoRows[1].configure(value: transaction.transactionType)

        includeRow.setOn(transaction.includeInFlow)
        categoryRow.configure(value: transaction.categoryTitle, placeholder: false)
        if let ledgerTitle = LedgerBookCatalog.title(for: transaction.ledgerId) {
            ledgerRow.configure(value: ledgerTitle, placeholder: false)
        } else {
            ledgerRow.configure(value: "请选择", placeholder: true)
        }
        noteField.text = transaction.note

        refreshExpandState(animated: false)
    }

    private func refreshExpandState(animated: Bool) {
        extraInfoRows.forEach { $0.isHidden = !isDetailExpanded }
        let title = isDetailExpanded ? "收起" : "查看更多"
        let symbol = isDetailExpanded ? "chevron.up" : "chevron.down"
        expandButton.setTitle(title, for: .normal)
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 9, weight: .semibold)
        expandButton.setImage(UIImage(systemName: symbol, withConfiguration: chevronConfig), for: .normal)

        let updates = {
            self.infoStack.layoutIfNeeded()
            self.contentView.layoutIfNeeded()
        }
        if animated {
            UIView.animate(withDuration: 0.25, animations: updates)
        } else {
            updates()
        }
    }

    // MARK: - Pickers

    private func showCategoryPicker() {
        dismissActiveSheet()
        let options = IncomeExpenseFilterCatalog.selectableOptions(for: transaction.direction)
        let sheet = IncomeExpenseOptionPickerSheet()
        sheet.onSelect = { [weak self] id in
            guard let self else { return }
            FinanceLedgerStore.shared.updateTransactionDetail(id: self.transactionId, categoryId: id)
            self.activeSheet = nil
        }
        sheet.onCancel = { [weak self] in self?.activeSheet = nil }
        sheet.present(
            in: navigationController?.view ?? view,
            title: "选择分类",
            options: options.map { ($0.id, $0.title) },
            selectedId: transaction.categoryId
        )
        activeSheet = sheet
    }

    private func showLedgerPicker() {
        dismissActiveSheet()
        let sheet = IncomeExpenseOptionPickerSheet()
        sheet.onSelect = { [weak self] id in
            guard let self else { return }
            FinanceLedgerStore.shared.updateTransactionLedger(id: self.transactionId, ledgerId: id)
            self.activeSheet = nil
        }
        sheet.onCancel = { [weak self] in self?.activeSheet = nil }
        sheet.present(
            in: navigationController?.view ?? view,
            title: "归属账本",
            options: LedgerBookCatalog.options.map { ($0.id, $0.title) },
            selectedId: transaction.ledgerId
        )
        activeSheet = sheet
    }

    private func dismissActiveSheet() {
        activeSheet?.removeFromSuperview()
        activeSheet = nil
    }

    // MARK: - Actions

    @objc private func backTapped() {
        view.endEditing(true)
        noteEditingEnded()
        navigationController?.popViewController(animated: true)
    }

    @objc private func expandTapped() {
        isDetailExpanded.toggle()
        refreshExpandState(animated: true)
    }

    @objc private func noteEditingEnded() {
        let text = noteField.text ?? ""
        if text != transaction.note {
            FinanceLedgerStore.shared.updateTransactionDetail(id: transactionId, note: text)
        }
    }

    @objc private func endEditingTap() {
        view.endEditing(true)
    }

    private struct IconStyle {
        let symbol: String
        let tint: UIColor
        let background: UIColor
    }

    private static func iconStyle(for tx: LedgerTransaction) -> IconStyle {
        switch tx.iconKey {
        case "music.note":
            return IconStyle(
                symbol: "play.rectangle.fill",
                tint: .white,
                background: UIColor(red: 20 / 255, green: 180 / 255, blue: 140 / 255, alpha: 1)
            )
        case "yensign.circle":
            return IconStyle(
                symbol: "person.fill",
                tint: UIColor(red: 160 / 255, green: 160 / 255, blue: 160 / 255, alpha: 1),
                background: UIColor(red: 240 / 255, green: 240 / 255, blue: 240 / 255, alpha: 1)
            )
        case "a.circle":
            return IconStyle(
                symbol: "a.circle.fill",
                tint: .white,
                background: UIColor(red: 20 / 255, green: 150 / 255, blue: 230 / 255, alpha: 1)
            )
        case "message":
            return IconStyle(
                symbol: "message.fill",
                tint: .white,
                background: UIColor(red: 40 / 255, green: 190 / 255, blue: 90 / 255, alpha: 1)
            )
        case "person.crop.circle":
            return IconStyle(
                symbol: "person.fill",
                tint: .white,
                background: UIColor(red: 70 / 255, green: 150 / 255, blue: 230 / 255, alpha: 1)
            )
        case "creditcard":
            return IconStyle(
                symbol: "creditcard.fill",
                tint: .white,
                background: UIColor(red: 30 / 255, green: 190 / 255, blue: 100 / 255, alpha: 1)
            )
        default:
            return IconStyle(symbol: tx.iconKey, tint: .white, background: .abankTeal)
        }
    }
}

extension IncomeExpenseDetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Info row

private final class IncomeExpenseDetailInfoRow: UIView {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .abankTextTertiary
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        valueLabel.font = .systemFont(ofSize: 14)
        valueLabel.textColor = .abankTextPrimary
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 0

        addSubview(titleLabel)
        addSubview(valueLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(10)
            make.width.equalTo(72)
        }
        valueLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(16)
            make.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(value: String) {
        valueLabel.text = value.isEmpty ? "-" : value
    }
}

// MARK: - Toggle row

private final class IncomeExpenseDetailToggleRow: UIView {
    var onToggle: ((Bool) -> Void)?

    private let titleLabel = UILabel()
    private let toggle = UISwitch()
    private let separator = UIView()

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.textColor = .abankTextPrimary

        toggle.onTintColor = .abankPrimary
        toggle.addTarget(self, action: #selector(changed), for: .valueChanged)

        separator.backgroundColor = .abankSeparator

        addSubview(titleLabel)
        addSubview(toggle)
        addSubview(separator)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        toggle.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        separator.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setOn(_ on: Bool) {
        toggle.isOn = on
    }

    @objc private func changed() {
        onToggle?(toggle.isOn)
    }
}

// MARK: - Select row

private final class IncomeExpenseDetailSelectRow: UIControl {
    var onTap: (() -> Void)?

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let arrowView = UIImageView()
    private let separator = UIView()

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.textColor = .abankTextPrimary

        valueLabel.font = .systemFont(ofSize: 15)
        valueLabel.textAlignment = .right

        let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        arrowView.image = UIImage(systemName: "chevron.down", withConfiguration: config)
        arrowView.tintColor = UIColor(red: 190 / 255, green: 190 / 255, blue: 190 / 255, alpha: 1)
        arrowView.contentMode = .scaleAspectFit

        separator.backgroundColor = .abankSeparator

        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(arrowView)
        addSubview(separator)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        arrowView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(12)
        }
        valueLabel.snp.makeConstraints { make in
            make.trailing.equalTo(arrowView.snp.leading).offset(-6)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(12)
        }
        separator.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(value: String, placeholder: Bool) {
        valueLabel.text = value
        valueLabel.textColor = placeholder ? .abankTextTertiary : .abankTextPrimary
    }

    @objc private func tapped() { onTap?() }
}
