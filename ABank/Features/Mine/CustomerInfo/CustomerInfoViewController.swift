//
//  CustomerInfoViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class CustomerInfoViewController: BaseViewController {

    private var record: CustomerInfoRecord
    private var pickerSheet: CustomerInfoPickerSheetView?

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.keyboardDismissMode = .onDrag
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    private let contentView = UIView()
    private let footerView = UIView()

    private let nameRow = CustomerInfoFormRowView(title: "姓名", required: true)
    private let genderRow = CustomerInfoFormRowView(title: "性别", accessory: .dropdown)
    private let nationalityRow = CustomerInfoFormRowView(title: "国籍", required: true)
    private let idTypeRow = CustomerInfoFormRowView(title: "证件类型", required: true)
    private let idNumberRow = CustomerInfoFormRowView(title: "证件号码", required: true)
    private let idValidityRow = CustomerInfoFormRowView(title: "证件有效期", accessory: .camera)
    private let mobileRow = CustomerInfoFormRowView(title: "手机号码", accessory: .modify)
    private let emailRow = CustomerInfoFormRowView(
        title: "邮箱",
        accessory: .none,
        placeholder: "请输入邮箱",
        editable: true,
        keyboardType: .emailAddress
    )
    private let landlineRow = CustomerInfoLandlineRowView()
    private let regionRow = CustomerInfoFormRowView(title: "选择地区", accessory: .dropdown)
    private let addressRow = CustomerInfoFormRowView(
        title: "详细地址",
        placeholder: "请输入详细地址",
        editable: true
    )
    private let postalRow = CustomerInfoFormRowView(
        title: "邮政编码",
        placeholder: "请输入邮政编码",
        editable: true,
        keyboardType: .numberPad
    )
    private let occupation1Row = CustomerInfoFormRowView(title: "一级职业", accessory: .dropdown)
    private let occupation2Row = CustomerInfoFormRowView(title: "二级职业", accessory: .dropdown)

    private let taxPrefixLabel = UILabel()
    private let taxLinkButton = UIButton(type: .system)
    private let hintLabel = UILabel()
    private let confirmButton = UIButton(type: .system)

    init(record: CustomerInfoRecord = CustomerInfoStore.shared.load()) {
        self.record = record
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "客户信息"
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
        navigationController?.setNavigationBarHidden(false, animated: animated)
        reloadFromStore()
    }

    private func reloadFromStore() {
        record = CustomerInfoStore.shared.load()
        refreshRows()
    }

    private func persistRecord() {
        CustomerInfoStore.shared.save(record)
    }

    override func setupUI() {
        view.backgroundColor = .white
        view.addSubview(scrollView)
        view.addSubview(footerView)
        scrollView.addSubview(contentView)

        footerView.backgroundColor = .white
        let footerSeparator = UIView()
        footerSeparator.backgroundColor = .abankSeparator
        footerView.addSubview(footerSeparator)
        footerSeparator.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }

        confirmButton.setTitle("确定", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        confirmButton.backgroundColor = UIColor(red: 1.0, green: 0.48, blue: 0.16, alpha: 1)
        confirmButton.layer.cornerRadius = 4
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        footerView.addSubview(confirmButton)
        footerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        confirmButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-8)
        }

        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(footerView.snp.top)
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        let addressHeader = CustomerInfoSectionHeaderView(title: "联系地址")
        let occupationHeader = CustomerInfoSectionHeaderView(title: "职业信息")

        taxPrefixLabel.text = "声明我的税收身份"
        taxPrefixLabel.font = .systemFont(ofSize: 14)
        taxPrefixLabel.textColor = .abankTextPrimary
        taxLinkButton.setTitle("请点这里", for: .normal)
        taxLinkButton.setTitleColor(.abankTeal, for: .normal)
        taxLinkButton.titleLabel?.font = .systemFont(ofSize: 14)
        taxLinkButton.addTarget(self, action: #selector(taxTapped), for: .touchUpInside)

        hintLabel.text = "带*的客户信息如需修改，请去柜台处理"
        hintLabel.font = .systemFont(ofSize: 13)
        hintLabel.textColor = .abankError
        hintLabel.numberOfLines = 0

        let rows: [UIView] = [
            nameRow, genderRow, nationalityRow, idTypeRow, idNumberRow, idValidityRow,
            mobileRow, emailRow, landlineRow, addressHeader, regionRow, addressRow, postalRow,
            occupationHeader, occupation1Row, occupation2Row
        ]
        var previous: UIView?
        rows.forEach { row in
            contentView.addSubview(row)
            row.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                if let previous {
                    make.top.equalTo(previous.snp.bottom)
                } else {
                    make.top.equalToSuperview()
                }
            }
            previous = row
        }

        contentView.addSubview(taxPrefixLabel)
        contentView.addSubview(taxLinkButton)
        contentView.addSubview(hintLabel)

        taxPrefixLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(occupation2Row.snp.bottom).offset(20)
        }
        taxLinkButton.snp.makeConstraints { make in
            make.leading.equalTo(taxPrefixLabel.snp.trailing).offset(4)
            make.centerY.equalTo(taxPrefixLabel)
        }
        hintLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(taxPrefixLabel.snp.bottom).offset(12)
            make.bottom.equalToSuperview().offset(-20)
        }

        emailRow.textField.autocapitalizationType = .none
        emailRow.textField.autocorrectionType = .no
        postalRow.textField.addTarget(self, action: #selector(postalChanged), for: .editingChanged)

        bindRowActions()
        refreshRows()
        registerKeyboard()
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func bindRowActions() {
        nameRow.onTap = { [weak self] in self?.showCounterHint() }
        nationalityRow.onTap = { [weak self] in self?.showCounterHint() }
        idTypeRow.onTap = { [weak self] in self?.showCounterHint() }
        idNumberRow.onTap = { [weak self] in self?.showCounterHint() }

        genderRow.onTap = { [weak self] in self?.showGenderPicker() }
        regionRow.onTap = { [weak self] in self?.showRegionPicker() }
        occupation1Row.onTap = { [weak self] in self?.showOccupationPicker(level: 1) }
        occupation2Row.onTap = { [weak self] in self?.showOccupationPicker(level: 2) }

        idValidityRow.onCameraTapped = { [weak self] in self?.scanIdCard() }
        mobileRow.onModifyTapped = { [weak self] in
            self?.navigationController?.pushViewController(ModifyMobileViewController(), animated: true)
        }

        emailRow.onTextChanged = { [weak self] text in
            self?.record.email = text
            self?.persistRecord()
        }
        addressRow.onTextChanged = { [weak self] text in
            self?.record.detailAddress = text
            self?.persistRecord()
        }
        landlineRow.onAreaChanged = { [weak self] text in
            self?.record.landlineAreaCode = text
            self?.persistRecord()
        }
        landlineRow.onNumberChanged = { [weak self] text in
            self?.record.landlineNumber = text
            self?.persistRecord()
        }
    }

    private func refreshRows() {
        nameRow.setValue(record.maskedName)
        genderRow.setValue(record.gender, color: .abankTeal)
        nationalityRow.setValue(record.nationality)
        idTypeRow.setValue(record.idType)
        idNumberRow.setValue(record.maskedIdNumber)
        idValidityRow.setValue(record.idValidityDisplay)
        mobileRow.setValue(record.maskedMobile)
        emailRow.setValue(record.email)
        landlineRow.configure(area: record.landlineAreaCode, number: record.landlineNumber)
        regionRow.setValue(record.regionDisplay, color: .abankTeal)
        addressRow.setValue(record.detailAddress)
        postalRow.setValue(record.postalCode)
        occupation1Row.setValue(record.occupationLevel1, color: .abankTextPrimary)
        occupation2Row.setValue(record.occupationLevel2, color: .abankTextPrimary)
    }

    @objc private func postalChanged() {
        let digits = (postalRow.textField.text ?? "").filter(\.isNumber)
        postalRow.textField.text = String(digits.prefix(6))
        record.postalCode = postalRow.textField.text ?? ""
        persistRecord()
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func endEditing() {
        view.endEditing(true)
    }

    @objc private func taxTapped() {
        navigationController?.pushViewController(TaxIdentityViewController(), animated: true)
    }

    private func showCounterHint() {
        showToast("带*的客户信息如需修改，请去柜台处理")
    }

    private func showGenderPicker() {
        view.endEditing(true)
        let sheet = CustomerInfoPickerSheetView()
        let selected = CustomerInfoCatalog.genders.firstIndex(of: record.gender) ?? 0
        sheet.onConfirm = { [weak self] rows in
            guard let self, let row = rows.first else { return }
            self.record.gender = CustomerInfoCatalog.genders[row]
            self.refreshRows()
            self.persistRecord()
        }
        sheet.present(in: view, title: "选择性别", columns: [CustomerInfoCatalog.genders], selected: [selected])
        pickerSheet = sheet
    }

    private func showOccupationPicker(level: Int) {
        view.endEditing(true)
        if level == 1 {
            let options = CustomerInfoCatalog.occupations.map(\.0)
            let selected = options.firstIndex(of: record.occupationLevel1) ?? 0
            let sheet = CustomerInfoPickerSheetView()
            sheet.onConfirm = { [weak self] rows in
                guard let self, let row = rows.first, options.indices.contains(row) else { return }
                let next = options[row]
                self.record.occupationLevel1 = next
                self.record.occupationLevel2 = CustomerInfoCatalog.level2Options(for: next).first ?? ""
                self.refreshRows()
                self.persistRecord()
            }
            sheet.present(in: view, title: "选择一级职业", columns: [options], selected: [selected])
            pickerSheet = sheet
        } else {
            let options = CustomerInfoCatalog.level2Options(for: record.occupationLevel1)
            guard !options.isEmpty else { return }
            let selected = options.firstIndex(of: record.occupationLevel2) ?? 0
            let sheet = CustomerInfoPickerSheetView()
            sheet.onConfirm = { [weak self] rows in
                guard let self, let row = rows.first, options.indices.contains(row) else { return }
                self.record.occupationLevel2 = options[row]
                self.refreshRows()
                self.persistRecord()
            }
            sheet.present(in: view, title: "选择二级职业", columns: [options], selected: [selected])
            pickerSheet = sheet
        }
    }

    private func showRegionPicker() {
        view.endEditing(true)
        let provinces = CustomerInfoCatalog.regions.map(\.name)
        let provinceIndex = provinces.firstIndex(of: record.province) ?? 0
        var cities = CustomerInfoCatalog.regions[provinceIndex].children.map(\.name)
        let cityIndex = cities.firstIndex(of: record.city) ?? 0
        var districts = CustomerInfoCatalog.regions[provinceIndex].children[cityIndex].children.map(\.name)
        let districtIndex = districts.firstIndex(of: record.district) ?? 0

        let sheet = CustomerInfoPickerSheetView()
        sheet.onColumnChanged = { component, row, _ in
            if component == 0 {
                cities = CustomerInfoCatalog.regions[row].children.map(\.name)
                districts = CustomerInfoCatalog.regions[row].children.first?.children.map(\.name) ?? []
                sheet.updateColumn(1, options: cities, selectedRow: 0)
                sheet.updateColumn(2, options: districts, selectedRow: 0)
            } else if component == 1 {
                let p = sheet.selectedRows[0]
                let cityNodes = CustomerInfoCatalog.regions[p].children
                let safeRow = min(row, max(cityNodes.count - 1, 0))
                districts = cityNodes[safeRow].children.map(\.name)
                sheet.updateColumn(2, options: districts, selectedRow: 0)
            }
        }
        sheet.onConfirm = { [weak self] rows in
            guard let self, rows.count >= 3 else { return }
            let provinceIndex = rows[0]
            guard CustomerInfoCatalog.regions.indices.contains(provinceIndex) else { return }
            let provinceNode = CustomerInfoCatalog.regions[provinceIndex]
            let cityIndex = min(rows[1], max(provinceNode.children.count - 1, 0))
            guard provinceNode.children.indices.contains(cityIndex) else { return }
            let cityNode = provinceNode.children[cityIndex]
            let districtIndex = min(rows[2], max(cityNode.children.count - 1, 0))
            guard cityNode.children.indices.contains(districtIndex) else { return }
            let districtNode = cityNode.children[districtIndex]
            self.record.province = provinceNode.name
            self.record.city = cityNode.name
            self.record.district = districtNode.name
            if let postal = districtNode.postalCode {
                self.record.postalCode = postal
            }
            self.refreshRows()
            self.persistRecord()
        }
        sheet.present(
            in: view,
            title: "选择地区",
            columns: [provinces, cities, districts],
            selected: [provinceIndex, cityIndex, districtIndex]
        )
        pickerSheet = sheet
    }

    private func scanIdCard() {
        view.endEditing(true)
        let alert = UIAlertController(title: "证件识别", message: "将模拟识别身份证，并回填证件有效期。", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "开始识别", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.showLoading()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.hideLoading()
                self.record.idValidFrom = "2018/08/08"
                self.record.idValidTo = "2038/08/08"
                self.refreshRows()
                self.persistRecord()
                self.showToast("已识别证件有效期")
            }
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func confirmTapped() {
        view.endEditing(true)
        if let message = validationMessage() {
            showToast(message)
            return
        }
        CustomerInfoStore.shared.save(record)
        showToast("客户信息已保存")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }

    private func validationMessage() -> String? {
        if !record.email.isEmpty {
            let emailReg = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
            if record.email.range(of: emailReg, options: .regularExpression) == nil {
                return "请输入正确的邮箱地址"
            }
        }
        let hasArea = !record.landlineAreaCode.isEmpty
        let hasNumber = !record.landlineNumber.isEmpty
        if hasArea != hasNumber {
            return "请完整填写区号和固话号码"
        }
        if hasArea {
            if !(3...4).contains(record.landlineAreaCode.count) {
                return "区号一般为3-4位数字"
            }
            if !(7...8).contains(record.landlineNumber.count) {
                return "固话号码一般为7-8位数字"
            }
        }
        if record.detailAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "请填写详细地址"
        }
        if record.postalCode.count != 6 {
            return "请输入6位邮政编码"
        }
        if record.occupationLevel1.isEmpty || record.occupationLevel2.isEmpty {
            return "请选择职业信息"
        }
        return nil
    }

    private func registerKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let converted = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - converted.minY - footerView.bounds.height)
        scrollView.contentInset.bottom = overlap
        scrollView.verticalScrollIndicatorInsets.bottom = overlap
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
