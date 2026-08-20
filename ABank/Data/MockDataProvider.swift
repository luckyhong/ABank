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

    // MARK: - 财富

    func getWealthPageData() -> WealthPageData {
        WealthPageData(
            searchPlaceholder: "存款证明",
            messageBadge: 322,
            greeting: WealthGreeting(
                message: "上午好，点击查看持仓",
                loginTitle: "登录"
            ),
            gridItems: [
                WealthGridItem(title: "存款", systemIcon: "house.fill"),
                WealthGridItem(title: "理财产品", systemIcon: "circle.grid.3x3.fill"),
                WealthGridItem(title: "基金", systemIcon: "chart.line.uptrend.xyaxis"),
                WealthGridItem(title: "贵金属", systemIcon: "square.stack.3d.up.fill"),
                WealthGridItem(title: "债券", systemIcon: "chart.bar.fill"),
                WealthGridItem(title: "保险", systemIcon: "shield.fill"),
                WealthGridItem(title: "证券期货", systemIcon: "doc.text.fill"),
                WealthGridItem(title: "外汇", systemIcon: "dollarsign.arrow.circlepath"),
                WealthGridItem(title: "个人养老金", systemIcon: "house.and.flag.fill"),
                WealthGridItem(title: "全部", systemIcon: "ellipsis.circle")
            ],
            hotspot: WealthHotspot(
                tag: "热点",
                headline: "美国财政部宣布扩大国债回购规模，美债收益率显著下跌"
            ),
            productTabs: [
                WealthProductTab(
                    title: "日日悦享",
                    product: WealthFeaturedProduct(
                        name: "农银理财农银匠心·天天利理财产品2号",
                        yieldRate: "2.40%",
                        yieldLabel: "成立以来年化 ⓘ",
                        yieldDateRange: "2024/09/05-2026/08/19",
                        riskLevel: "中低风险",
                        riskLabel: "风险等级",
                        holdingPeriod: "最低持有1天",
                        holdingLabel: "最短持有期限",
                        actionTitle: "立即购买",
                        disclaimer: "理财产品过往业绩不代表其未来表现，不等于理财产品实际收益，投资须谨慎",
                        isAd: true
                    )
                ),
                WealthProductTab(
                    title: "低波稳健",
                    product: WealthFeaturedProduct(
                        name: "农银理财农银安心·天天利理财产品（票息优选）",
                        yieldRate: "1.90%",
                        yieldLabel: "成立以来年化 ⓘ",
                        yieldDateRange: "2025/07/25-2026/08/19",
                        riskLevel: "中低风险",
                        riskLabel: "风险等级",
                        holdingPeriod: "最低持有1天",
                        holdingLabel: "最短持有期限",
                        actionTitle: "立即购买",
                        disclaimer: "理财产品过往业绩不代表其未来表现，不等于理财产品实际收益，投资须谨慎",
                        isAd: true
                    )
                ),
                WealthProductTab(
                    title: "业绩优选",
                    product: WealthFeaturedProduct(
                        name: "农银理财农银匠心·灵动180天理财产品（量化多元增强）",
                        yieldRate: "2.96%",
                        yieldLabel: "成立以来年化 ⓘ",
                        yieldDateRange: "2026/04/21-2026/08/18",
                        riskLevel: "中低风险",
                        riskLabel: "风险等级",
                        holdingPeriod: "最低持有180天",
                        holdingLabel: "最短持有期限",
                        actionTitle: "立即购买",
                        disclaimer: "理财产品过往业绩不代表其未来表现，不等于理财产品实际收益，投资须谨慎",
                        isAd: true
                    )
                )
            ],
            spareMoneyFeatured: WealthSpareMoneyFeatured(
                title: "农银时时付",
                tag: "理财",
                descriptions: ["现金管理类产品", "信用卡一键还款"],
                yieldRate: "0.90%",
                yieldLabel: "近7日年化",
                actionTitle: "查看详情"
            ),
            spareMoneySides: [
                WealthSpareMoneySide(
                    title: "农银快e宝2号",
                    tag: "基金",
                    subtitle: "最高20万元快赎额度",
                    yieldPrefix: "最高近7日年化",
                    yieldRate: "1.37%",
                    yieldLabel: ""
                ),
                WealthSpareMoneySide(
                    title: "农银快e宝",
                    tag: "基金",
                    subtitle: "支持自动还款",
                    yieldPrefix: "近7日年化",
                    yieldRate: "0.71%",
                    yieldLabel: ""
                )
            ],
            steadyProducts: [
                WealthSteadyProduct(
                    name: "农银理财农银安心·天天利理财产品（票息优选）",
                    yieldRate: "1.90%",
                    yieldLabel: "成立以来年化 ⓘ",
                    yieldDateRange: "2025/07/25-2026/08/19",
                    holdingPeriod: "最低持有1天",
                    purchaseInfo: "1.00元起购 | 中低风险",
                    isHot: true,
                    disclaimer: "理财产品过往业绩不代表其未来表现，不等于理财产品实际收益，投资须谨慎"
                ),
                WealthSteadyProduct(
                    name: "农银理财农银匠心·灵动180天理财产品（量化多元增强）",
                    yieldRate: "2.96%",
                    yieldLabel: "成立以来年化 ⓘ",
                    yieldDateRange: "2026/04/21-2026/08/18",
                    holdingPeriod: "最低持有180天",
                    purchaseInfo: "1.00元起购 | 中低风险",
                    isHot: false,
                    disclaimer: "理财产品过往业绩不代表其未来表现，不等于理财产品实际收益，投资须谨慎"
                )
            ],
            fundItems: [
                WealthFundItem(
                    name: "申万菱信乐享混合",
                    yieldRate: "113.61%",
                    yieldLabel: "近一年涨幅",
                    category: "混合型",
                    isSelected: true
                ),
                WealthFundItem(
                    name: "易方达科讯",
                    yieldRate: "82.25%",
                    yieldLabel: "近一年涨幅",
                    category: "混合型",
                    isSelected: false
                )
            ],
            depositItems: [
                WealthDepositItem(
                    name: "金穗2026年第29期个人大额存单（可转让）",
                    rate: "0.95%",
                    rateLabel: "年利率",
                    term: "6个月",
                    minPurchase: "200,000.00元起购"
                ),
                WealthDepositItem(
                    name: "金穗2026年第30期个人大额存单（可转让）",
                    rate: "1.05%",
                    rateLabel: "年利率",
                    term: "1年",
                    minPurchase: "200,000.00元起购"
                )
            ],
            bondIndex: WealthBondIndex(
                name: "中债-农行乡村振兴债券指数",
                yieldRate: "1.55%",
                yieldLabel: "收益率",
                indexValue: "117.68",
                indexLabel: "指数值",
                asOfDate: "截至日期：2026-08-19"
            ),
            studyBanner: WealthStudyBanner(
                title: "低价旅游背后的养老骗局",
                brand: "农银汇理基金",
                isAd: true
            ),
            studyCards: [
                WealthStudyCard(
                    title: "住房公积金提取和使用范围拓宽",
                    backgroundColor: UIColor(red: 1.0, green: 0.96, blue: 0.88, alpha: 1),
                    actionTitle: "GO"
                ),
                WealthStudyCard(
                    title: "如何看待宏观数据与微观感受的'温差'",
                    backgroundColor: UIColor(red: 0.88, green: 0.94, blue: 1.0, alpha: 1),
                    actionTitle: "GO"
                )
            ]
        )
    }

    // MARK: - 我的

    func getMinePageData() -> MinePageData {
        MinePageData(
            profile: MineProfileInfo(
                displayName: "*继宏",
                lastLoginDevice: "上次登录 iPhone 15",
                lastLoginTime: "2026-08-13 21:03:30",
                vipLevel: "二星客户",
                benefitsTitle: "权益中心"
            ),
            assetStats: [
                MineAssetStat(value: 1, label: "银行卡"),
                MineAssetStat(value: 0, label: "小豆"),
                MineAssetStat(value: 3, label: "积分"),
                MineAssetStat(value: 0, label: "礼券")
            ],
            assetLiability: MineAssetLiability(
                assets: 2660.66,
                liabilities: 10318.93,
                billNotice: "您的月度账单已出，请查看"
            ),
            monthlyFlow: MineMonthlyFlow(
                expense: 15054.91,
                income: 17205.04,
                billSectionTitle: "月度账单",
                billNotice: "您的7月份账单已出",
                hasBillBadge: true
            ),
            branch: MineBranchInfo(
                name: "西安沣东新城支行",
                distance: "2552米",
                services: [
                    MineGridItem(title: "我要开卡", systemIcon: "creditcard.badge.plus"),
                    MineGridItem(title: "纪念币预约", systemIcon: "bitcoinsign.circle"),
                    MineGridItem(title: "同号换卡", systemIcon: "iphone.and.arrow.forward"),
                    MineGridItem(title: "网点查询", systemIcon: "building.columns")
                ]
            ),
            securityItems: [
                MineGridItem(title: "登录设置", systemIcon: "door.left.hand.open"),
                MineGridItem(title: "转账设置", systemIcon: "shield.lefthalf.filled"),
                MineGridItem(title: "支付设置", systemIcon: "lock.shield"),
                MineGridItem(title: "登录设备", systemIcon: "iphone")
            ],
            customerManager: MineCustomerManager(
                name: "*凡柳",
                role: "客户经理",
                branch: "西安兴庆路支行营业室"
            )
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
