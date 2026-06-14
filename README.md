# NotchMeter

NotchMeter is a tiny open-source macOS notch HUD for keeping coding-agent and model usage visible without leaving the workspace.

The first provider reads local Codex Desktop / Codex CLI session JSONL files from `~/.codex/sessions`, finds `token_count` events, and shows rate-limit windows plus today's token totals. NotchMeter can also try Codex subscription-account usage through the same ChatGPT OAuth credentials used by Codex, then fall back to local data. The project is intentionally provider-ready so future versions can add other coding agents and models, such as Claude Code.

Repository: `https://github.com/ttc9082/notch-meter`

## Status

This is an early prototype:

- macOS menu bar app: working
- notch-integrated floating pixel HUD: working
- small microinteractions for refresh, hover, status, and usage bars: working
- local Codex token/rate-limit provider: working
- remote Codex subscription provider: experimental
- additional coding-agent/model providers: planned
- NotchNook or other notch-widget host: planned
- packaged `.app` / `.dmg` release workflow: working

## Build

```sh
swift build
```

## Package DMG

```sh
scripts/package-dmg.sh
```

The packaged app and DMG are written to `dist/`.

## Run

```sh
swift run notch-meter
```

The app appears as a small top-center HUD that visually attaches to the MacBook notch area.

Hover the compact notch HUD to expand the dashboard. The panel shows animated quota bars, token cards, themeable visual styles, and quick `SYNC` controls. Right-click the HUD to quit.

## Data Sources

By default, NotchMeter runs in `auto` mode:

```sh
NOTCHMETER_CODEX_SOURCE=auto swift run notch-meter
```

Supported values:

- `auto`: try remote Codex subscription usage from your Codex login, otherwise read local Codex session files.
- `remote`: require remote Codex subscription usage.
- `local`: only read local Codex session files.

Remote subscription usage signs in with a Codex-compatible ChatGPT OAuth flow. Right-click the notch HUD and choose **Sign in with OpenAI**. NotchMeter opens the browser, listens for the local OAuth callback, stores the resulting tokens in macOS Keychain, and refreshes tokens when needed.

To force remote mode:

```sh
export NOTCHMETER_CODEX_SOURCE=remote
swift run notch-meter
```

For advanced setups, you can pass credentials through the environment instead of Keychain:

```sh
export NOTCHMETER_CODEX_ACCESS_TOKEN="..."
export NOTCHMETER_CODEX_REFRESH_TOKEN="..."
swift run notch-meter
```

The remote subscription endpoint is useful for accurate 5-hour and weekly quota windows. Local session files are still used as a fallback and to fill token totals when the remote response only includes quota data. If NotchMeter has no Keychain credentials, it can still fall back to the existing Codex `~/.codex/auth.json` cache.

## Install From Source

```sh
git clone https://github.com/ttc9082/notch-meter.git
cd notch-meter
swift run notch-meter
```

## Publish

Maintainers can create and push the public GitHub repository with either `gh` or `GITHUB_TOKEN`:

```sh
scripts/publish-github.sh
```

GitHub Actions runs CI on pushes and pull requests. Pushing a version tag creates a release DMG:

```sh
git tag v0.1.0
git push origin v0.1.0
```

## What It Shows

- Current provider rate-limit usage
- Today's total, input, output, cached input, and reasoning tokens
- 5-hour and weekly windows when available from remote Codex subscription usage or local Codex events

## Privacy

In local mode, NotchMeter only reads local usage files and only extracts numeric usage fields from supported provider events. For the current Codex provider, it reads:

- `payload.info.total_token_usage`
- `payload.info.last_token_usage`
- `payload.rate_limits`

In remote Codex mode, NotchMeter stores its own OAuth credentials in macOS Keychain, or reads credentials from environment variables / `~/.codex/auth.json` as fallback, then sends an authenticated usage request to OpenAI's ChatGPT Codex backend. It does not read, store, upload, or display prompt/response text.

## Roadmap

- Add a proper SwiftUI popover with compact charts
- Add Claude Code and other provider adapters
- Add a NotchNook-compatible widget adapter if/when a public widget API is available
- Add Developer ID signing and notarization for release builds
- Add settings for custom Codex data directories and refresh intervals

## Contributing

This project is intentionally small. Good first contributions:

- improve parsing for future Codex usage event shapes
- add provider adapters for other coding agents and model usage sources
- add a native popover design
- document compatibility with notch utilities such as NotchNook
- package a signed app bundle for releases

## License

MIT
