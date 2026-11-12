import UIKit
import SnapKit

final class BankingAccountPickerRow: UIControl {
    init(account: LedgerAccount?, id: String, action: @escaping () -> Void) {
        super.init(frame: .zero)
        let row = TransferInfoRow("付款账户", value: (account?.cardLabel ?? "请选择账户"))
        row.isUserInteractionEnabled = false
        addSubview(row)
        row.snp.makeConstraints { $0.leading.top.bottom.equalToSuperview(); $0.trailing.equalToSuperview().offset(-20) }
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right")); chevron.tintColor = .abankTextSecondary; chevron.contentMode = .scaleAspectFit
        addSubview(chevron); chevron.snp.makeConstraints { $0.trailing.equalToSuperview().inset(12); $0.centerY.equalToSuperview(); $0.width.equalTo(10); $0.height.equalTo(16) }
        accessibilityIdentifier = id
        accessibilityLabel = "付款账户，" + (account?.cardLabel ?? "请选择账户")
        addAction(UIAction { _ in action() }, for: .touchUpInside)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    static func choose(from controller: UIViewController, ledger: FinanceLedgerStore, selected: String?, onSelect: @escaping (String) -> Void) {
        let alert = UIAlertController(title: "选择付款账户", message: nil, preferredStyle: .actionSheet)
        for account in ledger.load().accounts where account.currency == "人民币" {
            let title = account.cardLabel + (account.isReportedLost ? " · 已挂失" : "") + "　¥" + account.balance.abankPlainAmountString()
            alert.addAction(UIAlertAction(title: title + (account.id == selected ? "（当前）" : ""), style: .default) { _ in onSelect(account.id) })
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.popoverPresentationController?.sourceView = controller.view
        alert.popoverPresentationController?.sourceRect = CGRect(x: controller.view.bounds.midX, y: controller.view.bounds.midY, width: 1, height: 1)
        controller.present(alert, animated: true)
    }
}
