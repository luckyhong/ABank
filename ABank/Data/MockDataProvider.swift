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

    // MARK: - 生活

    func getLifePageData() -> LifePageData {
        LifePageData(
            city: "西安市",
            searchPlaceholders: ["本地优惠", "实物贵金属", "生活缴费", "手机充值"],
            banners: [
                LifeBannerItem(
                    title: "1元秒杀美酒",
                    subtitle: "每周都有特惠商品",
                    actionTitle: "立即参与 >",
                    backgroundColor: UIColor(red: 1.0, green: 0.96, blue: 0.90, alpha: 1),
                    accentColor: UIColor(red: 0.55, green: 0.35, blue: 0.20, alpha: 1),
                    systemIcon: "wineglass.fill",
                    isAd: true
                ),
                LifeBannerItem(
                    title: "掌银生活节",
                    subtitle: "精彩活动进行中",
                    actionTitle: "立即参与 >",
                    backgroundColor: UIColor(red: 1.0, green: 0.94, blue: 0.88, alpha: 1),
                    accentColor: UIColor(red: 0.85, green: 0.35, blue: 0.20, alpha: 1),
                    systemIcon: "gift.fill",
                    isAd: true
                )
            ],
            gridPages: [
                [
                    LifeGridItem(title: "生活缴费", systemIcon: "drop.fill", tintColor: .abankPrimary),
                    LifeGridItem(title: "手机充值", systemIcon: "iphone", tintColor: .abankOrange),
                    LifeGridItem(title: "政务民生", systemIcon: "person.fill", tintColor: .abankTeal),
                    LifeGridItem(title: "社保医保", systemIcon: "person.text.rectangle", tintColor: .abankPrimary),
                    LifeGridItem(title: "小豆乐园", systemIcon: "leaf.fill", tintColor: .abankSuccess),
                    LifeGridItem(title: "校园", systemIcon: "graduationcap.fill", tintColor: .abankPrimary),
                    LifeGridItem(title: "食堂", systemIcon: "fork.knife", tintColor: .abankOrange),
                    LifeGridItem(title: "党费", systemIcon: "flag.fill", tintColor: .abankHighlight),
                    LifeGridItem(title: "车主服务", systemIcon: "car.fill", tintColor: .abankTeal),
                    LifeGridItem(title: "农银商城", systemIcon: "storefront.fill", tintColor: .abankPrimary)
                ],
                [
                    LifeGridItem(title: "美团外卖", systemIcon: "bag.fill", tintColor: .abankOrange),
                    LifeGridItem(title: "电影演出", systemIcon: "film.fill", tintColor: .abankPrimary),
                    LifeGridItem(title: "酒店旅行", systemIcon: "airplane", tintColor: .abankTeal),
                    LifeGridItem(title: "快递寄件", systemIcon: "shippingbox.fill", tintColor: .abankOrange),
                    LifeGridItem(title: "医疗挂号", systemIcon: "cross.case.fill", tintColor: .abankPrimary),
                    LifeGridItem(title: "公积金", systemIcon: "building.columns.fill", tintColor: .abankTeal),
                    LifeGridItem(title: "交通出行", systemIcon: "bus.fill", tintColor: .abankPrimary),
                    LifeGridItem(title: "积分商城", systemIcon: "star.fill", tintColor: .abankOrange),
                    LifeGridItem(title: "爱心公益", systemIcon: "heart.fill", tintColor: .abankHighlight),
                    LifeGridItem(title: "全部", systemIcon: "ellipsis.circle", tintColor: .abankTextSecondary)
                ]
            ],
            colorfulFeatured: LifeActivityCard(
                title: "小豆乐园",
                subtitle: "小豆兑好礼",
                backgroundColor: UIColor(red: 1.0, green: 0.96, blue: 0.92, alpha: 1),
                systemIcon: "calendar",
                isAd: true
            ),
            colorfulSides: [
                LifeActivityCard(
                    title: "乡村集市",
                    subtitle: "好农品 货真价实",
                    backgroundColor: UIColor(red: 0.94, green: 0.98, blue: 0.94, alpha: 1),
                    systemIcon: "basket.fill",
                    isAd: true
                ),
                LifeActivityCard(
                    title: "茶影优惠享",
                    subtitle: "瑞幸咖啡低至6元起",
                    backgroundColor: UIColor(red: 1.0, green: 0.97, blue: 0.94, alpha: 1),
                    systemIcon: "cup.and.saucer.fill",
                    isAd: true
                )
            ],
            promoBanner: LifePromoBanner(
                title: "海量权益 一键直达",
                subtitle: "限时秒杀 | 热门卡券 | 积分抵扣",
                backgroundColor: UIColor(red: 1.0, green: 0.94, blue: 0.92, alpha: 1),
                systemIcon: "gift.fill",
                isAd: true
            ),
            feedItems: [
                LifeFeedItem(title: "天天返现（8月）", subtitle: "单笔满18元享随机返现", imageBackground: UIColor(red: 0.90, green: 0.97, blue: 0.94, alpha: 1), imageHeight: 120, systemIcon: "yensign.circle.fill", iconTint: .abankHighlight, isAd: true),
                LifeFeedItem(title: "茶影优惠享", subtitle: "瑞幸咖啡低至6元起", imageBackground: UIColor(red: 0.95, green: 0.98, blue: 1.0, alpha: 1), imageHeight: 100, systemIcon: "cup.and.saucer.fill", iconTint: UIColor(red: 0.55, green: 0.32, blue: 0.18, alpha: 1), isAd: false),
                LifeFeedItem(title: "逛九州享好礼", subtitle: "惊喜盲盒等你抽", imageBackground: UIColor(red: 0.92, green: 0.96, blue: 0.90, alpha: 1), imageHeight: 110, systemIcon: "building.2.fill", iconTint: .abankPrimary, isAd: true),
                LifeFeedItem(title: "美食聚\"惠\"", subtitle: "好农品 来掌银", imageBackground: UIColor(red: 1.0, green: 0.96, blue: 0.90, alpha: 1), imageHeight: 90, systemIcon: "takeoutbag.and.cup.and.straw.fill", iconTint: .abankOrange, isAd: true),
                LifeFeedItem(title: "潮玩盲盒开开乐", subtitle: "最高抽16元刷卡金券", imageBackground: UIColor(red: 0.88, green: 0.94, blue: 1.0, alpha: 1), imageHeight: 115, systemIcon: "cube.fill", iconTint: .abankPrimary, isAd: true),
                LifeFeedItem(title: "线上消费 笔笔有积分", subtitle: "消费1元累计1积分", imageBackground: UIColor(red: 0.85, green: 0.92, blue: 1.0, alpha: 1), imageHeight: 105, systemIcon: "creditcard.fill", iconTint: .abankPrimary, isAd: false),
                LifeFeedItem(title: "农夫山泉", subtitle: "天然好水送到家", imageBackground: UIColor(red: 0.90, green: 0.96, blue: 1.0, alpha: 1), imageHeight: 100, systemIcon: "drop.fill", iconTint: UIColor(red: 0.2, green: 0.55, blue: 0.9, alpha: 1), isAd: true),
                LifeFeedItem(title: "抽京东E卡", subtitle: "逛集市，享优惠！", imageBackground: UIColor(red: 1.0, green: 0.93, blue: 0.85, alpha: 1), imageHeight: 110, systemIcon: "giftcard.fill", iconTint: .abankOrange, isAd: true),
                LifeFeedItem(title: "华为商城", subtitle: "至高12期0分期利息", imageBackground: UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1), imageHeight: 100, systemIcon: "laptopcomputer.and.iphone", iconTint: .abankTextPrimary, isAd: true),
                LifeFeedItem(title: "低碳空间", subtitle: "减碳赢勋章", imageBackground: UIColor(red: 0.92, green: 0.96, blue: 0.92, alpha: 1), imageHeight: 95, systemIcon: "leaf.fill", iconTint: .abankSuccess, isAd: true),
                LifeFeedItem(title: "爱奇艺白金会员", subtitle: "月卡低至15元", imageBackground: UIColor(red: 1.0, green: 0.94, blue: 0.96, alpha: 1), imageHeight: 100, systemIcon: "play.rectangle.fill", iconTint: .abankHighlight, isAd: true),
                LifeFeedItem(title: "卡券福利", subtitle: "超多好券超惊喜", imageBackground: UIColor(red: 1.0, green: 0.93, blue: 0.94, alpha: 1), imageHeight: 105, systemIcon: "ticket.fill", iconTint: .abankHighlight, isAd: true),
                LifeFeedItem(title: "测一测适合你的一款酒", subtitle: "找到你的\"酒圈\"人格", imageBackground: UIColor(red: 0.92, green: 0.97, blue: 0.92, alpha: 1), imageHeight: 110, systemIcon: "wineglass.fill", iconTint: UIColor(red: 0.45, green: 0.65, blue: 0.35, alpha: 1), isAd: true),
                LifeFeedItem(title: "喜马拉雅白金会员", subtitle: "月卡低至15元", imageBackground: UIColor(red: 1.0, green: 0.94, blue: 0.96, alpha: 1), imageHeight: 100, systemIcon: "headphones", iconTint: UIColor(red: 0.85, green: 0.35, blue: 0.35, alpha: 1), isAd: true)
            ],
            loadFinishedText: "已经全部加载完毕"
        )
    }

    // MARK: - 资讯

    func getNewsPageData() -> NewsPageData {
        NewsPageData(
            searchPlaceholders: ["资讯热榜", "话题广场", "公积金", "基金理财"],
            messageBadge: 322,
            categories: ["热点", "服务", "三农", "基金", "黄金", "保险", "房产"],
            heroBanners: [
                NewsHeroBannerItem(
                    tag: "#热点关注",
                    title: "公积金新政发布",
                    subtitle: "住房公积金提取范围迎重大变化！官方详解",
                    backgroundColor: UIColor(red: 0.42, green: 0.72, blue: 0.92, alpha: 1),
                    accentColor: UIColor(red: 1.0, green: 0.85, blue: 0.45, alpha: 1),
                    systemIcon: "house.fill"
                ),
                NewsHeroBannerItem(
                    tag: "#市场观察",
                    title: "A股震荡整理",
                    subtitle: "机构：短期关注政策面与流动性变化",
                    backgroundColor: UIColor(red: 0.15, green: 0.45, blue: 0.72, alpha: 1),
                    accentColor: .white,
                    systemIcon: "chart.line.uptrend.xyaxis"
                ),
                NewsHeroBannerItem(
                    tag: "#理财攻略",
                    title: "财富轻攻略",
                    subtitle: "理财干货，一看就会",
                    backgroundColor: UIColor(red: 0.95, green: 0.55, blue: 0.35, alpha: 1),
                    accentColor: .white,
                    systemIcon: "book.fill"
                ),
                NewsHeroBannerItem(
                    tag: "#农银财富",
                    title: "匠心守护 智富未来",
                    subtitle: "中国农业银行发布2026中期策略报告",
                    backgroundColor: UIColor(red: 0.0, green: 0.55, blue: 0.42, alpha: 1),
                    accentColor: UIColor(red: 1.0, green: 0.92, blue: 0.65, alpha: 1),
                    systemIcon: "leaf.fill"
                )
            ],
            flashNews: NewsFlashItem(
                time: "10:55",
                headline: "【折叠屏概念震荡拉升 科森科技涨停】财联社8月20日电，折叠屏概念盘..."
            ),
            hotVideos: [
                NewsVideoItem(
                    title: "防范“圆梦卡”诈骗",
                    overlayTitle: "防范 ‘圆梦卡’ 诈骗",
                    backgroundColor: UIColor(red: 0.18, green: 0.28, blue: 0.38, alpha: 1),
                    systemIcon: "person.fill",
                    iconTint: UIColor(red: 0.85, green: 0.72, blue: 0.52, alpha: 1)
                ),
                NewsVideoItem(
                    title: "你的公积金还能这么用！",
                    overlayTitle: "",
                    backgroundColor: UIColor(red: 0.55, green: 0.76, blue: 0.92, alpha: 1),
                    systemIcon: "house.fill",
                    iconTint: UIColor(red: 0.95, green: 0.82, blue: 0.35, alpha: 1)
                ),
                NewsVideoItem(
                    title: "全年经营分析会",
                    overlayTitle: "",
                    backgroundColor: UIColor(red: 0.42, green: 0.48, blue: 0.58, alpha: 1),
                    systemIcon: "person.3.fill",
                    iconTint: UIColor.white.withAlphaComponent(0.85)
                ),
                NewsVideoItem(
                    title: "黄金市场观察",
                    overlayTitle: "",
                    backgroundColor: UIColor(red: 0.45, green: 0.38, blue: 0.22, alpha: 1),
                    systemIcon: "chart.bar.fill",
                    iconTint: UIColor(red: 1.0, green: 0.82, blue: 0.35, alpha: 1)
                )
            ],
            hotRankItems: [
                NewsHotRankItem(rank: 1, title: "A股全线下跌，午后跌幅加大，谁砸的？", badge: nil),
                NewsHotRankItem(rank: 2, title: "美股收涨！医药龙头暴涨近180%，存...", badge: .new),
                NewsHotRankItem(rank: 3, title: "闪崩！全球抛售潮加剧", badge: .hot)
            ],
            interactiveTopic: NewsInteractiveTopic(
                question: "暑期档影片大比拼，您更喜欢哪一部？",
                participantCount: 1303,
                description: "今年暑期档电影类型丰富，从动作大片到温情治愈，您最期待哪一部？",
                options: ["《功夫女足》", "《蜘蛛侠：崭新之日》", "《八仙！》"]
            ),
            followSuggestions: [
                NewsFollowSuggestion(name: "远程银行中心", systemIcon: "building.columns.fill", tintColor: .abankPrimary),
                NewsFollowSuggestion(name: "掌银全攻略", systemIcon: "iphone", tintColor: .abankOrange),
                NewsFollowSuggestion(name: "农银财富", systemIcon: "chart.pie.fill", tintColor: .abankTeal),
                NewsFollowSuggestion(name: "财经全视角", systemIcon: "newspaper.fill", tintColor: .abankHighlight)
            ],
            trendingItems: [
                NewsTrendingItem(title: "中央媒体看辽宁 | 央视新闻：一条路牵动万家企业"),
                NewsTrendingItem(title: "一周展望：美联储纪要携手PMI来袭，市场如何走？"),
                NewsTrendingItem(title: "暑期消费回暖，文旅板块迎来修复行情")
            ],
            pkPoll: NewsPKPoll(
                question: "您选燃油车还是新能源车呢？",
                participantCount: 18765,
                leftOption: "燃油车",
                rightOption: "新能源车"
            ),
            initialFeed: makeInitialNewsFeed(),
            totalFeedPages: 5
        )
    }

    func loadMoreNewsFeed(page: Int, category: String) -> NewsFeedPageResult {
        let hasMore = page < 5
        let items = makeNewsFeedPage(page: page, category: category)
        return NewsFeedPageResult(items: items, hasMore: hasMore)
    }

    private func makeInitialNewsFeed() -> [NewsFeedEntry] {
        [
            .strip(NewsFeedStripItem(
                id: "strip-1",
                brand: "金融界",
                headline: "美联储利率决议前瞻：通胀担忧与政策分歧成关注焦点",
                brandColor: UIColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 1)
            )),
            .article(NewsArticleItem(
                id: "article-1",
                title: "美国财政部宣布扩大国债回购规模，美债收益率显著下跌",
                source: "金融市场日报",
                readCount: 902,
                date: "08-20",
                thumbnailBackground: UIColor(red: 0.92, green: 0.95, blue: 1.0, alpha: 1),
                systemIcon: "flag.fill",
                iconTint: UIColor(red: 0.20, green: 0.40, blue: 0.75, alpha: 1)
            )),
            .article(NewsArticleItem(
                id: "article-2",
                title: "7月国民经济运行总体平稳，新质生产力加快培育",
                source: "中新经纬",
                readCount: 651,
                date: "08-20",
                thumbnailBackground: UIColor(red: 0.90, green: 0.96, blue: 0.94, alpha: 1),
                systemIcon: "chart.bar.doc.horizontal.fill",
                iconTint: .abankPrimary
            )),
            .article(NewsArticleItem(
                id: "article-3",
                title: "商务部：中方愿与各方一道维护多边贸易体制",
                source: "财经全视角",
                readCount: 328,
                date: "08-20",
                thumbnailBackground: UIColor(red: 1.0, green: 0.96, blue: 0.90, alpha: 1),
                systemIcon: "globe.asia.australia.fill",
                iconTint: .abankOrange
            )),
            .topic(NewsFeedTopicItem(
                id: "topic-1",
                tag: "专题",
                title: "投资小喇叭 | 普及金融知识，理性稳健投资",
                bannerTitle: "投资小喇叭",
                bannerSubtitle: "每日市场速递，把握投资脉搏",
                backgroundColor: UIColor(red: 1.0, green: 0.55, blue: 0.20, alpha: 1),
                systemIcon: "megaphone.fill",
                iconTint: UIColor.white.withAlphaComponent(0.9)
            )),
            .article(NewsArticleItem(
                id: "article-4",
                title: "风口财评 | 演出票请给退改留好缓冲带",
                source: "财经全视角",
                readCount: 147,
                date: "08-20",
                thumbnailBackground: UIColor(red: 0.94, green: 0.92, blue: 0.98, alpha: 1),
                systemIcon: "ticket.fill",
                iconTint: UIColor(red: 0.45, green: 0.30, blue: 0.65, alpha: 1)
            )),
            .banner(NewsFeedBannerItem(
                id: "banner-2",
                title: "农银财富 | 稳健增值之选",
                subtitle: "专业投研 安心托付",
                backgroundColor: UIColor(red: 0.0, green: 0.58, blue: 0.45, alpha: 1),
                systemIcon: "leaf.fill",
                iconTint: UIColor.white.withAlphaComponent(0.9)
            )),
            .video(NewsFeedVideoItem(
                id: "video-1",
                title: "市场分析：美国20年期国债需求略显疲软",
                backgroundColor: UIColor(red: 0.18, green: 0.22, blue: 0.32, alpha: 1),
                systemIcon: "chart.line.uptrend.xyaxis",
                iconTint: UIColor(red: 1.0, green: 0.78, blue: 0.30, alpha: 1)
            )),
            .article(NewsArticleItem(
                id: "article-5",
                title: "经纬早班车 | 美股三大指数小幅上涨，Moderna飙涨近17%",
                source: "中新经纬",
                readCount: 851,
                date: "08-20",
                thumbnailBackground: UIColor(red: 0.88, green: 0.94, blue: 1.0, alpha: 1),
                systemIcon: "sunrise.fill",
                iconTint: UIColor(red: 0.95, green: 0.55, blue: 0.20, alpha: 1)
            )),
            .article(NewsArticleItem(
                id: "article-6",
                title: "华尔街最担心的事要发生了?",
                source: "财经全视角",
                readCount: 10,
                date: "08-20",
                thumbnailBackground: UIColor(red: 0.92, green: 0.92, blue: 0.96, alpha: 1),
                systemIcon: "exclamationmark.triangle.fill",
                iconTint: .abankHighlight
            )),
            .article(NewsArticleItem(
                id: "article-7",
                title: "2026.08.20星期四",
                source: "财经全视角",
                readCount: 579,
                date: "08-20",
                thumbnailBackground: UIColor(red: 0.95, green: 0.93, blue: 0.90, alpha: 1),
                systemIcon: "calendar",
                iconTint: .abankOrange
            )),
            .topic(NewsFeedTopicItem(
                id: "topic-2",
                tag: "专题",
                title: "财富轻攻略 | 解锁理财实用手册",
                bannerTitle: "财富轻攻略",
                bannerSubtitle: "理财干货，一看就会",
                backgroundColor: UIColor(red: 1.0, green: 0.72, blue: 0.52, alpha: 1),
                systemIcon: "book.closed.fill",
                iconTint: UIColor.white.withAlphaComponent(0.9)
            ))
        ]
    }

    private func makeNewsFeedPage(page: Int, category: String) -> [NewsFeedEntry] {
        let titles = [
            "【\(category)】央行公开市场开展7000亿元逆回购操作",
            "【\(category)】多家银行下调存款利率，储户如何配置资产",
            "【\(category)】新能源汽车销量持续走高，产业链迎机遇",
            "【\(category)】房地产支持政策再加码，一线城市成交回暖",
            "【\(category)】基金二季报披露完毕，权益类仓位稳中有升",
            "【\(category)】黄金价格高位震荡，短期关注美联储表态"
        ]
        let sources = ["财经全视角", "金融市场日报", "中新经纬", "金融界"]
        let icons = ["chart.bar.fill", "yensign.circle.fill", "building.2.fill", "leaf.fill"]
        let colors: [UIColor] = [
            UIColor(red: 0.90, green: 0.96, blue: 0.94, alpha: 1),
            UIColor(red: 0.94, green: 0.92, blue: 0.98, alpha: 1),
            UIColor(red: 1.0, green: 0.96, blue: 0.90, alpha: 1),
            UIColor(red: 0.88, green: 0.94, blue: 1.0, alpha: 1)
        ]
        let tints: [UIColor] = [.abankPrimary, .abankOrange, .abankTeal, .abankHighlight]

        var entries: [NewsFeedEntry] = []
        let baseIndex = (page - 1) * 6

        for i in 0..<6 {
            let idx = baseIndex + i
            let title = titles[i % titles.count]
            entries.append(.article(NewsArticleItem(
                id: "page-\(page)-article-\(i)",
                title: title,
                source: sources[i % sources.count],
                readCount: 50 + (idx * 37) % 900,
                date: "08-20",
                thumbnailBackground: colors[i % colors.count],
                systemIcon: icons[i % icons.count],
                iconTint: tints[i % tints.count]
            )))
        }

        if page == 2 {
            entries.insert(.topic(NewsFeedTopicItem(
                id: "page-2-topic",
                tag: "专题",
                title: "匠心守护，智富未来 | 中国农业银行发布中期策略",
                bannerTitle: "农银财富",
                bannerSubtitle: "匠心守护 智富未来",
                backgroundColor: UIColor(red: 0.0, green: 0.55, blue: 0.42, alpha: 1),
                systemIcon: "leaf.circle.fill",
                iconTint: UIColor.white.withAlphaComponent(0.9)
            )), at: 2)
        }

        if page == 3 {
            entries.insert(.video(NewsFeedVideoItem(
                id: "page-3-video",
                title: "美联储利率决议前瞻：通胀担忧与政策分歧成关注焦点",
                backgroundColor: UIColor(red: 0.22, green: 0.28, blue: 0.38, alpha: 1),
                systemIcon: "play.rectangle.fill",
                iconTint: .white
            )), at: 1)
        }

        return entries
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
