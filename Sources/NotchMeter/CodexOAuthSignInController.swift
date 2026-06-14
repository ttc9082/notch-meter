import AgentUsageCore
import AppKit
import CryptoKit
import Foundation
import Network

@MainActor
final class CodexOAuthSignInController {
    private let clientID = "app_EMoamEEZ73f0CkXaXp7hrann"
    private let authorizeURL = URL(string: "https://auth.openai.com/oauth/authorize")!
    private let tokenURL = URL(string: "https://auth.openai.com/oauth/token")!
    private let redirectURI = "http://127.0.0.1:1455/auth/callback"
    private var pendingTask: Task<CodexOAuthCredentials, Error>?

    func signIn() async throws -> CodexOAuthCredentials {
        if let pendingTask {
            return try await pendingTask.value
        }

        let task = Task<CodexOAuthCredentials, Error> { @MainActor in
            let verifier = PKCE.randomVerifier()
            let challenge = PKCE.challenge(for: verifier)
            let state = PKCE.randomVerifier(length: 32)
            let listener = OAuthCallbackListener(expectedState: state)

            try await listener.start()

            guard let authURL = authorizationURL(codeChallenge: challenge, state: state) else {
                listener.stop()
                throw CodexRemoteUsageError.invalidURL
            }

            await MainActor.run {
                _ = NSWorkspace.shared.open(authURL)
            }

            do {
                let code = try await listener.waitForCode()
                listener.stop()
                let credentials = try await exchange(code: code, verifier: verifier)
                try CodexOAuthKeychainStore.shared.save(credentials)
                return credentials
            } catch {
                listener.stop()
                throw error
            }
        }

        pendingTask = task
        defer {
            pendingTask = nil
        }
        return try await task.value
    }

    func signOut() {
        try? CodexOAuthKeychainStore.shared.delete()
    }

    private func authorizationURL(codeChallenge: String, state: String) -> URL? {
        var components = URLComponents(url: authorizeURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: "openid profile email offline_access"),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "id_token_add_organizations", value: "true"),
            URLQueryItem(name: "originator", value: "openai_native"),
            URLQueryItem(name: "state", value: state)
        ]
        return components?.url
    }

    private func exchange(code: String, verifier: String) async throws -> CodexOAuthCredentials {
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = formBody([
            "grant_type": "authorization_code",
            "client_id": clientID,
            "code": code,
            "redirect_uri": redirectURI,
            "code_verifier": verifier
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
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

private final class OAuthCallbackListener: @unchecked Sendable {
    private let expectedState: String
    private var listener: NWListener?
    private var continuation: CheckedContinuation<String, Error>?

    init(expectedState: String) {
        self.expectedState = expectedState
    }

    func start() async throws {
        let listener = try NWListener(using: .tcp, on: 1455)
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
                  url.path == "/auth/callback",
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
