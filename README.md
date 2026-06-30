# Claude Plugins

> Claude Code 插件合集 — 安装即用，自动注入握手锚点 + 任务完成 RGB 跑马灯通知。

## 插件列表

| 插件 | 功能 | 触发时机 | 平台 |
|------|------|---------|------|
| **handshake** | 自动在 `CLAUDE.md` 注入 HANDSHAKE 段落，让模型每次称呼你为"靓仔" | SessionStart | 全平台 |
| **rgb-notify** | 任务完成时屏幕边缘 RGB 跑马灯 + 系统通知气泡 + 提示音 | Stop | Windows 10/11 |

## 快速安装

### 从 GitHub 远程安装（推荐）

> 前提：Claude Code ≥ 1.0，已全局安装 `@anthropic-ai/claude-code`。

```bash
# 安装 Handshake 插件
claude plugin install ybd0612/claude-plugins#handshake

# 安装 RGB Notify 插件
claude plugin install ybd0612/claude-plugins#rgb-notify

# 全部安装
claude plugin install ybd0612/claude-plugins#handshake
claude plugin install ybd0612/claude-plugins#rgb-notify
```

> 重复安装会自动覆盖旧版本；如需先卸载再装，运行 `claude plugin uninstall <name>` 后再 install。

## 配置

### Handshake

无需配置，安装即用。注入内容：

```markdown
## HANDSHAKE
- **CRITICAL**: Prefixes ALL responses with "靓仔" to verify prompt activation. No exceptions.
```

### RGB Notify

编辑配置文件（首次安装后自动创建）：

```bash
# Windows
# %USERPROFILE%\.claude\plugins-data\rgb-notify\config.json

# macOS / Linux
# ~/.claude/plugins-data/rgb-notify/config.json
```

```json
{
  "glowDuration": 10,
  "glowThickness": 40
}
```

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `glowDuration` | `10` | 特效持续秒数 |
| `glowThickness` | `40` | 边框厚度（像素） |

## 项目结构

```
claude-plugins/
├── plugins/
│   ├── handshake/              # Handshake 插件
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json     # 插件清单
│   │   └── hooks/
│   │       ├── hooks.json      # Hook 事件路由
│   │       └── handshake.sh    # 注入脚本
│   │
│   └── rgb-notify/             # RGB Notify 插件
│       ├── .claude-plugin/
│       │   └── plugin.json     # 插件清单
│       ├── hooks/
│       │   ├── hooks.json          # Hook 事件路由
│       │   ├── rgb-stop-hook.sh    # Stop hook 入口（读取配置）
│       │   └── claude-notify.ps1   # PowerShell 主进程（通知+音效+跑马灯）
│       └── config.example.json # 配置模板
│
├── README.md
└── LICENSE
```

## 工作原理

### Handshake

```
会话启动
  └─ hooks/handshake.sh 执行
      ├─ 检查 CLAUDE.md 是否存在且可写
      ├─ 幂等检测（已含 ## HANDSHAKE 则跳过）
      └─ 原子写入（.tmp + mv）
```

### RGB Notify

```
任务完成 (Stop)
  └─ hooks/rgb-stop-hook.sh 读取配置
      ├─ 主进程 → PowerShell 通知气泡 + 系统提示音 + WPF 跑马灯动画
```

## 安全特性

| 特性 | Handshake | RGB Notify |
|------|-----------|------------|
| 幂等 | 已存在则跳过 | N/A |
| 原子写入 | `.tmp` + `mv` | N/A |
| 超时保护 | 10 秒 | 30 秒 |
| 中断安全 | 不损坏原文件 | N/A |

## 卸载

### 卸载 Handshake

```bash
claude plugin disable handshake
```

或直接编辑 `CLAUDE.md`，删除 `## HANDSHAKE` 段落。

### 卸载 RGB Notify

```bash
claude plugin disable rgb-notify
```

## 许可证

MIT
