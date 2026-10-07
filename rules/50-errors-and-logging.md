---
description: Failure paths, error messages, and what belongs in a log line.
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

# Errors and logging

## Handle the failures that can happen

Handle a failure when it can occur and you can do something useful about it: retry, fall back, ask the
caller, or fail with a clear message. Do not write a handler for a case the type system or the call
graph already rules out — that is dead code that reads as if the case is possible.

## Fail where you can act

- **Validate at the boundary.** Check input where it enters your control — the request handler, the CLI
  parser, the file reader. Inside that boundary, trust the type.
- **Do not catch what you cannot handle.** Let it propagate to the layer that can decide. A `catch` that
  logs and rethrows adds a log line and nothing else.
- **Never swallow.** An empty catch block, a bare `except: pass`, an ignored error return — each turns a
  failure into wrong behaviour later, far from the cause.
- **Add context as it rises.** Wrap with what the caller needs to locate it (`"read config %s: %w"`), and
  keep the original cause attached. Never replace the cause with your own message.
- **Fail fast on a broken invariant.** A program in an impossible state should stop, not continue.
- **Clean up on every path.** Use the language's scope mechanism — `defer`, `with`, `try/finally`,
  RAII — so the early return cannot leak the handle.
- **Distinguish expected from exceptional.** "No rows matched" is a result. "The database is
  unreachable" is an error. Do not model them the same way.

## Error messages

An error message is read by someone under pressure who cannot ask you a question. It states three things:

1. **What failed** — the operation, in their words.
2. **Why** — the specific cause, with the value that caused it.
3. **What to do** — the next action, when there is one.

```
// Says nothing actionable
throw new Error("Invalid input");

// Names the operation, the cause, the value, and the fix
throw new Error(
  `parse config: "timeout" must be a positive integer, got "${raw}". Use milliseconds, e.g. 5000.`
);
```

Rules for the string:

- Lower-case start, no trailing period, so it reads correctly when wrapped.
- Include the offending value, and the expected shape or range.
- Name the file, key, field, or index — never "an item".
- Leave out stack traces, internal type names, and advice the reader cannot act on.
- Never put a secret, token, password, or full request body in the message.
- Write it under `style/communication.md`. An error string is the strictest case: short, active,
  single-meaning.

## Logging

Log for the person reading the log at 2am, not for yourself while writing the code.

| Level | Use it for | Example |
|---|---|---|
| `error` | A failure a human must act on | Write failed after retries exhausted |
| `warn` | Degraded but continuing | Fell back to the cache, upstream timed out |
| `info` | A state change worth an audit trail | Job started, config reloaded, request completed |
| `debug` | Detail for diagnosing, off in production | Chosen strategy, computed intermediate value |

- **Structure the fields.** Use the project's structured logger with key/value pairs, not string
  concatenation, so the log is searchable.
- **One event, one line.** A failure logged at three layers reads as three failures.
- **Include the correlating identifier** — request id, job id, tenant — every time. A log line with no
  identifier cannot be joined to anything.
- **Never log a secret,** a token, a password, a full authorization header, a card number, or personal
  data beyond what the project's policy allows. Log the identifier, not the payload.
- **Do not log inside a hot loop.** Aggregate and log the count.
- **Log the decision, not the obvious.** "Chose exponential backoff, attempt 3 of 5" earns its line.
  "Entering function" does not.

## Temporary debug logging

Tag every throwaway log with a unique marker: `[DEBUG-a4f2]`. Cleanup becomes one grep. Untagged debug
logs survive into production; tagged ones do not. Remove them before you claim the work is done.
