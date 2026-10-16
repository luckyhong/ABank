# 农行安装包功能线索与 ABank 补齐建议

分析日期：2026-10-16。对照 ABank 提交 `1d52c4e`。本轮只做静态逆向和源码对照，没有修改业务代码。

## 结论

目前最影响真实感的是入口缺少后续页面和数据联动。优先完成 **转账模拟闭环 → 收支分析/月度账单/电子回单 → 全部功能目录与搜索**，再补安全中心、网点服务、权益订单、财富与生活子页。

已有资产负债、账户明细、收支编辑和贷款详情链路，可以复用。原包资源已批量导入工程，本次又核验了 30 个候选资源的原文件哈希及已有 imageset 位置，无需再次导入整包。

## 证据范围与限制

| 编号 | 本次证据 | 能够证明的内容 |
| --- | --- | --- |
| E1 | REA `inspect_artifact`：`ev_ec71e1343a0d919376eee0f2af3ba2e9870af6534fb4d9d8e828487e7903275f` | IPA 内容图谱、成员路径和内容身份；Manifest `agm_f7c02da485d3a1462aaf29706c826108954eabbc10d183b15dd8264186e85af7` |
| E2 | REA `extract_artifact`：`ev_480265f21901ad15f7d99a907592d6ac979a75b43cc4b4bbac006f44745c1cee` | 普通文件提取及路径包含关系验证 |
| E3 | REA `inspect_plist` 主应用：`ev_f37140a57bb8a1bff8fe7a0d3716374d9da11e9800d69039391a7f1e3d69c566` | 版本、权限用途声明、桌面快捷操作声明 |
| E4 | REA `inspect_plist` MobileRuntime：`ev_92bbd73fd54de2f4044ff943bf081057cd28b35cbfb57b3da437426ba9c75386` | 原生模块和服务注册声明，包括全部菜单、二维码、客户管理、IM、语音、乘车码 |
| E5 | REA `inspect_macho`：`ev_b538b6d4da641e03d8b5bc5c8d06ecd33d226d49e11805d0e7ebab4e9ba2128f` | arm64 主程序、`LC_ENCRYPTION_INFO_64.cryptid = 1`，加密范围覆盖主程序 `__TEXT` 的绝大部分 |
| E6 | REA Widget 扩展 plist：`ev_bef898457881b965f18a17fd692918ca33d9a02e65177d1a83485dc5650860f2` | 确有 `com.apple.widgetkit-extension` 声明；不证明各组件的实际运行状态 |
| E7 | REA TitleList：`ev_f292d58f50338f4a2e2229b4bb0b871d761dee7e3beb87e5251d6165f8a9fea2` | 文件包含余额宝、蚂蚁花呗等通用条目，因此不把该列表用作农行业务功能清单 |

目标：`com.bankabc.iphonerelease`，版本 `11.3.0`，构建 `11.3.1`。IPA SHA-256：`913457167f6e52daed0004cc3022bf936aa4cc169c4cadb8a01b7031b6fc6e9b`。

机器可读摘要见 [abc-feature-gap-evidence.json](abc-feature-gap-evidence.json)。完整本地 REA 记录保存在 `artifacts/abc-resources/analysis/feature-gap-rea-evidence.json`，约 10 MB，不进入版本库。

**已观察**：包内文件、图标、声明和 ABank 当前源码。**推断**：这些线索支持哪些功能方向。**实现建议**：下文提出的页面顺序和本地数据规则，是 ABank 的设计建议。

没有启动或操作原版农行，没有请求银行服务，没有恢复原始源码或验证线上流程。`home.lua`、`mode_home.lua`、`barcodenew.lua`、`map_native.xml`、`mpaas_menu_native.xml` 不是可直接读取的 UTF-8 内容，本轮未解码。主程序深度反编译没有进行；Objective-C 元数据工具还因主程序约 128 MB 超过其 64 MiB 输入预算而拒绝分析。当前 REA 会话未配置可用的深度反编译引擎。

图标名称不能证明当前版本正在使用该图标，也不能证明功能已对所有用户开放。SDK 文件、地区专属业务和历史资源需要进一步筛选；具体页面排版、字段、文案和状态应继续以用户提供的真实截图或实机观察为准。

## 按优先级补齐的功能

| 优先级 | 功能 | 原包依据及确定性 | ABank 当前缺口 | 建议完成范围 |
| --- | --- | --- | --- | --- |
| P0 | 转账完整模拟流程 | E1/E2：`transfer_new_native500.png`、`transfer_detail_qry_native500.png`；结合用户已提供的转账首页截图可确认入口，后续表单未验证 | [TransferViewController.swift](../ABank/Features/Transfer/TransferViewController.swift#L153) 的主入口、记录和设置只 toast；伙伴选择最终也只 toast（202、211 行） | 账号/手机号转账、伙伴选择、金额与附言、确认、模拟处理状态、成功/失败、转账记录及回单入口 |
| P0 | 月度账单、收支分析与搜索 | E1/E2：`month_bills_native500.png`、`bank_statement_qry_native500.png`；用户真实收支截图含“分析”和搜索入口，分析内容未验证 | [IncomeExpenseViewController.swift](../ABank/Features/Mine/IncomeExpense/IncomeExpenseViewController.swift#L108) 的分析、214 行搜索，以及 [MineViewController.swift](../ABank/Features/Mine/MineViewController.swift#L167) 的月账单入口占位 | 月份切换、收入/支出分类、趋势、主要收支、交易搜索；全部从同一本地账本派生 |
| P0 | 电子回单 | E1/E2：`receiptinitact_webview_native500.png`；现有导出库还有“电子回单”图像，实际回单样式待核对 | [AccountDetailQueryViewController.swift](../ABank/Features/MyAccount/AccountDetailQuery/AccountDetailQueryViewController.swift#L205) 回单查询只 toast | 已完成模拟转账的回单列表、详情、保存/分享；导出的学习回单清楚标注“模拟交易”，不用真实银行印章 |
| P1 | 全部功能目录、统一功能搜索、常用编辑 | E4 明确注册 `HomePageAllMenusAppDelegate`；E1/E2 有 `hp_allmenus_icon_add/delete.png`。支持存在菜单及编辑资源，具体编辑规则未验证 | [HomeViewController.swift](../ABank/Features/Home/HomeViewController.swift#L230) 搜索占位，263 行全部入口占位；仅三个快捷入口真正跳转 | 分类目录、文字搜索、常用添加/移除和排序、最近使用；首页/我的/财富共享同一路由。最近使用与排序为实现建议 |
| P1 | 安全中心、设备与转账设置 | E1/E2：`safecenter_login_setting_700`、`trans_setting_700`、`pay_setting_700`、`trusted_device_1100`、`account_lock` 资源 | [MineViewController.swift](../ABank/Features/Mine/MineViewController.swift#L190) 安全中心及四个入口只 toast | 模拟登录状态、设备详情/移除、转账限额、金额隐私和演示设置；具体设置项需截图核对，不移植真实安全协议 |
| P1 | 网点列表、详情、预约和排队记录 | E1/E2：`branch_query_mini`、`branch_appoint`、`online_fetch_number`、`my_appointment_numbers/records`；还有排队中/结束等状态资源 | [MineViewController.swift](../ABank/Features/Mine/MineViewController.swift#L179) 网点入口占位；[HomeViewController.swift](../ABank/Features/Home/HomeViewController.swift#L273) 提示“已取号”却不创建记录 | 城市选择、附近网点、营业时间、预约日期/时段、模拟取号、排队详情、取消和历史记录；地图可先本地列表/示意图 |
| P1 | 权益、积分小豆、卡券与订单 | E1/E2：`enjoy_interests_def`、`credit_only_point_qry`、`hp_mine_order_*`；用户截图确认权益和统计入口 | [MineViewController.swift](../ABank/Features/Mine/MineViewController.swift#L156) 权益/等级占位；198 行订单占位；[MineAssetStatsCardView.swift](../ABank/Features/Mine/Views/MineAssetStatsCardView.swift#L88) 统计项未绑定点击 | 权益页、积分/小豆明细、卡券可用/已用/过期、兑换、订单状态与详情；积分与小豆分账，领取/兑换后联动 |
| P2 | 财富产品列表、详情、风险测评、持仓 | E1/E2：`wealth_test`、`comm_risk_checked/unchecked`、`financing_pro_my` 及基金/存款/理财资源。功能方向可推断，题目和交易流程未知 | [FinanceViewController.swift](../ABank/Features/Finance/FinanceViewController.swift#L195) 至 251 行几乎所有业务点击只 toast | 先实现一种产品的列表/筛选/详情与模拟持仓，再扩分类；风险题目自行构造并标注练习，不冒充原版评测 |
| P2 | 生活缴费、手机充值、订单与卡券 | E1/E2：`calls_payment_webview`、`epayment_pay`、`home_life_menu_phoneRecharge` 资源。地区业务不应直接按文件名映射到当前城市 | [LifeViewController.swift](../ABank/Features/Life/LifeViewController.swift#L157) 至 183 行城市、服务、活动、订单和卡券全部占位 | 城市/缴费项目、模拟户号、待缴金额、确认和缴费结果、记录；充值面额选择及订单联动 |
| P2 | 账户管理与贷款剩余动作 | 原包资源有 `card_manage`、`paymng_account_manage`、`my_loan_contract_qry` 等；用户截图确认账户别名及贷款功能入口 | [MyAccountViewController.swift](../ABank/Features/MyAccount/MyAccountViewController.swift#L133) 别名等只 toast；[MyLoanViewController.swift](../ABank/Features/Mine/MyLoan/MyLoanViewController.swift#L103) 待办/进度/结清证明等占位；[LoanPrepaymentViewController.swift](../ABank/Features/Mine/MyLoan/LoanPrepaymentViewController.swift#L123) 最终提交占位 | 别名保存回填、模拟交易权限、卡号展示分享；贷款待办/进度/证明及提前还款确认结果，保留已存在的详情链路 |
| P3 | 桌面快捷操作、Widget、扫码及本地助手 | E3 明确声明医保服务/账户查询/收付款/扫一扫四个快捷操作；E6 确认 Widget 扩展。E4 注册语音/二维码服务，只证明注册 | 目前以 App 内页面为主；首页扫一扫仍 toast | 先用 UIApplicationShortcutItem 打开已完成页面；其后做模拟余额 Widget、演示二维码或本地关键词助手。真实摄像头/语音不是首阶段依赖 |

P0/P1/P2 是针对这个学习项目的实施优先级，不是原版 App 的功能等级。

## 已经实现的基础，应继续复用

- 账户首页 → 明细查询 / 借记卡详情 / 转账首页已有跳转：[MyAccountViewController.swift:115](../ABank/Features/MyAccount/MyAccountViewController.swift#L115)。缺的是转账首页后续及部分管理动作。
- 明细查询已有日期范围、币种和高级筛选：[AccountDetailQueryViewController.swift:124](../ABank/Features/MyAccount/AccountDetailQuery/AccountDetailQueryViewController.swift#L124)。收支已有月份、账户筛选与详情编辑，详情可更新计入收支、分类、账本、备注。
- 资产负债已有账户/贷款入口，贷款已有应还、合同详情、提前还款页面和使用记录。新增功能不应另建一套互不一致的账户、贷款余额。
- 客户资料、修改手机号和税收身份已有本地表单与保存。资讯已完成公开 RSS、缓存、搜索、关注和原文入口。
- [FinanceLedgerStore.swift:39](../ABank/Features/Mine/FinanceLedger/FinanceLedgerStore.swift#L39) 的 `update` 会重算余额并保存，保存会发变更通知；可作为跨页面一致性的基础。该 Store 还没有完整的转账业务 API，需要增加一次性提交和重复提交保护。

## 真实感的共同问题

1. **统一日期。** [FinanceLedgerStore.swift:97](../ABank/Features/Mine/FinanceLedger/FinanceLedgerStore.swift#L97) 的默认月份仍为 `2026-08`，账单文案固定 7 月。先定义统一演示日期/月份策略，空月展示真实空态；若要每日生成模拟流水，需稳定 ID、按日生成一次、允许重置，不能只改日期标签。
2. **让变化有来源。** 一笔模拟转账只写一次交易和转账记录，然后派生账户余额、明细、收支和首页资产；确认页的余额不足、超限、取消不能生成成功记录。金额计算建议使用 Decimal 或整数分，避免新增 Double 运算累计误差。
3. **用记录支持结果。** 取号、兑换、缴费不能仅弹成功提示。应该可查看、取消或查历史，并有取消/过期/失败/空态。
4. **统一入口行为。** 同一功能从首页、全部、我的进入应抵达同一控制器并携带账户/月份等上下文；页面暂未完成时不要提示已经完成某项业务。
5. **逐页核对视觉。** 原资源仅作为候选。先用真实截图确认图形、颜色、尺寸、文字和状态，再赋语义名称并接入；尤其订单图标不能仅由 deliver/receive 文件名决定含义。

## 素材复用与命名

[abc-feature-gap-assets.json](abc-feature-gap-assets.json) 记录 30 个候选的源名称、SHA-256、尺寸、现有 imageset 和建议语义名。本轮逐一比对了 IPA 普通成员的哈希，并核对 imageset 目录存在；缩略图已人工查看。这不是运行时资源引用证明，也没有将建议名称实际导入工程。

建议新增页面沿用 `ABCImported/<模块>/` 分组，例如 `abc_security_login`、`abc_branch_appointment`、`abc_statement_monthly_entry`。已有合适语义名优先复用；确需新语义映射时更新对应导入脚本及来源清单，保留尺度、original/template 选择和来源信息。不要为 1x 原图虚构 2x/3x，也不靠重复导入全素材解决引用问题。

本地联系表：`artifacts/abc-resources/verification/feature-gap-assets.jpg`。它是供选材核对的排版，不是农行原页面。

## 建议的首轮可验收成果

**第一轮：账号转账闭环。** 从已有伙伴进入 → 选择模拟付款账户 → 输入金额/附言 → 确认 → 明确模拟结果 → 转账记录/详情。返回后账户余额、账户明细、收支和首页资产一致。验证余额不足、金额格式、重复点击、取消、失败重试、返回再进入及不同入口跳转。

**第二轮：账单和回单。** 账本数据驱动月份/分类统计、交易搜索，已完成转账可查看和分享带模拟标记的回单；验证跨月、空月、隐藏金额、筛选、退款/不计入收支规则。

**第三轮：全部功能与统一路由。** 搜索可找到已实现功能、编辑常用入口；把首页、财富、我的里指向已有页面的入口接通。尚未完成的功能明确为待体验状态，不制造已执行业务的提示。

## 本轮验证记录

- REA 身份、清单、提取、plist、Mach-O 和 Apple 图谱检查；分析结束已关闭原生会话。
- 30 个候选独立资源的原包哈希与已有清单一致，imageset 目录存在；查看了选材联系表。
- 源码只读核对路由、占位动作及账本联动。完整覆盖线上业务、深度反编译和运行时调用均未完成。
- 本轮未改 Swift、资源或构建配置，不运行无关构建；新增的分析文档和候选清单未提交。
