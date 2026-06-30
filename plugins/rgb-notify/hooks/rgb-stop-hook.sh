#!/bin/bash
# Stop hook entry: read config and launch rgb-notify

PLUGIN_DATA_DIR="${HOME}/.claude/plugins-data/rgb-notify"
CONFIG_FILE="${PLUGIN_DATA_DIR}/config.json"

# Default values
GLOW_DURATION=10
GLOW_THICKNESS=40
ENABLE_MARQUEE=true
ENABLE_NOTIFY=true
ENABLE_SOUND=true

# Read config if exists
if [ -f "$CONFIG_FILE" ]; then
  GLOW_DURATION=$(grep -o '"glowDuration":[0-9]*' "$CONFIG_FILE" | grep -o '[0-9]*$')
  GLOW_THICKNESS=$(grep -o '"glowThickness":[0-9]*' "$CONFIG_FILE" | grep -o '[0-9]*$')
  ENABLE_MARQUEE=$(grep -o '"enableMarquee":[a-z]*' "$CONFIG_FILE" | grep -o '[a-z]*$')
  ENABLE_NOTIFY=$(grep -o '"enableNotify":[a-z]*' "$CONFIG_FILE" | grep -o '[a-z]*$')
  ENABLE_SOUND=$(grep -o '"enableSound":[a-z]*' "$CONFIG_FILE" | grep -o '[a-z]*$')
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Launch PowerShell script with config
pwsh -NoProfile -ExecutionPolicy Bypass -File "${SCRIPT_DIR}/claude-notify.ps1" \
  -GlowDuration "$GLOW_DURATION" \
  -GlowThickness "$GLOW_THICKNESS" \
  -EnableMarquee "$ENABLE_MARQUEE" \
  -EnableNotify "$ENABLE_NOTIFY" \
  -EnableSound "$ENABLE_SOUND"
