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
            heroBanners: [
                HomeHeroBannerItem(
                    title: "掌银收支", subtitle: "花多少 花在哪", actionTitle: "查看账单", isAd: false,
                    imageName: "abc_home_bill_banner", featureID: .incomeExpense,
                    backdropColor: UIColor(red: 1.0, green: 0.78, blue: 0.58, alpha: 1)
                ),
                HomeHeroBannerItem(
                    title: "签到领小豆", subtitle: "查看小豆权益", actionTitle: "去签到", isAd: false,
                    imageName: "abc_home_beans_banner", featureID: .beans,
                    backdropColor: UIColor(red: 1.0, green: 0.91, blue: 0.72, alpha: 1)
                ),
                HomeHeroBannerItem(
                    title: "掌银连接美好生活", subtitle: "便捷生活服务", actionTitle: "查看服务", isAd: false,
                    imageName: "abc_home_life_banner", featureID: .lifePayment,
                    backdropColor: UIColor(red: 0.92, green: 0.88, blue: 0.81, alpha: 1)
                )
            ],
            shortcuts: [
                HomeShortcutItem(title: "我的账户", imageName: "abc_home_account", systemIcon: "person.fill", backgroundColor: UIColor(red: 0.0, green: 0.68, blue: 0.58, alpha: 1), featureID: .myAccount),
                HomeShortcutItem(title: "转账", imageName: "abc_home_transfer", systemIcon: "arrow.left.arrow.right", backgroundColor: UIColor(red: 1.0, green: 0.58, blue: 0.18, alpha: 1), featureID: .transfer),
                HomeShortcutItem(title: "收支", imageName: "abc_home_income", systemIcon: "list.bullet.rectangle", backgroundColor: UIColor(red: 0.12, green: 0.62, blue: 0.52, alpha: 1), featureID: .incomeExpense),
                HomeShortcutItem(title: "扫一扫", imageName: "abc_home_scan", systemIcon: "qrcode.viewfinder", backgroundColor: UIColor(red: 1.0, green: 0.62, blue: 0.28, alpha: 1), featureID: .scan)
            ],
            promoBanners: [
                HomePromoBannerItem(title: "积分专区", subtitle: "查看可用积分", tone: .gold, route: .pointsMall),
                HomePromoBannerItem(title: "每日签到", subtitle: "查看小豆权益", tone: .peach, route: .beans),
                HomePromoBannerItem(title: "绿色金融专区", subtitle: "低碳生活有礼", tone: .mint),
                HomePromoBannerItem(title: "贵金属热卖", subtitle: "投资收藏优选", tone: .gold)
            ],
            wealthFeatured: HomeWealthFeaturedItem(
                title: SimulatedFund.name,
                tag: "基金",
                subtitle: "申购与赎回",
                highlightValue: "次日确认",
                highlightLabel: "按模拟净值计算",
                actionTitle: "查看详情"
            ),
            wealthSides: [
                HomeWealthSideItem(title: "银利多", tag: "存款", subtitle: "起存金额低、存期选择多", actionTitle: "去看看"),
                HomeWealthSideItem(title: "存金通", tag: "贵金属", subtitle: "买黄金，到农行", actionTitle: "去查看")
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
            branch: homeBranchInfo(),
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
            messageBadge: BankMessageStore.shared.unreadCount(),
            greeting: WealthGreeting(
                message: "欢迎回来，查看您的资产与持仓",
                loginTitle: "我的持仓"
            ),
            gridItems: [
                WealthGridItem(title: "存款", imageName: "abc_wealth_menu_deposit", systemIcon: "house.fill", featureID: .deposit),
                WealthGridItem(title: "理财产品", imageName: "abc_wealth_menu_wealth", systemIcon: "circle.grid.3x3.fill", featureID: .wealthProduct),
                WealthGridItem(title: "基金", imageName: "abc_wealth_menu_fund", systemIcon: "chart.line.uptrend.xyaxis", featureID: .fund),
                WealthGridItem(title: "贵金属", imageName: "abc_wealth_menu_metals", systemIcon: "square.stack.3d.up.fill", featureID: .preciousMetals),
                WealthGridItem(title: "债券", imageName: "abc_wealth_menu_bonds", systemIcon: "chart.bar.fill", featureID: .bonds),
                WealthGridItem(title: "保险", imageName: "abc_wealth_menu_insurance", systemIcon: "shield.fill", featureID: .insurance),
                WealthGridItem(title: "证券期货", imageName: "abc_wealth_menu_securities", systemIcon: "doc.text.fill", featureID: .securities),
                WealthGridItem(title: "外汇", imageName: "abc_wealth_menu_forex", systemIcon: "dollarsign.arrow.circlepath", featureID: .forex),
                WealthGridItem(title: "个人养老金", imageName: "abc_wealth_menu_pension", systemIcon: "house.and.flag.fill", featureID: .personalPension),
                WealthGridItem(title: "全部", imageName: "abc_wealth_menu_all", systemIcon: "ellipsis.circle")
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
                    ),
                    productID: "w.tiantianli2"
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
                    ),
                    productID: "w.piaoxi"
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
                    ),
                    productID: "w.lingdong180"
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
                WealthSpareMoneySide(title: SimulatedFund.name, tag: "基金", subtitle: "按次日模拟净值确认",
                                    yieldPrefix: "", yieldRate: "1.00", yieldLabel: "元起购")
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
                    disclaimer: "理财产品过往业绩不代表其未来表现，不等于理财产品实际收益，投资须谨慎",
                    productID: "w.piaoxi"
                ),
                WealthSteadyProduct(
                    name: "农银理财农银匠心·灵动180天理财产品（量化多元增强）",
                    yieldRate: "2.96%",
                    yieldLabel: "成立以来年化 ⓘ",
                    yieldDateRange: "2026/04/21-2026/08/18",
                    holdingPeriod: "最低持有180天",
                    purchaseInfo: "1.00元起购 | 中低风险",
                    isHot: false,
                    disclaimer: "理财产品过往业绩不代表其未来表现，不等于理财产品实际收益，投资须谨慎",
                    productID: "w.lingdong180"
                )
            ],
            fundItems: [
                WealthFundItem(name: SimulatedFund.name, yieldRate: "1.00", yieldLabel: "元起购",
                               category: "混合型 · 模拟", isSelected: true)
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

    // MARK: - 网点卡（当前城市默认网点 + 实时营业状态）

    func homeBranchInfo(cities: CitySelectionStore = .shared, dates: BankingDateContext = .system) -> HomeBranchInfo {
        let summary = BranchCardSummary.make(cityID: cities.currentCity.id, at: dates.now, dates: dates)
        return HomeBranchInfo(
            name: summary.name,
            status: summary.status,
            distance: "距您约" + summary.distanceText,
            address: summary.address,
            services: [
                HomeBranchServiceItem(title: "我要开卡", imageName: "abc_home_branch_open", systemIcon: "creditcard.fill", featureID: .openCard),
                HomeBranchServiceItem(title: "纪念币预约", imageName: "abc_home_branch_coin", systemIcon: "bitcoinsign.circle", featureID: .coinReservation),
                HomeBranchServiceItem(title: "同号换卡", imageName: "abc_home_branch_replace", systemIcon: "arrow.triangle.2.circlepath", featureID: .sameNumberReplace)
            ]
        )
    }

    func mineBranchInfo(cities: CitySelectionStore = .shared, dates: BankingDateContext = .system) -> MineBranchInfo {
        let summary = BranchCardSummary.make(cityID: cities.currentCity.id, at: dates.now, dates: dates)
        return MineBranchInfo(
            name: summary.name,
            distance: summary.distanceText,
            services: [
                MineGridItem(title: "我要开卡", imageName: "abc_mine_branch_open", systemIcon: "creditcard.badge.plus", featureID: .openCard),
                MineGridItem(title: "纪念币预约", imageName: "abc_mine_branch_coin", systemIcon: "bitcoinsign.circle", featureID: .coinReservation),
                MineGridItem(title: "同号换卡", imageName: "abc_mine_branch_replace", systemIcon: "iphone.and.arrow.forward", featureID: .sameNumberReplace),
                MineGridItem(title: "网点查询", imageName: "abc_mine_branch_find", systemIcon: "building.columns", featureID: .branchQuery)
            ]
        )
    }

    // MARK: - 生活

    func getLifePageData(
        dates: BankingDateContext = .system,
        benefits: BenefitsStore = .shared,
        cityStore: CitySelectionStore = .shared
    ) -> LifePageData {
        let now = dates.now
        let city = cityStore.currentCity.name
        let dayIndex = Int(floor(dates.calendar.startOfDay(for: now).timeIntervalSince1970 / 86_400))
        let month = dates.string(from: now, format: "M月")
        let couponCount = benefits.unusedCouponCount
        let points = benefits.balance(.points)
        let checkIn = benefits.hasCheckedInToday ? "今日已签到" : "今日签到可领\(benefits.nextCheckInReward)小豆"
        let coupons = couponCount == 0 ? "查看卡券中心" : "\(couponCount)张卡券可用"

        let blue = UIColor(red: 0.88, green: 0.95, blue: 0.99, alpha: 1)
        let peach = UIColor(red: 1, green: 0.92, blue: 0.87, alpha: 1)
        let green = UIColor(red: 0.89, green: 0.96, blue: 0.91, alpha: 1)
        let amber = UIColor(red: 1, green: 0.96, blue: 0.85, alpha: 1)
        let lilac = UIColor(red: 0.95, green: 0.92, blue: 0.99, alpha: 1)
        let warmInk = UIColor(red: 0.42, green: 0.23, blue: 0.13, alpha: 1)
        let blueInk = UIColor(red: 0.14, green: 0.33, blue: 0.49, alpha: 1)
        let tips = [
            "缴费前核对户号和账单金额",
            "按需领取卡券，留意使用期限",
            "离家随手关灯，减少待机耗电",
            "短途出行可优先步行或骑行"
        ]
        let tip = tips[(dayIndex % tips.count + tips.count) % tips.count]

        let banners = [
            LifeBannerItem(title: "生活缴费", subtitle: "\(month)水电燃气账单", actionTitle: "查看账单",
                           backgroundColor: blue, accentColor: blueInk, artworkName: "life_illustration_payment", route: .lifePayment),
            LifeBannerItem(title: "小豆乐园", subtitle: checkIn, actionTitle: "查看签到",
                           backgroundColor: peach, accentColor: warmInk, artworkName: "life_illustration_calendar", route: .beans),
            LifeBannerItem(title: "积分兑换", subtitle: "可用积分 \(points)", actionTitle: "查看好礼",
                           backgroundColor: amber, accentColor: warmInk, artworkName: "life_illustration_gift", route: .pointsMall)
        ]
        let lead = (dayIndex % banners.count + banners.count) % banners.count

        return LifePageData(
            city: city,
            searchPlaceholders: ["生活缴费", "手机充值", "小豆乐园", "城市专区"],
            banners: Array(banners[lead...] + banners[..<lead]),
            gridPages: [
                [
                    LifeGridItem(title: "生活缴费", imageName: "abc_life_menu_payment", systemIcon: "drop.fill", tintColor: .abankPrimary, featureID: .lifePayment),
                    LifeGridItem(title: "手机充值", imageName: "abc_life_menu_mobile", systemIcon: "iphone", tintColor: .abankOrange, featureID: .mobileRecharge),
                    LifeGridItem(title: "政务民生", imageName: "abc_life_menu_government", systemIcon: "person.fill", tintColor: .abankTeal, featureID: .government),
                    LifeGridItem(title: "社保医保", imageName: "abc_life_menu_social", systemIcon: "person.text.rectangle", tintColor: .abankPrimary, featureID: .socialInsurance),
                    LifeGridItem(title: "小豆乐园", imageName: "abc_life_menu_beans", systemIcon: "leaf.fill", tintColor: .abankSuccess, featureID: .beans),
                    LifeGridItem(title: "校园", imageName: "abc_life_menu_campus", systemIcon: "graduationcap.fill", tintColor: .abankPrimary, featureID: .campus),
                    LifeGridItem(title: "食堂", imageName: "abc_life_menu_cafeteria", systemIcon: "fork.knife", tintColor: .abankOrange, featureID: .cafeteria),
                    LifeGridItem(title: "党费", imageName: "abc_life_menu_party", systemIcon: "flag.fill", tintColor: .abankHighlight, featureID: .partyFee),
                    LifeGridItem(title: "车主服务", imageName: "abc_life_menu_car", systemIcon: "car.fill", tintColor: .abankTeal, featureID: .carService),
                    LifeGridItem(title: "农银商城", imageName: "abc_life_menu_market", systemIcon: "storefront.fill", tintColor: .abankPrimary, featureID: .abcMall)
                ],
                [
                    LifeGridItem(title: "优惠卡券", imageName: "life_shortcut_ticket", systemIcon: "ticket", tintColor: .abankMintInk, route: .coupons),
                    LifeGridItem(title: "积分商城", imageName: "abc_life_menu_points", systemIcon: "gift", tintColor: .abankMintInk, featureID: .pointsMall),
                    LifeGridItem(title: "电影演出", imageName: "life_shortcut_film", systemIcon: "film", tintColor: .abankMintInk, featureID: .movies),
                    LifeGridItem(title: "酒店旅行", imageName: "life_shortcut_travel", systemIcon: "suitcase.rolling", tintColor: .abankMintInk, featureID: .hotelTravel),
                    LifeGridItem(title: "城市专区", imageName: "abc_home_city", systemIcon: "building.2", tintColor: .abankMintInk, route: .cityPicker),
                    LifeGridItem(title: "快递寄件", imageName: "life_shortcut_parcel", systemIcon: "shippingbox", tintColor: .abankMintInk, featureID: .express),
                    LifeGridItem(title: "医疗挂号", imageName: "abc_life_menu_hospital", systemIcon: "cross.case", tintColor: .abankMintInk, featureID: .hospital),
                    LifeGridItem(title: "公积金", imageName: "abc_life_menu_provident", systemIcon: "building.columns", tintColor: .abankMintInk, featureID: .providentFund),
                    LifeGridItem(title: "交通出行", imageName: "abc_life_menu_transport", systemIcon: "bus", tintColor: .abankMintInk, featureID: .transport),
                    LifeGridItem(title: "全部", imageName: "abc_life_menu_all", systemIcon: "ellipsis.circle", tintColor: .abankTextSecondary)
                ]
            ],
            colorfulFeatured: LifeActivityCard(title: "小豆乐园", subtitle: checkIn, backgroundColor: peach, artworkName: "life_illustration_calendar"),
            colorfulSides: [
                LifeActivityCard(title: "城市精选", subtitle: "当前城市 · \(city)", backgroundColor: green, artworkName: "life_illustration_city"),
                LifeActivityCard(title: "卡券福利", subtitle: coupons, backgroundColor: amber, artworkName: "life_illustration_ticket")
            ],
            promoBanner: LifeActivityCard(title: "生活权益", subtitle: "可用积分 \(points) · 可用卡券 \(couponCount)张",
                                         backgroundColor: lilac, artworkName: "life_illustration_gift"),
            feedItems: [
                LifeFeedItem(title: "\(month)生活账单", subtitle: "查看水电燃气缴费", imageBackground: blue,
                             imageAspectRatio: 0.94, artworkName: "life_illustration_payment", route: .lifePayment),
                LifeFeedItem(title: "卡券福利", subtitle: coupons, imageBackground: peach,
                             imageAspectRatio: 0.60, artworkName: "life_illustration_ticket", route: .coupons),
                LifeFeedItem(title: "城市生活", subtitle: "\(city) · 查看服务城市", imageBackground: green,
                             imageAspectRatio: 0.88, artworkName: "life_illustration_city", route: .cityPicker),
                LifeFeedItem(title: "生活贴士", subtitle: tip, imageBackground: amber,
                             imageAspectRatio: 0.85, artworkName: "life_illustration_leaf"),
                LifeFeedItem(title: "积分好礼", subtitle: "可用积分 \(points)", imageBackground: lilac,
                             imageAspectRatio: 0.90, artworkName: "life_illustration_gift", route: .pointsMall),
                LifeFeedItem(title: "每日签到", subtitle: checkIn, imageBackground: peach,
                             imageAspectRatio: 0.82, artworkName: "life_illustration_calendar", route: .beans)
            ]
        )
    }

    // MARK: - 我的

    func getMinePageData() -> MinePageData {
        MinePageData(
            profile: MineProfileInfo(
                displayName: "*继宏",
                lastLoginDevice: "当前设备 " + UIDevice.current.model,
                lastLoginTime: CustomerSessionStore.shared.lastLogin.isEmpty ? "欢迎回来" : CustomerSessionStore.shared.lastLogin,
                vipLevel: BenefitsStore.shared.level.title,
                benefitsTitle: "权益中心"
            ),
            assetStats: MineAssetStats.make(benefits: .shared, accountCount: FinanceLedgerStore.shared.load().accounts.count + FinanceLedgerStore.shared.load().creditCards.count),
            assetLiability: FinanceLedgerStore.shared.mineAssetLiability(),
            monthlyFlow: FinanceLedgerStore.shared.mineMonthlyFlow(),
            branch: mineBranchInfo(),
            securityItems: [
                MineGridItem(title: "登录设置", imageName: "abc_mine_security_login", systemIcon: "door.left.hand.open", featureID: .loginSettings),
                MineGridItem(title: "转账设置", imageName: "abc_mine_security_transfer", systemIcon: "shield.lefthalf.filled", featureID: .transferLimits),
                MineGridItem(title: "支付设置", imageName: "abc_mine_security_payment", systemIcon: "lock.shield", featureID: .paymentSettings),
                MineGridItem(title: "登录设备", imageName: "abc_mine_security_devices", systemIcon: "iphone", featureID: .loginDevices)
            ],
            customerManager: MineCustomerManager(
                name: "*凡柳",
                role: "客户经理",
                branch: "西安兴庆路支行营业室"
            )
        )
    }

    // MARK: - 资产负债

    func getAssetLiabilityPageData() -> AssetLiabilityPageData {
        FinanceLedgerStore.shared.assetLiabilityPageData()
    }

    // MARK: - 我的账户

    func getMyAccountPageData() -> MyAccountPageData {
        MyAccountPageData(
            debitCards: FinanceLedgerStore.shared.load().accounts.map(\.debitCard),
            creditAdImageName: "abc_account_credit_banner",
            creditAdTitle: "神骏贺岁 福运相随"
        )
    }

    func getDebitCardDetailPageData(
        card: MyAccountDebitCard? = nil
    ) -> DebitCardDetailPageData {
        let source = card ?? getMyAccountPageData().debitCards.first ?? MyAccountDebitCard(accountClass: "—", maskedNumber: "—", fullNumber: "—", availableBalance: 0, actions: [])
        let account = FinanceLedgerStore.shared.account(id: source.accountId)
        return DebitCardDetailPageData(
            accountClass: source.accountClass,
            maskedNumber: source.maskedNumber,
            fullNumber: source.fullNumber,
            infoItems: [
                .init(title: "注册渠道", value: source.accountId.hasPrefix("electronic_") ? "手机银行" : (source.accountId == FinanceLedgerRecord.defaultAccountId ? "网点注册" : "—")),
                .init(title: "开户网点", value: account?.openingBranch ?? "—"),
                .init(title: "卡状态", value: account?.isReportedLost == true ? "已挂失" : "正常户"),
                .init(title: "账户状态", value: "正常户"),
                .init(title: "默认账户", value: source.accountId == FinanceLedgerRecord.defaultAccountId ? "是" : "否")
            ],
            actions: [account?.isReportedLost == true ? "解除挂失" : "挂失", "账户别名", "交易权限", "更多"],
            currencyTitle: (account?.currency ?? "人民币") + "活期",
            availableBalance: source.availableBalance,
            accountBalance: source.availableBalance,
            cashRemittanceMark: "本币",
            interestRateText: "0.05000%",
            openDateText: account?.openedOn?.replacingOccurrences(of: "-", with: "/") ?? (source.accountId == FinanceLedgerRecord.defaultAccountId ? "2017/08/09" : "—")
        )
    }

    // MARK: - 账户信息（其他模块复用）

    struct AccountInfo {
        let cardNumber: String
        let balance: Double
        let accountName: String
    }

    func getAccountInfo() -> AccountInfo {
        let account = FinanceLedgerStore.shared.account(id: FinanceLedgerRecord.defaultAccountId)
        return AccountInfo(
            cardNumber: account?.fullCardNumber ?? "—",
            balance: account?.balance ?? 0,
            accountName: CustomerInfoStore.shared.load().name
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

    // MARK: - 转账

    func getTransferPageData() -> TransferPageData {
        TransferPageData(
            noticeText: "安全小贴士：杜绝一切非法金融活动",
            primaryActions: [
                TransferPrimaryAction(title: "账号转账", systemIcon: "creditcard.fill", badge: nil, imageName: "abc_transfer_primary_account"),
                TransferPrimaryAction(title: "手机号转账", systemIcon: "iphone", badge: "免卡号", imageName: "abc_transfer_primary_phone")
            ],
            secondaryActions: [
                TransferSecondaryAction(title: "转账记录", systemIcon: "doc.text", imageName: "abc_transfer_record"),
                TransferSecondaryAction(title: "转账设置", systemIcon: "gearshape", imageName: "abc_transfer_settings")
            ],
            functionItems: [
                TransferFunctionItem(title: "信用卡还款", systemIcon: "creditcard", imageName: "abc_transfer_repay", featureID: .creditCardRepay),
                TransferFunctionItem(title: "预约转账", systemIcon: "clock", imageName: "abc_transfer_schedule", featureID: .scheduledTransfer),
                TransferFunctionItem(title: "向多人转账", systemIcon: "person.3", imageName: "abc_transfer_multiple", featureID: .multiTransfer),
                TransferFunctionItem(title: "他行卡转入", systemIcon: "arrow.uturn.left", imageName: "abc_transfer_other_bank", featureID: .otherBankIn),
                TransferFunctionItem(title: "跨境服务", systemIcon: "airplane", imageName: "abc_transfer_crossborder", featureID: .crossBorder),
                TransferFunctionItem(title: "公益捐款", systemIcon: "heart", imageName: "abc_transfer_donation", featureID: .donation),
                TransferFunctionItem(title: "手机号收款", systemIcon: "iphone.gen1", imageName: "abc_transfer_mobile_collection", featureID: .mobileCollection),
                TransferFunctionItem(title: "转账撤销", systemIcon: "arrow.uturn.backward", imageName: "abc_transfer_cancel", featureID: .transferCancel)
            ],
            recentPartners: [
                TransferPartner(
                    id: "p1",
                    name: "韩继宏",
                    avatarSystemIcon: "person.crop.circle.fill",
                    avatarTintHex: "4A90D9",
                    accounts: [
                        TransferAccount(
                            id: "a1",
                            bankName: "中国农业银行",
                            maskedNumber: "6230****8472",
                            bankColorHex: "009882",
                            bankSymbol: "农",
                            imageName: "abc_account_bank_logo"
                        ),
                        TransferAccount(
                            id: "a2",
                            bankName: "中国工商银行",
                            maskedNumber: "6222****9517",
                            bankColorHex: "C8102E",
                            bankSymbol: "工"
                        )
                    ],
                    lastTransferDate: nil,
                    isExpanded: false,
                    avatarImageName: "abc_transfer_partner_avatar"
                ),
                TransferPartner(
                    id: "p2",
                    name: "欧梦瑶",
                    avatarSystemIcon: nil,
                    avatarTintHex: nil,
                    accounts: [
                        TransferAccount(
                            id: "a3",
                            bankName: "中国建设银行",
                            maskedNumber: "6217****0593",
                            bankColorHex: "003B8E",
                            bankSymbol: "建",
                            imageName: "abc_transfer_bank_ccb_wordmark"
                        )
                    ],
                    lastTransferDate: "08-10",
                    isExpanded: false
                ),
                TransferPartner(
                    id: "p3",
                    name: "俞增林",
                    avatarSystemIcon: nil,
                    avatarTintHex: nil,
                    accounts: [
                        TransferAccount(
                            id: "a4",
                            bankName: "中国建设银行",
                            maskedNumber: "6227****1081",
                            bankColorHex: "003B8E",
                            bankSymbol: "建",
                            imageName: "abc_transfer_bank_ccb_wordmark"
                        )
                    ],
                    lastTransferDate: "2022-06-22",
                    isExpanded: false
                )
            ]
        )
    }
}
