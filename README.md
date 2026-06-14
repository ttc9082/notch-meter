# NotchMeter

NotchMeter is a tiny open-source macOS notch HUD for keeping coding-agent and model usage visible without leaving the workspace.

The first provider reads local Codex Desktop / Codex CLI session JSONL files from `~/.codex/sessions`, finds `token_count` events, and shows rate-limit windows plus today's token totals. NotchMeter can also try the official Codex Enterprise Analytics API when configured, then fall back to local data. The project is intentionally provider-ready so future versions can add other coding agents and models, such as Claude Code.

Repository: `https://github.com/ttc9082/notch-meter`

## Status

This is an early prototype:

- macOS menu bar app: working
- notch-integrated floating pixel HUD: working
- small microinteractions for refresh, hover, status, and usage bars: working
- local Codex token/rate-limit provider: working
- remote Codex Analytics provider: experimental
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

- `auto`: try the remote Codex Analytics API when configured, otherwise read local Codex session files.
- `remote`: require the remote Codex Analytics API.
- `local`: only read local Codex session files.

Remote Codex analytics requires a ChatGPT Enterprise/Business workspace with Codex Analytics API access. Configure it with:

```sh
export NOTCHMETER_CODEX_SOURCE=remote
export NOTCHMETER_CODEX_WORKSPACE_ID="..."
export NOTCHMETER_CODEX_ANALYTICS_API_KEY="..."
swift run notch-meter
```

Codex access tokens and ChatGPT sign-in authorize Codex local workflows, but OpenAI's public docs do not currently describe a personal real-time quota endpoint for the 5-hour and weekly rate-limit windows. Until that exists, NotchMeter uses remote analytics for token totals and keeps using the newest local Codex rate-limit event to fill live quota windows.

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

- Current provider rate-limit usage, when present in the newest local usage event
- Today's total, input, output, cached input, and reasoning tokens
- 5-hour and weekly windows when Codex records them locally

## Privacy

NotchMeter only reads local usage files and only extracts numeric usage fields from supported provider events. For the current Codex provider, it reads:

- `payload.info.total_token_usage`
- `payload.info.last_token_usage`
- `payload.rate_limits`

It does not read, store, upload, or display prompt/response text.

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
