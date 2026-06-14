import Foundation
import Security

public final class CodexOAuthKeychainStore: @unchecked Sendable {
    public static let shared = CodexOAuthKeychainStore()

    private let service = "NotchMeter.CodexOAuth"
    private let account = "CodexSubscription"

    public init() {}

    public func load() throws -> CodexOAuthCredentials? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError(status: status)
        }

        return try JSONDecoder().decode(CodexOAuthCredentials.self, from: data)
    }

    public func save(_ credentials: CodexOAuthCredentials) throws {
        let data = try JSONEncoder().encode(credentials)
        var query = baseQuery()
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw KeychainError(status: updateStatus)
        }

        query.merge(attributes) { _, new in new }
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainError(status: addStatus)
        }
    }

    public func delete() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError(status: status)
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

public struct KeychainError: Error, Equatable {
    public var status: OSStatus

    public init(status: OSStatus) {
        self.status = status
    }
}

extension KeychainError: LocalizedError {
    public var errorDescription: String? {
        "Keychain operation failed with status \(status)."
    }
}
