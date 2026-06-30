#!/bin/bash
# Stop hook entry: read config and launch rgb-notify

PLUGIN_DATA_DIR="${HOME}/.claude/plugins-data/rgb-notify"
CONFIG_FILE="${PLUGIN_DATA_DIR}/config.json"

# Default values
GLOW_DURATION=10
GLOW_THICKNESS=40

# Read config if exists
if [ -f "$CONFIG_FILE" ]; then
  GLOW_DURATION=$(grep -o '"glowDuration":[0-9]*' "$CONFIG_FILE" | grep -o '[0-9]*$')
  GLOW_THICKNESS=$(grep -o '"glowThickness":[0-9]*' "$CONFIG_FILE" | grep -o '[0-9]*$')
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Launch PowerShell script with config
pwsh -NoProfile -ExecutionPolicy Bypass -File "${SCRIPT_DIR}/claude-notify.ps1" -GlowDuration "$GLOW_DURATION" -GlowThickness "$GLOW_THICKNESS"
