import Foundation

public enum AgentUsageProvider: String, CaseIterable, Codable, Sendable {
    case codex
    case claude

    public var displayName: String {
        switch self {
        case .codex:
            return "Codex"
        case .claude:
            return "Claude Code"
        }
    }

    public var compactName: String {
        switch self {
        case .codex:
            return "CX"
        case .claude:
            return "CC"
        }
    }
}
