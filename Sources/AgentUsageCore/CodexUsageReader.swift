import Foundation

public struct TokenUsage: Equatable, Sendable {
    public var inputTokens: Int
    public var cachedInputTokens: Int
    public var outputTokens: Int
    public var reasoningOutputTokens: Int
    public var totalTokens: Int

    public static let zero = TokenUsage(
        inputTokens: 0,
        cachedInputTokens: 0,
        outputTokens: 0,
        reasoningOutputTokens: 0,
        totalTokens: 0
    )

    public static func + (left: TokenUsage, right: TokenUsage) -> TokenUsage {
        TokenUsage(
            inputTokens: left.inputTokens + right.inputTokens,
            cachedInputTokens: left.cachedInputTokens + right.cachedInputTokens,
            outputTokens: left.outputTokens + right.outputTokens,
            reasoningOutputTokens: left.reasoningOutputTokens + right.reasoningOutputTokens,
            totalTokens: left.totalTokens + right.totalTokens
        )
    }
}

public struct RateLimitWindow: Equatable, Sendable {
    public var usedPercent: Double
    public var windowMinutes: Int?
    public var resetsAt: Date?
}

public struct RateLimitStatus: Equatable, Sendable {
    public var primary: RateLimitWindow?
    public var secondary: RateLimitWindow?
    public var planType: String?
}

public struct CodexUsageSnapshot: Equatable, Sendable {
    public var scannedFiles: Int
    public var sessionsWithUsage: Int
    public var totalUsage: TokenUsage
    public var lastUsage: TokenUsage?
    public var rateLimits: RateLimitStatus?
    public var newestEventDate: Date?
    public var source: UsageDataSource?

    public static let empty = CodexUsageSnapshot(
        scannedFiles: 0,
        sessionsWithUsage: 0,
        totalUsage: .zero,
        lastUsage: nil,
        rateLimits: nil,
        newestEventDate: nil,
        source: nil
    )
}

public struct UsageDataSource: Equatable, Sendable {
    public var provider: AgentUsageProvider
    public var mode: UsageDataSourceMode

    public init(provider: AgentUsageProvider, mode: UsageDataSourceMode) {
        self.provider = provider
        self.mode = mode
    }

    public var label: String {
        "\(provider.compactName) \(mode.label)"
    }
}

public enum UsageDataSourceMode: String, Equatable, Sendable {
    case remote
    case local

    public var label: String {
        switch self {
        case .remote:
            return "REMOTE"
        case .local:
            return "LOCAL"
        }
    }
}

public enum CodexUsageReaderError: Error, Equatable {
    case sessionsDirectoryMissing(URL)
}

extension CodexUsageReaderError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .sessionsDirectoryMissing(let url):
            return "Codex sessions directory is missing: \(url.path)"
        }
    }
}

public final class CodexUsageReader: Sendable {
    public let sessionsDirectory: URL
    public let calendar: Calendar

    public init(
        sessionsDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/sessions", isDirectory: true),
        calendar: Calendar = .current
    ) {
        self.sessionsDirectory = sessionsDirectory
        self.calendar = calendar
    }

    public func snapshot(for interval: DateInterval? = nil) throws -> CodexUsageSnapshot {
        guard FileManager.default.fileExists(atPath: sessionsDirectory.path) else {
            throw CodexUsageReaderError.sessionsDirectoryMissing(sessionsDirectory)
        }

        let files = sessionFiles(in: sessionsDirectory, interval: interval)
        var snapshot = CodexUsageSnapshot.empty
        snapshot.scannedFiles = files.count

        for file in files {
            guard let session = readLatestUsage(from: file, interval: interval) else {
                continue
            }

            snapshot.sessionsWithUsage += 1
            snapshot.totalUsage = snapshot.totalUsage + session.totalUsage

            if snapshot.newestEventDate == nil || session.eventDate > snapshot.newestEventDate! {
                snapshot.newestEventDate = session.eventDate
                snapshot.lastUsage = session.lastUsage
                snapshot.rateLimits = session.rateLimits
            }
        }

        return snapshot
    }

    public func todaySnapshot(now: Date = Date()) throws -> CodexUsageSnapshot {
        let start = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
        return try snapshot(for: DateInterval(start: start, end: end))
    }

    private func sessionFiles(in directory: URL, interval: DateInterval?) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return enumerator.compactMap { item in
            guard let url = item as? URL, url.pathExtension == "jsonl" else {
                return nil
            }

            if let interval {
                let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
                if let modified = values?.contentModificationDate, !interval.intersects(DateInterval(start: modified, duration: 0)) {
                    return nil
                }
            }

            return url
        }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private func readLatestUsage(from file: URL, interval: DateInterval?) -> SessionUsage? {
        guard let data = try? Data(contentsOf: file),
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }

        var latest: SessionUsage?

        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            guard let event = parseTokenCountLine(String(line)) else {
                continue
            }

            if let interval, !interval.contains(event.eventDate) {
                continue
            }

            if latest == nil || event.eventDate > latest!.eventDate {
                latest = event
            }
        }

        return latest
    }

    private func parseTokenCountLine(_ line: String) -> SessionUsage? {
        guard let data = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let payload = json["payload"] as? [String: Any],
              payload["type"] as? String == "token_count",
              let info = payload["info"] as? [String: Any],
              let total = info["total_token_usage"] as? [String: Any],
              let timestamp = json["timestamp"] as? String,
              let eventDate = Self.date(from: timestamp) else {
            return nil
        }

        let last = info["last_token_usage"] as? [String: Any]
        let rateLimits = payload["rate_limits"] as? [String: Any]

        return SessionUsage(
            eventDate: eventDate,
            totalUsage: TokenUsage(dictionary: total),
            lastUsage: last.map(TokenUsage.init(dictionary:)),
            rateLimits: rateLimits.map(RateLimitStatus.init(dictionary:))
        )
    }

    private static func date(from timestamp: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: timestamp)
    }
}

private struct SessionUsage {
    var eventDate: Date
    var totalUsage: TokenUsage
    var lastUsage: TokenUsage?
    var rateLimits: RateLimitStatus?
}

private extension TokenUsage {
    init(dictionary: [String: Any]) {
        self.init(
            inputTokens: dictionary.intValue("input_tokens"),
            cachedInputTokens: dictionary.intValue("cached_input_tokens"),
            outputTokens: dictionary.intValue("output_tokens"),
            reasoningOutputTokens: dictionary.intValue("reasoning_output_tokens"),
            totalTokens: dictionary.intValue("total_tokens")
        )
    }
}

private extension RateLimitStatus {
    init(dictionary: [String: Any]) {
        self.init(
            primary: (dictionary["primary"] as? [String: Any]).map(RateLimitWindow.init(dictionary:)),
            secondary: (dictionary["secondary"] as? [String: Any]).map(RateLimitWindow.init(dictionary:)),
            planType: dictionary["plan_type"] as? String
        )
    }
}

private extension RateLimitWindow {
    init(dictionary: [String: Any]) {
        let resetsAtSeconds = dictionary.doubleValue("resets_at")
        self.init(
            usedPercent: dictionary.doubleValue("used_percent"),
            windowMinutes: dictionary["window_minutes"] as? Int,
            resetsAt: resetsAtSeconds > 0 ? Date(timeIntervalSince1970: resetsAtSeconds) : nil
        )
    }
}

private extension Dictionary where Key == String, Value == Any {
    func intValue(_ key: String) -> Int {
        if let value = self[key] as? Int {
            return value
        }
        if let value = self[key] as? Double {
            return Int(value)
        }
        if let value = self[key] as? String, let parsed = Int(value) {
            return parsed
        }
        return 0
    }

    func doubleValue(_ key: String) -> Double {
        if let value = self[key] as? Double {
            return value
        }
        if let value = self[key] as? Int {
            return Double(value)
        }
        if let value = self[key] as? String, let parsed = Double(value) {
            return parsed
        }
        return 0
    }
}
