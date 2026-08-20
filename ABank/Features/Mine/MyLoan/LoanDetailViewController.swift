//
//  LoanDetailViewController.swift
//  ABank
//

import UIKit
import SnapKit

final class LoanDetailViewController: BaseViewController {

    private let contractId: String
    private var contract: LoanContract

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let gaugeView = LoanAvailableGaugeView()
    private let totalAmountLabel = UILabel()
    private let totalTitleLabel = UILabel()
    private let usedAmountLabel = UILabel()
    private let usedTitleLabel = UILabel()
    private let actionBar = LoanDetailActionBarView()
    private let infoStack = UIStackView()
    private let repaymentLinkButton = UIButton(type: .system)

    private let ringColor = UIColor(red: 255 / 255, green: 200 / 255, blue: 160 / 255, alpha: 1)
    private let amountFont = UIFont(name: "TimesNewRomanPSMT", size: 20)
        ?? .systemFont(ofSize: 20, weight: .regular)

    init(contract: LoanContract) {
        self.contractId = contract.id
        self.contract = contract
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "贷款详情"
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.tintColor = .abankTextPrimary

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        let serviceConfig = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "headphones", withConfiguration: serviceConfig),
            style: .plain,
            target: self,
            action: #selector(serviceTapped)
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let latest = FinanceLedgerStore.shared.loanContract(id: contractId) {
            contract = latest
            applyContract()
        }
    }

    override func setupUI() {
        view.backgroundColor = .white

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true

        totalAmountLabel.font = amountFont
        totalAmountLabel.textColor = .abankTextPrimary
        totalAmountLabel.textAlignment = .center
        usedAmountLabel.font = amountFont
        usedAmountLabel.textColor = .abankTextPrimary
        usedAmountLabel.textAlignment = .center

        totalTitleLabel.text = "总额度(元)"
        usedTitleLabel.text = "已用额度(元)"
        [totalTitleLabel, usedTitleLabel].forEach {
            $0.font = .systemFont(ofSize: 13)
            $0.textColor = .abankTextSecondary
            $0.textAlignment = .center
        }

        infoStack.axis = .vertical
        infoStack.alignment = .fill
        infoStack.spacing = 0

        repaymentLinkButton.setTitle("还款详情", for: .normal)
        repaymentLinkButton.setTitleColor(.abankTextPrimary, for: .normal)
        repaymentLinkButton.titleLabel?.font = .systemFont(ofSize: 15)
        repaymentLinkButton.addTarget(self, action: #selector(repaymentDetailTapped), for: .touchUpInside)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        [gaugeView, totalAmountLabel, totalTitleLabel, usedAmountLabel, usedTitleLabel,
         actionBar, infoStack, repaymentLinkButton].forEach { contentView.addSubview($0) }

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        gaugeView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.centerX.equalToSuperview()
            make.size.equalTo(168)
        }
        totalAmountLabel.snp.makeConstraints { make in
            make.top.equalTo(gaugeView.snp.bottom).offset(28)
            make.leading.equalToSuperview()
            make.trailing.equalTo(contentView.snp.centerX)
        }
        totalTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(totalAmountLabel.snp.bottom).offset(6)
            make.leading.trailing.equalTo(totalAmountLabel)
        }
        usedAmountLabel.snp.makeConstraints { make in
            make.centerY.equalTo(totalAmountLabel)
            make.leading.equalTo(contentView.snp.centerX)
            make.trailing.equalToSuperview()
        }
        usedTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(totalTitleLabel)
            make.leading.trailing.equalTo(usedAmountLabel)
        }
        actionBar.snp.makeConstraints { make in
            make.top.equalTo(totalTitleLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(52)
        }
        infoStack.snp.makeConstraints { make in
            make.top.equalTo(actionBar.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        repaymentLinkButton.snp.makeConstraints { make in
            make.top.equalTo(infoStack.snp.bottom).offset(28)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-40)
            make.height.equalTo(44)
        }

        actionBar.onPrepayTapped = { [weak self] in self?.showToast("提前还款") }
        actionBar.onUsageTapped = { [weak self] in self?.showToast("使用记录") }

        applyContract()
    }

    private func applyContract() {
        let progress: CGFloat
        if contract.contractLimit > 0 {
            progress = CGFloat(contract.usedLimit / contract.contractLimit)
        } else {
            progress = 0
        }
        gaugeView.configure(
            availableText: contract.availableLimit.abankPlainAmountString(),
            progress: progress,
            ringColor: ringColor
        )
        totalAmountLabel.text = contract.contractLimit.abankPlainAmountString()
        usedAmountLabel.text = contract.usedLimit.abankPlainAmountString()

        infoStack.arrangedSubviews.forEach {
            infoStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let rows: [(String, String, Bool)] = [
            ("贷款发放日", contract.disbursementDateText, false),
            ("贷款金额", "\(contract.loanAmount.abankPlainAmountString())元", false),
            ("未还本金", "\(contract.unpaidPrincipal.abankPlainAmountString())元", false),
            ("贷款年化利率", String(format: "%.1f%%", contract.annualRatePercent), true),
            ("利率定价方式", contract.pricingMethod, false),
            ("利率定价基准", contract.pricingBenchmark, false),
            ("利率浮动幅度", contract.floatingRange, false),
            ("重定价周期", contract.repricingCycle, false),
            ("重定价日", contract.repricingDatesText, false),
            ("贷款到期日", contract.maturityDateText, false),
            ("贷款状态", contract.statusText, false)
        ]

        for item in rows {
            let row = LoanDetailInfoRowView(
                title: item.0,
                value: item.1.isEmpty ? "-" : item.1,
                showsInfo: item.2,
                showsSeparator: true
            )
            if item.2 {
                row.onInfoTapped = { [weak self] in self?.showToast("贷款年化利率说明") }
            }
            infoStack.addArrangedSubview(row)
        }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func serviceTapped() { showToast("客服") }
    @objc private func repaymentDetailTapped() { showToast("还款详情") }
}

// MARK: - Gauge

private final class LoanAvailableGaugeView: UIView {

    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor(red: 245 / 255, green: 235 / 255, blue: 225 / 255, alpha: 1).cgColor
        trackLayer.lineWidth = 18
        trackLayer.lineCap = .round

        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor(red: 255 / 255, green: 200 / 255, blue: 160 / 255, alpha: 1).cgColor
        progressLayer.lineWidth = 18
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 1

        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)

        titleLabel.text = "可用额度(元)"
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.textColor = .abankTextSecondary
        titleLabel.textAlignment = .center

        valueLabel.font = UIFont(name: "TimesNewRomanPSMT", size: 28)
            ?? .systemFont(ofSize: 28, weight: .regular)
        valueLabel.textColor = UIColor(red: 80 / 255, green: 80 / 255, blue: 80 / 255, alpha: 1)
        valueLabel.textAlignment = .center

        addSubview(titleLabel)
        addSubview(valueLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-16)
        }
        valueLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let inset: CGFloat = 12
        let rect = bounds.insetBy(dx: inset, dy: inset)
        let path = UIBezierPath(ovalIn: rect)
        trackLayer.path = path.cgPath
        progressLayer.path = path.cgPath
        trackLayer.frame = bounds
        progressLayer.frame = bounds
    }

    func configure(availableText: String, progress: CGFloat, ringColor: UIColor) {
        valueLabel.text = availableText
        progressLayer.strokeColor = ringColor.cgColor
        // 已用越多，环越完整；可用为 0 时显示满环
        progressLayer.strokeEnd = max(0.08, min(1, progress <= 0 ? 1 : progress))
    }
}

// MARK: - Action bar

private final class LoanDetailActionBarView: UIView {

    var onPrepayTapped: (() -> Void)?
    var onUsageTapped: (() -> Void)?

    private let prepayButton = UIButton(type: .system)
    private let usageButton = UIButton(type: .system)
    private let topLine = UIView()
    private let bottomLine = UIView()
    private let midLine = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        topLine.backgroundColor = .abankSeparator
        bottomLine.backgroundColor = .abankSeparator
        midLine.backgroundColor = .abankSeparator

        configure(button: prepayButton, title: "提前还款", symbol: "yensign.circle")
        configure(button: usageButton, title: "使用记录", symbol: "doc.text")
        prepayButton.addTarget(self, action: #selector(prepayTapped), for: .touchUpInside)
        usageButton.addTarget(self, action: #selector(usageTapped), for: .touchUpInside)

        addSubview(topLine)
        addSubview(bottomLine)
        addSubview(midLine)
        addSubview(prepayButton)
        addSubview(usageButton)

        topLine.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
        bottomLine.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
        midLine.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
            make.width.equalTo(0.5)
        }
        prepayButton.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.equalTo(midLine.snp.leading)
        }
        usageButton.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
            make.leading.equalTo(midLine.snp.trailing)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func configure(button: UIButton, title: String, symbol: String) {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        button.setImage(UIImage(systemName: symbol, withConfiguration: config), for: .normal)
        button.setTitle(" \(title)", for: .normal)
        button.setTitleColor(.abankTextPrimary, for: .normal)
        button.tintColor = .abankTextPrimary
        button.titleLabel?.font = .systemFont(ofSize: 15)
    }

    @objc private func prepayTapped() { onPrepayTapped?() }
    @objc private func usageTapped() { onUsageTapped?() }
}

// MARK: - Info row

private final class LoanDetailInfoRowView: UIView {

    var onInfoTapped: (() -> Void)?

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let infoButton = UIButton(type: .system)
    private let separator = UIView()

    init(title: String, value: String, showsInfo: Bool, showsSeparator: Bool) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .abankTextSecondary

        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14)
        valueLabel.textColor = .abankTextPrimary
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 2

        let infoConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        infoButton.setImage(UIImage(systemName: "info.circle", withConfiguration: infoConfig), for: .normal)
        infoButton.tintColor = UIColor(red: 190 / 255, green: 190 / 255, blue: 190 / 255, alpha: 1)
        infoButton.isHidden = !showsInfo
        infoButton.addTarget(self, action: #selector(infoTapped), for: .touchUpInside)

        separator.backgroundColor = .abankSeparator
        separator.isHidden = !showsSeparator

        addSubview(titleLabel)
        addSubview(infoButton)
        addSubview(valueLabel)
        addSubview(separator)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(14)
            make.bottom.equalToSuperview().offset(-14)
        }
        infoButton.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(4)
            make.centerY.equalTo(titleLabel)
            make.size.equalTo(18)
        }
        valueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(titleLabel)
            make.leading.greaterThanOrEqualTo(infoButton.snp.trailing).offset(12)
        }
        separator.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(48)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func infoTapped() { onInfoTapped?() }
}
