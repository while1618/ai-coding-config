---
description: What to comment, what to explain, and what to leave to the code.
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

# Comments and documentation

## What a comment is for

Code states *what* happens. A comment states what the code cannot: **why**, and what would break.

Write a comment when you know something the next reader cannot recover from the code:

- **Why this way.** The alternative you rejected and the reason. `// Sequential: the API rate-limits
  parallel writes to this endpoint.`
- **The invariant.** What must stay true. `// Callers hold the lock. Do not acquire it here.`
- **The non-obvious constraint.** `// Offsets are 1-based — the vendor's format, not ours.`
- **The reference.** An RFC, spec section, or vendor bug that explains a strange shape.
- **The trap.** `// Empty string is a valid value here; only nil means "unset".`
- **The deliberate omission.** `// No retry: this call is not idempotent.`

## What to leave out

A comment that restates the line below it costs a line and goes stale. Delete `// increment counter`
above `counter++`. Where a comment feels necessary because the code is unclear, rename the variable or
extract the function instead — that fix cannot go stale.

Leave out change narration (`// added by ...`, `// fixed 2026-04-02`) and commented-out code. Git holds
both.

## Form

- **One line, above the code it explains.** Trailing comments crowd the line and wrap badly.
- **Present tense, active voice, plain words.** "Skips deleted rows", not "deleted rows are skipped".
- **Full sentences for prose, fragments for labels.** Both end without decoration.
- **Comment the block, not each line.** One comment above a five-line calculation beats five comments.
- **A `TODO` carries an owner and a condition.** `// TODO(dz): drop when the v1 endpoint retires.`
  A bare `TODO` is a wish.

## Docstrings and API documentation

Document every exported symbol. A caller reads the docstring instead of the body, so it states
everything needed to call correctly:

- What it does, in one line, starting with a verb.
- Parameters that are not self-evident from name and type, with units and valid ranges.
- What it returns, including the empty and absent cases.
- What it raises or returns as an error, and when.
- Side effects: writes, network calls, mutation of arguments, global state.
- Ordering or concurrency constraints — what must happen first, what must not run in parallel.

Follow the language's convention exactly (JSDoc/TSDoc, docstrings, doc comments, XML docs). Skip a
docstring on a private one-line function whose name already says everything.

## What to explain outside the code

Some knowledge fits no comment. Put it where a reader will look:

| Knowledge | Home |
|---|---|
| How to run, test, lint, and build | `AGENTS.md` (agents) and `README.md` (humans) |
| Why the architecture is shaped this way | An ADR — the `write-adr` skill |
| What the domain words mean | A glossary in the README or `CONTEXT.md` |
| How to use the thing | `README.md`, with a runnable example |
| Why a specific line is strange | A comment on that line |

## When you explain to a person

The `explain-topic` skill covers depth and pacing. `style/communication.md` covers the sentences.
Both apply to a code review comment, a PR description, and a chat answer alike.
