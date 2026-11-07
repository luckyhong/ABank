# M5 网点服务设计

日期：2026-11-06。基线：`main@1923ede`（M4 已合并），分支 `feat/m5-branch-services`。对应 [开发计划](../../development-plan.md) 阶段 M5。

## 1. 目标与已确认决策

**目标**：把网点服务从“即将上线”占位变成可演示的本地模块：统一城市选择、网点列表/详情（含营业时间与示意图）、取号、预约、取消与历史。全部为本地模拟数据，不接地图 SDK，不发网络请求，不定位，不拨号。

用户已确认：

| 议题 | 决策 |
|---|---|
| 目录范围 | 5 项全部改为可用。网点查询、网点取号为独立入口；我要开卡、同号换卡、纪念币预约作为“预约业务”，从对应入口进入预约表单并预选该业务；纪念币多一个兑换数量 |
| 统一城市 | 全局一个当前城市。生活 Tab 的城市按钮、网点列表共用同一城市选择页；首页“网点服务”卡与“我的”“我的网点”卡显示当前城市默认网点，切换城市后各处同步 |
| 数据规模 | 6 个城市，每市 3–5 个网点，覆盖不同营业时间（含午休、周末休息、纯自助） |
| 取号规则 | 仅营业中可取；全局同时只能有一张有效号；按业务分队列（个人现金 A、个人非现金 B、对公 C）；按取号时间推算前方人数与状态；可取消；跨天未完成的过期 |
| 预约规则 | 未来 7 天 × 营业时段，每小时一档，含模拟“已约满”；同一业务同时只能有一条待办理预约；纪念币 1–20 枚；可取消；时段结束后过期 |
| 方案 | Foundation 纯模型层 + `CitySelectionStore` + `BranchServiceStore`；状态在读取时按时间推算 |
| 视觉参考 | 无原版截图，按现有设计系统设计，交接中标注“待截图校准” |

**验收标准**

1. 功能目录 M5 的 5 项（网点查询、网点取号、纪念币预约、我要开卡、同号换卡）改为已完成并接上路由；搜索、首页宫格/网点卡、“我的”网点卡进入正确页面。
2. 在城市选择页切换城市后，生活 Tab 城市名、网点列表、首页网点卡、“我的”网点卡同步；重启后保持。
3. 网点列表显示示意图与列表，可按“全部 / 营业中 / 业务”筛选；详情显示地址、电话、本周营业时间（今天高亮）、支持业务与实时营业状态。
4. 营业中网点可取号，生成号票（如 `A023`），每次取号都有一条可在历史中查询的记录；不营业或自助网点不能取号且说明原因；已有有效号时不能再取。
5. 预约可选业务、网点、日期、时段（纪念币选数量），提交后显示预约码与结果；违反规则时给出明确提示。
6. 取号与预约均可取消（需确认），取消后状态更新并保留在历史中；重启后记录与状态一致。
7. 数据检查（新增网点服务检查）、正常构建、模拟器验收全部通过；不新增网络请求，不改账本存储结构。

**不在本阶段范围**：真实定位与距离计算、地图 SDK、拨号、推送/本地通知提醒、各业务的真实办理流程（开卡资料填写等）、过号重取、原版截图校准。

## 2. 方案选择

采用 **Foundation 纯模型层 + 两个 Store**。

- `CitySelectionStore` 只管当前城市（跨模块全局状态，生活 Tab 也用）。
- `BranchServiceStore` 管取号与预约记录。
- 网点目录、营业状态、可约日期/时段、排队推算都是纯函数，时间统一来自注入的 `BankingDateContext`，检查脚本可在 macOS 上用固定时钟验证。

备选：

- B：一个 Store 同时管城市和记录。文件少，但生活 Tab 会依赖网点模块，职责混杂。
- C：记录写进 `FinanceLedgerStore`。需改账本存储版本，且记录与资金无关，不采用。

## 3. 数据模型

新目录 `ABank/Features/BranchService/`：

```
BranchService/
  Models/BranchModels.swift        // City、Branch、BusinessHours、BranchBusiness、Ticket、Reservation 等（仅 Foundation）
  Models/BranchCatalog.swift       // 6 城市 × 3–5 网点静态数据
  Models/BranchSchedule.swift      // 营业状态、可约日期/时段、排队推算（纯函数）
  CitySelectionStore.swift
  BranchServiceStore.swift
  CityPickerViewController.swift
  BranchListViewController.swift
  BranchDetailViewController.swift
  TakeTicketViewController.swift
  TicketDetailViewController.swift
  ReservationFormViewController.swift
  ReservationResultViewController.swift
  BranchServiceHistoryViewController.swift
  Views/BranchSketchMapView.swift  // 用 UIView 绘制的示意图
  Views/…                          // 网点行、状态标签、营业时间表、时段宫格等复用视图
```

### 3.1 城市与网点

- `BranchCity`：`id`（如 `xian`）、`name`（如“西安市”）。6 个城市：西安、北京、上海、广州、成都、武汉。默认西安。
- `Branch`：
  - `id`、`cityID`、`name`、`address`、`phone`（虚构号码）、`distanceMeters`（模拟距离，用于列表排序与显示）
  - `kind`：`.full`（柜面 + 自助）或 `.selfService`（纯自助）
  - `hours: BusinessHours`
  - `businesses: Set<BranchBusiness>`（自助网点为空）
  - `mapPosition`：示意图中的归一化坐标（x、y 取 0…1）
- 每城 3–5 个网点，共 21 个；每城第一个网点为“默认网点”（按 `distanceMeters` 最小）。西安第一个网点为现有的“西安沣东新城支行”，保持首页现状一致。
- 地址、名称、电话均为虚构，不对应真实网点。

### 3.2 营业时间 `BusinessHours`

- 按星期（周一到周日）给出 `DayHours?`：`open`、`close`（自 0 点起的分钟数），可选午休 `lunch`（开始、结束）。`nil` 表示当天休息。
- 自助网点标记为 `isAllDay`（24 小时，仅自助设备）。
- 模板：
  - 工作日 9:00–17:00、周末 9:30–16:00（无午休）
  - 工作日 9:00–17:00 含午休 12:00–13:30，周末休息
  - 每天 9:00–17:30（无午休）
  - 24 小时自助
- 营业状态 `BranchOpenState`（纯函数，按 Asia/Shanghai 时间）：`open`（营业中）、`lunchBreak`（午休中）、`closed(nextOpen: Date?)`（休息中，附下一次营业时间）、`selfService`（自助 24 小时）。

### 3.3 业务 `BranchBusiness`

| 业务 | 取号 | 预约 | 队列前缀 |
|---|---|---|---|
| 个人现金 `personalCash` | ✓ | – | A |
| 个人非现金 `personalNonCash` | ✓ | ✓ | B |
| 对公业务 `corporate` | ✓ | – | C |
| 我要开卡 `openCard` | – | ✓ | – |
| 同号换卡 `sameNumberReplace` | – | ✓ | – |
| 纪念币兑换 `commemorativeCoin` | – | ✓（需数量 1–20） | – |

### 3.4 取号记录 `QueueTicket`（Codable）

字段：`id`、`branchID`、`business`、`number`（如 `A023`）、`takenAt`、`aheadAtTaking`（取号时前方人数）、`cancelledAt?`。

- 号码与前方人数由网点 ID、业务和取号分钟数的确定性哈希生成：前方 2–9 人，号码数字 = 当天开门后已过分钟数 ÷ 3（取整）+ 前方人数 + 1，三位补零（模拟当天已发号数）。
- 状态 `QueueTicketStatus` 在读取时推算（每人平均 3 分钟）：
  - 已取消：`cancelledAt` 非空
  - 已过期：取号日之后的 0 点起仍未完成
  - 等待中：剩余前方人数 ≥ 3
  - 即将叫号：剩余前方 1–2 人
  - 已叫号：剩余 0 人，持续 15 分钟
  - 已完成：叫号 15 分钟后（模拟办理完成）
- 有效号 = 等待中 / 即将叫号 / 已叫号。

### 3.5 预约记录 `BranchReservation`（Codable）

字段：`id`、`branchID`、`business`、`date`（当天 0 点，Asia/Shanghai）、`slotStartMinute`、`quantity?`（仅纪念币）、`code`（8 位数字预约码，确定性生成）、`createdAt`、`cancelledAt?`。

- 状态在读取时推算：已取消、已过期（时段结束后）、待办理。
- 可约日期：今天起 7 天中该网点营业的日子。
- 时段：每小时一档，从开门整点到关门前，避开午休覆盖的时段；开始时间早于当前时间的不可选；由网点 ID + 日期 + 时段的确定性哈希模拟约 1/5 “已约满”。

### 3.6 规则与错误 `BranchServiceError`

| 错误 | 触发 | 提示文案 |
|---|---|---|
| `activeTicketExists` | 已有有效号时再取号 | 您已有一张有效号票（附“查看”） |
| `branchNotOpen` | 非营业中（含午休）取号 | 网点当前未营业，可预约其他时间 |
| `businessNotSupported` | 网点不支持该业务或业务不允许取号/预约 | 该网点暂不支持此业务 |
| `duplicateReservation` | 同一业务已有待办理预约 | 已有待办理的同类预约 |
| `slotUnavailable` | 日期不可约、时段已过或已约满 | 该时段已不可预约 |
| `invalidQuantity` | 纪念币数量不在 1–20 | 兑换数量需在 1–20 枚之间 |
| `recordNotFound` / `notCancellable` | 取消不存在或已结束的记录 | 该记录已无法取消 |
| `saveFailed` | 写入失败 | 保存失败，请稍后重试 |

### 3.7 Store

两者均按 `SecuritySettingsStore` 模式实现：`static let shared`、`static let didChangeNotification`、可注入 `defaults`、`notificationCenter`、`dataWriter`（模拟写入失败）与 `BankingDateContext`。

- **`CitySelectionStore`**：键 `abank.selectedCity.v1`，保存城市 ID。未知或损坏回到西安。`select(cityID:) -> Bool`。
- **`BranchServiceStore`**：键 `abank.branchServices.v1`，保存 `{ tickets, reservations }`。无法解码时视为空，原数据保留到下次成功保存。
  - 查询：`tickets`、`reservations`（按时间倒序）、`activeTicket`、`status(of:)`、`queueSnapshot(branchID:business:)`（当前前方人数，用于取号前展示）。
  - 修改：`takeTicket(branchID:business:) throws -> QueueTicket`、`reserve(branchID:business:date:slotStartMinute:quantity:) throws -> BranchReservation`、`cancelTicket(id:) throws`、`cancelReservation(id:) throws`。
  - 每次修改前按当前时间重新校验；只有保存成功后才更新内存并发通知。

## 4. 页面与联动

所有新页面继承 `BaseViewController`，标准导航栏，背景 `abankBackground`，分组卡片白底 `CornerRadius.lg`、左右 `Spacing.md`，状态标签沿用首页网点卡的描边样式。

### 4.1 页面

- **城市选择**：顶部“当前城市”，下方 6 个城市宫格（选中态用 `abankPrimary`）。点选保存后返回；保存失败 toast 并停留。
- **网点列表**：
  - 导航栏右侧“我的记录”进入历史。
  - 顶部城市按钮（“西安市 ▾”）进入城市选择。
  - 有效号横幅（若有）：号码与状态，点击进入号票详情。
  - 示意图（约 180pt）：街道网格 + 当前城市网点标记，点击标记高亮并滚动到对应行。
  - 筛选：全部 / 营业中 / 个人现金 / 个人非现金 / 对公。
  - 行：名称、状态标签（营业中 / 午休中 / 休息中 / 自助 24 小时）、距离、地址。按距离排序。筛选无结果时显示空态“当前城市暂无符合条件的网点”。
- **网点详情**：单标记示意图、名称与状态、地址、电话（点击 toast“演示环境不拨打电话”）、本周营业时间表（今天高亮，休息日显示“休息”）、支持业务标签；底部“取号”“预约”两个按钮。取号不可用时按钮禁用并在上方说明原因（未营业 / 自助网点）；自助网点“预约”同样禁用。
- **取号**：网点名称与状态，业务单选（仅该网点支持的取号业务），显示“当前前方约 N 人”，“确认取号”。成功后用号票详情替换当前页（返回时回到网点详情）。
- **号票详情**：大号码、业务、网点、取号时间、状态、前方人数与预计等待时间；有效时显示“取消取号”（确认框“确定取消该号票？”）。进入页面与每 30 秒刷新一次显示（只重算，不写库）。
- **预约表单**：业务（可预选）、网点（默认当前城市第一个支持该业务的网点，点击从当前城市支持该业务的网点中选择）、日期横向 7 天（不可约置灰）、时段宫格（已过/约满置灰）、纪念币数量步进器（1–20），“提交预约”。当前城市无网点支持该业务时显示空态。
- **预约结果**：成功图标、预约码、业务、网点、日期时段；按钮“查看记录”（进入历史）和“完成”（返回入口页）。
- **历史**：分段“取号 / 预约”，按时间倒序；行显示主信息与状态；有效记录可左滑或点“取消”（需确认）；取号行点击进入号票详情。空态“暂无记录”。

### 4.2 路由与入口

- `AppRoute` 新增：`.cityPicker`、`.branchList`、`.branchQueue`、`.branchDetail(branchID: String)`、`.takeTicket(branchID: String)`、`.ticketDetail(ticketID: String)`、`.branchReservation(business: BranchBusiness, branchID: String?)`、`.branchServiceHistory`。预约结果页由表单直接推入，不单独建路由。
- `.branchQueue` 由路由器在构造时判断：有有效号进入号票详情，否则进入网点列表。
- `FeatureCatalog`：
  - `branchQuery` → `.branchList`
  - `branchQueue` → `.branchQueue`
  - `openCard` → `.branchReservation(business: .openCard, branchID: nil)`
  - `sameNumberReplace` → `.branchReservation(business: .sameNumberReplace, branchID: nil)`
  - `coinReservation` → `.branchReservation(business: .commemorativeCoin, branchID: nil)`
  - `branchStage` 不再被引用时删除。
- 首页“网点服务”卡与“我的”“我的网点”卡：名称、状态、距离、地址改由当前城市默认网点 + 实时营业状态生成（`MockDataProvider` 的固定值改为读取 Store 与目录）；刷新按钮重新生成并 toast“已刷新”；卡片其余入口沿用现有 `open(feature:)`。首页电话按钮 toast 保持演示文案。
- 生活 Tab：城市名读取 `CitySelectionStore`，城市按钮打开 `.cityPicker`。
- 相关页面监听两个 Store 的通知并刷新；进入页面时也重读一次。

### 4.3 资源

不新增导入素材。复用已有 `abc_branch_location`、`abc_home_branch_*`、`abc_mine_branch_*`，其余用 SF Symbols（`UIImage.abankAsset(_:fallback:)`）。

## 5. 错误处理

| 情况 | 行为 |
|---|---|
| 城市或记录数据无法解码 | 城市回西安、记录视为空；原数据保留到下次成功保存 |
| 写入失败 | 内存与界面不变；toast“保存失败，请稍后重试” |
| 业务规则不满足 | 按 §3.6 文案 toast；有效号已存在时提供“查看” |
| 提交时时段刚失效 | 重新校验后提示并刷新时段宫格 |
| 路由传入未知网点/号票 ID | 显示空态“网点不存在”/“记录不存在” |

## 6. 验证

**新增 `scripts/check_branch_services.swift`**，接入 `check_banking_data.sh`（sources 增加 `BranchModels.swift`、`BranchCatalog.swift`、`BranchSchedule.swift`、`CitySelectionStore.swift`、`BranchServiceStore.swift`）。检查内容：

1. 目录：6 城市，每城 3–5 网点，网点 ID 唯一，每个网点城市存在，默认网点为西安沣东新城支行；全功能网点至少支持一种取号业务；坐标在 0…1。
2. 营业状态（固定时钟）：工作日营业中、午休中、下班后、周末休息、自助 24 小时、`nextOpen` 跨周末正确。
3. 可约日期与时段：7 天内跳过休息日；午休时段排除；当天已过时段不可选；约满模拟是确定性的。
4. 取号：成功生成号码与前方人数；非营业、午休、自助、不支持业务被拒；有效号存在时被拒；状态随时间推进（等待中 → 即将叫号 → 已叫号 → 已完成）；跨天过期；取消后可再取。
5. 预约：成功生成 8 位预约码；同业务重复被拒、不同业务允许；纪念币数量 0/21 被拒；过期时段被拒；时段结束后状态为已过期；取消后可再约。
6. Store：保存后新建 Store 读回一致；损坏数据回退且不覆盖原数据；写入失败内存不变、不发通知；城市切换持久化，未知城市回西安。
7. 目录：M5 五项为 `.available` 且路由符合 §4.2。

**构建**：按开发计划的 `xcodebuild` 命令。

**模拟器（iPhone 16 Pro）**：入口（全部功能、搜索、首页、我的）；切换城市后生活 Tab、列表、首页卡、我的卡同步且重启保持；列表筛选与示意图标记；详情营业时间；取号 → 号票详情 → 重复取号被拒 → 取消；三种预约业务（含纪念币数量）提交与结果；重复预约被拒；历史两段与取消；重启后记录保持。截图存 `artifacts/abc-resources/verification/m5-*.png`（被 Git 忽略）。验收后删除模拟器上的 `abank.selectedCity.v1` 与 `abank.branchServices.v1`，或在交接中说明保留了哪些记录。

**预期未验证项**：320pt 宽度；无原版截图的布局待校准；状态长时间推进（叫号、完成）仅用脚本固定时钟验证，模拟器只看初始状态。
