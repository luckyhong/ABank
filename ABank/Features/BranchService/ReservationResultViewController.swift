//
//  ReservationResultViewController.swift
//  ABank
//
//  预约结果：预约码、业务、网点、日期时段与数量。“完成”回到进入预约前的页面。
//

import UIKit
import SnapKit

final class ReservationResultViewController: BranchFlowViewController {
    private let reservationID: String

    init(reservationID: String, cities: CitySelectionStore = .shared, services: BranchServiceStore = .shared,
         dates: BankingDateContext = .system) {
        self.reservationID = reservationID
        super.init(cities: cities, services: services, dates: dates)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        super.setupUI()
        title = "预约结果"
        navigationItem.hidesBackButton = true
    }

    override func refreshBankingData() {
        clearContent()
        guard let reservation = services.reservation(id: reservationID) else {
            addEmptyState("记录不存在", id: "reservationResult.empty")
            return
        }
        let status = services.status(of: reservation)
        let icon = UIImageView(image: UIImage(systemName: status == .pending ? "checkmark.circle.fill" : "info.circle.fill",
                                              withConfiguration: UIImage.SymbolConfiguration(pointSize: 52)))
        icon.tintColor = status == .pending ? .abankPrimary : .abankTextTertiary
        icon.contentMode = .scaleAspectFit
        let title = UILabel()
        title.text = status == .pending ? "预约成功" : "预约" + status.title
        title.font = .abankHeadline()
        title.textAlignment = .center
        let code = UILabel()
        code.text = "预约码 " + reservation.code
        code.font = .systemFont(ofSize: 22, weight: .semibold)
        code.textColor = .abankTextPrimary
        code.textAlignment = .center
        code.accessibilityIdentifier = "reservationResult.code"
        addCard([icon, title, code, branchCaption("请凭预约码与本人有效证件到网点办理", color: .abankTextSecondary)],
                spacing: Spacing.sm, insets: Spacing.lg)

        var rows = [
            TransferInfoRow("业务", value: reservation.business.title),
            TransferInfoRow("网点", value: BranchCatalog.displayName(branchID: reservation.branchID)),
            TransferInfoRow("日期时段", value: dayLabel(reservation.date) + " " + reservation.slotLabel)
        ]
        if let quantity = reservation.quantity {
            rows.append(TransferInfoRow("兑换数量", value: "\(quantity) 枚"))
        }
        addCard(rows, spacing: 0, insets: 0)

        _ = addButton("查看记录", id: "reservationResult.history", primary: false) { [weak self] in
            guard let self else { return }
            self.router.open(.branchServiceHistory, from: self)
        }
        _ = addButton("完成", id: "reservationResult.done") { [weak self] in self?.finish() }
    }

    /// 回到预约表单之前的页面。
    private func finish() {
        guard let nav = navigationController else { return }
        if let formIndex = nav.viewControllers.lastIndex(where: { $0 is ReservationFormViewController }), formIndex > 0 {
            nav.popToViewController(nav.viewControllers[formIndex - 1], animated: true)
        } else {
            nav.popToRootViewController(animated: true)
        }
    }
}
