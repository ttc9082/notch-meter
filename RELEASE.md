# Release Notes

## 1.0

NotchMeter 1.0 is the first formal release of the macOS notch HUD for coding-agent and model usage. It integrates with the MacBook notch, shows compact quota indicators in the notch ears, and expands into a themed usage dashboard on hover.

![NotchMeter v1.0 themes](https://raw.githubusercontent.com/ttc9082/notch-meter/main/docs/assets/notchmeter-v1.0-themes.png)

### Highlights

- Notch-integrated compact HUD with adaptive left/right ear widths.
- Compact mode shows 5-hour and weekly remaining quota.
- Expanded mode shows large remaining-quota progress bars and provider-specific detail cards.
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

- `NotchMeter-1.0.dmg`

Open the DMG, drag or run `NotchMeter.app`, then hover the notch HUD to expand details. This build is ad-hoc signed and not notarized yet, so macOS may require using right-click → Open the first time.

### Notes

- OAuth credentials are stored locally in `~/.notchmeter/auth.json` with `0600` permissions.
- Claude Code usage polling is cached and throttled to reduce `429` responses.
- Local Codex mode reads numeric usage fields from session JSONL files and does not read prompt or response text.
