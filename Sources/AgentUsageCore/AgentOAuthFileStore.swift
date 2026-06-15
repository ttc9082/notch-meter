import Foundation

public final class AgentOAuthFileStore: @unchecked Sendable {
    public static let shared = AgentOAuthFileStore()

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
        return file.credentials[provider.rawValue]
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
}

private struct AgentOAuthFile: Codable {
    var version = 1
    var credentials: [String: CodexOAuthCredentials] = [:]
}
