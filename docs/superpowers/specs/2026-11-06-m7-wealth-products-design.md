# M7 财富产品（理财）设计

日期：2026-11-06。基线：`main@f5d0ce9`（M6 已合并），分支 `feat/m7-wealth-products`。对应 [开发计划](../../development-plan.md) 阶段 M7。

## 1. 目标与已确认决策

**目标**：把“理财产品”从“即将上线”占位变成可演示的本地模块：产品列表/筛选/详情、风险测评、购买、持仓与收益、赎回，并让现金与持仓的转换与资产汇总保持一致。全部为本地模拟数据，不发网络请求，不涉及真实资金。

用户已确认：

| 议题 | 决策 |
|---|---|
| 范围 | 本阶段只做理财产品；存款、基金仍为“即将上线”，目录阶段标签改为后续阶段，之后单独扩展并复用持仓/订单模型 |
| 收益模型 | 年化收益按日累计：持仓价值 = 本金 + 累计收益，读取时按上海自然日计算、不落库；最低持有天数内不可赎回，赎回后本息立即回到付款账户 |
| 风险测评 | 必须先测评，且测评等级不低于产品风险等级才能购买（硬拦截）；5 题问卷 → C1–C5，有效期 365 天，可重测，重测不影响已有持仓 |
| 存储方案 | 理财订单放入账本根快照（`FinanceLedgerRecord.wealthOrders`，解码缺省为空），购买/赎回与账户流水一次原子写入；风险测评无资金，单独 `RiskAssessmentStore` |
| 月度收支 | 理财买入/赎回流水不计入“本月收支”（`includeInFlow = false`） |
| 赎回 | 仅整笔赎回，不做部分赎回 |

**验收标准**

1. 功能目录“理财产品”改为已完成并接入路由；理财 Tab 的“理财产品”宫格、精选产品页签与“立即购买”、稳健增长产品、“请登录查看持仓”卡进入对应新页面，其余卡片保持提示；存款/基金仍为即将上线。
2. 产品列表显示约 8 款产品，可按分类（全部/日日悦享/低波稳健/业绩优选）、风险等级与持有期限筛选；详情显示年化、风险等级、最低持有期、起购额与风险提示。
3. 风险测评：5 题全部作答才可提交；得到 C1–C5；结果保存、365 天后过期；产品风险等级高于测评等级、未测评或已过期时不能购买并说明原因，可去测评/重测后返回。
4. 购买：金额不得低于起购额、不得超过账户可用余额、单笔不超过 100 万元；提交时重新校验余额、测评与产品；同一请求重复提交只产生一笔订单；成功后账户扣款、生成“理财购买”流水（不计入本月收支）与持仓订单并进入订单详情（带成功横幅）。
5. 收益与持仓：累计收益 = 本金 × 年化 × 持有天数 / 365（整数分，向下取整，购买当日为 0 天）；持仓页显示总持仓价值、累计收益与各笔明细；订单详情显示本金、收益、当前价值、持有天数与可赎回日期。
6. 赎回：持有天数达到最低持有期才可赎回；赎回需确认，成功后本息回到账户、生成“理财赎回”流水，订单变为已赎回并保留；重复赎回被拒。
7. 资产一致：总资产 = 账户余额 + 持仓价值；购买前后总资产不变，赎回后总资产 = 现金。资产负债页新增“理财”资产类别，“我的”资产负债卡同步。
8. 检查脚本（新增理财检查）、正常构建、模拟器验收全部通过；账本存储键仍为 `abank.financeLedger.record.v8`，旧数据解码为空订单列表；不新增网络请求。

**不在本阶段范围**：存款、基金、净值型产品与亏损、部分赎回、手续费/税、定投、风险测评之外的适当性文书、原版截图校准。

## 2. 方案选择

采用 **理财订单并入账本根快照**。购买/赎回在 `FinanceLedgerStore` 内同一次 `persist` 写入订单与流水，沿用 `submitTransfer` 的“读最新 → 校验 → 构造一个根快照 → 写一次”模式；持仓即“未赎回的订单”，不另建持仓表。

备选：B 独立 `WealthStore` + 账本调用，需补偿且两个 key 无法原子写入；C 通用跨 Store 事务层，超出本阶段需要。均不采用。

## 3. 数据模型

新目录 `ABank/Features/WealthProduct/`（模型 Foundation-only、`nonisolated`）：

```
WealthProduct/
  Models/WealthProductModels.swift   // 风险等级、分类、产品、订单、错误
  Models/WealthProductCatalog.swift  // 静态产品目录
  Models/WealthRules.swift           // 收益、持有天数、可赎回、测评等级与有效期
  Models/RiskAssessmentModels.swift  // 问卷、选项、测评结果
  RiskAssessmentStore.swift
  页面控制器与 Views/
Mine/FinanceLedger/FinanceLedgerStore+Wealth.swift   // 购买/赎回/持仓读取（账本扩展）
```

### 3.1 产品与风险等级

- `ProductRiskLevel`：R1 低风险、R2 中低风险、R3 中风险。`RiskProfile`：C1 保守型 … C5 进取型；R_n 产品需测评等级 ≥ C_n（R1→C1，R2→C2，R3→C3）。
- `WealthProduct`：`id`、`name`、`category`（日日悦享/低波稳健/业绩优选）、`risk`、`rateBasisPoints`（年化，万分之一）、`minHoldDays`、`minPurchaseInCents`、`summary`。
- 8 款产品（名称取自理财 Tab 现有模拟数据，机构名虚构不变）：

| ID | 名称 | 分类 | 风险 | 年化 | 最低持有 | 起购 |
|---|---|---|---|---|---|---|
| `w.shishifu` | 农银时时付（现金管理类） | 日日悦享 | R1 | 0.90% | 1 天 | 1 元 |
| `w.tiantianli2` | 农银匠心·天天利理财产品2号 | 日日悦享 | R2 | 2.40% | 1 天 | 1 元 |
| `w.piaoxi` | 农银安心·天天利理财产品（票息优选） | 低波稳健 | R2 | 1.90% | 1 天 | 1 元 |
| `w.wenjian7` | 农银安心·7天持有稳健 | 低波稳健 | R1 | 1.70% | 7 天 | 100 元 |
| `w.wenjian30` | 农银安心·30天持有（纯债） | 低波稳健 | R2 | 2.20% | 30 天 | 100 元 |
| `w.lingdong90` | 农银匠心·灵动90天理财产品（固收增强） | 业绩优选 | R2 | 2.65% | 90 天 | 1,000 元 |
| `w.lingdong180` | 农银匠心·灵动180天理财产品（量化多元增强） | 业绩优选 | R2 | 2.96% | 180 天 | 1 元 |
| `w.chengzhang` | 农银匠心·成长优选180天（权益增强） | 业绩优选 | R3 | 3.60% | 180 天 | 1,000 元 |

筛选：分类 / 风险等级 / 持有期限（不限、≤7 天、≤30 天、>30 天）。

### 3.2 风险测评

5 题（投资经验、可承受最大亏损、计划投资期限、收入稳定性、投资目的），每题 4 个选项计 1–4 分，总分 5–20：5–8 → C1，9–11 → C2，12–14 → C3，15–17 → C4，18–20 → C5。`RiskAssessmentRecord`：`answers`（每题选项下标）、`level`、`assessedAt`；有效期 = 测评日（上海）0 点 + 365 天，`now ≥ 到期时刻` 即过期。`RiskAssessmentStore`（键 `abank.riskAssessment.v1`）：可注入 defaults/通知中心/日期/dataWriter，损坏数据视为未测评且不覆盖原字节，写入失败内存不变；变更发通知。

### 3.3 订单与收益

- `WealthOrder`（Codable）：`id`、`requestID`、`productID`、`productName`（快照）、`accountID`、`principalInCents: Int64`、`rateBasisPoints`（快照）、`minHoldDays`（快照）、`createdAt`（`yyyy-MM-dd HH:mm:ss`，上海）、`purchaseTransactionID`、`redeemedAt?`、`redeemedAmountInCents?`、`redeemTransactionID?`。
- 持有天数 = 购买日到今天的上海自然日差（购买当日为 0）。累计收益（分）= `principal × rateBasisPoints × days / (10_000 × 365)`，整数向下取整；天数封顶 3,650，单笔本金 ≤ 1 亿分，保证 `Int64` 不溢出。持仓价值 = 本金 + 累计收益。
- 可赎回：未赎回且 `days ≥ minHoldDays`；可赎回日 = 购买日 + `minHoldDays` 天。
- 状态（读取时）：持有中（含“可赎回/N 天后可赎回”）、已赎回。

### 3.4 账本变更

`FinanceLedgerRecord` 新增 `wealthOrders: [WealthOrder] = []`（`CodingKeys` 加入，`decodeIfPresent`）。`FinanceLedgerStore+Wealth.swift`：

- `submitWealthPurchase(productID:amountInCents:requestID:) throws -> WealthOrder`：校验顺序——请求 ID → 同请求已存在则直接返回 → 严格读取最新账本（损坏则报错、不重置）→ 产品存在 → 测评（未测评/过期/等级不足）→ 金额（≥ 起购、≤ 100 万元、≤ 付款账户余额）→ 构造订单与一条支出流水（`wealth_buy_<订单ID>`，标题“理财购买-产品名”，`categoryId: "wealth_purchase"`，`includeInFlow: false`，渠道“本机模拟”）→ 重算余额 → 一次 `persist`。
- `redeemWealthOrder(orderID:) throws`：订单存在、未赎回、`days ≥ minHoldDays` → 收入流水（`wealth_redeem_<订单ID>`，金额 = 本金 + 累计收益，`categoryId: "wealth_redeem"`，`includeInFlow: false`）→ 订单写入赎回信息 → 一次 `persist`。
- 读取：`wealthOrders()`、`wealthOrder(id:)`、`holdingValueInCents(of:)`、`accruedInterestInCents(of:)`、`totalHoldingValue()`。`totalAssets()` 改为账户余额 + 持仓价值；`assetLiabilityPageData()` 在“活期”后新增“理财”类别（每笔未赎回订单一项：标题产品名、金额当前价值、副标题“本金 x 元 · 收益 y 元”）。
- 测评由注入的 `riskProfileProvider: @MainActor () -> RiskAssessmentRecord?`（默认读 `RiskAssessmentStore.shared`）提供；账本内部把私有的严格读取与 `persist` 改为内部可见以便扩展文件使用。
- 错误 `WealthError`（中文文案）：`invalidRequest`、`productNotFound`、`assessmentRequired`、`assessmentExpired`、`riskLevelTooLow`、`invalidAmount`、`belowMinimum`、`aboveMaximum`、`insufficientBalance`、`orderNotFound`、`notRedeemable`、`alreadyRedeemed`、`corruptLedger`、`persistence`。

## 4. 页面与路由

`AppRoute` 新增：`wealthProducts`、`wealthProductDetail(productID:)`、`riskAssessment`、`wealthPurchase(productID:)`、`wealthOrderDetail(orderID:justPurchased:)`、`wealthHoldings`；`AppRouter` 穷举 switch 补全，新页面实现 `RouteHosting`，页面继承 `BankingDataViewController` 系基类（账本变更、回前台、跨日刷新）。

- **产品列表**：分类页签 + 风险/期限筛选条；行显示名称、年化、风险、最低持有、起购；右上“我的持仓”。
- **产品详情**：年化、风险等级、最低持有期、起购额、可赎回规则、风险提示；“立即购买”：未测评/过期/等级不足时进入前先提示并引导测评。
- **风险测评**：5 题单选，全部作答后提交，结果页显示等级与有效期，可重测；从购买流程进入时完成后返回。
- **购买页**：付款账户与可用余额、金额输入（起购额/余额提示）、预计可赎回日、风险揭示勾选；确认弹窗后提交，成功进入订单详情（成功横幅，标注“本机模拟”）。
- **我的持仓**：总持仓价值、累计收益；持有中/已赎回两段；行点进订单详情；空态引导去选产品。
- **订单详情**：产品、本金、累计收益、当前价值、持有天数、购买时间、可赎回日；“赎回”按钮（未满期禁用并说明；确认文案含预计到账金额）；已赎回显示赎回金额与时间。

## 5. 入口接线

- `FeatureCatalog`：`wealthProduct` 改 `.available(.wealthProducts)`；`deposit`、`fund` 保持计划中，阶段标签 `wealthStage` 改为“M7 后续（存款/基金）”；`check_feature_catalog.swift` 同步（可用数 29 → 30，`.mobileRecharge` 等“计划中”样例不变）。
- 理财 Tab：`WealthProductTab`/`WealthSteadyProduct` 增加可选 `productID`（日日悦享→`w.tiantianli2`，低波稳健→`w.piaoxi`，业绩优选→`w.lingdong180`；稳健增长两项→`w.piaoxi`、`w.lingdong180`），“立即购买”/行点击进详情；“请登录查看持仓”卡进入 `wealthHoldings`；其余提示保持不变。

## 6. 验证

- `scripts/check_wealth.swift`（接入 `check_banking_data.sh`）：目录与风险映射、测评计分与等级边界、有效期边界、收益整数分与日界/月界、持有天数与可赎回日、购买校验（未测评/过期/等级不足/起购/余额恰好/超额/超上限）、同请求幂等、购买后余额与流水与总资产不变、赎回边界（`days == minHoldDays`）与重复赎回、赎回后总资产 = 现金、`includeInFlow` 不影响本月收支、写入失败与损坏数据原子性、旧账本解码缺省订单、资产负债页“理财”类别。
- 既有账本/转账检查保持通过；正常构建；`git diff --check`。
- 模拟器：入口、未测评被拦截、测评、购买、持仓/收益展示、赎回受限与赎回成功、资产负债页与“我的”资产同步、重启保持；截图 `artifacts/abc-resources/verification/m7-*.png`；验收后清理账本与测评数据。
- 全分支审查后更新开发计划、任务记录与 CURRENT 索引。

## 7. 风险与边界

- 无原版截图，布局按现有设计系统，交接标注“待截图校准”。
- 收益靠时钟推算：页面可见时跨日依赖回前台/午夜刷新；模拟器时钟与真实日期可能不一致，种子日期无关逻辑。
- 付款账户当前只有一张借记卡且余额较小（约 1,499.66 元），演示购买额度受其限制。
