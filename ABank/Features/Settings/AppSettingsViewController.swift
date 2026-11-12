import UIKit

final class AppSettingsViewController: UITableViewController {
    private let sections: [[(String, AppRoute)]] = [
        [("客户资料", .customerInfo), ("安全中心", .securityCenter), ("登录设备", .loginDevices)],
        [("转账限额", .transferLimits), ("交易权限", .accountPermissions(accountID: nil)), ("登录设置", .loginSettings), ("支付设置", .paymentSettings)],
        [("常用功能", .editFavorites), ("消息中心", .messages)]
    ]
    init() { super.init(style: .insetGrouped); hidesBottomBarWhenPushed = true }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() { super.viewDidLoad(); title = "设置"; tableView.rowHeight = 56 }
    override func numberOfSections(in tableView: UITableView) -> Int { sections.count + 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { section < sections.count ? sections[section].count : 2 }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        if indexPath.section < sections.count { cell.textLabel?.text = sections[indexPath.section][indexPath.row].0; cell.accessoryType = .disclosureIndicator }
        else if indexPath.row == 0 {
            cell.textLabel?.text = "当前版本"; cell.detailTextLabel?.text = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            cell.selectionStyle = .none
        } else { cell.textLabel?.text = "退出登录"; cell.textLabel?.textColor = .abankError }
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section < sections.count { AppRouter.shared.open(sections[indexPath.section][indexPath.row].1, from: self) }
        else if indexPath.row == 1 { Self.confirmLogout(from: self) }
    }
    static func confirmLogout(from controller: UIViewController) {
        let alert = UIAlertController(title: "退出登录？", message: "退出后需重新验证手机号，账户资料和历史记录会保留。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "退出", style: .destructive) { _ in CustomerSessionStore.shared.signOut() })
        controller.present(alert, animated: true)
    }
}
