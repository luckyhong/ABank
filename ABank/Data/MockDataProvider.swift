//
//  MockDataProvider.swift
//  ABank
//
//  Created by 韩继宏 on 2025/10/27.
//

import UIKit

/// 假数据提供者 - 模拟网络请求返回的数据
final class MockDataProvider {

    static let shared = MockDataProvider()

    private init() {}

    // MARK: - 首页

    func getHomePageData() -> HomePageData {
        HomePageData(
            searchPlaceholders: ["分期借钱", "存金通", "个人养老金", "农银快e宝", "生活缴费"],
            messageBadge: 322,
            heroBanners: [
                HomeHeroBannerItem(
                    title: "微信首绑享优惠",
                    subtitle: "16元返现券",
                    actionTitle: "查看详情 >",
                    isAd: true
                ),
                HomeHeroBannerItem(
                    title: "掌银新客专享礼",
                    subtitle: "最高88元立减金",
                    actionTitle: "立即领取 >",
                    isAd: true
                ),
                HomeHeroBannerItem(
                    title: "信用卡笔笔返现",
                    subtitle: "达标最高返88元",
                    actionTitle: "去看看 >",
                    isAd: true
                )
            ],
            shortcuts: [
                HomeShortcutItem(title: "我的账户", systemIcon: "person.fill", backgroundColor: UIColor(red: 0.0, green: 0.68, blue: 0.58, alpha: 1)),
                HomeShortcutItem(title: "转账", systemIcon: "arrow.left.arrow.right", backgroundColor: UIColor(red: 1.0, green: 0.58, blue: 0.18, alpha: 1)),
                HomeShortcutItem(title: "收支", systemIcon: "list.bullet.rectangle", backgroundColor: UIColor(red: 0.12, green: 0.62, blue: 0.52, alpha: 1)),
                HomeShortcutItem(title: "扫一扫", systemIcon: "qrcode.viewfinder", backgroundColor: UIColor(red: 1.0, green: 0.62, blue: 0.28, alpha: 1))
            ],
            gridItems: [
                HomeGridItem(title: "信用卡", systemIcon: "creditcard", badge: nil),
                HomeGridItem(title: "养老社区", systemIcon: "house", badge: nil),
                HomeGridItem(title: "普惠金融", systemIcon: "yensign.circle", badge: "NEW"),
                HomeGridItem(title: "存款", systemIcon: "banknote", badge: nil),
                HomeGridItem(title: "理财产品", systemIcon: "chart.line.uptrend.xyaxis", badge: nil),
                HomeGridItem(title: "贷款", systemIcon: "bag.fill", badge: nil),
                HomeGridItem(title: "生活缴费", systemIcon: "bolt.fill", badge: nil),
                HomeGridItem(title: "热门活动", systemIcon: "megaphone.fill", badge: nil),
                HomeGridItem(title: "城市专区", systemIcon: "building.2.fill", badge: nil),
                HomeGridItem(title: "全部", systemIcon: "ellipsis.circle", badge: nil)
            ],
            notices: [
                HomeNoticeItem(tag: "待办", text: "您的月度账单已出，请查看"),
                HomeNoticeItem(tag: "焦点", text: "新品速递 | 农银理财新发产品火热销售中")
            ],
            promoBanners: [
                HomePromoBannerItem(title: "江泽民诞辰100周年", subtitle: "金银纪念币", tone: .gold),
                HomePromoBannerItem(title: "掌银生活节", subtitle: "精彩活动进行中", tone: .peach),
                HomePromoBannerItem(title: "绿色金融专区", subtitle: "低碳生活有礼", tone: .mint),
                HomePromoBannerItem(title: "贵金属热卖", subtitle: "投资收藏优选", tone: .gold)
            ],
            wealthFeatured: HomeWealthFeaturedItem(
                title: "农银快e宝2号",
                tag: "基金",
                subtitle: "最快实时到账",
                highlightValue: "20万元",
                highlightLabel: "每日最高累计快赎额度",
                actionTitle: "查看详情"
            ),
            wealthSides: [
                HomeWealthSideItem(title: "银利多", tag: "存款", subtitle: "起存金额低、存期选择多", actionTitle: "去看看 >"),
                HomeWealthSideItem(title: "存金通", tag: "贵金属", subtitle: "买黄金，到农行", actionTitle: "去看看 >")
            ],
            marketQuotes: [
                HomeMarketQuote(name: "美元(USD)", value: "673.66"),
                HomeMarketQuote(name: "黄金(AU)", value: "971.29")
            ],
            activityFeatured: HomeActivityFeaturedItem(
                title: "小豆乐园兑好礼",
                subtitle: "精彩活动不容错过",
                isAd: true
            ),
            activitySides: [
                HomeActivitySideItem(title: "茶影优惠享", subtitle: "瑞幸低至6元起", actionTitle: "去查看 >", isAd: true),
                HomeActivitySideItem(title: "天天返现", subtitle: "单笔满18元享随机返现", actionTitle: "去参与 >", isAd: true)
            ],
            pensionSlogan: "岁月静好 悦享人生",
            pensionSubtitle: "开启银龄生活新篇章",
            pensionServices: [
                HomePensionServiceItem(title: "社保服务", systemIcon: "person.text.rectangle"),
                HomePensionServiceItem(title: "企业年金", systemIcon: "calendar"),
                HomePensionServiceItem(title: "个人养老金", systemIcon: "doc.text"),
                HomePensionServiceItem(title: "退休年龄", systemIcon: "function")
            ],
            branch: HomeBranchInfo(
                name: "西安沣东新城支行",
                status: "营业中",
                distance: "距您约2552米",
                address: "陕西省西安市沣东新城大明宫·沣东一路88号",
                services: [
                    HomeBranchServiceItem(title: "我要开卡", systemIcon: "creditcard.fill"),
                    HomeBranchServiceItem(title: "纪念币预约", systemIcon: "bitcoinsign.circle"),
                    HomeBranchServiceItem(title: "同号换卡", systemIcon: "arrow.triangle.2.circlepath")
                ]
            ),
            infoMarket: HomeInfoMarketItem(
                title: "市场观点",
                source: "财经全视角",
                summary: "券商看市：美联储今年大概率维持利率不变，美国通胀步入新阶段"
            ),
            infoVideos: [
                HomeInfoVideoItem(
                    title: "黄金市场观察",
                    caption: "央行偷偷买爆黄金！散户割肉时它为何在抄底",
                    headline: "央行偷偷买爆黄金！"
                ),
                HomeInfoVideoItem(
                    title: "债市观察",
                    caption: "债市波动加大，稳健配置怎么选",
                    headline: "债市波动加大"
                ),
                HomeInfoVideoItem(
                    title: "理财小课堂",
                    caption: "新手理财三步走，稳健收益看得见",
                    headline: "新手理财三步走"
                )
            ],
            consumerProtection: [
                HomeConsumerProtectionItem(
                    title: "资讯速递",
                    subtitle: "了解消保动态",
                    backgroundColor: UIColor(red: 0.90, green: 0.97, blue: 0.95, alpha: 1)
                ),
                HomeConsumerProtectionItem(
                    title: "消保博览",
                    subtitle: "提升金融素养",
                    backgroundColor: UIColor(red: 0.90, green: 0.94, blue: 1.0, alpha: 1)
                ),
                HomeConsumerProtectionItem(
                    title: "投诉指南",
                    subtitle: "知悉投诉渠道",
                    backgroundColor: UIColor(red: 1.0, green: 0.96, blue: 0.90, alpha: 1)
                ),
                HomeConsumerProtectionItem(
                    title: "服务价格标准",
                    subtitle: "了解服务详情",
                    backgroundColor: UIColor(red: 1.0, green: 0.93, blue: 0.94, alpha: 1)
                )
            ]
        )
    }

    // MARK: - 账户信息（其他模块复用）

    struct AccountInfo {
        let cardNumber: String
        let balance: Double
        let accountName: String
    }

    func getAccountInfo() -> AccountInfo {
        AccountInfo(
            cardNumber: "6228480012345678901",
            balance: 128456.78,
            accountName: "张三"
        )
    }

    // MARK: - 交易记录

    struct Transaction {
        let id: String
        let title: String
        let amount: Double
        let date: Date
        let type: TransactionType
    }

    enum TransactionType {
        case income
        case expense
    }

    func getTransactions(limit: Int = 20) -> [Transaction] {
        let transactions: [Transaction] = [
            Transaction(id: "1", title: "工资收入", amount: 12800.0, date: Date(), type: .income),
            Transaction(id: "2", title: "转账-李四", amount: -2000.0, date: Date().addingTimeInterval(-86400), type: .expense),
            Transaction(id: "3", title: "理财收益", amount: 186.32, date: Date().addingTimeInterval(-172800), type: .income),
            Transaction(id: "4", title: "美团外卖", amount: -38.5, date: Date().addingTimeInterval(-259200), type: .expense),
            Transaction(id: "5", title: "水电缴费", amount: -126.8, date: Date().addingTimeInterval(-345600), type: .expense)
        ]
        return Array(transactions.prefix(limit))
    }
}
