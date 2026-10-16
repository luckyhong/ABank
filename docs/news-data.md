# 资讯模块：动态新闻数据与本地降级

## 目标与范围

资讯模块现在读取公开新闻订阅，金融业务继续使用本地模拟数据。没有银行账户、支付或贷款接口，没有服务端、账号或 API Key。

原实现存在固定日期/标题、随机生成的翻页内容、无实际筛选的频道按钮、虚构阅读量与互动人数，以及文章点击只弹提示等问题。旧资讯 Mock 工厂已移除，统一使用 `Features/News/Data` 中的数据链路。

## 来源与更新

来源为[中国新闻网官方 RSS 订阅页](https://www.chinanews.com.cn/rss/)列出的公开频道：

| 频道 | 地址 | 用途 |
| --- | --- | --- |
| 财经 | `https://www.chinanews.com.cn/rss/finance.xml` | 财经轮播、主信息流、基金/黄金/保险/房产关键词筛选 |
| 即时 | `https://www.chinanews.com.cn/rss/scroll-news.xml` | 补充新闻、三农关键词匹配及完整搜索范围 |
| 生活 | `https://www.chinanews.com.cn/rss/life.xml` | 服务频道、生活关注内容 |
| 视频 | `https://www.chinanews.com.cn/rss/sp.xml` | 真实视频标题与原文入口 |

这批订阅无需 Key，已在本机及模拟器实际验证；属于公开 RSS，不是有稳定性承诺的商业 API。标题、摘要和发布时间来自订阅源，原文在发布方网站打开。不会伪造实时行情、涨跌幅或官方政策。

- 打开资讯页面时更新；同一天自动请求间隔至少 15 分钟，返回前台/跨日时检查。下拉刷新可主动重试。
- 财经内容优先用于轮播；“热点”优先展示财经与生活，缺少这两个频道时显示其他可用新闻。全部内容保留真实发布时间与来源。
- 服务按生活频道筛选；三农、基金、黄金、保险、房产以标题/摘要关键词筛选；基金、黄金仅从财经频道匹配，减少生活资讯的同名关键词误判。不匹配就显示空态，不用其他频道凑数。这是本地分类，不冒充出版方提供的精确金融标签。
- 按原文 URL 去重，按发布时间排序。每次展示 20 条，在已获取的快照中追加分页；到底显示完结，不伪造远程分页和无限新内容。频道内容较少时补足滚动区域，使分类栏仍能吸顶；移除没有广告内容的旧广告标签。
- 推荐、快讯、最新资讯、关注页近期资讯来自同一快照。消息数为零，实时文章不展示编造的阅读量；“热榜”改为“最新资讯”。

## 缓存与降级

`NewsRepository` 为 actor，四个频道并行请求，每个请求 12 秒超时，RSS 最大 2MB、每频道最多保留 80 条。公开元数据缓存到系统 Caches 下 `ABankNews/feeds-v1.json`，用 JSON 版本号和原子写入保护文件。

1. 先显示已有缓存，后台更新。
2. 某个频道失败时保留该频道未过期的缓存，其他频道可以正常更新；页面提示“部分频道暂不可用”。
3. 全部失败时使用 7 天内缓存，并标记“离线缓存”及上次更新时间。
4. 首次离线、无有效缓存时使用 `NewsDemoContent` 的金融常识，标记“学习示例 / 非实时新闻”。示例没有伪造新闻日期、媒体署名和原文链接，按北京时间的日期轮换排序；不将同一篇旧新闻改成今天发布。

刷新任务取消与请求代次共同防止旧结果覆盖新结果；取消的请求不写入仓库缓存。数据快照与频道选择分开，刷新完成按当前频道/关注状态重新筛选。

解析兼容订阅中的未转义 `&`（实测财经源标题存在 `R&D`）；禁用外部实体，处理 CDATA、HTML 标签和常见实体，拒绝空标题、不安全链接、无法解析的日期及超出当前时间 5 分钟以上的新闻。

## 配图与阅读

这批 RSS 通常没有直接提供图片。文章无配图时采用纯文字列表，不用无关照片装饰。轮播在无配图时保留原生渐变底，使用真实标题与来源。

视频封面分阶段补齐：新闻先呈现，再读取最多四个视频原文页面的公开 `vList` 封面元数据。必须与当前新闻 URL 的 path 精确匹配，避免误取页面中的推荐视频、广告或网站 Logo；页面结构变化或请求失败时继续使用原有视频占位图。封面链接随新闻元数据缓存，不自动播放视频。

`NewsRemoteImageView` 支持复用取消/代次核对、缓存和 ImageIO 下采样（最大 1000 像素），图片响应超过 8MB 时不解码，内存图片缓存预算为 16MB。所有链接只允许 HTTP/HTTPS，HTTP 地址升级为 HTTPS；没有放宽 ATS。

点击轮播、快讯、最新资讯条目、视频和正文进入原生摘要页；“查看原文 / 观看视频”打开 `SFSafariViewController`。只保存 RSS 提供的短摘要，不搬运整篇新闻正文。

搜索在当前已加载快照的标题、摘要、来源中匹配，不冒充全网搜索。关注为本地主题订阅，可单项关注/取消、一键关注并保存；“阅读偏好”仅用于本机浏览，没有伪造多人投票或关注真实媒体账户。

## 代码结构

| 文件 | 责任 |
| --- | --- |
| `NewsStory.swift` | 可序列化新闻、频道、筛选和每日知识示例 |
| `NewsRSSParser.swift` | XML 解析、字段标准化、日期及 URL 验证 |
| `NewsCoverMetadata.swift` | 只提取路径匹配的视频封面 |
| `NewsRepository.swift` | 并行请求、逐源缓存、部分失败和降级 |
| `NewsDashboard.swift` | 将统一快照映射到现有页面模型，不制造业务数据 |
| `NewsViewController.swift` | 刷新、选择、有限分页、关注与搜索导航 |
| `NewsStoryViewController.swift` | 原生摘要、搜索/新闻列表、原文阅读 |

## 验证

`xcodebuild -workspace ABank.xcworkspace -scheme ABank -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/ABank-ResourceBuild CODE_SIGNING_ALLOWED=NO build`

独立数据检查不依赖新增 Xcode 测试 target：

```sh
xcrun swiftc -module-cache-path /private/tmp/abank-news-module-cache \
  -swift-version 5 -default-isolation MainActor -parse-as-library \
  ABank/Features/News/Data/NewsStory.swift \
  ABank/Features/News/Data/NewsRSSParser.swift \
  ABank/Features/News/Data/NewsCoverMetadata.swift \
  ABank/Features/News/Data/NewsRepository.swift \
  scripts/check_news_data.swift -o /private/tmp/abank-news-data-checks
/private/tmp/abank-news-data-checks
```

覆盖 CDATA、实体/未转义字符、重复 URL、无效 URL、未来日期、无效 XML、体积限制、解析器复用、封面与新闻路径匹配、本地分类、每日示例、部分源失败、持久缓存、缓存过期、取消刷新。还以实际下载的四份 RSS 验证解析，本次返回财经 30、即时 30、生活 23、视频 30 条（订阅会持续变化，不以该数量作固定断言）。

模拟器已确认四频道在线加载、真实封面补齐；通过临时预览检查正文流、频道筛选、关注、详情、搜索结果和离线示例。截图位于 `artifacts/abc-resources/verification/news-*.png`。状态预览不等同于所有手势和 Safari 外部网站的完整点击回归；独立数据检查使用 URLProtocol 模拟网络故障。临时预览代码在交付前移除，正常首页入口保持不变。
