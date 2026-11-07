# M6 权益订单设计

日期：2026-11-06。基线：`main@3ae87eb`（M5 已合并），分支 `feat/m6-benefits-orders`。对应 [开发计划](../../development-plan.md) 阶段 M6。

## 1. 目标与已确认决策

**目标**：把“权益中心 / 小豆乐园 / 积分商城 / 我的订单 / 客户等级”从“即将上线”占位变成可演示的本地模块：积分与小豆分账、权益领取、小豆签到、兑换、卡券状态、订单列表/详情与取消，并让“我的”资产统计卡的“银行卡”跳到已有账户页。全部为本地假数据，不发网络请求，不涉及真实资金。

用户已确认：

| 议题 | 决策 |
|---|---|
| 获得方式 | 小豆：小豆乐园每日签到；积分：领取“送积分”类权益；不与转账/账本联动 |
| 客户等级 | 做轻量只读页：由累计获得积分推算等级，显示进度与等级权益对比；权益领取可按最低等级限制 |
| 存储方案 | 单一 `BenefitsStore` 持有一个快照（流水、卡券、订单、领取记录、签到日），每次变更整体提交一次写入，保证联动原子性 |
| 范围 | 兑换商品仅限虚拟卡券；无实物、无收货地址；不新增图片资源（SF Symbols + 现有图标） |

**验收标准**

1. 功能目录 5 项（权益中心、小豆乐园、积分商城、我的订单、客户等级）改为已完成并接入路由；搜索、生活宫格、“我的”入口进入正确页面。
2. 积分与小豆各自独立：余额 = 种子余额 + 用户流水之和（读取时计算），兑换只扣商品标价币种；种子余额积分 12,860、小豆 260；“我的”统计卡的小豆/积分/礼券实时读取，不再是占位值。
3. 小豆签到：每个上海自然日一次，连续 7 日奖励 5/5/8/8/10/10/20 小豆，中断重置，满 7 日后循环；重启与跨日正确。
4. 权益领取：按“仅一次 / 每月一次”与最低等级限制；积分类写入积分流水，卡券类生成卡券；已领、本月已领、等级不足均有明确状态。
5. 兑换：确认页显示兑换后余额；提交时重新校验余额与每月限兑；成功生成订单、卡券和一条支出流水并进入订单详情。
6. 卡券状态：待使用 / 已使用 / 已过期 / 已作废，读取时按时钟推算；可“模拟使用”（显示模拟券码）。
7. 订单：列表可按状态筛选；详情显示订单号、商品、币种与数量、关联卡券；仅当卡券待使用且未过期时可取消，取消后卡券作废、原币种全额退回并产生退回流水，订单保留。
8. “我的”统计卡四格均可点击：银行卡 → 已有 `myAccount` 页；小豆/积分 → 对应明细；礼券 → 我的卡券。生活页“卡券”按钮、“订单”按钮进入对应页。
9. 数据检查（新增权益订单检查）、正常构建、模拟器验收全部通过；不新增网络请求，不改账本存储结构。

**不在本阶段范围**：实物商品与物流、真实支付、转账/消费送积分、推送提醒、M5 延后的 Minor、原版截图校准。

## 2. 方案选择

采用 **Foundation 纯模型层 + 单一聚合 `BenefitsStore`**（沿用 `BranchServiceStore` 的模式）。

- 目录（权益、商品、卡券模板）为静态数据；等级、卡券/订单状态、签到连续天数、余额都是纯函数，时间来自注入的 `BankingDateContext`。
- 兑换/取消/领取/签到各自在快照副本上修改，一次 `commit` 写入成功后才更新内存并发通知；写入失败内存不变。

备选：B 分设流水/卡券/订单三个 Store——联动要跨 Store 写入，可能出现半成功；C 仅存事件日志、全部派生——最一致但可读性差，与项目现有风格不符。均不采用。

## 3. 数据模型

新目录 `ABank/Features/Benefits/`：

```
Benefits/
  Models/BenefitsModels.swift     // 币种、流水、权益、商品、卡券、订单、快照、错误（仅 Foundation，nonisolated）
  Models/BenefitsCatalog.swift    // 静态：卡券模板、权益、商品、种子流水
  Models/BenefitsRules.swift      // 纯函数：等级、签到、状态、限制、稳定编码
  BenefitsStore.swift
  BenefitsFlowViewController.swift          // 基类
  BenefitsCenterViewController.swift
  RewardMallViewController.swift            // 积分商城 / 小豆乐园共用（币种参数）
  GoodsDetailViewController.swift
  RewardLedgerViewController.swift
  CouponsViewController.swift
  CouponDetailViewController.swift
  OrdersViewController.swift
  OrderDetailViewController.swift
  CustomerLevelViewController.swift
  Views/BenefitsViews.swift ...
```

### 3.1 币种与流水

- `RewardCurrency`：`.points`（积分）、`.beans`（小豆）。
- `RewardEntry`：`id`、`currency`、`amount`（有符号 Int）、`kind`（`seed / checkIn / claim / redeem / refund`）、`title`、`createdAt`、`orderID?`。
- 种子流水为 `BenefitsCatalog` 中固定的绝对日期条目（不落库）：积分 12,860（含若干收入与一笔历史兑换支出，累计获得 14,360）、小豆 260。用户流水存于快照。
- 余额 = 种子之和 + 用户流水之和；累计获得积分 = 种子与用户流水中积分正收入之和（`refund` 不计入，避免取消订单抬高等级）。

### 3.2 等级

累计获得积分阈值：普通 0、一星 2,000、二星 10,000、三星 30,000、四星 80,000、五星 200,000。种子累计 14,360 即“二星客户”。等级页显示当前等级、距下一级差额与进度条、各等级权益对比表。“我的”资料头等级文案改读推算结果。

### 3.3 权益（可领取）

8 个静态权益，每个有 `id`、标题、副标题、最低等级、领取周期（`once` / `monthly`）、奖励（`.points(Int)` 或 `.coupon(templateID)`）：

| 权益 | 奖励 | 周期 | 最低等级 |
|---|---|---|---|
| 新客礼 | 500 积分 | 仅一次 | 普通 |
| 外卖红包 | 外卖 15 元券 | 仅一次 | 普通 |
| 月度积分礼 | 200 积分 | 每月 | 一星 |
| 咖啡月礼 | 咖啡 10 元券 | 每月 | 一星 |
| 二星月度加成 | 500 积分 | 每月 | 二星 |
| 观影月礼 | 电影 20 元券 | 每月 | 二星 |
| 三星月度加成 | 1,000 积分 | 每月 | 三星 |
| 贵宾出行礼 | 出行 30 元券 | 每月 | 三星 |

状态（读取时计算）：可领取 / 已领取（仅一次）/ 本月已领 / 需 X 星（等级不足）。“每月”按上海自然月判定。

### 3.4 商品与卡券模板

卡券模板：`id`、标题、品牌、面额文案、有效天数、使用说明。商品：`id`、模板、币种、标价、每月限兑次数（取消的订单不计入）。商品 12 个：积分 6 个（1,000–5,000）、小豆 6 个（50–200），每月限兑 2–3 次。

### 3.5 卡券与订单

- `Coupon`：`id`、`templateID`、`source`（`claim(benefitID)` / `redeem(orderID)`）、`receivedAt`、`usedAt?`、`voidedAt?`；`expiresAt = receivedAt + validDays`（按上海日界取当天末）。
- `CouponStatus`（读取时）：`voided` > `used` > `expired`（now ≥ expiresAt）> `unused`。
- `RewardOrder`：`id`、`orderNo`、`goodsID`、标题快照、币种、`cost`、`quantity`（固定 1）、`createdAt`、`couponID`、`cancelledAt?`。订单号由 FNV-1a 稳定编码（`M6` + 日期 + 8 位）。
- `OrderStatus`（读取时）：已取消 / 已使用 / 已过期 / 待使用（由卡券与取消时间决定）。
- 取消条件：订单未取消且关联卡券 `unused`。取消时：订单 `cancelledAt`、卡券 `voidedAt`、追加一条同币种同金额的 `refund` 流水，三者一次提交。
- 订单只由兑换产生；权益领取记录在 `BenefitClaim`（`id`、`benefitID`、`createdAt`、`couponID?`）并体现在流水/卡券中。

### 3.6 签到

快照保存已签到日字符串（`yyyy-MM-dd`，上海）。连续天数：从今天（若已签）或昨天起向前连续的天数。下一次签到奖励 = `[5,5,8,8,10,10,20][streak % 7]`。签到写入一条 `checkIn` 小豆流水并记录日期；同日重复签到被拒。

### 3.7 快照与持久化

`BenefitsRecords`：`entries`、`coupons`、`orders`、`claims`、`checkInDays`。UserDefaults 键 `abank.benefits.v1`。无法解码时视为空快照并保留原字节直到下次成功保存；写入失败（含注入的 `dataWriter`）抛 `BenefitsError.saveFailed`，内存不变，不发通知。变更成功后发 `BenefitsStore.didChangeNotification`。

### 3.8 错误

`BenefitsError`：`insufficientBalance`、`monthlyLimitReached`、`alreadyCheckedIn`、`alreadyClaimed`、`levelTooLow`、`notCancellable`、`notUsable`、`unknownItem`、`saveFailed`，均有中文 `localizedDescription`。

## 4. 页面与路由

`AppRoute` 新增：`benefits`、`pointsMall`、`beans`、`goodsDetail(goodsID:)`、`rewardLedger(currency:)`、`coupons`、`couponDetail(couponID:)`、`orders`、`orderDetail(orderID:)`、`customerLevel`。`AppRouter` 穷举 switch 补全；新页面实现 `RouteHosting`。

- **权益中心**：等级与积分/小豆余额卡（可点进明细）、快捷入口（积分商城、小豆乐园、我的卡券、我的订单、客户等级）、可领取权益列表（领取按钮，状态见 3.3）。
- **积分商城 / 小豆乐园**：同一 `RewardMallViewController(currency:)`；小豆乐园顶部多“签到卡”（7 日进度条、今日奖励、签到按钮）。商品卡显示标价、本月余量。
- **商品详情**：卡券说明、有效期、标价、每月限兑；“立即兑换”→ 确认（显示兑换后余额）→ 成功进入订单详情（带成功横幅）。余额不足/超限时按钮禁用并说明。
- **积分/小豆明细**：余额头 + 全部/收入/支出，按月分组；种子与用户流水合并倒序。
- **我的卡券**：待使用 / 已使用 / 已失效三段；**卡券详情**：模拟券码（FNV-1a 派生）、有效期、说明、“模拟使用”、关联订单入口。
- **我的订单**：全部/待使用/已使用/已失效/已取消筛选；**订单详情**：状态、商品、订单号、下单时间、关联卡券、取消订单（需确认；不可取消时说明原因）。
- **客户等级**：见 3.2。
- 页面继承 `BankingDataViewController`（回前台/跨日刷新），并监听 `BenefitsStore.didChangeNotification`。

## 5. 入口接线

- `FeatureCatalog`：`beans / pointsMall / benefits / customerLevel / orders` 由 `.planned` 改 `.available(route)`；`benefitsStage` 常量删除；`check_feature_catalog.swift` 中以 `.benefits` 作为“计划中”样例的断言改为其他仍计划中的功能（如 `.mobileRecharge`）。
- “我的”：统计卡四格可点；值来自 `BenefitsStore`（小豆余额、积分余额、待使用卡券数；银行卡保持 1）；监听通知刷新；资料头“权益中心”“二星客户”走路由并读推算等级。订单卡已走 `.orders`。
- 生活：卡券按钮 → `coupons`；缤纷活动主卡 → `beans`；“海量权益”横幅 → `benefits`；订单按钮已走路由。其余 toast 不动。

## 6. 验证

- `scripts/check_benefits.swift`（接入 `check_banking_data.sh`）：种子余额与累计、等级边界、权益状态（一次/每月/等级）、上海月/日界、签到连续与中断与循环、领取（积分/卡券）、兑换（扣款/限兑/余额再校验）、卡券状态与有效期边界、使用、取消与退回（含累计积分不被抬高）、订单状态、双币种互不影响、编码稳定性、持久化/损坏回退/写入失败原子性。
- 功能目录检查同步更新；正常构建；`git diff --check`。
- 模拟器：入口、签到、领取、兑换、使用卡券、取消订单、“我的”统计卡点击（含银行卡 → 账户页）、重启保持；截图 `artifacts/abc-resources/verification/m6-*.png`；验收后清理 `abank.benefits.v1`。
- 全分支审查后更新开发计划、任务记录与 CURRENT 索引。

## 7. 风险与边界

- 无原版截图，布局按现有设计系统，交接标注“待截图校准”。
- 状态靠时钟推算：页面可见时跨过过期时刻依赖回前台/午夜刷新，不做秒级刷新。
- 种子流水为固定日期，演示日期漂移不影响逻辑。
