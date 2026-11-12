import UIKit

final class LifeOfferViewController: TransferFlowViewController {
    private let offerTitle: String
    private let subtitle: String
    init(title: String, subtitle: String) { self.offerTitle = title; self.subtitle = subtitle; super.init(nibName: nil, bundle: nil); hidesBottomBarWhenPushed = true }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func setupUI() {
        super.setupUI(); title = "活动详情"
        contentStack.addArrangedSubview(BankingPageStyle.surface([BankingPageStyle.text(offerTitle, style: .title2), BankingPageStyle.text(subtitle, style: .body, color: .abankTextSecondary)]))
        contentStack.addArrangedSubview(BankingReadSection(title: "领取与使用", body: "可领取的权益与有效期请在卡券中心查看。领取后可在“我的卡券”查询使用状态，充值缴费优惠请在确认页面选择。"))
        _ = addButton("查看可用卡券", id: "life.offer.coupons") { [weak self] in guard let self else { return }; self.router.open(.coupons, from: self) }
        _ = addButton("查看权益中心", id: "life.offer.benefits", primary: false) { [weak self] in guard let self else { return }; self.router.open(.benefits, from: self) }
    }
}
