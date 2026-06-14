import Foundation

public final class ClaudeSubscriptionUsageReader: @unchecked Sendable {
    private static let clientID = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"

    public let usageURL: URL
    public let tokenURL: URL
    private let environmentCredentials: CodexOAuthCredentials?
    private let keychainStore: CodexOAuthKeychainStore

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
                ?? URL(string: "https://api.anthropic.com/v1/oauth/token")!,
            environmentCredentials: environmentCredentials,
            keychainStore: .shared
        )
    }

    public init(
        usageURL: URL = URL(string: "https://api.anthropic.com/api/oauth/usage")!,
        tokenURL: URL = URL(string: "https://api.anthropic.com/v1/oauth/token")!,
        environmentCredentials: CodexOAuthCredentials? = nil,
        keychainStore: CodexOAuthKeychainStore = .shared
    ) {
        self.usageURL = usageURL
        self.tokenURL = tokenURL
        self.environmentCredentials = environmentCredentials
        self.keychainStore = keychainStore
    }

    public func todaySnapshot(now: Date = Date()) async throws -> CodexUsageSnapshot {
        var credentials = try loadCredentials()
        do {
            return try await fetchSnapshot(accessToken: credentials.accessToken)
        } catch CodexRemoteUsageError.requestFailed(let status) where status == 401 || status == 403 {
            credentials = try await refreshCredentials(credentials)
            return try await fetchSnapshot(accessToken: credentials.accessToken)
        }
    }

    private func fetchSnapshot(accessToken: String) async throws -> CodexUsageSnapshot {
        var request = URLRequest(url: usageURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse,
           !(200..<300).contains(http.statusCode) {
            throw CodexRemoteUsageError.requestFailed(http.statusCode)
        }

        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rateLimits = ClaudeUsageParser.rateLimits(from: object) else {
            throw CodexRemoteUsageError.emptyResponse
        }

        return CodexUsageSnapshot(
            scannedFiles: 0,
            sessionsWithUsage: 0,
            totalUsage: .zero,
            lastUsage: nil,
            rateLimits: rateLimits,
            newestEventDate: Date()
        )
    }

    private func loadCredentials() throws -> CodexOAuthCredentials {
        if let environmentCredentials {
            return environmentCredentials
        }
        if let keychainCredentials = try keychainStore.load(provider: .claude) {
            return keychainCredentials
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

        let (data, response) = try await URLSession.shared.data(for: request)
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
            try? keychainStore.save(refreshed, provider: .claude)
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
}

private enum ClaudeUsageParser {
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
}
