# Working agreement

## Evidence before claims
- "Done", "passing", "fixed" come with the command you ran and its last lines. No output, no claim.
- Before a bugfix, reproduce it with a failing test or a failing command; keep the test.
- The project's whole suite defines green, not the one file you touched.

## Scope
- Make the smallest change that satisfies the test or the ask. Say so before widening it.
- No new dependencies, config files, scripts, or directories unless the task needs them — and say so when it does.
- In a repository you do not own, never create `.claude/`, `CLAUDE.local.md`, `settings.local.json`, or any file outside the task. Personal config lives in `~/.claude` only.

## Fit the codebase
- The repo's own `CLAUDE.md`, conventions, and existing patterns win over your defaults. Read the neighbours before writing.
- Reuse what is there before adding an abstraction. Three similar lines beat a premature helper.

## Comments
- Comments explain *why*, never *what*. Nothing that restates the line below it, no docblock on every function, no "handle the error" narration.
- Match the file's existing comment density; if it has none, add none. A better name beats a comment.

## Exercise mode
When I say "exercise mode": skip brainstorming unless an answer would change what gets built; write a lean plan; execute natively in this session, no subagent-driven development; one `/code-review` pass at the end that also flags narration comments; the hooks run the tests and typecheck, trust their output.

## Tooling
- Cloudflare: use the `cf` CLI unless the project has a Wrangler configuration file.
