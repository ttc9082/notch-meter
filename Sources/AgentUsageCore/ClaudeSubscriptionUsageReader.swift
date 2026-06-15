import Foundation

public final class ClaudeSubscriptionUsageReader: @unchecked Sendable {
    private static let clientID = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
    private static let defaultCacheTTL: TimeInterval = 300
    private static let defaultFailureCooldown: TimeInterval = 300

    public let usageURL: URL
    public let tokenURL: URL
    private let environmentCredentials: CodexOAuthCredentials?
    private let credentialStore: AgentOAuthFileStore
    private let cacheTTL: TimeInterval
    private let failureCooldown: TimeInterval
    private let userAgent: String
    private var cachedSnapshot: CodexUsageSnapshot?
    private var cachedAt: Date?
    private var cooldownUntil: Date?

    public convenience init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        let accessToken = environment["NOTCHMETER_CLAUDE_ACCESS_TOKEN"]
        let refreshToken = environment["NOTCHMETER_CLAUDE_REFRESH_TOKEN"]
        let environmentCredentials = accessToken.map {
            CodexOAuthCredentials(accessToken: $0, refreshToken: refreshToken)
        }

        self.init(
            usageURL: environment["NOTCHMETER_CLAUDE_USAGE_URL"]
                .flatMap(URL.init(string:))
                ?? URL(string: "https://api.anthropic.com/api/oauth/usage")!,
            tokenURL: environment["NOTCHMETER_CLAUDE_TOKEN_URL"]
                .flatMap(URL.init(string:))
                ?? URL(string: "https://platform.claude.com/v1/oauth/token")!,
            environmentCredentials: environmentCredentials,
            credentialStore: .shared,
            cacheTTL: Self.interval(
                from: environment["NOTCHMETER_CLAUDE_USAGE_CACHE_SECONDS"],
                fallback: Self.defaultCacheTTL
            ),
            failureCooldown: Self.interval(
                from: environment["NOTCHMETER_CLAUDE_FAILURE_COOLDOWN_SECONDS"],
                fallback: Self.defaultFailureCooldown
            ),
            userAgent: Self.claudeCodeUserAgent(environment: environment)
        )
    }

    public init(
        usageURL: URL = URL(string: "https://api.anthropic.com/api/oauth/usage")!,
        tokenURL: URL = URL(string: "https://platform.claude.com/v1/oauth/token")!,
        environmentCredentials: CodexOAuthCredentials? = nil,
        credentialStore: AgentOAuthFileStore = .shared,
        cacheTTL: TimeInterval = 300,
        failureCooldown: TimeInterval = 300,
        userAgent: String? = nil
    ) {
        self.usageURL = usageURL
        self.tokenURL = tokenURL
        self.environmentCredentials = environmentCredentials
        self.credentialStore = credentialStore
        self.cacheTTL = cacheTTL
        self.failureCooldown = failureCooldown
        self.userAgent = userAgent ?? Self.claudeCodeUserAgent()
    }

    public func todaySnapshot(now: Date = Date()) async throws -> CodexUsageSnapshot {
        if let cachedSnapshot,
           let cachedAt,
           now.timeIntervalSince(cachedAt) < cacheTTL {
            return cachedSnapshot
        }

        if let cooldownUntil,
           now < cooldownUntil,
           let cachedSnapshot {
            return cachedSnapshot
        }

        var credentials = try loadCredentials()
        do {
            return try await fetchSnapshot(accessToken: credentials.accessToken, now: now)
        } catch CodexRemoteUsageError.requestFailed(let status) where status == 401 {
            credentials = try await refreshCredentials(credentials)
            return try await fetchSnapshot(accessToken: credentials.accessToken, now: now)
        } catch {
            if let cachedSnapshot {
                return cachedSnapshot
            }
            throw error
        }
    }

    public func hasCredentials() -> Bool {
        if environmentCredentials != nil {
            return true
        }
        return (try? credentialStore.load(provider: .claude)) != nil
    }

    private func fetchSnapshot(accessToken: String, now: Date) async throws -> CodexUsageSnapshot {
        var request = URLRequest(url: usageURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await AgentUsageNetwork.data(for: request)
        if let http = response as? HTTPURLResponse,
           !(200..<300).contains(http.statusCode) {
            if http.statusCode == 429 {
                let delay = Self.retryDelay(from: http) ?? failureCooldown
                cooldownUntil = now.addingTimeInterval(delay)
            }
            throw CodexRemoteUsageError.requestFailed(http.statusCode)
        }

        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rateLimits = ClaudeUsageParser.rateLimits(from: object) else {
            throw CodexRemoteUsageError.emptyResponse
        }

        let snapshot = CodexUsageSnapshot(
            scannedFiles: 0,
            sessionsWithUsage: 0,
            totalUsage: .zero,
            lastUsage: nil,
            rateLimits: rateLimits,
            claudeDetails: ClaudeUsageParser.details(from: object),
            newestEventDate: Date()
        )
        cachedSnapshot = snapshot
        cachedAt = now
        cooldownUntil = nil
        return snapshot
    }

    private func loadCredentials() throws -> CodexOAuthCredentials {
        if let environmentCredentials {
            return environmentCredentials
        }
        if let fileCredentials = try credentialStore.load(provider: .claude) {
            return fileCredentials
        }
        throw CodexRemoteUsageError.missingCredentials
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
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": Self.clientID
        ])

        let (data, response) = try await AgentUsageNetwork.data(for: request)
        if let http = response as? HTTPURLResponse,
           !(200..<300).contains(http.statusCode) {
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
            expiresAt: Self.expiresAt(from: object["expires_in"]),
            lastRefreshAt: Date()
        )

        if environmentCredentials == nil {
            try? credentialStore.save(refreshed, provider: .claude)
        }

        return refreshed
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

    private static func interval(from value: String?, fallback: TimeInterval) -> TimeInterval {
        guard let value,
              let interval = TimeInterval(value),
              interval >= 0 else {
            return fallback
        }
        return interval
    }

    private static func retryDelay(from response: HTTPURLResponse) -> TimeInterval? {
        guard let rawValue = response.value(forHTTPHeaderField: "Retry-After") else {
            return nil
        }
        if let seconds = TimeInterval(rawValue), seconds > 0 {
            return seconds
        }
        if let date = HTTPDateFormatter.shared.date(from: rawValue) {
            return max(0, date.timeIntervalSinceNow)
        }
        return nil
    }

    private static func claudeCodeUserAgent(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> String {
        if let configured = environment["NOTCHMETER_CLAUDE_USER_AGENT"],
           !configured.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return configured
        }
        return "claude-code/\(detectClaudeCodeVersion() ?? "2.1.0")"
    }

    private static func detectClaudeCodeVersion() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["claude", "--version"]

        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        guard process.terminationStatus == 0 else {
            return nil
        }

        let data = output.fileHandleForReading.readDataToEndOfFile()
        guard let versionOutput = String(data: data, encoding: .utf8) else {
            return nil
        }

        return versionOutput
            .split(whereSeparator: { $0.isWhitespace })
            .first
            .map(String.init)
    }
}

private final class HTTPDateFormatter: @unchecked Sendable {
    static let shared = HTTPDateFormatter()

    private let formatter: DateFormatter

    private init() {
        formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss z"
    }

    func date(from string: String) -> Date? {
        formatter.date(from: string)
    }
}

private enum ClaudeUsageParser {
    static func details(from object: [String: Any]) -> ClaudeUsageDetails {
        ClaudeUsageDetails(
            sonnetSevenDay: (object["seven_day_sonnet"] as? [String: Any]).map {
                window(from: $0, fallbackMinutes: 10_080)
            },
            extraUsage: (object["extra_usage"] as? [String: Any]).map(extraUsage(from:))
        )
    }

    static func rateLimits(from object: [String: Any]) -> RateLimitStatus? {
        let primary = (object["five_hour"] as? [String: Any]).map {
            window(from: $0, fallbackMinutes: 300)
        }
        let secondary = (object["seven_day"] as? [String: Any]).map {
            window(from: $0, fallbackMinutes: 10_080)
        }

        guard primary != nil || secondary != nil else {
            return nil
        }

        return RateLimitStatus(
            primary: primary,
            secondary: secondary,
            planType: "Claude Code"
        )
    }

    private static func extraUsage(from object: [String: Any]) -> ClaudeExtraUsage {
        ClaudeExtraUsage(
            isEnabled: boolValue(object["is_enabled"]),
            monthlyLimit: optionalDoubleValue(object["monthly_limit"]),
            usedCredits: optionalDoubleValue(object["used_credits"]),
            utilization: optionalDoubleValue(object["utilization"]).map { max(0, min(100, $0)) },
            currency: object["currency"] as? String,
            disabledReason: object["disabled_reason"] as? String
        )
    }

    private static func window(from object: [String: Any], fallbackMinutes: Int) -> RateLimitWindow {
        RateLimitWindow(
            usedPercent: max(0, min(100, doubleValue(object["utilization"]))),
            windowMinutes: fallbackMinutes,
            resetsAt: dateValue(object["resets_at"] ?? object["reset_at"])
        )
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

    private static func optionalDoubleValue(_ value: Any?) -> Double? {
        if let double = value as? Double {
            return double
        }
        if let int = value as? Int {
            return Double(int)
        }
        if let string = value as? String, let double = Double(string) {
            return double
        }
        return nil
    }

    private static func boolValue(_ value: Any?) -> Bool {
        if let bool = value as? Bool {
            return bool
        }
        if let int = value as? Int {
            return int != 0
        }
        if let string = value as? String {
            return ["true", "1", "yes", "enabled"].contains(string.lowercased())
        }
        return false
    }
}
