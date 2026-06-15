import AgentUsageCore
import AppKit
import CryptoKit
import Foundation
import Network

@MainActor
final class CodexOAuthSignInController {
    private var pendingTask: Task<CodexOAuthCredentials, Error>?

    func signIn(provider: AgentUsageProvider) async throws -> CodexOAuthCredentials {
        if let pendingTask {
            return try await pendingTask.value
        }

        let task = Task<CodexOAuthCredentials, Error> { @MainActor in
            let config = OAuthProviderConfig(provider: provider)
            let verifier = PKCE.randomVerifier()
            let challenge = PKCE.challenge(for: verifier)
            let state = PKCE.randomVerifier(length: 32)

            guard let authURL = authorizationURL(config: config, codeChallenge: challenge, state: state) else {
                throw CodexRemoteUsageError.invalidURL
            }

            await MainActor.run {
                _ = NSWorkspace.shared.open(authURL)
            }

            switch config.callback {
            case .loopback(let port, let path):
                let listener = OAuthCallbackListener(expectedState: state, port: port, path: path)
                try await listener.start()
                do {
                    let code = try await listener.waitForCode()
                    listener.stop()
                    let credentials = try await exchange(config: config, code: code, verifier: verifier, state: state)
                    try AgentOAuthFileStore.shared.save(credentials, provider: provider)
                    return credentials
                } catch {
                    listener.stop()
                    throw error
                }
            case .manualCode:
                let authorizationCode = try requestManualAuthorizationCode(provider: provider)
                let credentials = try await exchange(
                    config: config,
                    code: authorizationCode.code,
                    verifier: verifier,
                    state: authorizationCode.state ?? state
                )
                try AgentOAuthFileStore.shared.save(credentials, provider: provider)
                return credentials
            }
        }

        pendingTask = task
        defer {
            pendingTask = nil
        }
        return try await task.value
    }

    func signOut(provider: AgentUsageProvider) {
        try? AgentOAuthFileStore.shared.delete(provider: provider)
    }

    private func requestManualAuthorizationCode(provider: AgentUsageProvider) throws -> OAuthAuthorizationCode {
        let alert = NSAlert()
        alert.messageText = "\(provider.displayName) Authorization"
        alert.informativeText = "After approving in the browser, copy the callback URL or authorization code from the page/address bar and paste it here."
        alert.addButton(withTitle: "Continue")
        alert.addButton(withTitle: "Cancel")

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 420, height: 24))
        input.placeholderString = "https://platform.claude.com/oauth/code/callback?code=..."
        alert.accessoryView = input

        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else {
            throw CodexRemoteUsageError.missingCredentials
        }

        return try OAuthAuthorizationCode(input.stringValue)
    }

    private func authorizationURL(config: OAuthProviderConfig, codeChallenge: String, state: String) -> URL? {
        var components = URLComponents(url: config.authorizeURL, resolvingAgainstBaseURL: false)
        var queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: config.clientID),
            URLQueryItem(name: "redirect_uri", value: config.redirectURI),
            URLQueryItem(name: "scope", value: config.scope),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state)
        ]
        queryItems.append(contentsOf: config.extraQueryItems)
        components?.queryItems = queryItems
        return components?.url
    }

    private func exchange(
        config: OAuthProviderConfig,
        code: String,
        verifier: String,
        state: String
    ) async throws -> CodexOAuthCredentials {
        var request = URLRequest(url: config.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        switch config.tokenBody {
        case .form:
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = formBody([
                "grant_type": "authorization_code",
                "client_id": config.clientID,
                "code": code,
                "redirect_uri": config.redirectURI,
                "code_verifier": verifier
            ])
        case .json:
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "grant_type": "authorization_code",
                "client_id": config.clientID,
                "code": code,
                "state": state,
                "redirect_uri": config.redirectURI,
                "code_verifier": verifier
            ])
        }

        let (data, response) = try await AgentUsageNetwork.data(for: request)
        if let http = response as? HTTPURLResponse,
           !(200..<300).contains(http.statusCode) {
            throw CodexRemoteUsageError.requestFailed(http.statusCode)
        }

        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = object["access_token"] as? String else {
            throw CodexRemoteUsageError.missingCredentials
        }

        return CodexOAuthCredentials(
            accessToken: accessToken,
            refreshToken: object["refresh_token"] as? String,
            idToken: object["id_token"] as? String,
            expiresAt: Self.expiresAt(from: object["expires_in"]),
            lastRefreshAt: Date()
        )
    }

    private func formBody(_ values: [String: String]) -> Data {
        values
            .map { key, value in
                "\(Self.formEscape(key))=\(Self.formEscape(value))"
            }
            .joined(separator: "&")
            .data(using: .utf8) ?? Data()
    }

    private static func formEscape(_ value: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&+=")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
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

private struct OAuthAuthorizationCode {
    let code: String
    let state: String?

    init(_ pastedValue: String) throws {
        let trimmed = pastedValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw CodexRemoteUsageError.missingCredentials
        }

        if let components = URLComponents(string: trimmed),
           let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
           !code.isEmpty {
            self.code = code
            self.state = Self.state(from: components)
            return
        }

        let parts = trimmed.split(separator: "#", maxSplits: 1).map(String.init)
        self.code = parts[0]
        self.state = parts.count > 1 ? parts[1] : nil
    }

    private static func state(from components: URLComponents) -> String? {
        if let state = components.queryItems?.first(where: { $0.name == "state" })?.value {
            return state
        }
        if let fragment = components.fragment, !fragment.isEmpty {
            return fragment
        }
        return nil
    }
}

private struct OAuthProviderConfig {
    enum Callback {
        case loopback(port: UInt16, path: String)
        case manualCode
    }

    enum TokenBody {
        case form
        case json
    }

    let provider: AgentUsageProvider
    let clientID: String
    let authorizeURL: URL
    let tokenURL: URL
    let redirectURI: String
    let scope: String
    let extraQueryItems: [URLQueryItem]
    let tokenBody: TokenBody
    let callback: Callback

    init(provider: AgentUsageProvider) {
        self.provider = provider
        switch provider {
        case .codex:
            clientID = "app_EMoamEEZ73f0CkXaXp7hrann"
            authorizeURL = URL(string: "https://auth.openai.com/oauth/authorize")!
            tokenURL = URL(string: "https://auth.openai.com/oauth/token")!
            redirectURI = "http://localhost:1455/auth/callback"
            scope = "openid profile email offline_access"
            extraQueryItems = [
                URLQueryItem(name: "id_token_add_organizations", value: "true"),
                URLQueryItem(name: "codex_cli_simplified_flow", value: "true"),
                URLQueryItem(name: "originator", value: "codex_cli_rs")
            ]
            tokenBody = .form
            callback = .loopback(port: 1455, path: "/auth/callback")
        case .claude:
            clientID = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
            authorizeURL = URL(string: "https://claude.ai/oauth/authorize")!
            tokenURL = URL(string: "https://console.anthropic.com/v1/oauth/token")!
            redirectURI = "https://platform.claude.com/oauth/code/callback"
            scope = "org:create_api_key user:profile user:inference user:sessions:claude_code user:mcp_servers"
            extraQueryItems = [
                URLQueryItem(name: "code", value: "true")
            ]
            tokenBody = .json
            callback = .manualCode
        }
    }
}

private final class OAuthCallbackListener: @unchecked Sendable {
    private let expectedState: String
    private let port: UInt16
    private let path: String
    private var listener: NWListener?
    private var continuation: CheckedContinuation<String, Error>?

    init(expectedState: String, port: UInt16, path: String) {
        self.expectedState = expectedState
        self.port = port
        self.path = path
    }

    func start() async throws {
        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            throw CodexRemoteUsageError.invalidURL
        }
        let listener = try NWListener(using: .tcp, on: nwPort)
        listener.newConnectionHandler = { [weak self] connection in
            self?.handle(connection)
        }
        listener.start(queue: .main)
        self.listener = listener
    }

    func waitForCode() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    private func handle(_ connection: NWConnection) {
        connection.start(queue: .main)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, _, error in
            guard let self else {
                connection.cancel()
                return
            }

            defer {
                connection.cancel()
            }

            if let error {
                self.resume(throwing: error)
                return
            }

            guard let data,
                  let request = String(data: data, encoding: .utf8),
                  let firstLine = request.components(separatedBy: "\r\n").first else {
                self.send("Invalid OAuth callback.", status: "400 Bad Request", on: connection)
                self.resume(throwing: CodexRemoteUsageError.missingCredentials)
                return
            }

            let parts = firstLine.split(separator: " ")
            guard parts.count >= 2,
                  let url = URL(string: "http://127.0.0.1\(parts[1])"),
                  url.path == path,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                self.send("Invalid OAuth callback path.", status: "404 Not Found", on: connection)
                return
            }

            let items = components.queryItems ?? []
            let state = items.first(where: { $0.name == "state" })?.value
            let code = items.first(where: { $0.name == "code" })?.value
            let error = items.first(where: { $0.name == "error" })?.value

            if let error {
                self.send("OpenAI sign-in failed. You can close this window.", status: "400 Bad Request", on: connection)
                self.resume(throwing: NSError(domain: "NotchMeterOAuth", code: 1, userInfo: [NSLocalizedDescriptionKey: error]))
                return
            }

            guard state == expectedState, let code, !code.isEmpty else {
                self.send("OpenAI sign-in state did not match. You can close this window.", status: "400 Bad Request", on: connection)
                self.resume(throwing: CodexRemoteUsageError.missingCredentials)
                return
            }

            self.send("NotchMeter sign-in complete. You can close this window.", status: "200 OK", on: connection)
            self.resume(returning: code)
        }
    }

    private func send(_ body: String, status: String, on connection: NWConnection) {
        let html = """
        <!doctype html><html><head><meta charset="utf-8"><title>NotchMeter</title></head>
        <body style="font:14px -apple-system, BlinkMacSystemFont, sans-serif; padding:32px; background:#000; color:#f5f5f5;">
        <h1 style="font-size:18px;">\(body)</h1>
        </body></html>
        """
        let response = """
        HTTP/1.1 \(status)\r
        Content-Type: text/html; charset=utf-8\r
        Content-Length: \(html.utf8.count)\r
        Connection: close\r
        \r
        \(html)
        """
        connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in })
    }

    private func resume(returning code: String) {
        guard let continuation else {
            return
        }
        self.continuation = nil
        continuation.resume(returning: code)
    }

    private func resume(throwing error: Error) {
        guard let continuation else {
            return
        }
        self.continuation = nil
        continuation.resume(throwing: error)
    }
}

private enum PKCE {
    static func randomVerifier(length: Int = 64) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URLEncodedString()
    }

    static func challenge(for verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest).base64URLEncodedString()
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
