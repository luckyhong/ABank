//
//  ScanViewController.swift
//  ABank
//
//  演示扫码：不调用相机，选择示例码后显示识别结果，点“前往”才跳转，永不自动付款。
//

import UIKit
import SnapKit

final class ScanViewController: BaseViewController {

    private let frameView = UIView()
    private let scanLine = UIView()
    private let statusLabel = UILabel()
    private var sampleButtons: [UIButton] = []
    private let resultCard = UIView()
    private let resultTitle = UILabel()
    private let resultDetail = UILabel()
    private let goButton = UIButton(type: .system)
    private let retryButton = UIButton(type: .system)
    private var pendingRoute: AppRoute?

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        hidesBottomBarWhenPushed = true
    }

    convenience init() { self.init(nibName: nil, bundle: nil) }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "扫一扫"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.abankBackIndicator, style: .plain, target: self, action: #selector(backTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = .white
        // 透明导航栏、白色标题，只作用于本页，不改共享样式。
        let appearance = ABankNavigationController.makeStandardAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 17, weight: .semibold)]
        appearance.shadowColor = .clear
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
    }

    override func setupUI() {
        view.backgroundColor = .black

        let hint = UILabel()
        hint.text = "演示扫码 · 不调用相机"
        hint.font = .systemFont(ofSize: 14)
        hint.textColor = UIColor.white.withAlphaComponent(0.7)
        hint.textAlignment = .center

        frameView.layer.borderColor = UIColor.abankOrange.withAlphaComponent(0.35).cgColor
        frameView.layer.borderWidth = 1
        frameView.clipsToBounds = true
        scanLine.backgroundColor = .abankOrange
        frameView.addSubview(scanLine)

        statusLabel.text = "请选择下方示例码"
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.accessibilityIdentifier = "scan.status"

        let samples = UIStackView()
        samples.axis = .horizontal
        samples.distribution = .fillEqually
        samples.spacing = 8
        for (index, sample) in ScanSample.allCases.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(sample.title, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13)
            button.titleLabel?.numberOfLines = 2
            button.titleLabel?.textAlignment = .center
            button.backgroundColor = UIColor.white.withAlphaComponent(0.14)
            button.layer.cornerRadius = 8
            button.tag = index
            button.accessibilityIdentifier = "scan.sample.\(index)"
            button.addTarget(self, action: #selector(sampleTapped(_:)), for: .touchUpInside)
            button.snp.makeConstraints { $0.height.equalTo(56) }
            sampleButtons.append(button)
            samples.addArrangedSubview(button)
        }

        [hint, frameView, statusLabel, samples].forEach(view.addSubview)
        hint.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        frameView.snp.makeConstraints { make in
            make.top.equalTo(hint.snp.bottom).offset(32)
            make.centerX.equalToSuperview()
            make.size.equalTo(240)
        }
        scanLine.frame = CGRect(x: 0, y: 0, width: 240, height: 2)
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(frameView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        samples.snp.makeConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        for corner in 0..<4 { addCorner(corner) }
        setupResultCard()
    }

    private func addCorner(_ index: Int) {
        let size: CGFloat = 24, thickness: CGFloat = 3
        let horizontal = UIView(), vertical = UIView()
        [horizontal, vertical].forEach { $0.backgroundColor = .abankOrange; frameView.addSubview($0) }
        let left = index % 2 == 0, top = index < 2
        horizontal.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: size, height: thickness))
            if left { make.leading.equalToSuperview() } else { make.trailing.equalToSuperview() }
            if top { make.top.equalToSuperview() } else { make.bottom.equalToSuperview() }
        }
        vertical.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: thickness, height: size))
            if left { make.leading.equalToSuperview() } else { make.trailing.equalToSuperview() }
            if top { make.top.equalToSuperview() } else { make.bottom.equalToSuperview() }
        }
    }

    private func setupResultCard() {
        resultCard.backgroundColor = .white
        resultCard.layer.cornerRadius = 16
        resultCard.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        resultCard.isHidden = true

        resultTitle.font = .systemFont(ofSize: 17, weight: .semibold)
        resultTitle.textColor = .abankTextPrimary
        resultTitle.accessibilityIdentifier = "scan.result.title"
        resultDetail.font = .systemFont(ofSize: 14)
        resultDetail.textColor = .abankTextSecondary
        resultDetail.numberOfLines = 0
        resultDetail.accessibilityIdentifier = "scan.result.detail"

        goButton.setTitle("前往", for: .normal)
        goButton.setTitleColor(.white, for: .normal)
        goButton.backgroundColor = .abankOrange
        goButton.layer.cornerRadius = 22
        goButton.accessibilityIdentifier = "scan.result.go"
        goButton.addTarget(self, action: #selector(goTapped), for: .touchUpInside)
        retryButton.setTitle("重新扫描", for: .normal)
        retryButton.setTitleColor(.abankOrange, for: .normal)
        retryButton.accessibilityIdentifier = "scan.result.retry"
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        let buttons = UIStackView(arrangedSubviews: [retryButton, goButton])
        buttons.axis = .horizontal
        buttons.distribution = .fillEqually
        buttons.spacing = 12
        buttons.snp.makeConstraints { $0.height.equalTo(44) }
        let column = UIStackView(arrangedSubviews: [resultTitle, resultDetail, buttons])
        column.axis = .vertical
        column.spacing = 12
        resultCard.addSubview(column)
        view.addSubview(resultCard)
        column.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
        }
        resultCard.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startScanLine()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scanLine.layer.removeAllAnimations()
    }

    private func startScanLine() {
        scanLine.layer.removeAllAnimations()
        scanLine.frame.origin.y = 0
        UIView.animate(withDuration: 1.6, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut]) {
            self.scanLine.frame.origin.y = 238
        }
    }

    // MARK: - 交互

    @objc private func sampleTapped(_ sender: UIButton) {
        let sample = ScanSample.allCases[sender.tag]
        setSamplesEnabled(false)
        statusLabel.text = "识别中…"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.showResult(ScanCodeParser.parse(sample.payload))
        }
    }

    private func showResult(_ result: ScanResult) {
        pendingRoute = result.route
        statusLabel.text = "识别完成"
        switch result {
        case .payee(let name, let bank, let account):
            resultTitle.text = "个人收款码"
            resultDetail.text = "收款人 \(AccountHolderName.masked(name))\n\(bank) · 尾号 \(account.suffix(4))\n金额需在转账页自行输入"
        case .branch(_, let branchName):
            resultTitle.text = "网点取号码"
            resultDetail.text = branchName
        case .bill(_, let title):
            resultTitle.text = "缴费码"
            resultDetail.text = title
        case .unrecognized:
            resultTitle.text = "无法识别"
            resultDetail.text = "无法识别该二维码，请扫描 ABank 演示码"
        }
        goButton.isHidden = result.route == nil
        goButton.isEnabled = true
        resultCard.isHidden = false
    }

    @objc private func goTapped() {
        guard let route = pendingRoute, let nav = navigationController else { return }
        goButton.isEnabled = false
        pendingRoute = nil
        var stack = nav.viewControllers
        if let index = stack.firstIndex(of: self) { stack.remove(at: index) }
        stack.append(AppRouter.shared.makeViewController(for: route))
        nav.setViewControllers(stack, animated: true)
    }

    @objc private func retryTapped() {
        resultCard.isHidden = true
        pendingRoute = nil
        statusLabel.text = "请选择下方示例码"
        setSamplesEnabled(true)
    }

    private func setSamplesEnabled(_ enabled: Bool) {
        sampleButtons.forEach { $0.isEnabled = enabled; $0.alpha = enabled ? 1 : 0.5 }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}
