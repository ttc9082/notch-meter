# NotchMeter

[English](README.md)

NotchMeter 是一个开源的 macOS 刘海 HUD，用来在不离开工作区的情况下查看 coding agent 和模型用量。

它是一个好看的 coding agent HUD，会把订阅用量数据挂在你的屏幕顶部，并尽量和 MacBook 的真实刘海融为一体。平时它会收起成一个很轻量的顶部黑色区域，让你快速看到 5 小时和周额度；鼠标移上去后会展开成详情面板，让你实时了解自己的订阅用量、reset 时间和 token 数据。

NotchMeter 内置了一些视觉主题，并同时支持 Codex 和 Claude Code。项目结构也预留了更多 coding agent、模型和 provider 的接入空间。

![NotchMeter v1.0 themes](docs/assets/notchmeter-v1.0-themes.png)

## 为什么做这个

2026-06-12 那个周五，公司发了我一台 M 芯片 MacBook。我决定周末用它做点什么，于是有了 NotchMeter。

这是我开发的第一个 macOS 程序，也是这台 MBP 上开发的第一个程序。由于它几乎完全是 vibe coding 出来的，我对不少代码细节其实一无所知，所以它可能还有未知 bug。欢迎试用，也欢迎贡献。

## 当前状态

这是一个早期原型：

- macOS 菜单栏应用：可用
- 与刘海融合的悬浮 HUD：可用
- 收起/展开两种刘海状态：可用
- 多主题切换：可用
- provider 切换：可用
- 本地 Codex token 和额度窗口读取：可用
- 远程 Codex 订阅额度读取：实验性
- 远程 Claude Code 订阅额度读取：实验性
- 更多 coding agent / model provider：计划中
- 签名和 notarization：计划中

## Provider 支持

### Codex

Codex 支持授权模式远程获取订阅用量。这样即使你的 Codex 用量发生在别的机器、别的客户端或别的地方，NotchMeter 也可以观察到远程额度窗口。

Codex 同时支持本地数据作为 fallback。它可以读取本机 Codex session 文件，也可以复用本地 Codex 的授权缓存。如果你已经安装并登录过 Codex，又懒得在 NotchMeter 里再授权一次，这个 fallback 会比较方便。

### Claude Code

Claude Code 目前仅支持 code 授权，并通过远程接口获取用量。因为我自己没有订阅 Claude Code，所以这部分测试不如 Codex 充分，可能还有需要社区一起补齐的细节。

## 从源码运行

```sh
git clone https://github.com/ttc9082/notch-meter.git
cd notch-meter
swift run notch-meter
```

启动后，应用会出现在屏幕顶部中央，视觉上贴住 MacBook 的刘海区域。

把鼠标移动到收起的刘海 HUD 上，会展开详情面板。面板里包含额度进度条、token 数据卡片、provider 控制、登录状态、主题切换和 `SYNC` 同步按钮。右键点击 HUD 可以退出应用。

## 构建

```sh
swift build
```

## 本地打包

```sh
scripts/package-dmg.sh
```

打包后的 app 和 DMG 会输出到 `dist/`。

## 数据来源

默认情况下，NotchMeter 使用 `auto` 模式：

```sh
NOTCHMETER_CODEX_SOURCE=auto swift run notch-meter
```

支持的模式：

- `auto`：优先尝试读取当前 provider 的远程订阅用量，失败时回退到本地 Codex session 文件。
- `remote`：只使用远程订阅用量。
- `local`：只读取本地 Codex session 文件。

远程订阅用量通过 provider 兼容的 OAuth 流程登录。NotchMeter 会打开浏览器，把 provider token 保存到 `~/.notchmeter/auth.json`，并在需要时刷新 token。Codex 使用本地 callback。Claude Code 使用 Anthropic 注册的 HTTPS callback，所以授权后需要把 authorization code 粘贴回 NotchMeter；粘贴完整 callback URL 也可以。

高级用法下，也可以通过环境变量传入凭据，而不使用 NotchMeter 的 auth 文件：

```sh
export NOTCHMETER_CODEX_ACCESS_TOKEN="..."
export NOTCHMETER_CODEX_REFRESH_TOKEN="..."
# 或者
export NOTCHMETER_CLAUDE_ACCESS_TOKEN="..."
export NOTCHMETER_CLAUDE_REFRESH_TOKEN="..."
swift run notch-meter
```

远程订阅接口适合显示更准确的 5 小时和周额度窗口。本地 session 文件仍会作为兜底来源，也会在远程接口只返回额度信息时补充 token 总量。如果 NotchMeter 在 `~/.notchmeter/auth.json` 中没有找到 Codex 凭据，它也可以回退读取现有的 Codex `~/.codex/auth.json` 缓存。

如果网络需要代理，可以在应用里配置，也可以设置 `NOTCHMETER_PROXY_URL`。还可以写入配置文件 `~/.notchmeter/config.json`：

```json
{
  "proxyURL": "http://127.0.0.1:7890"
}
```

支持 HTTP、HTTPS、SOCKS 和 SOCKS5 代理地址。

## 显示哪些信息

- 当前 provider 和登录状态
- 可用时显示 5 小时和周额度窗口
- 可用时显示当天 total、input、output、cached input 和 reasoning tokens
- 进度条附近显示 reset 时间
- 针对不同 provider 只展示接口真实返回的有意义数据，不硬凑不存在的字段

## 隐私

本地模式下，NotchMeter 只读取本机用量文件，并且只提取支持事件里的数字用量字段。当前 Codex provider 会读取：

- `payload.info.total_token_usage`
- `payload.info.last_token_usage`
- `payload.rate_limits`

远程 provider 模式下，NotchMeter 会把自己的 OAuth 凭据保存到 `~/.notchmeter/auth.json`，文件权限为 `0600`；也可以改为从环境变量读取凭据。Codex 还可以回退读取 `~/.codex/auth.json`。应用只会向各 provider 的额度接口发送带认证的用量请求，不读取、保存、上传或展示你的 prompt/response 文本。

## 路线图

- 接入更多 coding agent 和模型用量 provider
- 针对不同 provider 做更清晰的专属详情页
- 增加自定义数据目录和刷新间隔设置
- 增加签名和 notarization 构建
- 如果 NotchNook 未来提供公开 widget API，增加兼容适配

## 贡献

这个项目会保持小而清晰。适合贡献的方向：

- 改进未来用量事件格式的解析
- 增加其他 coding agent 或模型用量 provider
- 优化不同 MacBook 屏幕尺寸下的刘海布局
- 改进主题设计和可访问性
- 完善签名 app 构建

## License

MIT
