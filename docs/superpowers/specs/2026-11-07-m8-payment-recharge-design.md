# M8 充值缴费（手机充值 + 生活缴费）设计

日期：2026-11-07。基线：`main@b310db9`（M7 已合并），分支 `feat/m8-payment-recharge`。对应 [开发计划](../../development-plan.md) 阶段 M8。

## 1. 目标与已确认决策

**目标**：把“手机充值”和“生活缴费（水/电/燃气）”从“即将上线”占位变成可演示的本地模块：输入、确认、结果、记录与订单，付款账户、流水、话费券与订单保持一致。全部为本地模拟数据，不发网络请求，不涉及真实资金。

用户已确认：

| 议题 | 决策 |
|---|---|
| 范围 | 手机充值与水/电/燃气缴费本阶段都做，复用同一套付款、流水和订单模型；两个目录入口都改为可用 |
| 话费券 | 手机充值可选一张 M6 的话费券抵扣（话费5元/10元充值券），券状态联动为已使用，订单记录抵扣额 |
| 记录与订单 | 缴费订单并入账本根快照（`FinanceLedgerRecord.paymentOrders`，解码缺省为空，存储键仍为 `abank.financeLedger.record.v8`），与账户流水一次原子写入；“我的订单”统一展示兑换订单与充值缴费订单 |

**验收标准**

1. 功能目录“手机充值”“生活缴费”改为已完成并接入路由；生活 Tab 宫格、生活缴费横幅、首页“生活缴费”入口进入对应新页面。
2. 手机充值：输入 11 位手机号（预填本机模拟号，可改）并校验，选择面额（10/20/30/50/100/200 元），确认页显示号码、运营商（按号段，仅展示）、面额、付款账户与余额、可选话费券与实付金额；提交成功进入订单详情（成功横幅，标注“本机模拟”）。
3. 话费券：仅列出“待使用”且面值小于所选面额的话费券；选中后实付 = 面额 − 券面值；提交成功后券变为“已使用”，M6 兑换订单状态随之变“已使用”；提交失败不消耗券。
4. 生活缴费：水费/电费/燃气费三类，每类预置模拟户号；查询当月账单（账单金额由“户号 + 账期”稳定哈希生成，同一账期同一户号金额固定），整笔缴清；同户号同账期缴清后显示“本期已缴清”，不能重复缴费；跨月后出现新账期账单。
5. 校验与幂等：提交时重新校验手机号/面额/账单/余额/话费券；同一请求重复提交只产生一笔订单且不重复扣款、不重复消耗券；余额不足明确提示。
6. 一致性：成功后账户扣款（实付额）、生成一条支出流水（类别“手机充值”或“生活缴费”，计入本月收支）、生成订单；总资产随支出减少；“本月收支”“账户明细”“订单列表”一致。
7. “我的订单”新增“充值缴费”筛选，“全部”按时间混排；缴费订单详情显示金额、抵扣、实付、付款账户、流水号和“模拟交易”标注；充值缴费不可取消、无退款。
8. 检查脚本（新增缴费检查）、正常构建、模拟器验收全部通过；不新增网络请求；旧账本解码得到空缴费订单。

**不在本阶段范围**：流量/套餐、国际漫游、自动缴费与缴费提醒、账单分摊、退款与撤销、多付款账户选择（当前账本仅一张人民币借记卡）、缴费凭证 PDF、原版截图校准。

## 2. 方案选择

采用 **缴费订单并入账本根快照**。提交在 `FinanceLedgerStore` 内“读最新 → 校验 → 构造一个根快照 → 写一次”，沿用 `submitTransfer`、`submitWealthPurchase` 的模式；订单即快照里的 `PaymentOrder`，不另建表。

话费券保存在 `abank.benefits.v1`，无法与账本一次写入。采用“先标记券已使用、再写账本；账本写入失败则释放券”的补偿顺序：

- 同请求已存在订单时，在动券之前直接返回旧订单（幂等）。
- 账本写入失败后调用 `BenefitsStore.releaseCoupon`；若释放也失败，最坏结果是演示数据里损失一张券，订单与扣款未发生，保持一致。
- 两步之间进程被杀同样只会多用掉一张券，不会多扣款。此取舍写入任务记录。

备选：A 独立 `PaymentStore` + 账本调用（余额与订单无法原子写入，需补偿）；B 通用跨 Store 事务层（超出本阶段需要）。均不采用。

## 3. 数据模型

新目录 `ABank/Features/Payment/`（模型 Foundation-only、`nonisolated`）：

```
Payment/
  Models/PaymentModels.swift       // 类型、订单、户号、错误
  Models/PaymentCatalog.swift      // 面额、预置户号、运营商号段
  Models/PaymentRules.swift        // 手机号校验、账单金额、账期、券抵扣
  页面控制器与 Views/
Mine/FinanceLedger/FinanceLedgerStore+Payment.swift   // 提交与读取（账本扩展）
```

### 3.1 类型与目录

- `PaymentKind`：`mobile`、`water`、`electric`、`gas`（标题：手机充值/水费/电费/燃气费）。
- 面额：10、20、30、50、100、200 元（`PaymentCatalog.denominationsInCents`）。
- `BillAccount`：`id`、`kind`、`name`、`accountNo`、`address`、`provider`。预置 6 个：

| ID | 类型 | 名称 | 户号 | 供应商 |
|---|---|---|---|---|
| `bill.water.home` | water | 家庭住宅 | 0301 2288 6401 | 模拟自来水公司 |
| `bill.water.parents` | water | 父母住宅 | 0301 5567 1023 | 模拟自来水公司 |
| `bill.electric.home` | electric | 家庭住宅 | 8802 1094 7735 | 模拟供电公司 |
| `bill.electric.office` | electric | 工作室 | 8802 3351 0286 | 模拟供电公司 |
| `bill.gas.home` | gas | 家庭住宅 | 6609 4417 2058 | 模拟燃气公司 |
| `bill.gas.parents` | gas | 父母住宅 | 6609 7782 1304 | 模拟燃气公司 |

- 运营商按号段仅展示：移动 134–139、147、150–152、157–159、172、178、182–184、187、188、195、197、198；联通 130–132、145、155、156、166、175、176、185、186、196；电信 133、149、153、173、177、180、181、189、191、199；其他号段显示“其他运营商”。默认手机号取 `CustomerInfoStore` 的模拟手机号。

### 3.2 规则（`PaymentRules`）

- 手机号合法：11 位纯数字，首位 1，第二位 3–9；输入时过滤空格与分隔符。
- 账期 = 上海自然月 `yyyy-MM`（经 `BankingDateContext`）；到期日 = 该月最后一天。
- 账单金额（分）= `base(kind) + stableHash(accountID + period) % span(kind)`：水 3,500 + [0, 6,000)，电 8,000 + [0, 18,000)，燃气 4,000 + [0, 14,000)；哈希沿用 `BranchSchedule.stableHash`（FNV-1a，不使用 `hashValue`）。最大账单 26,000 分，低于演示账户余额。
- 账单状态（读取时）：当月同户号存在 `kind` 为公用事业的订单 → 已缴清，否则待缴。
- 话费券：`PaymentRules.phoneCouponFaceInCents(templateID:)`（`phone5` → 500，`phone10` → 1000，其余不适用）；可用条件 = 券状态待使用 且 面值 < 面额；实付 = 面额 − 面值（> 0）。

### 3.3 订单

`PaymentOrder`（Codable）：`id`、`orderNo`、`requestID`、`kind`、`targetID`（手机号或户号 ID）、`targetTitle`（快照，如“手机号 152****8684”“水费 · 家庭住宅”）、`period?`（缴费账期）、`faceInCents: Int64`（面额/账单额）、`couponID?`、`couponDiscountInCents: Int64`、`paidInCents: Int64`、`accountID`、`createdAt`（`yyyy-MM-dd HH:mm:ss`，上海）、`transactionID`。订单状态只有“已完成”，无撤销。

### 3.4 账本变更

`FinanceLedgerRecord` 新增 `paymentOrders: [PaymentOrder] = []`（`CodingKeys` 加入，`decodeIfPresent`）。`FinanceLedgerStore+Payment.swift`：

- `submitMobileRecharge(phone:faceInCents:couponID:requestID:) throws -> PaymentOrder`、`submitUtilityPayment(billAccountID:requestID:) throws -> PaymentOrder`。顺序：请求 ID → 同请求已存在则直接返回 → 严格读取最新账本（损坏则报错、不重置）→ 校验（手机号/面额/户号与账期未缴/余额）→ 话费券校验并 `useCoupon`（仅充值且选券）→ 构造订单与一条支出流水（`payment_<订单ID>`，标题“手机充值-152****8684”“水费缴费-家庭住宅”，类别 `mobile_recharge`/`life_payment`，`includeInFlow = true`，渠道“本机模拟”）→ 重算余额 → 一次 `persist`；`persist` 失败时释放话费券。
- 读取：`paymentOrders()`（按时间倒序）、`paymentOrder(id:)`、`billStatus(of:)`、`currentBill(for:)`。
- `BenefitsStore` 新增 `releaseCoupon(id:)`（仅清除 `usedAt`；已过期/作废/未使用的券不处理）。
- 类别：`IncomeExpenseFilterCatalog.expenseGroup` 新增“手机充值”“生活缴费”；`allCategoryIds` 等集合随之包含。
- 错误 `PaymentError`（中文文案）：`invalidRequest`、`invalidPhone`、`invalidDenomination`、`billNotFound`、`alreadyPaid`、`couponUnavailable`、`insufficientBalance`、`orderNotFound`、`corruptLedger`、`persistence`。

### 3.5 订单列表统一

`OrdersViewController` 的数据改为 `OrderListItem`（`.reward(RewardOrder)` / `.payment(PaymentOrder)`），按创建时间倒序；筛选条在原有“全部/待使用/已使用/已失效/已取消”后追加“充值缴费”：“全部”与“充值缴费”显示缴费订单，状态筛选仅作用于兑换订单。缴费订单行：标题 `targetTitle`、副标题“实付 x 元 · 时间”、标签“已完成”。

## 4. 页面与路由

`AppRoute` 新增：`mobileRecharge`、`mobileRechargeConfirm(phone:faceInCents:)`、`lifePayment`、`utilityBill(billAccountID:)`、`paymentOrderDetail(orderID:justPaid:)`；`AppRouter` 穷举 switch 补全，新页面实现 `RouteHosting`，继承 `BankingDataViewController` 系基类（账本/券变更、回前台、跨日刷新）。

- **手机充值**：手机号输入（预填、可改、实时校验与运营商展示）、面额网格、“下一步”；右上“充值记录”（订单列表“充值缴费”筛选）。
- **充值确认**：号码、运营商、面额、付款账户与可用余额、话费券行（无可用券显示“暂无可用话费券”，点选进入选择列表，可取消选择）、实付金额；确认后提交，成功进入订单详情（成功横幅）。
- **生活缴费**：水/电/燃气三个类型页签，下列该类型户号行（名称、户号、本期待缴金额或“本期已缴清”）；点进账单页；右上“缴费记录”。
- **账单页**：户号、地址、供应商、账期、到期日、应缴金额、状态；付款账户与余额；“立即缴费”（已缴清禁用）；确认弹窗后提交，成功进入订单详情。
- **订单详情**：类型、对象、账期（缴费）、面额/账单额、话费券抵扣、实付金额、付款账户、订单号、创建时间、流水号，“模拟交易”标注；无取消入口。
- 所有金额输入/展示复用既有格式化（`TransferMoney`、`formattedAmount`），手机号列表展示掩码。

## 5. 入口接线

- `FeatureCatalog`：`lifePayment` 改 `.available(.lifePayment)`，`mobileRecharge` 改 `.available(.mobileRecharge)`；`paymentStage` 不再使用并删除；`check_feature_catalog.swift` 同步（可用数 30 → 32）。
- 生活 Tab：宫格“生活缴费”“手机充值”走目录路由；横幅“生活缴费”进入 `lifePayment`；搜索占位保持。首页“生活缴费”入口经目录跳转。
- 订单入口（生活 Tab、我的）保持，列表内容按 §3.5 统一。

## 6. 验证

- `scripts/check_payment.swift`（接入 `check_banking_data.sh`）：手机号校验与号段运营商、面额合法性、账单金额稳定且在区间内、账期与跨月新账单、已缴清判断、话费券抵扣规则（面值小于面额，等于或大于不可用）、提交校验顺序、同请求幂等（订单/扣款/券都不重复）、扣款与流水与订单一致、余额恰好与不足、账本写入失败时原子性且话费券被释放、损坏账本不覆盖字节、旧账本解码缺省订单、`releaseCoupon` 仅作用于已使用券、类别集合含新类别、订单列表混排与筛选。
- 既有账本/转账/权益/理财检查保持通过；正常构建；`git diff --check`。
- 模拟器：目录/宫格/横幅入口、手机号校验、选面额、选券抵扣提交、订单详情、水电燃查询与缴费、重复缴费被拒、余额不足提示、“我的订单”混排与“充值缴费”筛选、账户明细与本月收支同步、重启保持；截图 `artifacts/abc-resources/verification/m8-*.png`；验收后清理账本与权益数据。
- 全分支审查后更新开发计划、任务记录与 CURRENT 索引。

## 7. 风险与边界

- 无原版截图，布局按现有设计系统，交接标注“待截图校准”。
- 话费券与账本两个 key 的一致性见 §2；演示账户余额约 1,499.66 元，多次缴费后会触发“余额不足”，属预期。
- 账单金额随上海月份变化，模拟器时钟与真实日期不一致时以 `BankingDateContext` 为准。
