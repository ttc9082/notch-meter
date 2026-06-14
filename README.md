# NotchMeter

NotchMeter is a tiny open-source macOS notch HUD for keeping coding-agent and model usage visible without leaving the workspace.

The first provider reads local Codex Desktop / Codex CLI session JSONL files from `~/.codex/sessions`, finds `token_count` events, and shows rate-limit windows plus today's token totals. The project is intentionally provider-ready so future versions can add other coding agents and models, such as Claude Code.

Repository: `https://github.com/ttc9082/notch-meter`

## Status

This is an early prototype:

- macOS menu bar app: working
- notch-integrated floating pixel HUD: working
- small microinteractions for refresh, hover, status, and usage bars: working
- local Codex token/rate-limit provider: working
- additional coding-agent/model providers: planned
- NotchNook or other notch-widget host: planned
- packaged `.app` release: planned

## Build

```sh
swift build
```

## Run

```sh
swift run notch-meter
```

The app appears as a small top-center HUD that visually attaches to the MacBook notch area.

Hover the compact notch HUD to expand the dashboard. The panel shows animated quota bars, token cards, themeable visual styles, and quick `SYNC` controls. Right-click the HUD to quit.

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
- Add a signed `.app` packaging workflow
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
