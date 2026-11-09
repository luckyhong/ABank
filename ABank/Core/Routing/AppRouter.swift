//
//  AppRouter.swift
//  ABank
//
//  把 AppRoute 构造成页面并推入当前导航栈。所有功能入口统一经由这里。
//

import UIKit

protocol AppRouting: AnyObject {
    /// 打开指定路由；不记录最近使用（用于带上下文的直接跳转）。
    func open(_ route: AppRoute, from source: UIViewController)
    /// 打开功能入口：已完成功能记录最近使用后打开，待上线功能进入即将上线页。
    func open(feature id: FeatureID, from source: UIViewController)
}

/// 新页面声明自己承载的路由，用于栈顶去重。
protocol RouteHosting: UIViewController {
    var hostedRoute: AppRoute? { get }
}

final class AppRouter: AppRouting {
    static let shared = AppRouter()

    private let preferences: FeaturePreferencesStore
    private let ledger: FinanceLedgerStore
    private weak var lastPushed: UIViewController?
    private var lastRoute: AppRoute?

    init(preferences: FeaturePreferencesStore = .shared, ledger: FinanceLedgerStore = .shared) {
        self.preferences = preferences
        self.ledger = ledger
    }

    func open(_ route: AppRoute, from source: UIViewController) {
        guard let navigationController = source.navigationController else {
            assertionFailure("AppRouter 需要导航控制器：\(type(of: source))")
            return
        }
        let top = navigationController.topViewController
        if (top as? RouteHosting)?.hostedRoute == route { return }
        if let lastPushed, lastPushed === top, lastRoute == route { return }

        let controller = makeViewController(for: route)
        lastPushed = controller
        lastRoute = route
        navigationController.pushViewController(controller, animated: true)
    }

    func open(feature id: FeatureID, from source: UIViewController) {
        let descriptor = FeatureCatalog.descriptor(id)
        switch descriptor.availability {
        case .available(let route):
            preferences.recordUse(id)
            open(route, from: source)
        case .planned:
            open(.comingSoon(id), from: source)
        }
    }

    /// 穷举所有路由（禁止 default），新增路由时由编译器提示补全。
    func makeViewController(for route: AppRoute) -> UIViewController {
        switch route {
        case .myAccount:
            return MyAccountViewController()
        case .debitCardDetail:
            return DebitCardDetailViewController()
        case .transfer(let payerAccountID):
            return TransferViewController(payerAccountID: payerAccountID)
        case .transferForm(let method):
            return TransferFormViewController(method: method, store: ledger)
        case .assistant:
            return AssistantViewController()
        case .scan:
            return ScanViewController()
        case .transferToPayee(let name, let bankName, let account):
            let draft = TransferDraft(payerAccountID: ledger.load().accounts.first?.id ?? "", method: .account,
                                      recipientName: name, bankName: bankName, destination: account)
            return TransferFormViewController(method: .account, initialDraft: draft, store: ledger)
        case .transferRecords:
            return TransferRecordsViewController(store: ledger)
        case .transferLimits:
            return TransferSettingsViewController(ledger: ledger)
        case .transferReceipts:
            return TransferReceiptsViewController(store: ledger)
        case .accountDetail(let accountID, let maskedNumber):
            return AccountDetailQueryViewController(
                accountId: accountID ?? FinanceLedgerRecord.defaultAccountId,
                maskedNumber: maskedNumber ?? "6230 **** 8472"
            )
        case .incomeExpense(let accountID):
            return IncomeExpenseViewController(accountId: accountID)
        case .ledgerAnalysis:
            return LedgerAnalysisViewController()
        case .ledgerSearch:
            return LedgerSearchViewController(
                query: IncomeExpenseQuery(dateMode: .month(BankingDateContext.system.previousMonth))
            )
        case .assetLiability:
            return AssetLiabilityViewController()
        case .myLoan:
            return MyLoanViewController()
        case .accountAlias(let accountID):
            return AccountAliasViewController(accountID: accountID ?? FinanceLedgerRecord.defaultAccountId, ledger: ledger)
        case .accountShare(let accountID):
            return AccountShareViewController(accountID: accountID ?? FinanceLedgerRecord.defaultAccountId, ledger: ledger)
        case .accountPermissions(let accountID):
            return AccountPermissionsViewController(accountID: accountID ?? FinanceLedgerRecord.defaultAccountId, ledger: ledger)
        case .customerInfo:
            return CustomerInfoViewController()
        case .allFeatures(let keyword):
            return AllFeaturesViewController(searchKeyword: keyword, preferences: preferences)
        case .editFavorites:
            return FavoriteFeaturesEditViewController(preferences: preferences)
        case .comingSoon(let id):
            return ComingSoonViewController(featureID: id)
        case .securityCenter:
            return SecurityCenterViewController()
        case .loginSettings:
            return LoginSettingsViewController()
        case .paymentSettings:
            return PaymentSettingsViewController()
        case .loginDevices:
            return LoginDevicesViewController()
        case .loginDeviceDetail(let deviceID):
            return LoginDeviceDetailViewController(deviceID: deviceID)
        case .cityPicker:
            return CityPickerViewController()
        case .branchList:
            return BranchListViewController()
        case .branchQueue:
            if let ticket = BranchServiceStore.shared.activeTicket {
                return TicketDetailViewController(ticketID: ticket.id)
            }
            return BranchListViewController()
        case .branchDetail(let branchID):
            return BranchDetailViewController(branchID: branchID)
        case .takeTicket(let branchID):
            return TakeTicketViewController(branchID: branchID)
        case .ticketDetail(let ticketID):
            return TicketDetailViewController(ticketID: ticketID)
        case .branchReservation(let business, let branchID):
            return ReservationFormViewController(business: business, branchID: branchID)
        case .branchServiceHistory:
            return BranchServiceHistoryViewController()
        case .benefits:
            return BenefitsCenterViewController()
        case .pointsMall:
            return RewardMallViewController(currency: .points)
        case .beans:
            return RewardMallViewController(currency: .beans)
        case .goodsDetail(let goodsID):
            return GoodsDetailViewController(goodsID: goodsID)
        case .rewardLedger(let currency):
            return RewardLedgerViewController(currency: currency)
        case .coupons:
            return CouponsViewController()
        case .couponDetail(let couponID):
            return CouponDetailViewController(couponID: couponID)
        case .orders:
            return OrdersViewController()
        case .orderDetail(let orderID, let justRedeemed):
            return OrderDetailViewController(orderID: orderID, justRedeemed: justRedeemed)
        case .customerLevel:
            return CustomerLevelViewController()
        case .wealthProducts:
            return WealthProductListViewController()
        case .wealthProductDetail(let productID):
            return WealthProductDetailViewController(productID: productID)
        case .riskAssessment:
            return RiskAssessmentViewController()
        case .wealthPurchase(let productID):
            return WealthPurchaseViewController(productID: productID)
        case .wealthOrderDetail(let orderID, let justPurchased):
            return WealthOrderDetailViewController(orderID: orderID, justPurchased: justPurchased)
        case .wealthHoldings:
            return WealthHoldingsViewController()
        case .mobileRecharge:
            return MobileRechargeViewController()
        case .mobileRechargeConfirm(let phone, let faceInCents):
            return MobileRechargeConfirmViewController(phone: phone, faceInCents: faceInCents)
        case .lifePayment:
            return LifePaymentViewController()
        case .utilityBill(let billAccountID):
            return UtilityBillViewController(billAccountID: billAccountID)
        case .paymentOrderDetail(let orderID, let justPaid):
            return PaymentOrderDetailViewController(orderID: orderID, justPaid: justPaid)
        }
    }
}
