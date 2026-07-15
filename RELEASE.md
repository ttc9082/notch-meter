# Release Notes

## 1.0.5

NotchMeter 1.0.5 improves quota-window accuracy and removes the persistent gray halo that could appear around the notch HUD after expanding or collapsing it.

![NotchMeter v1.0 themes](https://raw.githubusercontent.com/ttc9082/notch-meter/main/docs/assets/notchmeter-v1.0-themes.png)

### Highlights

- Shows the most relevant available Codex quota window instead of assuming fixed 5-hour and weekly rows.
- Preserves both available Claude Code quota windows and sizes the expanded HUD to the actual row count.
- Uses the provider mark in the compact left ear and keeps the active quota summary readable in the right ear.
- Labels quota windows from their real durations and uses the longest available window in the standalone usage panel.
- Removes both the transparent panel shadow and the SwiftUI shape shadow, preventing a cached gray halo after notch expansion or collapse.

### Download

Download the DMG from this release's assets:

- `NotchMeter-1.0.5.dmg`

Open the DMG, drag `NotchMeter.app` to `Applications`, then hover the notch HUD to expand details. This build is ad-hoc signed and not notarized yet, so macOS may require using right-click → Open the first time.

### Notes

- OAuth credentials are stored locally in `~/.notchmeter/auth.json` with `0600` permissions.
- Claude Code usage polling is cached and throttled to reduce `429` responses.
- Local Codex mode reads numeric usage fields from session JSONL files and does not read prompt or response text.

## 1.0.4

NotchMeter 1.0.4 is a small reliability release for provider switching, sync feedback, and packaged app assets. It keeps the existing Codex and Claude Code usage dashboard, while making in-progress and failed refreshes less disruptive.

![NotchMeter v1.0 themes](https://raw.githubusercontent.com/ttc9082/notch-meter/main/docs/assets/notchmeter-v1.0-themes.png)

### Highlights

- Keeps the last good usage snapshot visible while a sync is still loading or after a transient sync failure.
- Stores the current-session usage snapshot separately for Codex and Claude Code, so switching providers does not wipe the other provider's displayed data.
- Shows the last successful sync time when hovering the expanded `SYNC` control.
- Keeps compact 5-hour and weekly quota labels visible during sync errors when cached rate-limit data is available.
- Packages the SwiftPM resource bundle into the DMG app bundle, so provider logos and app assets remain available in installed builds.

### Download

Download the DMG from this release's assets:

- `NotchMeter-1.0.4.dmg`

Open the DMG, drag `NotchMeter.app` to `Applications`, then hover the notch HUD to expand details. This build is ad-hoc signed and not notarized yet, so macOS may require using right-click → Open the first time.

### Notes

- OAuth credentials are stored locally in `~/.notchmeter/auth.json` with `0600` permissions.
- Claude Code usage polling is cached and throttled to reduce `429` responses.
- Local Codex mode reads numeric usage fields from session JSONL files and does not read prompt or response text.

## 1.0.1

NotchMeter 1.0.1 is a polish release for the macOS notch HUD. It keeps the first formal release's Codex and Claude Code usage dashboard, while improving the install experience, app branding, and theme readability.

![NotchMeter v1.0 themes](https://raw.githubusercontent.com/ttc9082/notch-meter/main/docs/assets/notchmeter-v1.0-themes.png)

### Highlights

- Notch-integrated compact HUD with adaptive left/right ear widths.
- Compact mode shows 5-hour and weekly remaining quota.
- Expanded mode shows large remaining-quota progress bars and provider-specific detail cards.
- Custom NotchMeter app icon and README logo.
- Drag-to-Applications DMG installer with a custom background and install arrow.
- Larger provider logo in the compact left notch ear.
- Higher-contrast compact HUD colors.
- Higher-contrast detail card and progress colors across themes.
- Provider switching between Codex and Claude Code.
- Codex remote subscription usage via OAuth, with local Codex usage fallback.
- Claude Code remote subscription usage via OAuth code paste flow.
- Self-contained notch modals for provider sign-in code entry, sign-out confirmation, and proxy configuration.
- Loading and success toast feedback for sync and sign-in flows.
- Proxy support through the app UI, config file, or environment variables.
- Six visual themes: `PIX`, `BAU`, `SWI`, `DEC`, `COB`, and `TBL`.
- Local fixture check target for CI-friendly parser verification.

### Download

Download the DMG from this release's assets:

- `NotchMeter-1.0.1.dmg`

Open the DMG, drag `NotchMeter.app` to `Applications`, then hover the notch HUD to expand details. This build is ad-hoc signed and not notarized yet, so macOS may require using right-click → Open the first time.

### Notes

- OAuth credentials are stored locally in `~/.notchmeter/auth.json` with `0600` permissions.
- Claude Code usage polling is cached and throttled to reduce `429` responses.
- Local Codex mode reads numeric usage fields from session JSONL files and does not read prompt or response text.
