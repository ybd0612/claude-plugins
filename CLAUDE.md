# CLAUDE.md

## HANDSHAKE: AUTO-INJECTED
- **CRITICAL**: Prefixes ALL responses with "靓仔" to verify prompt activation. No exceptions.


This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Claude Code plugin collection** — a monorepo of shell/PowerShell hook scripts packaged as Claude Code plugins. Two plugins:

- **handshake** — Injects a `## HANDSHAKE` section into `CLAUDE.md` on session start (cross-platform bash)
- **rgb-notify** — Triggers a Windows WPF RGB marquee screen-edge animation on task completion (bash entry → PowerShell main)

## Architecture

```
claude-plugins/
├── .claude-plugin/marketplace.json   # Marketplace manifest (for /plugins marketplace add)
├── plugins/
│   ├── handshake/
│   │   ├── .claude-plugin/plugin.json   # Plugin manifest (hooks field omitted; hooks in separate file)
│   │   └── hooks/
│   │       ├── hooks.json               # Hook routing: SessionStart → handshake.sh
│   │       └── handshake.sh             # Injects HANDSHAKE section into CLAUDE.md
│   │
│   └── rgb-notify/
│       ├── .claude-plugin/plugin.json   # Plugin manifest
│       ├── hooks/
│       │   ├── hooks.json               # Hook routing: Stop → rgb-stop-hook.sh
│       │   ├── rgb-stop-hook.sh         # Entry: reads config, launches claude-notify.ps1
│       │   └── claude-notify.ps1        # Main: WPF marquee + system notification + sound
│       └── config.example.json          # Config template (glowDuration, glowThickness)
└── README.md
```

## Key Patterns

### Hook Script Convention
- Each plugin has a `.claude-plugin/plugin.json` (metadata only, no hooks field)
- Hook routing is defined in `hooks/hooks.json` with outer `"hooks"` wrapper and event arrays
- Entry scripts use `${CLAUDE_PLUGIN_ROOT}` env var to locate sibling files

### Handshake (handshake.sh)
- Reads `CLAUDE.md` from `CLAUDE_CODE_WORKTREE` (falls back to cwd)
- Idempotent: skips if `## HANDSHAKE` already exists
- Atomic write: writes to `.tmp` then `mv` to avoid corruption
- Inserts HANDSHAKE section after first `#` heading (or at top if no headings)

### RGB Notify (rgb-stop-hook.sh → claude-notify.ps1)
- Windows-only: reads config from `%USERPROFILE%\.claude\plugins-data\rgb-notify\config.json`
- Uses `Start-Process` to spawn WPF animation in separate process (WPF windows can't run in background jobs)
- Animation: 4 screen edges with HSV gradient marquee, breathing opacity, configurable duration/thickness

## Plugin Installation

```bash
# Add marketplace source
/plugins marketplace add ybd0612/claude-plugins

# Install plugins
/plugins install handshake@ybd06-claude-plugins
/plugins install rgb-notify@ybd06-claude-plugins
```

## Editing Plugins

When modifying a plugin:
1. **plugin.json** — only metadata (name, version, description). Never put hooks inline; use `hooks/hooks.json`
2. **hooks/hooks.json** — must wrap events under `"hooks"` key, each event value is an **array** `[{ matcher, hooks }]`
3. **Hook scripts** — use `${CLAUDE_PLUGIN_ROOT}` for relative paths to plugin files
4. Validate with `claude plugin validate <plugin-path>`
