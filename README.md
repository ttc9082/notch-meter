# NotchCodex

NotchCodex is a tiny open-source macOS status item for keeping Codex usage visible near the MacBook notch.

It reads local Codex Desktop / Codex CLI session JSONL files from `~/.codex/sessions`, finds `token_count` events, and shows the latest rate-limit percentage plus today's token totals in the menu bar. No network requests are made and message content is not parsed.

Repository: `https://github.com/ttc9082/notch-codex`

## Status

This is an early prototype:

- macOS menu bar app: working
- local Codex token/rate-limit reader: working
- NotchNook or other notch-widget host: planned
- packaged `.app` release: planned

## Build

```sh
swift build
```

## Run

```sh
swift run notch-codex
```

The app appears as a `Codex ...` status item in the macOS menu bar, usually adjacent to the notch on notched MacBooks.

## Install From Source

```sh
git clone https://github.com/ttc9082/notch-codex.git
cd notch-codex
swift run notch-codex
```

## Publish

Maintainers can create and push the public GitHub repository with either `gh` or `GITHUB_TOKEN`:

```sh
scripts/publish-github.sh
```

## What It Shows

- Current Codex rate-limit usage, when present in the newest local `token_count` event
- Today's total, input, output, cached input, and reasoning tokens
- Session scan count and last usage update time
- 5-hour and weekly windows when Codex records them locally

## Privacy

NotchCodex only reads local JSONL files and only extracts numeric usage fields from `token_count` events:

- `payload.info.total_token_usage`
- `payload.info.last_token_usage`
- `payload.rate_limits`

It does not read, store, upload, or display prompt/response text.

## Roadmap

- Add a proper SwiftUI popover with compact charts
- Add a NotchNook-compatible widget adapter if/when a public widget API is available
- Add a signed `.app` packaging workflow
- Add settings for custom Codex data directories and refresh intervals

## Contributing

This project is intentionally small. Good first contributions:

- improve parsing for future Codex usage event shapes
- add a native popover design
- document compatibility with notch utilities such as NotchNook
- package a signed app bundle for releases

## License

MIT
