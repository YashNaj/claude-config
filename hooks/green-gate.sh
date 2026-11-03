#!/usr/bin/env bash
# Stop hook: refuse to end a turn while the project's tests are red.
#
# Runs only when the working tree changed since the last green run, so chat turns
# cost nothing. Detects the test command from the repo root, or reads an override
# from ~/.claude/claude-config/projects/<repo-basename>.env (TEST_CMD, TIMEOUT).
# Exit 2 + stderr = block, with the failing output as the reason. Claude Code caps
# consecutive Stop blocks at 8.
set -uo pipefail

input="$(cat)"
field() { printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null; }

cwd="$(field .cwd)"
[[ -n "$cwd" && -d "$cwd" ]] || exit 0
root="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$root" || exit 0

state_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/claude-config/state"
override="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/claude-config/projects/$(basename "$root").env"
mkdir -p "$state_dir"
key="$(printf '%s' "$root" | shasum | cut -c1-16)"
state="$state_dir/$key"

# Nothing to check if the tree is clean or only non-code files changed.
changed="$(git status --porcelain --untracked-files=all 2>/dev/null | awk '{print $NF}')"
[[ -n "$changed" ]] || exit 0
code_changed="$(printf '%s\n' "$changed" | grep -E '\.(ts|tsx|js|jsx|mjs|cjs|swift|py|go|rs|rb|kt|java|cs|prisma|sql)$' || true)"
[[ -n "$code_changed" ]] || exit 0

hash="$( (git status --porcelain --untracked-files=all; git diff; git diff --cached) 2>/dev/null | shasum | cut -c1-40)"
last_green="$(sed -n '1p' "$state" 2>/dev/null)"
last_red="$(sed -n '2p' "$state" 2>/dev/null)"
[[ "$hash" == "$last_green" ]] && exit 0
# Already blocked on exactly this state and nothing moved: don't block again.
[[ "$(field .stop_hook_active)" == "true" && "$hash" == "$last_red" ]] && exit 0

TEST_CMD="" TIMEOUT=300
[[ -f "$override" ]] && . "$override"

if [[ -z "$TEST_CMD" ]]; then
  if [[ -f package.json ]] && jq -e '.scripts.test' package.json >/dev/null 2>&1; then
    if [[ -f pnpm-lock.yaml ]]; then TEST_CMD="pnpm test"
    elif [[ -f yarn.lock ]]; then TEST_CMD="yarn test"
    elif [[ -f bun.lockb || -f bun.lock ]]; then TEST_CMD="bun test"
    else TEST_CMD="npm test --silent"; fi
  elif [[ -f Package.swift ]]; then TEST_CMD="swift test"
  elif [[ -f Cargo.toml ]]; then TEST_CMD="cargo test --quiet"
  elif [[ -f go.mod ]]; then TEST_CMD="go test ./..."
  elif [[ -f pyproject.toml || -f pytest.ini ]] && command -v pytest >/dev/null; then TEST_CMD="pytest -q"
  fi
fi
# Xcode projects need an explicit override: xcodebuild is too slow to run on every turn.
[[ -n "$TEST_CMD" ]] || exit 0

# Plain `bash -c`: inherit Claude Code's PATH (nvm, pnpm) rather than a login shell's,
# which on macOS can resolve to a different Node.
log="$(mktemp)"
if command -v timeout >/dev/null; then
  timeout "$TIMEOUT" bash -c "$TEST_CMD" >"$log" 2>&1
elif command -v gtimeout >/dev/null; then
  gtimeout "$TIMEOUT" bash -c "$TEST_CMD" >"$log" 2>&1
else
  bash -c "$TEST_CMD" >"$log" 2>&1
fi
status=$?

if [[ $status -eq 0 ]]; then
  printf '%s\n%s\n' "$hash" "" >"$state"
  rm -f "$log"
  exit 0
fi

printf '%s\n%s\n' "$last_green" "$hash" >"$state"
{
  echo "green-gate: \`$TEST_CMD\` failed (exit $status) in $root. Fix it before finishing; last 40 lines:"
  tail -n 40 "$log"
} >&2
rm -f "$log"
exit 2
