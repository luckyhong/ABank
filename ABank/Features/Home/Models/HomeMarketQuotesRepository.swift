import Foundation
import OSLog

nonisolated struct HomeMarketQuote: Codable, Sendable {
    let amount: Double
    let day: String
}

nonisolated struct HomeMarketQuotes: Codable, Sendable {
    var usd: HomeMarketQuote?
    var gold: HomeMarketQuote?
    var usdIsCached = true
    var goldIsCached = true

    var needsRetry: Bool { usd == nil || gold == nil || usdIsCached || goldIsCached }

    private enum CodingKeys: String, CodingKey { case usd, gold }
}

/// 首页公开参考价。只缓存价格和来源日期，不读取账户或交易数据。
actor HomeMarketQuotesRepository {
    nonisolated static let refreshInterval: TimeInterval = 30 * 60
    nonisolated static let retryInterval: TimeInterval = 60
    private static let logger = Logger(subsystem: "ABank", category: "MarketQuotes")
    static let shared = HomeMarketQuotesRepository()

    private let session: URLSession
    private let cacheURL: URL
    private var quotes: HomeMarketQuotes
    private var lastAttempt: Date?
    private var inFlight: Task<HomeMarketQuotes, Never>?

    init(session: URLSession? = nil, cacheURL: URL = HomeMarketQuotesRepository.defaultCacheURL) {
        self.session = session ?? Self.makeSession()
        self.cacheURL = cacheURL
        quotes = (try? JSONDecoder().decode(HomeMarketQuotes.self, from: Data(contentsOf: cacheURL))) ?? HomeMarketQuotes()
    }

    private static var defaultCacheURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ABankMarket", isDirectory: true)
            .appendingPathComponent("frankfurter-v1.json")
    }

    private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpShouldSetCookies = false
        configuration.urlCredentialStorage = nil
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 12
        return URLSession(configuration: configuration)
    }

    func currentQuotes(now: Date = Date()) -> HomeMarketQuotes {
        var result = quotes
        if let usd = result.usd, !Self.isUsable(usd, now: now) { result.usd = nil }
        if let gold = result.gold, !Self.isUsable(gold, now: now) { result.gold = nil }
        return result
    }

    func refresh(now: Date = Date(), force: Bool = false) async -> HomeMarketQuotes {
        if let inFlight { return await inFlight.value }
        let current = currentQuotes(now: now)
        let interval = current.needsRetry ? Self.retryInterval : Self.refreshInterval
        if !force, let lastAttempt, abs(now.timeIntervalSince(lastAttempt)) < interval {
            return current
        }

        lastAttempt = now
        let task = Task { await update(now: now) }
        inFlight = task
        return await task.value
    }

    private func update(now: Date) async -> HomeMarketQuotes {
        defer { inFlight = nil }

        async let usd = Self.fetchIfAvailable(.usd, session: session, now: now)
        async let gold = Self.fetchIfAvailable(.gold, session: session, now: now)
        let (newUSD, newGold) = await (usd, gold)
        quotes = currentQuotes(now: now)
        quotes.usdIsCached = true
        quotes.goldIsCached = true

        if let newUSD, newUSD.day >= (quotes.usd?.day ?? "") {
            quotes.usd = newUSD
            quotes.usdIsCached = false
        }
        if let newGold, newGold.day >= (quotes.gold?.day ?? "") {
            quotes.gold = newGold
            quotes.goldIsCached = false
        }

        if !quotes.usdIsCached || !quotes.goldIsCached {
            try? FileManager.default.createDirectory(at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? JSONEncoder().encode(quotes).write(to: cacheURL, options: .atomic)
        }
        return quotes
    }

    private nonisolated enum Asset: String, Sendable {
        case usd = "USD"
        case gold = "XAU"
    }

    private nonisolated struct RateResponse: Decodable {
        let date: String
        let base: String
        let quote: String
        let rate: Double
    }

    private static func fetchIfAvailable(_ asset: Asset, session: URLSession, now: Date) async -> HomeMarketQuote? {
        do {
            return try await fetch(asset, session: session, now: now)
        } catch {
            let failure = error as NSError
            logger.notice("Quote request failed: \(asset.rawValue, privacy: .public) \(failure.domain, privacy: .public) (\(failure.code, privacy: .public))")
            return nil
        }
    }

    private static func fetch(_ asset: Asset, session: URLSession, now: Date) async throws -> HomeMarketQuote {
        let url = URL(string: "https://api.frankfurter.dev/v2/rate/\(asset.rawValue)/CNY")!
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard http.statusCode == 200 else {
            throw NSError(domain: "MarketQuoteHTTP", code: http.statusCode)
        }
        let payload = try JSONDecoder().decode(RateResponse.self, from: data)
        guard payload.base == asset.rawValue, payload.quote == "CNY" else {
            throw URLError(.cannotDecodeContentData)
        }

        // 100 USD 和 1 克黄金分别对应界面的两个单位。
        let amount = asset == .usd ? payload.rate * 100 : payload.rate / 31.1034768
        let quote = HomeMarketQuote(amount: amount, day: payload.date)
        guard isUsable(quote, now: now) else {
            throw URLError(.cannotDecodeContentData)
        }
        return quote
    }

    private static func isUsable(_ quote: HomeMarketQuote, now: Date) -> Bool {
        let dates = BankingDateContext.system
        guard quote.amount.isFinite, quote.amount > 0,
              let day = dates.date(from: quote.day) else { return false }
        let today = dates.calendar.startOfDay(for: now)
        guard let oldestDay = dates.calendar.date(byAdding: .day, value: -7, to: today) else { return false }
        return day >= oldestDay && day <= today
    }
}
