# NotchMeter

NotchMeter is a tiny open-source macOS notch HUD for keeping coding-agent and model usage visible without leaving the workspace.

The first provider reads local Codex Desktop / Codex CLI session JSONL files from `~/.codex/sessions`, finds `token_count` events, and shows rate-limit windows plus today's token totals. NotchMeter can also sign in to provider subscription accounts, including Codex and Claude Code, then show remote quota data. The project is intentionally provider-ready so future versions can add other coding agents and models.

Repository: `https://github.com/ttc9082/notch-meter`

## Status

This is an early prototype:

- macOS menu bar app: working
- notch-integrated floating pixel HUD: working
- small microinteractions for refresh, hover, status, and usage bars: working
- local Codex token/rate-limit provider: working
- remote Codex subscription provider: experimental
- remote Claude Code subscription provider: experimental
- provider switching: working
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

- `auto`: try remote subscription usage for the selected provider, otherwise read local Codex session files.
- `remote`: require remote subscription usage for the selected provider.
- `local`: only read local Codex session files.

Remote subscription usage signs in with provider-compatible OAuth flows. Right-click the notch HUD to choose the active provider, then sign in to Codex or Claude Code. NotchMeter opens the browser, listens for the local OAuth callback, stores the resulting tokens per provider in `~/.notchmeter/auth.json`, and refreshes tokens when needed.

To force remote mode:

```sh
export NOTCHMETER_CODEX_SOURCE=remote
swift run notch-meter
```

For advanced setups, you can pass credentials through the environment instead of the NotchMeter auth file:

```sh
export NOTCHMETER_CODEX_ACCESS_TOKEN="..."
export NOTCHMETER_CODEX_REFRESH_TOKEN="..."
# or
export NOTCHMETER_CLAUDE_ACCESS_TOKEN="..."
export NOTCHMETER_CLAUDE_REFRESH_TOKEN="..."
swift run notch-meter
```

The remote subscription endpoint is useful for accurate 5-hour and weekly quota windows. Local session files are still used as a fallback and to fill token totals when the remote response only includes quota data. If NotchMeter has no Codex credentials in `~/.notchmeter/auth.json`, it can still fall back to the existing Codex `~/.codex/auth.json` cache.

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

In remote provider mode, NotchMeter stores its own OAuth credentials in `~/.notchmeter/auth.json` with `0600` file permissions, or reads provider credentials from environment variables. If an older NotchMeter build stored credentials in Keychain, the next launch migrates them into the auth file and removes the legacy item. Codex can additionally fall back to `~/.codex/auth.json`. It sends authenticated usage requests to each provider's quota endpoint and does not read, store, upload, or display prompt/response text.

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
