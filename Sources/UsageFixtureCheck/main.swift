import AgentUsageCore
import Foundation

let root = FileManager.default.temporaryDirectory
    .appendingPathComponent("notch-meter-fixture-check")
    .appendingPathComponent(UUID().uuidString, isDirectory: true)

try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

func write(_ contents: String, to url: URL) throws {
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try contents.write(to: url, atomically: true, encoding: .utf8)
}

try write(
    """
    {"timestamp":"2026-06-13T01:00:00.000Z","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"input_tokens":100,"cached_input_tokens":20,"output_tokens":10,"reasoning_output_tokens":2,"total_tokens":110},"last_token_usage":{"input_tokens":100,"cached_input_tokens":20,"output_tokens":10,"reasoning_output_tokens":2,"total_tokens":110}},"rate_limits":{"primary":{"used_percent":4.0,"window_minutes":300,"resets_at":1781360728},"secondary":{"used_percent":2.0,"window_minutes":10080,"resets_at":1781831720},"plan_type":"pro"}}}
    {"timestamp":"2026-06-13T02:00:00.000Z","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"input_tokens":150,"cached_input_tokens":40,"output_tokens":15,"reasoning_output_tokens":3,"total_tokens":165},"last_token_usage":{"input_tokens":50,"cached_input_tokens":20,"output_tokens":5,"reasoning_output_tokens":1,"total_tokens":55}},"rate_limits":{"primary":{"used_percent":7.0,"window_minutes":300,"resets_at":1781360728},"secondary":{"used_percent":3.0,"window_minutes":10080,"resets_at":1781831720},"plan_type":"pro"}}}
    """,
    to: root.appendingPathComponent("one.jsonl")
)

try write(
    """
    {"timestamp":"2026-06-13T03:00:00.000Z","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"input_tokens":10,"cached_input_tokens":0,"output_tokens":2,"reasoning_output_tokens":0,"total_tokens":12},"last_token_usage":{"input_tokens":10,"cached_input_tokens":0,"output_tokens":2,"reasoning_output_tokens":0,"total_tokens":12}},"rate_limits":{"primary":{"used_percent":8.0,"window_minutes":300,"resets_at":1781360728},"secondary":{"used_percent":4.0,"window_minutes":10080,"resets_at":1781831720},"plan_type":"pro"}}}
    """,
    to: root.appendingPathComponent("nested/two.jsonl")
)

var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(secondsFromGMT: 0)!

let reader = CodexUsageReader(sessionsDirectory: root, calendar: calendar)
let snapshot = try reader.snapshot()

precondition(snapshot.scannedFiles == 2, "expected 2 scanned files")
precondition(snapshot.sessionsWithUsage == 2, "expected 2 sessions with usage")
precondition(snapshot.totalUsage.totalTokens == 177, "expected 177 total tokens")
precondition(snapshot.totalUsage.inputTokens == 160, "expected 160 input tokens")
precondition(snapshot.lastUsage?.totalTokens == 12, "expected newest last usage")
precondition(snapshot.rateLimits?.primary?.usedPercent == 8.0, "expected newest primary limit")

print("usage fixture check passed")
