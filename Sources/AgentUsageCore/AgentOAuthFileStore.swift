import Foundation
import Security

public final class AgentOAuthFileStore: @unchecked Sendable {
    public static let shared = AgentOAuthFileStore()

    private let legacyService = "NotchMeter.AgentOAuth"
    private let legacyCodexService = "NotchMeter.CodexOAuth"
    private let legacyCodexAccount = "CodexSubscription"

    public let fileURL: URL

    public convenience init() {
        let baseDirectory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".notchmeter", isDirectory: true)
        self.init(fileURL: baseDirectory.appendingPathComponent("auth.json"))
    }

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func load(provider: AgentUsageProvider) throws -> CodexOAuthCredentials? {
        let file = try readFile()
        if let credentials = file.credentials[provider.rawValue] {
            return credentials
        }
        return try migrateLegacyCredentials(provider: provider)
    }

    public func save(_ credentials: CodexOAuthCredentials, provider: AgentUsageProvider) throws {
        var file = try readFile()
        file.credentials[provider.rawValue] = credentials
        try writeFile(file)
    }

    public func delete(provider: AgentUsageProvider) throws {
        var file = try readFile()
        file.credentials.removeValue(forKey: provider.rawValue)
        try writeFile(file)
    }

    private func readFile() throws -> AgentOAuthFile {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return AgentOAuthFile()
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(AgentOAuthFile.self, from: data)
    }

    private func writeFile(_ file: AgentOAuthFile) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(file)
        try data.write(to: fileURL, options: [.atomic])
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: fileURL.path
        )
    }

    private func migrateLegacyCredentials(provider: AgentUsageProvider) throws -> CodexOAuthCredentials? {
        guard let credentials = try loadLegacyCredentials(provider: provider) else {
            return nil
        }

        try save(credentials, provider: provider)
        try? deleteLegacyCredentials(provider: provider)
        return credentials
    }

    private func loadLegacyCredentials(provider: AgentUsageProvider) throws -> CodexOAuthCredentials? {
        let queries = legacyQueries(provider: provider)
        for query in queries {
            var lookup = query
            lookup[kSecReturnData as String] = true
            lookup[kSecMatchLimit as String] = kSecMatchLimitOne

            var result: CFTypeRef?
            let status = SecItemCopyMatching(lookup as CFDictionary, &result)
            if status == errSecItemNotFound {
                continue
            }
            guard status == errSecSuccess, let data = result as? Data else {
                throw AgentOAuthFileStoreError.legacyKeychainStatus(status)
            }

            return try JSONDecoder().decode(CodexOAuthCredentials.self, from: data)
        }
        return nil
    }

    private func deleteLegacyCredentials(provider: AgentUsageProvider) throws {
        for query in legacyQueries(provider: provider) {
            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw AgentOAuthFileStoreError.legacyKeychainStatus(status)
            }
        }
    }

    private func legacyQueries(provider: AgentUsageProvider) -> [[String: Any]] {
        var queries: [[String: Any]] = [
            [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: legacyService,
                kSecAttrAccount as String: provider.rawValue
            ]
        ]

        if provider == .codex {
            queries.append([
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: legacyCodexService,
                kSecAttrAccount as String: legacyCodexAccount
            ])
        }

        return queries
    }
}

private struct AgentOAuthFile: Codable {
    var version = 1
    var credentials: [String: CodexOAuthCredentials] = [:]
}

public enum AgentOAuthFileStoreError: Error, Equatable {
    case legacyKeychainStatus(OSStatus)
}

extension AgentOAuthFileStoreError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .legacyKeychainStatus(let status):
            return "Legacy Keychain migration failed with status \(status)."
        }
    }
}
