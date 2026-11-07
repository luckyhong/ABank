# M5 网点服务 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 本地模拟的网点服务模块：统一城市、网点列表/详情/示意图、取号、预约、取消与历史，并把功能目录 M5 五项改为可用。

**Architecture:** 纯 Foundation 模型层（目录、营业时间、时段、排队推算均为纯函数，时间来自注入的 `BankingDateContext`）+ `CitySelectionStore` + `BranchServiceStore`（UserDefaults，照 `SecuritySettingsStore` 模式）。UIKit 页面经 `AppRoute`/`AppRouter` 进入，监听两个 Store 的通知刷新。

**Tech Stack:** Swift 5、UIKit、SnapKit、UserDefaults；检查脚本 `xcrun swiftc -default-isolation MainActor`。

**Spec:** `docs/superpowers/specs/2026-11-06-m5-branch-services-design.md`

## Global Constraints

- iOS 15.6+；不新增依赖；不接地图 SDK、不定位、不拨号、不发网络请求、不加本地通知。
- 所有日期按 `BankingDateContext`（Asia/Shanghai）计算；不得用 `Date()` / `Calendar.current` 直接取时间。
- 被检查脚本编译的模型类型标 `nonisolated`（脚本带 `-default-isolation MainActor`）。
- 确定性模拟一律用自写的稳定哈希（FNV-1a 64 位），**不得**用 Swift `hashValue`（每次启动随机化）。
- 存储键：`abank.selectedCity.v1`、`abank.branchServices.v1`；无法解码时城市回西安、记录为空，原数据保留到下次成功保存；写入失败内存不变、不发通知。
- 文案用中文，错误文案按 spec §3.6；页面继承 `BaseViewController`，用 `abank*` 颜色/字体与 `Spacing`、`CornerRadius`。
- 工程使用文件系统同步分组（`PBXFileSystemSynchronizedRootGroup`），新文件放进 `ABank/` 目录即可，无需改 pbxproj。
- 提交：中文 Conventional Commits，只提交本任务文件，不推送。

## Review Focus

1. **提交时跨过整点**：用户在 9:58 打开表单选了 10:00 时段，10:01 才提交 → `reserve` 重新校验并抛 `slotUnavailable`（Task 2 测试 `reserveRevalidatesAtSubmit`）。
2. **设备时区不是东八区 / 深夜边界**：UTC 23:30（上海次日 07:30）时“今天”和可约日期按上海日期计算（Task 1 测试 `shanghaiDayBoundary`）。
3. **部分记录损坏**：存储 JSON 中某个字段类型错误 → 整体视为空、原数据不被覆盖，下次成功保存才替换（Task 2 测试 `corruptRecordsKeepOriginal`）。
4. **重复取消**：对已取消或已完成的号票/已过期预约再取消 → `notCancellable`，不发通知（Task 2 测试 `cancelTwice`）。
5. **历史中引用的网点已不在目录**：旧记录的 `branchID` 查不到 → 显示“网点已停用”，不崩溃（Task 2 测试 `unknownBranchName`，Task 5 历史行使用 `BranchCatalog.displayName(branchID:)`）。

---

### Task 1: 模型、目录与营业/排队纯函数

**Files:**
- Create: `ABank/Features/BranchService/Models/BranchModels.swift`
- Create: `ABank/Features/BranchService/Models/BranchCatalog.swift`
- Create: `ABank/Features/BranchService/Models/BranchSchedule.swift`
- Create: `scripts/check_branch_services.swift`
- Modify: `scripts/check_banking_data.sh`（sources 加三个模型文件；循环加 `branch` → `scripts/check_branch_services.swift`）

**Interfaces:**
- Produces（全部 `nonisolated`）：
  - `struct BranchCity: Equatable, Hashable { let id: String; let name: String }`
  - `enum BranchBusiness: String, Codable, CaseIterable { case personalCash, personalNonCash, corporate, openCard, sameNumberReplace, commemorativeCoin }`，属性 `title: String`（个人现金 / 个人非现金 / 对公业务 / 我要开卡 / 同号换卡 / 纪念币兑换）、`queuePrefix: String?`（A/B/C/nil）、`allowsTicket: Bool`、`allowsReservation: Bool`（personalNonCash、openCard、sameNumberReplace、commemorativeCoin）、`requiresQuantity: Bool`（仅纪念币）；`static let ticketBusinesses: [BranchBusiness]`、`static let reservationBusinesses: [BranchBusiness]`、`static let coinQuantityRange = 1...20`
  - `struct DayHours: Equatable { let open: Int; let close: Int; let lunchStart: Int?; let lunchEnd: Int? }`（自 0 点起分钟）
  - `struct BusinessHours: Equatable { let byWeekday: [Int: DayHours]; let isAllDay: Bool }`（key 为 `Calendar` weekday，1=周日…7=周六）；`func hours(onWeekday: Int) -> DayHours?`；静态模板 `.weekdayAndWeekend`、`.weekdayWithLunchWeekendClosed`、`.everyDayLong`、`.allDaySelfService`（值见 spec §3.2）
  - `enum BranchKind { case full, selfService }`
  - `struct Branch: Equatable { id, cityID, name, address, phone: String; distanceMeters: Int; kind: BranchKind; hours: BusinessHours; businesses: Set<BranchBusiness>; mapX: Double; mapY: Double }`
  - `enum BranchOpenState: Equatable { case open, lunchBreak, closed(nextOpen: Date?), selfService }`，`title`：营业中 / 午休中 / 休息中 / 自助 24 小时；`allowsTicket: Bool`（仅 `.open`）
  - `struct ReservationSlot: Equatable { let startMinute: Int; let isAvailable: Bool }`，`label`（如 `09:00-10:00`）
  - `struct QueueTicket: Codable, Equatable { id, branchID: String; business: BranchBusiness; number: String; takenAt: Date; aheadAtTaking: Int; var cancelledAt: Date? }`
  - `enum QueueTicketStatus: Equatable { case waiting(ahead: Int), almostCalled(ahead: Int), called, completed, cancelled, expired }`，`title`：等待中 / 即将叫号 / 已叫号 / 已完成 / 已取消 / 已过期；`isActive`
  - `struct BranchReservation: Codable, Equatable { id, branchID: String; business: BranchBusiness; date: Date; slotStartMinute: Int; quantity: Int?; code: String; createdAt: Date; var cancelledAt: Date? }`
  - `enum ReservationStatus: Equatable { case pending, cancelled, expired }`，`title`：待办理 / 已取消 / 已过期
  - `enum BranchServiceError: LocalizedError, Equatable { case activeTicketExists, branchNotOpen, businessNotSupported, duplicateReservation, slotUnavailable, invalidQuantity, notCancellable, saveFailed }`，`errorDescription` 按 spec §3.6（`recordNotFound` 合并入 `notCancellable`）
  - `enum BranchCatalog { static let defaultCityID = "xian"; static let cities: [BranchCity]; static let branches: [Branch]; static func city(id:) -> BranchCity?; static func branches(inCity:) -> [Branch]`（按距离升序）`; static func branch(id:) -> Branch?; static func defaultBranch(inCity:) -> Branch; static func displayName(branchID:) -> String`（查不到返回“网点已停用”）`}`
  - `enum BranchSchedule`（均带 `dates: BankingDateContext` 参数）：
    - `static func stableHash(_ parts: String...) -> UInt64`（FNV-1a 64）
    - `static func openState(of: Branch, at: Date, dates:) -> BranchOpenState`
    - `static func reservableDays(for: Branch, dates:) -> [Date]`（今天起 7 个自然日中营业的日子，元素为上海 0 点）
    - `static func slots(for: Branch, on day: Date, dates:) -> [ReservationSlot]`
    - `static func queueAhead(branchID: String, business: BranchBusiness, at: Date, dates:) -> Int`（2…9）
    - `static func ticketNumber(branch: Branch, business: BranchBusiness, at: Date, ahead: Int, dates:) -> String`
    - `static func status(of: QueueTicket, at: Date, dates:) -> QueueTicketStatus`
    - `static func status(of: BranchReservation, at: Date, dates:) -> ReservationStatus`
    - `static func reservationCode(seed: String) -> String`（8 位数字，含前导零）

- [ ] **Step 1: 写失败检查** `scripts/check_branch_services.swift`，`@main struct BranchServiceChecks`，固定时钟工具 `func clock(_ text: String) -> BankingDateContext`（解析 `yyyy-MM-dd HH:mm`，上海时区）。用例：
  - `catalog()`：`cities.count == 6`；每城 `3...5` 个网点；网点 ID 唯一；每个 `cityID` 存在；`defaultBranch(inCity: "xian").name == "西安沣东新城支行"`；`.full` 网点 `businesses` 至少含一个 `allowsTicket`；`.selfService` 网点 `businesses.isEmpty`；坐标在 `0...1`；`displayName(branchID: "none") == "网点已停用"`。
  - `openStates()`：选一个 `.weekdayWithLunchWeekendClosed` 网点，2026-11-06（周五）10:00 → `.open`；12:30 → `.lunchBreak`；17:30 → `.closed(nextOpen:)` 且 nextOpen 为 2026-11-09 09:00（跨周末）；2026-11-07 10:00 → `.closed`；自助网点任意时间 → `.selfService`。
  - `slotsAndDays()`：同一网点在 2026-11-06 10:20 时 `reservableDays` 不含 11-07、11-08，共 5 天且首日为 11-06；当天 `slots` 不含 12:00 档，09:00 和 10:00 档 `isAvailable == false`（已开始）；对同一参数调用两次结果相同；全部网点 7 天的时段合计中，“约满”占比在 5%–40% 之间。
  - `shanghaiDayBoundary()`：时钟为 UTC `2026-11-05T23:30:00Z`（上海 11-06 07:30），`reservableDays.first` 等于上海 11-06 0 点。
  - `ticketStatusProgression()`：`aheadAtTaking = 5`、取号 10:00 → 10:00 `.waiting(ahead: 5)`；10:09 `.almostCalled(ahead: 2)`；10:15 `.called`；10:29 `.called`；10:30 `.completed`；有 `cancelledAt` → `.cancelled`；`aheadAtTaking = 9` 在 23:50 取号，次日 00:00 → `.expired`。
  - `numbersAndCodes()`：`queueAhead` 在 `2...9` 且对同输入确定；`ticketNumber` 形如 `^[ABC]\d{3}$` 且前缀与业务对应；`reservationCode` 为 8 位数字且确定。
  - `reservationStatus()`：10:00 档在 10:59 为 `.pending`、11:00 为 `.expired`；有 `cancelledAt` 为 `.cancelled`。

- [ ] **Step 2: 运行确认失败** — `scripts/check_banking_data.sh`，预期编译错误（类型未定义）。

- [ ] **Step 3: 实现三个模型文件。** 规则：
  - 每人 3 分钟：`remaining = ahead - elapsedMinutes / 3`；≥3 等待中，1–2 即将叫号；叫号时刻 `takenAt + ahead*3 分钟`，持续 15 分钟后已完成；在活跃状态下若当前时间 ≥ 取号日次日 0 点 → 已过期。
  - 号码数字 = `max(0, (取号分钟 − 开门分钟)) / 3 + ahead + 1`，三位补零；自助/无营业时间按开门 0 分。
  - 时段：开门整点（向上取整）到关门前每小时一档，与午休有交集的档排除；`startMinute` 对应时刻 ≤ 当前时间 → 不可用；`stableHash(branchID, 日期字符串, startMinute) % 5 == 0` → 约满。
  - 数据：6 城（西安、北京、上海、广州、成都、武汉），共 21 网点，每城至少一个 `.weekdayWithLunchWeekendClosed` 网点，全国 2–3 个自助网点，名称/地址/电话虚构；西安首个网点沿用“西安沣东新城支行”、距离 2552 米、地址“陕西省西安市沣东新城大明宫·沣东一路88号”。

- [ ] **Step 4: 运行通过** — `scripts/check_banking_data.sh`，预期末尾输出 `Branch service checks passed` 且其余检查照常通过。

- [ ] **Step 5: 提交** — `git add ABank/Features/BranchService/Models scripts/check_branch_services.swift scripts/check_banking_data.sh && git commit -m "feat: 新增网点目录与营业排队规则"`

---

### Task 2: CitySelectionStore 与 BranchServiceStore

**Files:**
- Create: `ABank/Features/BranchService/CitySelectionStore.swift`
- Create: `ABank/Features/BranchService/BranchServiceStore.swift`
- Modify: `scripts/check_branch_services.swift`、`scripts/check_banking_data.sh`（sources 加两个 Store）

**Interfaces:**
- Consumes: Task 1 全部类型。
- Produces:
  - `final class CitySelectionStore { static let shared; static let storageKey = "abank.selectedCity.v1"; static let didChangeNotification = Notification.Name("ABank.selectedCityDidChange"); init(defaults: UserDefaults = .standard, notificationCenter: NotificationCenter = .default, dataWriter: ((Data) throws -> Void)? = nil); private(set) var currentCity: BranchCity; @discardableResult func select(cityID: String) -> Bool }`（未知 ID 返回 false 不改；选同一城市返回 true 不发通知）
  - `final class BranchServiceStore { static let shared; static let storageKey = "abank.branchServices.v1"; static let didChangeNotification = Notification.Name("ABank.branchServicesDidChange"); init(defaults:notificationCenter:dates: BankingDateContext = .system, dataWriter:) }`
    - 读：`var tickets: [QueueTicket]`、`var reservations: [BranchReservation]`（均按创建时间倒序）、`var activeTicket: QueueTicket?`、`func ticket(id:) -> QueueTicket?`、`func reservation(id:) -> BranchReservation?`、`func status(of: QueueTicket) -> QueueTicketStatus`、`func status(of: BranchReservation) -> ReservationStatus`、`func queueAhead(branchID:business:) -> Int`
    - 写（全部 `throws BranchServiceError`）：`takeTicket(branchID:business:) -> QueueTicket`、`reserve(branchID:business:day:slotStartMinute:quantity:) -> BranchReservation`、`cancelTicket(id:)`、`cancelReservation(id:)`
  - 持久化格式：`struct BranchServiceRecords: Codable { var tickets: [QueueTicket]; var reservations: [BranchReservation] }`

- [ ] **Step 1: 写失败检查**（沿用 `withSuite` / `expect` 写法，见 `scripts/check_security_settings.swift`）：
  - `cityStore()`：默认 `currentCity.id == "xian"`；`select(cityID: "beijing")` 为 true 且新建 Store 读回北京并发 1 次通知；`select(cityID: "mars")` 为 false；存入垃圾数据 → 西安；写入失败 → false、仍为原城市、无通知。
  - `takeTicketRules()`：周五 10:00 营业网点取 `.personalCash` 成功，号码以 A 开头，`activeTicket` 为它；再取 → `activeTicketExists`；12:30 → `branchNotOpen`；自助网点 → `businessNotSupported`；取 `.openCard` → `businessNotSupported`；取消后可再取。
  - `reserveRules()`：可用时段预约 `.openCard` 成功、`code` 8 位；再约 `.openCard` → `duplicateReservation`；约 `.sameNumberReplace` 成功；纪念币数量 0 和 21 → `invalidQuantity`，nil → `invalidQuantity`；非纪念币带数量 → 存为 nil；约满或已过时段、不可约日期 → `slotUnavailable`；`.personalCash` → `businessNotSupported`；预约取消后同业务可再约。
  - `reserveRevalidatesAtSubmit()`：用可变时钟，9:58 计算 10:00 档可用，时钟拨到 10:01 后 `reserve` → `slotUnavailable`。
  - `cancelTwice()`：取消号票后再取消 → `notCancellable`；叫号完成后的号票取消 → `notCancellable`；过期预约取消 → `notCancellable`；不存在的 ID → `notCancellable`；这些情况均不发通知。
  - `persistence()`：取号+预约后新建 Store 读回相等；写入失败时 `takeTicket` 抛 `saveFailed`、`tickets` 不变、无通知。
  - `corruptRecordsKeepOriginal()`：写入 `{"tickets":[{"id":1}],"reservations":[]}` → `tickets.isEmpty`，且 defaults 中原数据字节未变；随后成功取号会覆盖。
  - `unknownBranchName()`：手工写入 `branchID: "gone"` 的号票 → Store 正常加载，`BranchCatalog.displayName(branchID: "gone") == "网点已停用"`。

- [ ] **Step 2: 运行确认失败** — `scripts/check_banking_data.sh`，预期编译错误。

- [ ] **Step 3: 实现两个 Store。** 每次写操作：用 `dates.now` 重新校验 → 构造新 records → 编码写入（`dataWriter` 或 defaults）→ 成功后替换内存并发通知。`id` 用 `UUID().uuidString`；预约码种子为 `id`。

- [ ] **Step 4: 运行通过** — `scripts/check_banking_data.sh`，预期全部通过。

- [ ] **Step 5: 提交** — `git commit -m "feat: 新增城市选择与网点记录存储"`

---

### Task 3: 城市选择、网点列表、网点详情与示意图

**Files:**
- Create: `ABank/Features/BranchService/CityPickerViewController.swift`
- Create: `ABank/Features/BranchService/BranchListViewController.swift`
- Create: `ABank/Features/BranchService/BranchDetailViewController.swift`
- Create: `ABank/Features/BranchService/Views/BranchSketchMapView.swift`
- Create: `ABank/Features/BranchService/Views/BranchServiceViews.swift`（`BranchStatusTagView`、`BranchRowView`、`BusinessHoursTableView`、`ActiveTicketBannerView`）
- Modify: `ABank/Core/Routing/AppRoute.swift`、`ABank/Core/Routing/AppRouter.swift`

**Interfaces:**
- Consumes: Task 1/2。
- Produces: `AppRoute` 新增 `.cityPicker`、`.branchList`、`.branchDetail(branchID: String)`。列表的“我的记录”、有效号横幅点击、详情的“取号”“预约”按钮在 Task 4/5 接上。
  - `BranchSketchMapView`：`func configure(branches: [Branch], highlightedID: String?)`、`var onPinTapped: ((String) -> Void)?`；用 `CAShapeLayer` 画浅色街道网格 + 若干主干道，标记用 `abc_branch_location`（fallback `mappin.circle.fill`），高亮标记放大且为 `abankPrimary`。
  - 每个页面实现 `RouteHosting`。

- [ ] **Step 1: 路由** — `AppRoute` 加 `.cityPicker`、`.branchList`、`.branchDetail(branchID:)`；`AppRouter.makeViewController` 对应构造（注入 `.shared` Store）。
- [ ] **Step 2: 城市选择页** — 按 spec §4.1；选中后 `select` 成功则 pop，失败 toast“保存失败，请稍后重试”。
- [ ] **Step 3: 列表页** — 按 spec §4.1：城市按钮（→ `.cityPicker`）、有效号横幅（此步只显示）、示意图、筛选（全部 / 营业中 / 个人现金 / 个人非现金 / 对公）、行、空态“当前城市暂无符合条件的网点”。监听两个 Store 通知与 `viewWillAppear` 重算。点标记 → 高亮并滚动到行；点行 → `.branchDetail`。
- [ ] **Step 4: 详情页** — 按 spec §4.1：示意图单标记、状态、地址、电话（toast“演示环境不拨打电话”）、本周营业时间（周一到周日，今天高亮，休息日“休息”，自助“24 小时自助服务”）、业务标签、底部“取号”“预约”（此任务先禁用并在 Task 4/5 接上）。未知 ID 显示空态“网点不存在”。
- [ ] **Step 5: 构建** — 按开发计划的 `xcodebuild … CODE_SIGNING_ALLOWED=NO build`，预期 `BUILD SUCCEEDED`；`scripts/check_banking_data.sh` 仍通过。
- [ ] **Step 6: 提交** — `git commit -m "feat: 新增城市选择与网点列表详情"`

---

### Task 4: 取号与号票详情

**Files:**
- Create: `ABank/Features/BranchService/TakeTicketViewController.swift`
- Create: `ABank/Features/BranchService/TicketDetailViewController.swift`
- Modify: `AppRoute.swift`、`AppRouter.swift`、`BranchListViewController.swift`（横幅点击）、`BranchDetailViewController.swift`（“取号”按钮）

**Interfaces:**
- Consumes: Task 2 `takeTicket`、`cancelTicket`、`activeTicket`、`status(of:)`、`queueAhead`；Task 3 页面。
- Produces: `AppRoute` 新增 `.branchQueue`、`.takeTicket(branchID: String)`、`.ticketDetail(ticketID: String)`；`.branchQueue` 在 `makeViewController` 中：`activeTicket` 存在 → `TicketDetailViewController`，否则 `BranchListViewController`。

- [ ] **Step 1: 路由三条** 并接线。
- [ ] **Step 2: 详情页“取号”** — 仅 `openState.allowsTicket` 且有取号业务时可用；否则禁用并在按钮上方显示原因（“网点当前未营业，可预约其他时间”或“自助网点不提供柜面取号”）。已有有效号时点击 → toast“您已有一张有效号票”并直接打开号票详情。
- [ ] **Step 3: 取号页** — 业务单选、“当前前方约 N 人”、“确认取号”；成功后用号票详情替换当前页（`setViewControllers` 去掉取号页）；错误 toast `errorDescription`，`activeTicketExists` 时附带跳转号票详情。
- [ ] **Step 4: 号票详情** — 大号码、业务、网点（`displayName`）、取号时间、状态、前方人数、预计等待 `ahead × 3` 分钟；有效时“取消取号”确认框“确定取消该号票？”（取消 / 确定）；`Timer` 每 30 秒只重算显示，`viewWillDisappear` 失效。未知 ID 空态“记录不存在”。
- [ ] **Step 5: 列表横幅** 点击 → `.ticketDetail`。
- [ ] **Step 6: 构建** 通过；检查脚本通过。
- [ ] **Step 7: 提交** — `git commit -m "feat: 新增网点取号与号票详情"`

---

### Task 5: 预约、结果与历史

**Files:**
- Create: `ABank/Features/BranchService/ReservationFormViewController.swift`
- Create: `ABank/Features/BranchService/ReservationResultViewController.swift`
- Create: `ABank/Features/BranchService/BranchServiceHistoryViewController.swift`
- Create: `ABank/Features/BranchService/Views/ReservationPickerViews.swift`（日期条、时段宫格、数量步进器）
- Modify: `AppRoute.swift`、`AppRouter.swift`、`BranchListViewController.swift`（“我的记录”）、`BranchDetailViewController.swift`（“预约”按钮）

**Interfaces:**
- Consumes: Task 2 `reserve`、`cancelReservation`、`cancelTicket`、`status(of:)`；Task 1 `reservableDays`、`slots`、`displayName`。
- Produces: `AppRoute` 新增 `.branchReservation(business: BranchBusiness?, branchID: String?)`、`.branchServiceHistory`。`ReservationResultViewController(reservation: BranchReservation, store:)` 由表单直接 push（不建路由）。

- [ ] **Step 1: 路由两条** 并接线（详情页“预约”→ `.branchReservation(business: nil, branchID: id)`，自助网点禁用；列表“我的记录”→ 历史）。
- [ ] **Step 2: 预约表单** — 按 spec §4.1：业务（`reservationBusinesses`，预选或默认 `personalNonCash`；指定网点时只列该网点支持的业务）、网点（默认当前城市第一个支持该业务的网点；点击弹出当前城市支持该业务的网点列表；切换业务时若当前网点不支持则换为默认）、日期条、时段宫格、纪念币步进器（1–20，默认 1）、“提交预约”（未选时段时禁用）。无网点支持时空态“当前城市暂无可预约该业务的网点”。`slotUnavailable` 时 toast 并刷新时段、清空所选。
- [ ] **Step 3: 结果页** — 成功图标、预约码、业务、网点、日期时段（如 `11月09日 周一 10:00-11:00`）、数量（纪念币）；“查看记录”→ 历史；“完成”→ pop 到表单之前的页面。
- [ ] **Step 4: 历史页** — 分段“取号 / 预约”，倒序；行显示网点（`displayName`）、业务、时间与状态标签；有效记录行尾“取消”按钮 + 确认框；取号行点击 → 号票详情；空态“暂无记录”；监听记录通知刷新。
- [ ] **Step 5: 构建** 通过；检查脚本通过。
- [ ] **Step 6: 提交** — `git commit -m "feat: 新增网点预约与服务记录"`

---

### Task 6: 功能目录、首页/我的/生活联动

**Files:**
- Modify: `ABank/Features/AllFeatures/Models/FeatureCatalog.swift`（5 项改 `.available`，删除 `branchStage`）
- Modify: `scripts/check_feature_catalog.swift`（可用数 19 → 24，新增 5 条路由断言）
- Create: `ABank/Features/BranchService/Models/BranchCardSummary.swift`
- Modify: `ABank/Data/MockDataProvider.swift`（首页/我的网点卡、生活城市改读 Store）
- Modify: `ABank/Features/Home/HomeViewController.swift`、`ABank/Features/Mine/MineViewController.swift`、`ABank/Features/Life/LifeViewController.swift`、`ABank/Features/Life/Views/LifeSearchBarView.swift`
- Modify: `scripts/check_branch_services.swift`、`scripts/check_banking_data.sh`（sources 加 `BranchCardSummary.swift`）

**Interfaces:**
- Consumes: Task 1–5。
- Produces:
  - `nonisolated struct BranchCardSummary: Equatable { let branchID, name, status, distanceText, address: String; static func make(cityID: String, at: Date, dates: BankingDateContext) -> BranchCardSummary }`（`distanceText` 为 `"\(meters)米"`；`status` 为 `BranchOpenState.title`）
  - `MockDataProvider`：`func homeBranchInfo() -> HomeBranchInfo`、`func mineBranchInfo() -> MineBranchInfo`（读当前城市；首页距离显示 `"距您约" + distanceText`），原 page data 内的 `branch` 改由它们生成。
  - `LifeSearchBarView.setCity(_ name: String)`

- [ ] **Step 1: 写失败检查** — `check_feature_catalog.swift`：`filter(\.isAvailable).count == 24`；`branchQuery → .branchList`、`branchQueue → .branchQueue`、`openCard → .branchReservation(business: .openCard, branchID: nil)`、`sameNumberReplace → … .sameNumberReplace …`、`coinReservation → … .commemorativeCoin …`。`check_branch_services.swift` 新增 `cardSummary()`：西安周五 10:00 → name “西安沣东新城支行”、status “营业中”、distanceText “2552米”；北京 → 北京默认网点名。
- [ ] **Step 2: 运行确认失败。**
- [ ] **Step 3: 实现** 目录改动与 `BranchCardSummary`。
- [ ] **Step 4: 运行通过** — `scripts/check_banking_data.sh` 全部通过。
- [ ] **Step 5: 页面联动** — 首页、我的：网点卡配置改为调用 provider 方法，在 `viewWillAppear` 和城市通知时重配；刷新按钮重配后 toast“已刷新”。生活：城市名读 `CitySelectionStore.shared.currentCity.name`，城市按钮 `router.open(.cityPicker, from:)`，城市通知时 `setCity`。
- [ ] **Step 6: 构建** 通过。
- [ ] **Step 7: 提交** — `git commit -m "feat: 开放网点服务入口并统一城市"`

---

### Task 7: 模拟器验收、全分支审查与文档

**Files:**
- Modify: `docs/development-plan.md`（M5 行改“已完成”，新增“M5 实施记录”与“下一会话：M6”）
- Create: `docs/continuity/tasks/m5-branch-services.md`；Modify: `docs/continuity/CURRENT.md`（索引加入 M5）
- 截图：`artifacts/abc-resources/verification/m5-*.png`（Git 忽略）

- [ ] **Step 1: 全量检查** — `scripts/check_banking_data.sh`、正常构建、`git diff --check main...HEAD`，全部通过。
- [ ] **Step 2: 模拟器验收**（先 `xcrun simctl list devices booted` 查当前设备，不复用历史 ID），按 spec §6 清单逐项操作并截图：`m5-entry`、`m5-city-picker`、`m5-life-city`、`m5-branch-list`、`m5-branch-filter`、`m5-branch-detail`、`m5-ticket`、`m5-ticket-duplicate`、`m5-reservation-coin`、`m5-reservation-result`、`m5-history`、`m5-home-card`、`m5-mine-card`；重启 App 后确认城市与记录保持。验收后删除模拟器上两个存储键，或在交接中写明保留内容。
- [ ] **Step 3: 全分支审查** — 用 superpowers:requesting-code-review 对 `main...HEAD` 审查；Critical/Important 修复后重新构建与检查，Minor 记入交接。
- [ ] **Step 4: 更新文档** — 开发计划与任务记录写明：完成内容、验证结果、未验证项（320pt 宽度、原版截图校准、叫号/完成仅脚本验证）、下一步；不写 token、Cookie 或个人敏感数据。
- [ ] **Step 5: 提交** — `git commit -m "docs: 记录 M5 网点服务实施与验证结果"`；不推送、不合并。
