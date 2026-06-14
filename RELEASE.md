# Release Notes

## 0.1.0 Prototype

Initial open-source prototype for NotchMeter, a MacBook notch HUD for coding-agent and model usage.

![NotchMeter v0.1.0 themes](https://raw.githubusercontent.com/ttc9082/notch-meter/main/docs/assets/notchmeter-v0.1.0-themes.png)

### Highlights

- Reads local Codex `token_count` events from `~/.codex/sessions`
- Shows current coding-agent usage in a notch-integrated macOS HUD
- Compact notch mode shows 5-hour and weekly remaining quota
- Expanded mode shows large remaining-quota progress bars and token cards
- Displays `TOTAL`, `OUT`, `THINK`, and `CACHED` token usage
- Includes four visual themes: `PIX`, `ORB`, `COB`, and `TBL`
- Theme changes affect compact and expanded states, including typography, spacing, card shapes, and progress bars
- Right-click menu exits the app
- Includes a fixture check target for CI-friendly parser verification

### Download

- `NotchMeter-0.1.0.dmg`

This release uses ad-hoc signing. Developer ID signing and notarization are planned.
