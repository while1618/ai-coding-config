---
description: Naming, structure, and how to match an unfamiliar codebase.
paths:
  - "**/*.{ts,tsx,js,jsx,mjs,cjs}"
  - "**/*.py"
  - "**/*.go"
  - "**/*.rs"
  - "**/*.{java,kt,kts,scala}"
  - "**/*.{cs,fs}"
  - "**/*.rb"
  - "**/*.php"
  - "**/*.{ex,exs}"
  - "**/*.swift"
  - "**/*.{c,cc,cpp,h,hpp,m,mm}"
  - "**/*.{sh,bash}"
  - "**/*.sql"
  - "**/*.{vue,svelte}"
---

# Naming and style

## The codebase wins

Read the surrounding code before you write any. Copy its naming pattern, file layout, import order,
and error-handling shape. A consistent codebase you mildly dislike beats a mixed one you half-improved.

Where the codebase is silent, apply the rules below. Where the codebase documents a standard
(`CONTRIBUTING.md`, `CODING_STANDARDS.md`, a linter config), that standard overrides this file.

## Names

A name states what the thing is or does, in the vocabulary the project already uses.

- **Reveal intent.** `retryBudget` beats `n`. `activeSubscribers` beats `list2`.
- **Say the unit.** `timeoutMs`, `sizeBytes`, `priceCents`. A bare `timeout` invites a factor-of-1000 bug.
- **Booleans read as claims.** `isExpired`, `hasQuota`, `canRetry` — each answers yes or no.
- **Functions lead with a verb.** `parseHeader`, `resolveBaseBranch`. A noun name for a function hides
  whether it computes, fetches, or mutates.
- **One word per concept.** Pick `fetch` or `get` or `load` for the same action and use it everywhere.
  Rotating synonyms makes the reader ask whether three names mean three things.
- **Match the domain.** Use the project's own word — if the code says `tenant`, do not introduce `org`.
- **Length tracks scope.** A two-line loop index can be `i`. A module-level export cannot.

When no honest name comes, the design is unclear. Fix the design, not the name.

## Shape

- **One reason to change per file.** A file edited for several unrelated reasons wants splitting.
- **Files that change together live together.** Split by responsibility, not by technical layer.
- **Prefer small focused files.** You reason better about code you can hold at once, and edits to a
  focused file are more reliable.
- **Order top-down.** Public surface first, helpers below, so a reader meets the interface before the
  machinery.
- **Guard clauses over nesting.** Return early on the invalid case. Keep the happy path at one indent.
- **Delete instead of commenting out.** Git holds the history.

## Formatting

The formatter decides. Never argue with it and never hand-format around it. If the project has no
formatter, match the file you are editing and say that a formatter would help.

## Smells worth naming

These are heuristics, not violations. Name the smell, quote the code, and let the human decide. A
documented project standard overrides every one of them, and anything a linter already catches is the
linter's job.

| Smell | What you see | The move |
|---|---|---|
| Mysterious name | The name does not reveal what it holds or does | Rename. If no honest name comes, the design is murky |
| Duplicated code | The same logic shape in two places | Extract it, call it from both |
| Feature envy | A method reaches into another object's data more than its own | Move the method to the data |
| Data clumps | The same few parameters always travel together | Bundle them into one type |
| Primitive obsession | A string or int stands in for a domain concept | Give the concept its own small type |
| Repeated switches | The same branch on the same type recurs | Use polymorphism, or one shared map |
| Shotgun surgery | One logical change forces edits across many files | Gather what changes together |
| Divergent change | One file changes for several unrelated reasons | Split by reason |
| Speculative generality | Parameters or hooks for needs nobody has | Delete it, inline it back |
| Message chains | `a.b().c().d()` navigation in the caller | Hide the walk behind one method |
| Middle man | A class that mostly delegates onward | Cut it, call the real target |
| Refused bequest | A subclass ignores most of what it inherits | Drop inheritance, use composition |
