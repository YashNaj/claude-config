---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---

# TypeScript

- Never silence the compiler to make a test pass: no `any`, `as unknown as`, `// @ts-ignore`, or non-null `!` added to get past an error. Narrow the type or fix the data.
- Keep the project's layering. If routes call services and services call repositories, a new feature does the same; no shortcuts "for speed".
- Validate at the boundary (zod or whatever the repo uses), trust types inside.
- Tests live where the repo keeps them and use its runner and helpers. Assert on behaviour and on the exact error status/shape, not on `toBeTruthy()`.
- No `console.log` left behind; use the project's logger or remove it.
- Prefer `unknown` + narrowing over `any` in catch blocks; rethrow what you cannot handle.
