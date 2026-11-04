#!/usr/bin/env bash
# Installs this repo into ~/.claude (or $CLAUDE_CONFIG_DIR). Idempotent.
#
#   bash install.sh            # this machine: symlink CLAUDE.md, rules/, hooks/; merge settings.fragment.json
#   bash install.sh --portable # a fresh machine/Codespace: also install settings.portable.json as settings.json
#
# Nothing here touches any project repository.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
PORTABLE=0
[[ "${1:-}" == "--portable" ]] && PORTABLE=1

log() { printf '\033[1;34m[claude-config]\033[0m %s\n' "$*"; }
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

mkdir -p "$CLAUDE_DIR" "$CLAUDE_DIR/claude-config/projects"

link() { # link <source> <target>
  if [[ -e "$2" && ! -L "$2" ]]; then
    mv "$2" "$2.bak.$(date +%s)"
    log "backed up existing $(basename "$2")"
  fi
  ln -sfn "$1" "$2"
}
link "$HERE/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
link "$HERE/rules"     "$CLAUDE_DIR/rules"
link "$HERE/hooks"     "$CLAUDE_DIR/hooks"
chmod +x "$HERE"/hooks/*.sh
log "linked CLAUDE.md, rules/, hooks/ into $CLAUDE_DIR"

settings="$CLAUDE_DIR/settings.json"
if (( PORTABLE )); then
  [[ -f "$settings" ]] && cp "$settings" "$settings.bak.$(date +%s)"
  cp "$HERE/settings.portable.json" "$settings"
  log "installed settings.portable.json as settings.json"
else
  [[ -f "$settings" ]] || echo '{}' >"$settings"
  tmp="$(mktemp)"
  # Replace our hook groups (identified by script path) rather than appending duplicates.
  jq -s '
    def ours: "typecheck-on-edit\\.sh|green-gate\\.sh|exercise-mode\\.sh";
    def strip_ours(groups): [groups[]? | select((.hooks // []) | all(.command | test(ours) | not))];
    .[0] as $cur | .[1] as $frag
    | $cur
    | .hooks = (($cur.hooks // {}) | with_entries(.value = strip_ours(.value)))
    | reduce ($frag.hooks | keys[]) as $ev (.; .hooks[$ev] = ((.hooks[$ev] // []) + $frag.hooks[$ev]))
  ' "$settings" "$HERE/settings.fragment.json" >"$tmp" && mv "$tmp" "$settings"
  log "merged hooks into $settings"
fi

log "done — run /doctor inside Claude Code to confirm"
