# claude-config

Personal Claude Code configuration, tracked so it can change as the tooling does.

| Path | Role |
|---|---|
| `CLAUDE.md` | User-level working agreement (~25 lines, language-neutral) |
| `rules/` | Path-scoped rules; load only for matching files (`typescript.md` today, Swift next) |
| `hooks/typecheck-on-edit.sh` | PostToolUse, async: `tsc --noEmit` on the nearest tsconfig after a `.ts/.tsx` write |
| `hooks/exercise-mode.sh` | SessionStart: in a Codespace (`CODESPACES=true`) or with `~/.claude/claude-config/exercise-mode` present, tells Claude exercise mode is on |
| `hooks/green-gate.sh` | Stop: runs the project's tests when code changed since the last green run; blocks on red |
| `settings.fragment.json` | The `hooks` block, merged into an existing `settings.json` |
| `settings.portable.json` | Full `settings.json` for a fresh machine (no machine-specific `autoMode` text) |
| `install.sh` | Symlinks and merges; `--portable` on a new machine |

Per-repo overrides (never committed to the repo itself): `~/.claude/claude-config/projects/<repo-basename>.env`
with `TEST_CMD="..."` and optional `TIMEOUT=300`. Xcode projects need one; `xcodebuild test` is too slow to run on every turn.

Hooks only fire after the folder is trusted in Claude Code. `/doctor` lists what loaded.
