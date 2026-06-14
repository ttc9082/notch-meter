import Foundation

public enum CodexUsageSourceMode: String, Sendable {
    case auto
    case local
    case remote
}

public enum CodexRemoteUsageError: Error, Equatable {
    case missingConfiguration
    case invalidURL
    case requestFailed(Int)
    case emptyResponse
}

extension CodexRemoteUsageError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Remote Codex Analytics is not configured."
        case .invalidURL:
            return "Remote Codex Analytics URL is invalid."
        case .requestFailed(let status):
            return "Remote Codex Analytics request failed with HTTP \(status)."
        case .emptyResponse:
            return "Remote Codex Analytics returned no usage data."
        }
    }
}

public final class CodexUsageService: @unchecked Sendable {
    private let mode: CodexUsageSourceMode
    private let localReader: CodexUsageReader
    private let remoteReader: CodexAnalyticsUsageReader?

    public convenience init(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        localReader: CodexUsageReader = CodexUsageReader()
    ) {
        let mode = CodexUsageSourceMode(
            rawValue: environment["NOTCHMETER_CODEX_SOURCE"]?.lowercased() ?? ""
        ) ?? .auto

        let remoteReader = CodexAnalyticsUsageReader(environment: environment)
        self.init(mode: mode, localReader: localReader, remoteReader: remoteReader)
    }

    public init(
        mode: CodexUsageSourceMode,
        localReader: CodexUsageReader,
        remoteReader: CodexAnalyticsUsageReader?
    ) {
        self.mode = mode
        self.localReader = localReader
        self.remoteReader = remoteReader
    }

    public func todaySnapshot(now: Date = Date()) async throws -> CodexUsageSnapshot {
        switch mode {
        case .local:
            return try localReader.todaySnapshot(now: now)
        case .remote:
            return try await remoteSnapshot(now: now)
        case .auto:
            do {
                return try await remoteSnapshot(now: now)
            } catch {
                return try localReader.todaySnapshot(now: now)
            }
        }
    }

    private func remoteSnapshot(now: Date) async throws -> CodexUsageSnapshot {
        guard let remoteReader else {
            throw CodexRemoteUsageError.missingConfiguration
        }

        var snapshot = try await remoteReader.todaySnapshot(now: now)

        if snapshot.rateLimits == nil {
            let localSnapshot = try? localReader.todaySnapshot(now: now)
            snapshot.rateLimits = localSnapshot?.rateLimits
            snapshot.lastUsage = snapshot.lastUsage ?? localSnapshot?.lastUsage
        }

        return snapshot
    }
}

public final class CodexAnalyticsUsageReader: @unchecked Sendable {
    public let apiKey: String
    public let workspaceID: String
    public let baseURL: URL
    public let calendar: Calendar

    public convenience init?(environment: [String: String] = ProcessInfo.processInfo.environment) {
        guard let apiKey = environment["NOTCHMETER_CODEX_ANALYTICS_API_KEY"],
              let workspaceID = environment["NOTCHMETER_CODEX_WORKSPACE_ID"],
              !apiKey.isEmpty,
              !workspaceID.isEmpty else {
            return nil
        }

        let baseURL = environment["NOTCHMETER_CODEX_ANALYTICS_BASE_URL"]
            .flatMap(URL.init(string:))
            ?? URL(string: "https://api.chatgpt.com/v1/analytics/codex")!

        self.init(apiKey: apiKey, workspaceID: workspaceID, baseURL: baseURL)
    }

    public init(
        apiKey: String,
        workspaceID: String,
        baseURL: URL = URL(string: "https://api.chatgpt.com/v1/analytics/codex")!,
        calendar: Calendar = .current
    ) {
        self.apiKey = apiKey
        self.workspaceID = workspaceID
        self.baseURL = baseURL
        self.calendar = calendar
    }

    public func todaySnapshot(now: Date = Date()) async throws -> CodexUsageSnapshot {
        let start = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
        return try await snapshot(start: start, end: end, groupBy: "day")
    }

    public func snapshot(start: Date, end: Date, groupBy: String = "day") async throws -> CodexUsageSnapshot {
        var page: String?
        var aggregate = AnalyticsAggregate()
        var pagesRead = 0

        repeat {
            let payload = try await fetchUsagePage(start: start, end: end, groupBy: groupBy, page: page)
            aggregate.merge(payload.aggregate)
            page = payload.nextPage
            pagesRead += 1
        } while page != nil && pagesRead < 10

        guard aggregate.rows > 0 || aggregate.usage != .zero else {
            throw CodexRemoteUsageError.emptyResponse
        }

        return CodexUsageSnapshot(
            scannedFiles: 0,
            sessionsWithUsage: aggregate.rows,
            totalUsage: aggregate.usage,
            lastUsage: nil,
            rateLimits: nil,
            newestEventDate: Date()
        )
    }

    private func fetchUsagePage(
        start: Date,
        end: Date,
        groupBy: String,
        page: String?
    ) async throws -> AnalyticsPage {
        let endpoint = baseURL
            .appendingPathComponent("workspaces")
            .appendingPathComponent(workspaceID)
            .appendingPathComponent("usage")
        var components = URLComponents(
            url: endpoint,
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "start_time", value: "\(Int(start.timeIntervalSince1970))"),
            URLQueryItem(name: "end_time", value: "\(Int(end.timeIntervalSince1970))"),
            URLQueryItem(name: "group_by", value: groupBy),
            URLQueryItem(name: "group", value: "workspace"),
            URLQueryItem(name: "limit", value: "100")
        ]

        if let page {
            components?.queryItems?.append(URLQueryItem(name: "page", value: page))
        }

        guard let url = components?.url else {
            throw CodexRemoteUsageError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse,
           !(200..<300).contains(http.statusCode) {
            throw CodexRemoteUsageError.requestFailed(http.statusCode)
        }

        let json = try JSONSerialization.jsonObject(with: data)
        return AnalyticsPage(json: json)
    }
}

private struct AnalyticsPage {
    var aggregate: AnalyticsAggregate
    var nextPage: String?

    init(json: Any) {
        let rows = Self.rows(in: json)
        if rows.isEmpty {
            aggregate = AnalyticsAggregate(object: json)
        } else {
            aggregate = rows.reduce(into: AnalyticsAggregate()) { partial, row in
                partial.merge(AnalyticsAggregate(object: row))
            }
            aggregate.rows = rows.count
        }
        nextPage = Self.nextPage(in: json)
    }

    private static func rows(in json: Any) -> [[String: Any]] {
        guard let object = json as? [String: Any] else {
            return []
        }

        for key in ["data", "rows", "items", "results"] {
            if let rows = object[key] as? [[String: Any]] {
                return rows
            }
        }

        if let page = object["page"] as? [String: Any] {
            for key in ["data", "rows", "items", "results"] {
                if let rows = page[key] as? [[String: Any]] {
                    return rows
                }
            }
        }

        return []
    }

    private static func nextPage(in json: Any) -> String? {
        guard let object = json as? [String: Any] else {
            return nil
        }

        if let next = object["next_page"] as? String, !next.isEmpty {
            return next
        }

        if let page = object["page"] as? [String: Any],
           let hasMore = page["has_more"] as? Bool,
           hasMore,
           let next = page["next_page"] as? String,
           !next.isEmpty {
            return next
        }

        return nil
    }
}

private struct AnalyticsAggregate {
    var rows = 0
    var usage = TokenUsage.zero

    init() {}

    init(object: Any) {
        rows = 1
        usage = TokenUsage(
            inputTokens: Self.sum(keys: inputKeys, in: object),
            cachedInputTokens: Self.sum(keys: cachedInputKeys, in: object),
            outputTokens: Self.sum(keys: outputKeys, in: object),
            reasoningOutputTokens: Self.sum(keys: reasoningKeys, in: object),
            totalTokens: Self.sum(keys: totalKeys, in: object)
        )

        if usage.totalTokens == 0 {
            usage.totalTokens = usage.inputTokens + usage.outputTokens
        }
    }

    mutating func merge(_ other: AnalyticsAggregate) {
        rows += other.rows
        usage = usage + other.usage
    }

    private static func sum(keys: Set<String>, in value: Any) -> Int {
        if let object = value as? [String: Any] {
            return object.reduce(0) { total, item in
                let key = item.key.normalizedAnalyticsKey
                let direct = keys.contains(key) ? number(item.value) : 0
                return total + direct + sum(keys: keys, in: item.value)
            }
        }

        if let array = value as? [Any] {
            return array.reduce(0) { $0 + sum(keys: keys, in: $1) }
        }

        return 0
    }

    private static func number(_ value: Any) -> Int {
        if let int = value as? Int {
            return int
        }
        if let double = value as? Double {
            return Int(double)
        }
        if let string = value as? String, let double = Double(string) {
            return Int(double)
        }
        return 0
    }
}

private let inputKeys: Set<String> = [
    "inputtokens",
    "textinputtokens",
    "textinputtokencount"
]

private let cachedInputKeys: Set<String> = [
    "cachedinputtokens",
    "cachedtextinputtokens",
    "textcachedinputtokens",
    "cachedinputtokencount"
]

private let outputKeys: Set<String> = [
    "outputtokens",
    "textoutputtokens",
    "textoutputtokencount"
]

private let reasoningKeys: Set<String> = [
    "reasoningoutputtokens",
    "reasoningoutputtokencount"
]

private let totalKeys: Set<String> = [
    "totaltokens",
    "texttokens",
    "tokencount"
]

private extension String {
    var normalizedAnalyticsKey: String {
        lowercased().filter { $0.isLetter || $0.isNumber }
    }
}
