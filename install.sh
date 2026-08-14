#!/bin/bash
# Installs statusline.sh into ~/.claude and wires it up in ~/.claude/settings.json.
# Safe to re-run: it only ever overwrites the copied script and adds/updates the
# "statusLine" key in settings.json (a timestamped backup is made first).
set -euo pipefail

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
SCRIPT_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/statusline.sh"
SCRIPT_DEST="$CLAUDE_DIR/statusline.sh"

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not installed." >&2
  echo "Install it first, e.g.: brew install jq" >&2
  exit 1
fi

mkdir -p "$CLAUDE_DIR"
cp "$SCRIPT_SRC" "$SCRIPT_DEST"
chmod +x "$SCRIPT_DEST"
echo "Copied statusline.sh -> $SCRIPT_DEST"

if [ -f "$SETTINGS_FILE" ]; then
  backup="$SETTINGS_FILE.bak.$(date +%Y%m%d%H%M%S)"
  cp "$SETTINGS_FILE" "$backup"
  echo "Backed up existing settings.json -> $backup"
else
  echo '{}' > "$SETTINGS_FILE"
fi

tmp="$(mktemp)"
jq --arg cmd "$SCRIPT_DEST" \
  '.statusLine = {"type": "command", "command": $cmd}' \
  "$SETTINGS_FILE" > "$tmp"
mv "$tmp" "$SETTINGS_FILE"

echo "Updated $SETTINGS_FILE with the statusLine config."
echo "Restart Claude Code (or open a new session) to see the statusline."
