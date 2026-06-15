import Foundation

public enum CodexUsageSourceMode: String, Sendable {
    case auto
    case local
    case remote
}

public enum CodexRemoteUsageError: Error, Equatable {
    case missingCredentials
    case invalidURL
    case requestFailed(Int)
    case refreshFailed(Int)
    case unrecoverableRefresh
    case emptyResponse
}

extension CodexRemoteUsageError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "Codex subscription credentials are missing. Sign in with Codex, or configure NOTCHMETER_CODEX_ACCESS_TOKEN."
        case .invalidURL:
            return "Codex subscription usage URL is invalid."
        case .requestFailed(let status):
            return "Codex subscription usage request failed with HTTP \(status)."
        case .refreshFailed(let status):
            return "Codex token refresh failed with HTTP \(status)."
        case .unrecoverableRefresh:
            return "Codex refresh token is invalid or expired. Please sign in again."
        case .emptyResponse:
            return "Codex subscription usage returned no quota data."
        }
    }
}

public final class CodexUsageService: @unchecked Sendable {
    private let mode: CodexUsageSourceMode
    private let localReader: CodexUsageReader
    private let codexReader: CodexSubscriptionUsageReader
    private let claudeReader: ClaudeSubscriptionUsageReader

    public convenience init(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        localReader: CodexUsageReader = CodexUsageReader()
    ) {
        let mode = CodexUsageSourceMode(
            rawValue: environment["NOTCHMETER_CODEX_SOURCE"]?.lowercased() ?? ""
        ) ?? .auto

        self.init(
            mode: mode,
            localReader: localReader,
            codexReader: CodexSubscriptionUsageReader(environment: environment),
            claudeReader: ClaudeSubscriptionUsageReader(environment: environment)
        )
    }

    public init(
        mode: CodexUsageSourceMode,
        localReader: CodexUsageReader,
        codexReader: CodexSubscriptionUsageReader,
        claudeReader: ClaudeSubscriptionUsageReader
    ) {
        self.mode = mode
        self.localReader = localReader
        self.codexReader = codexReader
        self.claudeReader = claudeReader
    }

    public func todaySnapshot(
        provider: AgentUsageProvider = .codex,
        now: Date = Date()
    ) async throws -> CodexUsageSnapshot {
        switch mode {
        case .local:
            return try localSnapshot(provider: provider, now: now)
        case .remote:
            return try await remoteSnapshot(provider: provider, now: now)
        case .auto:
            do {
                return try await remoteSnapshot(provider: provider, now: now)
            } catch {
                if hasRemoteCredentials(provider: provider) {
                    throw error
                }
                return try localSnapshot(provider: provider, now: now)
            }
        }
    }

    private func hasRemoteCredentials(provider: AgentUsageProvider) -> Bool {
        switch provider {
        case .codex:
            return codexReader.hasCredentials()
        case .claude:
            return claudeReader.hasCredentials()
        }
    }

    private func localSnapshot(provider: AgentUsageProvider, now: Date) throws -> CodexUsageSnapshot {
        var snapshot = try localReader.todaySnapshot(now: now)
        snapshot.source = UsageDataSource(provider: provider, mode: .local)
        return snapshot
    }

    private func remoteSnapshot(provider: AgentUsageProvider, now: Date) async throws -> CodexUsageSnapshot {
        var snapshot: CodexUsageSnapshot
        switch provider {
        case .codex:
            snapshot = try await codexReader.todaySnapshot(now: now)
        case .claude:
            snapshot = try await claudeReader.todaySnapshot(now: now)
        }
        snapshot.source = UsageDataSource(provider: provider, mode: .remote)

        if provider == .codex, snapshot.totalUsage == .zero {
            let localSnapshot = try? localReader.todaySnapshot(now: now)
            snapshot.totalUsage = localSnapshot?.totalUsage ?? .zero
            snapshot.lastUsage = snapshot.lastUsage ?? localSnapshot?.lastUsage
            snapshot.newestEventDate = snapshot.newestEventDate ?? localSnapshot?.newestEventDate
        }

        return snapshot
    }
}

public final class CodexSubscriptionUsageReader: @unchecked Sendable {
    private static let clientID = "app_EMoamEEZ73f0CkXaXp7hrann"

    public let usageURL: URL
    public let tokenURL: URL
    public let authFileURL: URL
    private let environmentCredentials: CodexOAuthCredentials?
    private let credentialStore: AgentOAuthFileStore

    public convenience init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let authFileURL = environment["CODEX_HOME"]
            .map { URL(fileURLWithPath: $0, isDirectory: true).appendingPathComponent("auth.json") }
            ?? home.appendingPathComponent(".codex/auth.json")

        let usageURL = environment["NOTCHMETER_CODEX_USAGE_URL"]
            .flatMap(URL.init(string:))
            ?? URL(string: "https://chatgpt.com/backend-api/wham/usage")!
        let tokenURL = environment["NOTCHMETER_CODEX_TOKEN_URL"]
            .flatMap(URL.init(string:))
            ?? URL(string: "https://auth.openai.com/oauth/token")!

        let accessToken = environment["NOTCHMETER_CODEX_ACCESS_TOKEN"]
            ?? environment["CODEX_ACCESS_TOKEN"]
        let refreshToken = environment["NOTCHMETER_CODEX_REFRESH_TOKEN"]
        let environmentCredentials = accessToken.map {
            CodexOAuthCredentials(accessToken: $0, refreshToken: refreshToken)
        }

        self.init(
            usageURL: usageURL,
            tokenURL: tokenURL,
            authFileURL: authFileURL,
            environmentCredentials: environmentCredentials,
            credentialStore: .shared
        )
    }

    public init(
        usageURL: URL = URL(string: "https://chatgpt.com/backend-api/wham/usage")!,
        tokenURL: URL = URL(string: "https://auth.openai.com/oauth/token")!,
        authFileURL: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/auth.json"),
        environmentCredentials: CodexOAuthCredentials? = nil,
        credentialStore: AgentOAuthFileStore = .shared
    ) {
        self.usageURL = usageURL
        self.tokenURL = tokenURL
        self.authFileURL = authFileURL
        self.environmentCredentials = environmentCredentials
        self.credentialStore = credentialStore
    }

    public func todaySnapshot(now: Date = Date()) async throws -> CodexUsageSnapshot {
        var credentials = try loadCredentials()
        do {
            return try await fetchSnapshot(accessToken: credentials.accessToken)
        } catch CodexRemoteUsageError.requestFailed(let status) where status == 401 {
            credentials = try await refreshCredentials(credentials)
            return try await fetchSnapshot(accessToken: credentials.accessToken)
        }
    }

    public func hasCredentials() -> Bool {
        if environmentCredentials != nil {
            return true
        }
        if (try? credentialStore.load(provider: .codex)) != nil {
            return true
        }
        return FileManager.default.fileExists(atPath: authFileURL.path)
    }

    private func fetchSnapshot(accessToken: String) async throws -> CodexUsageSnapshot {
        var request = URLRequest(url: usageURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await AgentUsageNetwork.data(for: request)
        if let http = response as? HTTPURLResponse,
           !(200..<300).contains(http.statusCode) {
            throw CodexRemoteUsageError.requestFailed(http.statusCode)
        }

        let json = try JSONSerialization.jsonObject(with: data)
        guard let object = json as? [String: Any] else {
            throw CodexRemoteUsageError.emptyResponse
        }

        guard let rateLimits = CodexSubscriptionUsageParser.rateLimits(from: object) else {
            throw CodexRemoteUsageError.emptyResponse
        }

        return CodexUsageSnapshot(
            scannedFiles: 0,
            sessionsWithUsage: 0,
            totalUsage: CodexSubscriptionUsageParser.tokenUsage(from: object),
            lastUsage: nil,
            rateLimits: rateLimits,
            newestEventDate: Date()
        )
    }

    private func loadCredentials() throws -> CodexOAuthCredentials {
        if let environmentCredentials {
            return environmentCredentials
        }

        if let fileCredentials = try credentialStore.load(provider: .codex) {
            return fileCredentials
        }

        let data = try Data(contentsOf: authFileURL)
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tokens = object["tokens"] as? [String: Any],
              let accessToken = tokens["access_token"] as? String,
              !accessToken.isEmpty else {
            throw CodexRemoteUsageError.missingCredentials
        }

        return CodexOAuthCredentials(
            accessToken: accessToken,
            refreshToken: tokens["refresh_token"] as? String
        )
    }

    private func refreshCredentials(_ credentials: CodexOAuthCredentials) async throws -> CodexOAuthCredentials {
        guard let refreshToken = credentials.refreshToken, !refreshToken.isEmpty else {
            throw CodexRemoteUsageError.missingCredentials
        }

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "client_id": Self.clientID,
            "grant_type": "refresh_token",
            "refresh_token": refreshToken
        ])

        let (data, response) = try await AgentUsageNetwork.data(for: request)
        if let http = response as? HTTPURLResponse,
           !(200..<300).contains(http.statusCode) {
            if Self.isUnrecoverableRefresh(data: data) {
                throw CodexRemoteUsageError.unrecoverableRefresh
            }
            throw CodexRemoteUsageError.refreshFailed(http.statusCode)
        }

        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = object["access_token"] as? String,
              !accessToken.isEmpty else {
            throw CodexRemoteUsageError.missingCredentials
        }

        let refreshed = CodexOAuthCredentials(
            accessToken: accessToken,
            refreshToken: (object["refresh_token"] as? String) ?? refreshToken,
            idToken: object["id_token"] as? String,
            expiresAt: Self.expiresAt(from: object["expires_in"]),
            lastRefreshAt: Date()
        )

        if environmentCredentials == nil {
            try? credentialStore.save(refreshed, provider: .codex)
            try? persistRefreshedTokens(object, fallbackRefreshToken: refreshToken)
        }

        return refreshed
    }

    private func persistRefreshedTokens(_ refreshed: [String: Any], fallbackRefreshToken: String) throws {
        let data = try Data(contentsOf: authFileURL)
        guard var object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        var tokens = (object["tokens"] as? [String: Any]) ?? [:]
        for key in ["access_token", "refresh_token", "id_token", "expires_in"] {
            if let value = refreshed[key] {
                tokens[key] = value
            }
        }
        if tokens["refresh_token"] == nil {
            tokens["refresh_token"] = fallbackRefreshToken
        }

        object["tokens"] = tokens
        object["last_refresh"] = ISO8601DateFormatter().string(from: Date())

        let output = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        try output.write(to: authFileURL, options: [.atomic])
    }

    private static func isUnrecoverableRefresh(data: Data) -> Bool {
        let text = String(data: data, encoding: .utf8)?.lowercased() ?? ""
        return [
            "refresh_token_expired",
            "refresh_token_reused",
            "refresh_token_invalidated",
            "invalid_grant"
        ].contains { text.contains($0) }
    }

    private static func expiresAt(from value: Any?) -> Date? {
        if let seconds = value as? Int {
            return Date().addingTimeInterval(TimeInterval(seconds))
        }
        if let seconds = value as? Double {
            return Date().addingTimeInterval(seconds)
        }
        if let string = value as? String, let seconds = Double(string) {
            return Date().addingTimeInterval(seconds)
        }
        return nil
    }
}

public struct CodexOAuthCredentials: Codable, Equatable, Sendable {
    public var accessToken: String
    public var refreshToken: String?
    public var idToken: String?
    public var expiresAt: Date?
    public var lastRefreshAt: Date?

    public init(
        accessToken: String,
        refreshToken: String? = nil,
        idToken: String? = nil,
        expiresAt: Date? = nil,
        lastRefreshAt: Date? = nil
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.idToken = idToken
        self.expiresAt = expiresAt
        self.lastRefreshAt = lastRefreshAt
    }
}

private enum CodexSubscriptionUsageParser {
    static func rateLimits(from object: [String: Any]) -> RateLimitStatus? {
        let normal = firstDictionary(in: [
            object["rate_limit"],
            object["rate_limits"],
            nested(object, "rate_limits_by_limit_id", "codex")
        ]) ?? [:]

        let primary = firstDictionary(in: [
            normal["primary_window"],
            normal["primary"],
            object["primary_window"],
            object["primary"]
        ])

        let secondary = firstDictionary(in: [
            normal["secondary_window"],
            normal["secondary"],
            object["secondary_window"],
            object["secondary"]
        ])

        guard primary != nil || secondary != nil else {
            return nil
        }

        return RateLimitStatus(
            primary: primary.map { window(from: $0, fallbackMinutes: 300) },
            secondary: secondary.map { window(from: $0, fallbackMinutes: 10_080) },
            planType: stringValue(object["plan_type"]) ?? stringValue(nested(object, "summary", "plan"))
        )
    }

    static func tokenUsage(from object: [String: Any]) -> TokenUsage {
        TokenUsage(
            inputTokens: intValue(firstValue(in: object, keys: tokenInputKeys)),
            cachedInputTokens: intValue(firstValue(in: object, keys: tokenCachedInputKeys)),
            outputTokens: intValue(firstValue(in: object, keys: tokenOutputKeys)),
            reasoningOutputTokens: intValue(firstValue(in: object, keys: tokenReasoningKeys)),
            totalTokens: intValue(firstValue(in: object, keys: tokenTotalKeys))
        )
    }

    private static func window(from object: [String: Any], fallbackMinutes: Int) -> RateLimitWindow {
        let explicitMinutes = intValue(object["window_minutes"])
        let seconds = intValue(object["limit_window_seconds"] ?? object["window_seconds"])
        return RateLimitWindow(
            usedPercent: clampedPercent(object["used_percent"] ?? object["percent_used"]),
            windowMinutes: explicitMinutes > 0 ? explicitMinutes : (seconds > 0 ? seconds / 60 : fallbackMinutes),
            resetsAt: dateValue(object["reset_at"] ?? object["resets_at"] ?? object["resetAt"])
        )
    }

    private static func firstDictionary(in values: [Any?]) -> [String: Any]? {
        values.compactMap { $0 as? [String: Any] }.first
    }

    private static func nested(_ object: [String: Any], _ first: String, _ second: String) -> Any? {
        (object[first] as? [String: Any])?[second]
    }

    private static func firstValue(in value: Any, keys: Set<String>) -> Any? {
        if let object = value as? [String: Any] {
            for (key, item) in object {
                if keys.contains(key.normalizedRemoteUsageKey) {
                    return item
                }
            }

            for item in object.values {
                if let found = firstValue(in: item, keys: keys) {
                    return found
                }
            }
        }

        if let array = value as? [Any] {
            for item in array {
                if let found = firstValue(in: item, keys: keys) {
                    return found
                }
            }
        }

        return nil
    }

    private static func clampedPercent(_ value: Any?) -> Double {
        max(0, min(100, doubleValue(value)))
    }

    private static func dateValue(_ value: Any?) -> Date? {
        if let number = value as? Double {
            return Date(timeIntervalSince1970: number < 1e12 ? number : number / 1000)
        }
        if let number = value as? Int {
            let double = Double(number)
            return Date(timeIntervalSince1970: double < 1e12 ? double : double / 1000)
        }
        if let string = value as? String {
            if let double = Double(string) {
                return Date(timeIntervalSince1970: double < 1e12 ? double : double / 1000)
            }
            return ISO8601DateFormatter().date(from: string)
        }
        return nil
    }

    private static func intValue(_ value: Any?) -> Int {
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

    private static func doubleValue(_ value: Any?) -> Double {
        if let double = value as? Double {
            return double
        }
        if let int = value as? Int {
            return Double(int)
        }
        if let string = value as? String, let double = Double(string) {
            return double
        }
        return 0
    }

    private static func stringValue(_ value: Any?) -> String? {
        value as? String
    }
}

private let tokenInputKeys: Set<String> = [
    "inputtokens",
    "textinputtokens",
    "textinputtokencount"
]

private let tokenCachedInputKeys: Set<String> = [
    "cachedinputtokens",
    "cachedtextinputtokens",
    "textcachedinputtokens",
    "cachedinputtokencount"
]

private let tokenOutputKeys: Set<String> = [
    "outputtokens",
    "textoutputtokens",
    "textoutputtokencount"
]

private let tokenReasoningKeys: Set<String> = [
    "reasoningoutputtokens",
    "reasoningoutputtokencount"
]

private let tokenTotalKeys: Set<String> = [
    "totaltokens",
    "texttokens",
    "tokencount"
]

private extension String {
    var normalizedRemoteUsageKey: String {
        lowercased().filter { $0.isLetter || $0.isNumber }
    }
}
