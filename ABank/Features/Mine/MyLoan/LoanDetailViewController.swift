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

    private let amountFont = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .regular)

    init(contract: LoanContract) {
        self.contractId = contract.id
        self.contract = contract
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupNavigationBar() {
        title = "贷款详情"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.abankBackIndicator,
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage.abankAsset("abc_mine_detail_toolbar_service", fallback: "headphones", renderingMode: .alwaysTemplate, pointSize: 24),
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
        totalAmountLabel.textColor = .abankAmount
        totalAmountLabel.textAlignment = .center
        usedAmountLabel.font = amountFont
        usedAmountLabel.textColor = .abankAmount
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
        repaymentLinkButton.accessibilityIdentifier = "loan.detail.repayment"
        repaymentLinkButton.titleLabel?.font = UIFontMetrics(forTextStyle: .callout)
            .scaledFont(for: .systemFont(ofSize: 15))
        repaymentLinkButton.titleLabel?.adjustsFontForContentSizeCategory = true
        repaymentLinkButton.addTarget(self, action: #selector(repaymentDetailTapped), for: .touchUpInside)

        let repaymentSeparator = UIView()
        repaymentSeparator.backgroundColor = .abankSeparator

        view.addSubview(scrollView)
        let columnContainer = UIView()
        scrollView.addSubview(columnContainer)
        columnContainer.addSubview(contentView)
        [gaugeView, totalAmountLabel, totalTitleLabel, usedAmountLabel, usedTitleLabel,
         actionBar, infoStack, repaymentSeparator, repaymentLinkButton].forEach { contentView.addSubview($0) }

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        columnContainer.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        contentView.snp.makeConstraints { make in
            make.top.bottom.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
            make.width.equalTo(640).priority(999)
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
        repaymentSeparator.snp.makeConstraints { make in
            make.top.equalTo(infoStack.snp.bottom).offset(Spacing.sm)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
        repaymentLinkButton.snp.makeConstraints { make in
            make.top.equalTo(repaymentSeparator.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-Spacing.md)
            make.height.greaterThanOrEqualTo(44)
        }

        actionBar.onPrepayTapped = { [weak self] in
            guard let self else { return }
            let controller = LoanPrepaymentViewController(contractId: self.contractId)
            self.navigationController?.pushViewController(controller, animated: true)
        }
        actionBar.onUsageTapped = { [weak self] in
            guard let self else { return }
            let controller = LoanUsageRecordsViewController(contractId: self.contractId)
            self.navigationController?.pushViewController(controller, animated: true)
        }

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
            progress: progress
        )
        totalAmountLabel.text = (contract.hasOriginalContractDetails || contract.contractLimit > 0) ? contract.contractLimit.abankPlainAmountString() : "—"
        usedAmountLabel.text = (contract.hasOriginalContractDetails || contract.contractLimit > 0) ? contract.usedLimit.abankPlainAmountString() : "—"

        infoStack.arrangedSubviews.forEach {
            infoStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let rows: [(String, String, Bool)] = [
            ("贷款发放日", contract.disbursementDateText, false),
            ("贷款金额", (contract.hasOriginalContractDetails || contract.loanAmount > 0) ? "\(contract.loanAmount.abankPlainAmountString())元" : "—", false),
            ("未还本金", "\(contract.unpaidPrincipal.abankPlainAmountString())元", false),
            ("贷款年化利率", String(format: "%.1f%%", contract.annualRatePercent), true),
            ("利率定价方式", contract.pricingMethod.replacingOccurrences(of: "模拟", with: ""), false),
            ("利率定价基准", contract.pricingBenchmark, false),
            ("利率浮动幅度", contract.floatingRange.replacingOccurrences(of: "-", with: "−"), false),
            ("重定价周期", contract.repricingCycle, false),
            ("重定价日", contract.repricingDatesText, false),
            ("贷款到期日", contract.maturityDateText, false),
            ("贷款状态", contract.statusText, false)
        ]

        for (index, item) in rows.enumerated() {
            let row = LoanDetailInfoRowView(
                title: item.0,
                value: item.1.isEmpty ? "—" : item.1,
                showsInfo: item.2,
                showsSeparator: index == 0
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

    @objc private func serviceTapped() { AppRouter.shared.open(.assistant, from: self) }
    @objc private func repaymentDetailTapped() {
        let controller = LoanRepaymentDetailViewController(contractId: contractId)
        navigationController?.pushViewController(controller, animated: true)
    }
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
        trackLayer.strokeColor = UIColor.abankOrange.withAlphaComponent(0.10).cgColor
        trackLayer.lineWidth = 21
        trackLayer.lineCap = .round

        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor.abankOrange.withAlphaComponent(0.34).cgColor
        progressLayer.lineWidth = 21
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 1

        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)

        titleLabel.text = "可用额度(元)"
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.textColor = .abankTextSecondary
        titleLabel.textAlignment = .center

        valueLabel.font = .systemFont(ofSize: 18, weight: .regular)
        valueLabel.textColor = .abankAmount
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

    func configure(availableText: String, progress: CGFloat) {
        valueLabel.text = availableText
        progressLayer.strokeEnd = max(0, min(1, progress))
        progressLayer.isHidden = progress <= 0
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

        configure(button: prepayButton, title: "提前还款", symbol: "yensign.circle", asset: "loan_prepay")
        configure(button: usageButton, title: "使用记录", symbol: "doc.text", asset: "loan_usage")
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

    private func configure(button: UIButton, title: String, symbol: String, asset: String) {
        button.setImage(UIImage.abankAsset("abc_mine_detail_\(asset)", fallback: symbol, pointSize: 18), for: .normal)
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
        titleLabel.font = .preferredFont(forTextStyle: .callout)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .abankTextPrimary

        valueLabel.text = value
        valueLabel.font = .preferredFont(forTextStyle: .callout)
        valueLabel.adjustsFontForContentSizeCategory = true
        valueLabel.textColor = .abankTextSecondary
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 0

        infoButton.setImage(UIImage.abankAsset("abc_mine_detail_info_reference", fallback: "info.circle", renderingMode: .alwaysTemplate, pointSize: 13), for: .normal)
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
            make.top.equalToSuperview().offset(8)
            make.bottom.lessThanOrEqualToSuperview().offset(-8)
        }
        infoButton.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(4)
            make.centerY.equalTo(titleLabel)
            make.size.equalTo(18)
        }
        valueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.firstBaseline.equalTo(titleLabel)
            make.bottom.lessThanOrEqualToSuperview().offset(-8)
            if showsInfo {
                make.leading.greaterThanOrEqualTo(infoButton.snp.trailing).offset(12)
            } else {
                make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(12)
            }
        }
        separator.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(32)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func infoTapped() { onInfoTapped?() }
}
