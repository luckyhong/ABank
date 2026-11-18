import UIKit

final class LifeTipViewController: TransferFlowViewController {
    private let tip: String

    init(tip: String) {
        self.tip = tip
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "生活贴士"
        contentStack.addArrangedSubview(BankingPageStyle.surface([
            BankingPageStyle.text(tip, style: .body)
        ]))
    }
}
