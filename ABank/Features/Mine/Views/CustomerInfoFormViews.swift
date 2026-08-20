//
//  CustomerInfoFormViews.swift
//  ABank
//

import UIKit
import SnapKit

private enum CustomerInfoFormMetrics {
    static let horizontalInset: CGFloat = 16
    static let titleWidth: CGFloat = 88
    static let titleValueGap: CGFloat = 12
    static let valueAccessoryGap: CGFloat = 8
    static let rowMinHeight: CGFloat = 52
    static let dropdownArrowPointSize: CGFloat = 14
    static let dropdownArrowLayoutSize: CGFloat = 16
    static let dropdownArrowSpacing: CGFloat = 6
}

private func customerInfoDropdownArrow(down: Bool) -> UIImage? {
    let config = UIImage.SymbolConfiguration(pointSize: CustomerInfoFormMetrics.dropdownArrowPointSize, weight: .medium)
    let name = down ? "chevron.down" : "chevron.right"
    return UIImage(systemName: name, withConfiguration: config)?.withRenderingMode(.alwaysTemplate)
}

final class CustomerInfoSectionHeaderView: UIView {
    private let titleLabel = UILabel()

    init(title: String) {
        super.init(frame: .zero)
        backgroundColor = UIColor(red: 244 / 255, green: 244 / 255, blue: 244 / 255, alpha: 1)
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.textColor = .abankTextSecondary
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(CustomerInfoFormMetrics.horizontalInset)
            make.centerY.equalToSuperview()
        }
        snp.makeConstraints { make in
            make.height.equalTo(36)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class CustomerInfoFormRowView: UIView, UITextFieldDelegate {

    enum Accessory {
        case none
        case dropdown
        case disclosure
        case camera
        case modify
    }

    var onTap: (() -> Void)?
    var onCameraTapped: (() -> Void)?
    var onModifyTapped: (() -> Void)?
    var onTextChanged: ((String) -> Void)?
    var onBeginEditing: (() -> Void)?

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    let textField = UITextField()
    private let accessoryView = UIImageView()
    private let modifyActionControl = UIControl()
    private let modifyStack = UIStackView()
    private let modifyTitleLabel = UILabel()
    private let modifyArrowView = UIImageView()
    private let cameraButton = UIButton(type: .system)
    private let trailingAnchorView = UIView()
    private let valueStack = UIStackView()
    private let tapControl = UIControl()
    private let separator = UIView()
    private let isEditable: Bool
    private let showsInlineDropdown: Bool
    private var accessory: Accessory = .none

    init(
        title: String,
        required: Bool = false,
        accessory: Accessory = .none,
        placeholder: String? = nil,
        editable: Bool = false,
        keyboardType: UIKeyboardType = .default
    ) {
        self.isEditable = editable
        self.showsInlineDropdown = accessory == .dropdown || accessory == .disclosure
        super.init(frame: .zero)
        self.accessory = accessory
        backgroundColor = .white
        setupTitle(title, required: required)

        valueLabel.font = .systemFont(ofSize: 16)
        valueLabel.textColor = .abankTextPrimary
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 2
        valueLabel.lineBreakMode = .byTruncatingTail
        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        textField.font = .systemFont(ofSize: 16)
        textField.textColor = .abankTeal
        textField.textAlignment = .right
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.returnKeyType = .done
        textField.delegate = self
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        textField.isHidden = !editable
        valueLabel.isHidden = editable

        accessoryView.tintColor = .abankTextTertiary
        accessoryView.contentMode = .scaleAspectFit
        accessoryView.isHidden = true
        accessoryView.setContentCompressionResistancePriority(.required, for: .horizontal)
        accessoryView.setContentHuggingPriority(.required, for: .horizontal)

        valueStack.axis = .horizontal
        valueStack.alignment = .center
        valueStack.spacing = CustomerInfoFormMetrics.dropdownArrowSpacing
        valueStack.isHidden = true
        valueStack.isUserInteractionEnabled = false

        modifyTitleLabel.text = "去修改"
        modifyTitleLabel.font = .systemFont(ofSize: 13)
        modifyTitleLabel.textColor = .abankTextTertiary
        modifyArrowView.image = customerInfoDropdownArrow(down: false)
        modifyArrowView.tintColor = .abankTextTertiary
        modifyArrowView.contentMode = .scaleAspectFit
        modifyStack.axis = .horizontal
        modifyStack.alignment = .center
        modifyStack.spacing = 2
        modifyStack.isUserInteractionEnabled = false
        modifyStack.addArrangedSubview(modifyTitleLabel)
        modifyStack.addArrangedSubview(modifyArrowView)
        modifyActionControl.addTarget(self, action: #selector(modifyTapped), for: .touchUpInside)
        modifyActionControl.isHidden = accessory != .modify
        modifyActionControl.setContentCompressionResistancePriority(.required, for: .horizontal)
        modifyActionControl.setContentHuggingPriority(.required, for: .horizontal)
        modifyArrowView.snp.makeConstraints { make in
            make.size.equalTo(CustomerInfoFormMetrics.dropdownArrowLayoutSize)
        }

        cameraButton.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        cameraButton.tintColor = .abankTeal
        cameraButton.addTarget(self, action: #selector(cameraTapped), for: .touchUpInside)
        cameraButton.isHidden = accessory != .camera
        cameraButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        cameraButton.setContentHuggingPriority(.required, for: .horizontal)

        trailingAnchorView.setContentCompressionResistancePriority(.required, for: .horizontal)
        trailingAnchorView.setContentHuggingPriority(.required, for: .horizontal)

        separator.backgroundColor = .abankSeparator

        tapControl.addTarget(self, action: #selector(rowTapped), for: .touchUpInside)

        addSubview(titleLabel)
        if showsInlineDropdown {
            addSubview(valueStack)
        } else {
            addSubview(valueLabel)
        }
        if isEditable {
            addSubview(textField)
        }
        addSubview(trailingAnchorView)
        if !showsInlineDropdown {
            trailingAnchorView.addSubview(accessoryView)
        }
        modifyActionControl.addSubview(modifyStack)
        trailingAnchorView.addSubview(modifyActionControl)
        trailingAnchorView.addSubview(cameraButton)
        addSubview(tapControl)
        addSubview(separator)

        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(CustomerInfoFormMetrics.horizontalInset)
            make.centerY.equalToSuperview()
            make.width.equalTo(CustomerInfoFormMetrics.titleWidth)
        }

        let usesInlineDropdown = showsInlineDropdown
        if usesInlineDropdown {
            valueStack.isHidden = false
            accessoryView.isHidden = false
            accessoryView.image = customerInfoDropdownArrow(down: accessory == .dropdown)
            valueStack.addArrangedSubview(valueLabel)
            valueStack.addArrangedSubview(accessoryView)
            accessoryView.snp.makeConstraints { make in
                make.size.equalTo(CustomerInfoFormMetrics.dropdownArrowLayoutSize)
            }
            valueLabel.textAlignment = .right
            valueLabel.numberOfLines = 1
            valueStack.snp.makeConstraints { make in
                make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(CustomerInfoFormMetrics.titleValueGap)
                make.trailing.equalToSuperview().inset(CustomerInfoFormMetrics.horizontalInset)
                make.centerY.equalToSuperview()
                make.top.greaterThanOrEqualToSuperview().offset(14)
                make.bottom.lessThanOrEqualToSuperview().offset(-14)
            }
        } else {
            trailingAnchorView.snp.makeConstraints { make in
                make.trailing.equalToSuperview().inset(CustomerInfoFormMetrics.horizontalInset)
                make.centerY.equalToSuperview()
            }

            switch accessory {
            case .none:
                trailingAnchorView.isHidden = true
            case .dropdown, .disclosure:
                break
            case .camera:
                cameraButton.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                    make.size.equalTo(24)
                }
            case .modify:
                modifyStack.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
                modifyActionControl.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }

            valueLabel.snp.makeConstraints { make in
                make.leading.equalTo(titleLabel.snp.trailing).offset(CustomerInfoFormMetrics.titleValueGap)
                make.top.equalToSuperview().offset(14)
                make.bottom.equalToSuperview().offset(-14)
                if accessory == .none {
                    make.trailing.equalToSuperview().inset(CustomerInfoFormMetrics.horizontalInset)
                } else {
                    make.trailing.equalTo(trailingAnchorView.snp.leading).offset(-CustomerInfoFormMetrics.valueAccessoryGap)
                }
            }
            if isEditable {
                textField.snp.makeConstraints { make in
                    make.edges.equalTo(valueLabel)
                }
            }
        }

        tapControl.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tapControl.isHidden = editable || accessory == .modify
        if usesInlineDropdown {
            bringSubviewToFront(valueStack)
        } else {
            bringSubviewToFront(trailingAnchorView)
            if accessory == .modify {
                bringSubviewToFront(modifyActionControl)
            }
        }

        separator.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(CustomerInfoFormMetrics.horizontalInset)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }

        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(CustomerInfoFormMetrics.rowMinHeight)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setValue(_ text: String, color: UIColor = .abankTextPrimary, placeholder: String? = nil) {
        if isEditable {
            textField.text = text
            return
        }

        if text.isEmpty, let placeholder {
            valueLabel.text = placeholder
            valueLabel.textColor = .abankTextTertiary
        } else {
            valueLabel.text = text
            valueLabel.textColor = color
        }

        if showsInlineDropdown {
            valueStack.setNeedsLayout()
            valueStack.layoutIfNeeded()
        }
    }

    func textValue() -> String {
        if isEditable {
            return textField.text ?? ""
        }
        return valueLabel.text ?? ""
    }

    private func setupTitle(_ title: String, required: Bool) {
        if required {
            let attributed = NSMutableAttributedString(
                string: title,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.abankTextPrimary
                ]
            )
            attributed.append(NSAttributedString(
                string: "*",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.abankError
                ]
            ))
            titleLabel.attributedText = attributed
        } else {
            titleLabel.text = title
            titleLabel.font = .systemFont(ofSize: 16)
            titleLabel.textColor = .abankTextPrimary
        }
    }

    @objc private func rowTapped() { onTap?() }
    @objc private func cameraTapped() { onCameraTapped?() }
    @objc private func modifyTapped() { onModifyTapped?() }
    @objc private func textDidChange() { onTextChanged?(textField.text ?? "") }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        onBeginEditing?()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

final class CustomerInfoLandlineRowView: UIView, UITextFieldDelegate {
    var onAreaChanged: ((String) -> Void)?
    var onNumberChanged: ((String) -> Void)?
    var onBeginEditing: (() -> Void)?

    private let titleLabel = UILabel()
    private let areaField = UITextField()
    private let dashLabel = UILabel()
    private let numberField = UITextField()
    private let separator = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        titleLabel.text = "固定电话"
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .abankTextPrimary

        configure(areaField, placeholder: "区号", keyboard: .numberPad)
        configure(numberField, placeholder: "固话号码", keyboard: .phonePad)

        dashLabel.text = "-"
        dashLabel.font = .systemFont(ofSize: 16)
        dashLabel.textColor = .abankTextTertiary
        dashLabel.textAlignment = .center

        separator.backgroundColor = .abankSeparator

        addSubview(titleLabel)
        addSubview(areaField)
        addSubview(dashLabel)
        addSubview(numberField)
        addSubview(separator)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(CustomerInfoFormMetrics.horizontalInset)
            make.centerY.equalToSuperview()
            make.width.equalTo(CustomerInfoFormMetrics.titleWidth)
        }
        numberField.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(CustomerInfoFormMetrics.horizontalInset)
            make.centerY.equalToSuperview()
            make.width.equalTo(112)
            make.height.equalTo(36)
        }
        dashLabel.snp.makeConstraints { make in
            make.trailing.equalTo(numberField.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
            make.width.equalTo(10)
        }
        areaField.snp.makeConstraints { make in
            make.trailing.equalTo(dashLabel.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
            make.width.equalTo(72)
            make.height.equalTo(36)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(CustomerInfoFormMetrics.titleValueGap)
        }
        separator.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(CustomerInfoFormMetrics.horizontalInset)
            make.trailing.bottom.equalToSuperview()
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }
        snp.makeConstraints { make in
            make.height.equalTo(CustomerInfoFormMetrics.rowMinHeight)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(area: String, number: String) {
        areaField.text = area
        numberField.text = number
    }

    private func configure(_ field: UITextField, placeholder: String, keyboard: UIKeyboardType) {
        field.placeholder = placeholder
        field.font = .systemFont(ofSize: 16)
        field.textColor = .abankTeal
        field.textAlignment = .right
        field.keyboardType = keyboard
        field.delegate = self
        field.addTarget(self, action: #selector(editingChanged(_:)), for: .editingChanged)
    }

    @objc private func editingChanged(_ sender: UITextField) {
        if sender === areaField {
            onAreaChanged?(sender.text ?? "")
        } else {
            onNumberChanged?(sender.text ?? "")
        }
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        onBeginEditing?()
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let current = textField.text ?? ""
        let next = (current as NSString).replacingCharacters(in: range, with: string)
        let max = textField === areaField ? 4 : 8
        return next.count <= max && next.allSatisfy(\.isNumber)
    }
}

final class CustomerInfoPickerSheetView: UIView, UIPickerViewDataSource, UIPickerViewDelegate {
    var onConfirm: (([Int]) -> Void)?
    var onCancel: (() -> Void)?

    private let dimView = UIView()
    private let panel = UIView()
    private let titleLabel = UILabel()
    private let cancelButton = UIButton(type: .system)
    private let confirmButton = UIButton(type: .system)
    private let picker = UIPickerView()
    private var columns: [[String]] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancelTapped)))

        panel.backgroundColor = .white
        panel.layer.cornerRadius = 12
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .abankTextPrimary
        titleLabel.textAlignment = .center

        cancelButton.setTitle("取消", for: .normal)
        cancelButton.setTitleColor(.abankTextSecondary, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        confirmButton.setTitle("确定", for: .normal)
        confirmButton.setTitleColor(.abankTeal, for: .normal)
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        picker.dataSource = self
        picker.delegate = self

        addSubview(dimView)
        addSubview(panel)
        panel.addSubview(cancelButton)
        panel.addSubview(titleLabel)
        panel.addSubview(confirmButton)
        panel.addSubview(picker)

        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        panel.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        cancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(12)
            make.height.equalTo(32)
        }
        confirmButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(cancelButton)
        }
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(cancelButton)
        }
        picker.snp.makeConstraints { make in
            make.top.equalTo(cancelButton.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(216)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func present(in host: UIView, title: String, columns: [[String]], selected: [Int]) {
        self.columns = columns
        titleLabel.text = title
        picker.reloadAllComponents()
        for (index, row) in selected.enumerated() where index < columns.count && row < columns[index].count {
            picker.selectRow(row, inComponent: index, animated: false)
        }
        frame = host.bounds
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.addSubview(self)
        panel.transform = CGAffineTransform(translationX: 0, y: 280)
        dimView.alpha = 0
        UIView.animate(withDuration: 0.25) {
            self.panel.transform = .identity
            self.dimView.alpha = 1
        }
    }

    func updateColumn(_ index: Int, options: [String], selectedRow: Int) {
        guard columns.indices.contains(index) else { return }
        columns[index] = options
        picker.reloadComponent(index)
        let row = min(selectedRow, max(options.count - 1, 0))
        picker.selectRow(row, inComponent: index, animated: true)
    }

    var selectedRows: [Int] {
        (0..<columns.count).map { picker.selectedRow(inComponent: $0) }
    }

    func selectedTitle(in component: Int) -> String {
        let row = picker.selectedRow(inComponent: component)
        guard columns.indices.contains(component), columns[component].indices.contains(row) else { return "" }
        return columns[component][row]
    }

    var onColumnChanged: ((Int, Int, String) -> Void)?

    @objc private func cancelTapped() {
        dismiss()
        onCancel?()
    }

    @objc private func confirmTapped() {
        let rows = selectedRows
        let callback = onConfirm
        dismiss {
            DispatchQueue.main.async {
                callback?(rows)
            }
        }
    }

    private func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, animations: {
            self.panel.transform = CGAffineTransform(translationX: 0, y: 280)
            self.dimView.alpha = 0
        }) { _ in
            self.removeFromSuperview()
            completion?()
        }
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int { columns.count }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        columns[component].count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        columns[component][row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let title = columns[component][row]
        onColumnChanged?(component, row, title)
    }
}
