#!/usr/bin/env bash
# SessionStart hook: inside a GitHub Codespace (or when ~/.claude/claude-config/exercise-mode
# exists), tell Claude that exercise mode is on for this session. Stdout from a
# SessionStart hook is added to Claude's context. Silent everywhere else.
marker="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/claude-config/exercise-mode"
[[ "${CODESPACES:-}" == "true" || "${CLAUDE_EXERCISE_MODE:-}" == "1" || -f "$marker" ]] || exit 0

cat <<'EOF'
Exercise mode is ON for this session (see ~/.claude/CLAUDE.md, "Exercise mode"):
skip brainstorming unless an answer would change what gets built; write a lean plan in
chat; execute natively in this session, no subagent-driven development; one /code-review
pass at the end that also flags narration comments; the hooks run the typecheck and tests,
trust their output. Never create .claude/, CLAUDE.local.md, settings.local.json, or any
file outside the task in this repository.
EOF
