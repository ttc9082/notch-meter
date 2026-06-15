# NotchMeter

[中文说明](README.zh-CN.md)

NotchMeter is a tiny open-source macOS notch HUD for keeping coding-agent and model usage visible without leaving the workspace.

It visually attaches to the MacBook notch, stays compact during normal work, and expands into a quota dashboard on hover. The first supported providers are Codex and Claude Code, with a provider-ready structure for more coding agents and model usage sources later.

![NotchMeter v1.0 themes](docs/assets/notchmeter-v1.0-themes.png)

## Status

This is an early prototype:

- macOS menu bar app: working
- notch-integrated floating HUD: working
- compact and expanded notch states: working
- theme switching: working
- provider switching: working
- local Codex token and rate-limit provider: working
- remote Codex subscription provider: experimental
- remote Claude Code subscription provider: experimental
- additional coding-agent/model providers: planned
- signed and notarized app builds: planned

## Run From Source

```sh
git clone https://github.com/ttc9082/notch-meter.git
cd notch-meter
swift run notch-meter
```

The app appears as a small top-center HUD that visually attaches to the MacBook notch area.

Hover the compact notch HUD to expand the dashboard. The panel shows quota bars, token cards, provider controls, sign-in status, theme switching, and quick `SYNC` controls. Right-click the HUD to quit.

## Build

```sh
swift build
```

## Package Locally

```sh
scripts/package-dmg.sh
```

The packaged app and DMG are written to `dist/`.

## Data Sources

By default, NotchMeter runs in `auto` mode:

```sh
NOTCHMETER_CODEX_SOURCE=auto swift run notch-meter
```

Supported values:

- `auto`: try remote subscription usage for the selected provider, otherwise read local Codex session files.
- `remote`: require remote subscription usage for the selected provider.
- `local`: only read local Codex session files.

Remote subscription usage signs in with provider-compatible OAuth flows. NotchMeter opens the browser, stores provider tokens in `~/.notchmeter/auth.json`, and refreshes tokens when needed. Codex uses a local callback. Claude Code uses Anthropic's registered HTTPS callback, so after approval you paste the authorization code back into NotchMeter. Pasting the full callback URL also works.

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

If your network needs a proxy, configure one in the app or set `NOTCHMETER_PROXY_URL`. You can also write a config file at `~/.notchmeter/config.json`:

```json
{
  "proxyURL": "http://127.0.0.1:7890"
}
```

HTTP, HTTPS, and SOCKS/SOCKS5 proxy URLs are accepted.

## What It Shows

- Current provider and sign-in state
- 5-hour and weekly quota windows when available
- Today's total, input, output, cached input, and reasoning tokens when available
- Reset timing near the quota bars
- Provider-specific details without inventing fields the provider does not return

## Privacy

In local mode, NotchMeter only reads local usage files and only extracts numeric usage fields from supported provider events. For the current Codex provider, it reads:

- `payload.info.total_token_usage`
- `payload.info.last_token_usage`
- `payload.rate_limits`

In remote provider mode, NotchMeter stores its own OAuth credentials in `~/.notchmeter/auth.json` with `0600` file permissions, or reads provider credentials from environment variables. Codex can additionally fall back to `~/.codex/auth.json`. It sends authenticated usage requests to each provider's quota endpoint and does not read, store, upload, or display prompt/response text.

## Roadmap

- Add more coding-agent and model usage providers
- Add clearer provider-specific dashboards
- Add settings for custom data directories and refresh intervals
- Add signed and notarized app builds
- Add a NotchNook-compatible widget adapter if a public widget API becomes available

## Contributing

This project is intentionally small. Good first contributions:

- improve parsing for future usage event shapes
- add provider adapters for other coding agents and model usage sources
- refine notch layout behavior across MacBook display sizes
- improve theme design and accessibility
- package signed app builds

## License

MIT
