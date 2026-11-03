#!/usr/bin/env bash
# PostToolUse hook (Edit|Write|MultiEdit), async: after a .ts/.tsx write, run
# `tsc --noEmit` against the nearest tsconfig.json and hand any errors back to
# Claude. Silent when the file is not TypeScript, no tsconfig/tsc is found, or
# another run for the same tsconfig is already in flight.
set -uo pipefail

input="$(cat)"
file="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
[[ "$file" == *.ts || "$file" == *.tsx ]] || exit 0
[[ -f "$file" ]] || exit 0
[[ "$file" == *.d.ts ]] && exit 0

dir="$(cd "$(dirname "$file")" && pwd)"
root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || echo /)"

tsconfig=""
d="$dir"
while [[ "$d" != "/" && "$d" == "$root"* ]]; do
  if [[ -f "$d/tsconfig.json" ]]; then tsconfig="$d/tsconfig.json"; break; fi
  d="$(dirname "$d")"
done
[[ -n "$tsconfig" ]] || exit 0
proj="$(dirname "$tsconfig")"

tsc=""
d="$proj"
while [[ "$d" != "/" ]]; do
  if [[ -x "$d/node_modules/.bin/tsc" ]]; then tsc="$d/node_modules/.bin/tsc"; break; fi
  [[ "$d" == "$root" ]] && break
  d="$(dirname "$d")"
done
[[ -n "$tsc" ]] || exit 0

lock="${TMPDIR:-/tmp}/claude-typecheck-$(printf '%s' "$tsconfig" | shasum | cut -c1-12).lock"
mkdir "$lock" 2>/dev/null || exit 0
trap 'rmdir "$lock" 2>/dev/null' EXIT

out="$(cd "$proj" && "$tsc" --noEmit -p "$tsconfig" --pretty false 2>&1)"
status=$?
[[ $status -eq 0 ]] && exit 0

rel="${tsconfig#"$root"/}"
{
  echo "typecheck: \`tsc --noEmit -p $rel\` reports errors after editing ${file#"$root"/}:"
  printf '%s\n' "$out" | grep -E 'error TS' | head -n 25
} >&2
exit 2
