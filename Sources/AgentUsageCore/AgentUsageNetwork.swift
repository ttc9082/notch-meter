import Foundation

public enum AgentUsageAppConfig {
    public static let fileURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".notchmeter", isDirectory: true)
        .appendingPathComponent("config.json")

    public static func configuredProxyURL(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> URL? {
        let environmentValue = environment["NOTCHMETER_PROXY_URL"]
            ?? environment["HTTPS_PROXY"]
            ?? environment["https_proxy"]
            ?? environment["HTTP_PROXY"]
            ?? environment["http_proxy"]

        if let environmentValue,
           let url = normalizedProxyURL(environmentValue) {
            return url
        }

        return try? load().proxyURL.flatMap(normalizedProxyURL)
    }

    public static func savedProxyURLString() -> String? {
        try? load().proxyURL
    }

    public static func saveProxyURLString(_ value: String?) throws {
        var config = try load()
        config.proxyURL = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        if config.proxyURL?.isEmpty == true {
            config.proxyURL = nil
        }
        try save(config)
    }

    private static func load() throws -> AgentUsageConfigFile {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return AgentUsageConfigFile()
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(AgentUsageConfigFile.self, from: data)
    }

    private static func save(_ config: AgentUsageConfigFile) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: fileURL, options: [.atomic])
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: fileURL.path
        )
    }

    private static func normalizedProxyURL(_ value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        return URL(string: "http://\(trimmed)")
    }
}

public enum AgentUsageNetwork {
    public static func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let session = URLSession(configuration: configuration())
        defer {
            session.finishTasksAndInvalidate()
        }
        return try await session.data(for: request)
    }

    private static func configuration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60

        if let proxyURL = AgentUsageAppConfig.configuredProxyURL(),
           let proxyDictionary = proxyDictionary(for: proxyURL) {
            configuration.connectionProxyDictionary = proxyDictionary
        }

        return configuration
    }

    private static func proxyDictionary(for url: URL) -> [AnyHashable: Any]? {
        guard let host = url.host else {
            return nil
        }
        let port = url.port ?? defaultPort(for: url)
        let scheme = url.scheme?.lowercased()

        switch scheme {
        case "http", "https", nil:
            return [
                kCFNetworkProxiesHTTPEnable as String: true,
                kCFNetworkProxiesHTTPProxy as String: host,
                kCFNetworkProxiesHTTPPort as String: port,
                kCFNetworkProxiesHTTPSEnable as String: true,
                kCFNetworkProxiesHTTPSProxy as String: host,
                kCFNetworkProxiesHTTPSPort as String: port
            ]
        case "socks", "socks5":
            return [
                kCFNetworkProxiesSOCKSEnable as String: true,
                kCFNetworkProxiesSOCKSProxy as String: host,
                kCFNetworkProxiesSOCKSPort as String: port
            ]
        default:
            return nil
        }
    }

    private static func defaultPort(for url: URL) -> Int {
        switch url.scheme?.lowercased() {
        case "https":
            return 443
        case "socks", "socks5":
            return 1080
        default:
            return 80
        }
    }
}

private struct AgentUsageConfigFile: Codable {
    var proxyURL: String?
}
