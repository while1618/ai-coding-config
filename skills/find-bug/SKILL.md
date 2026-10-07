---
name: find-bug
description: Find and fix the root cause of a bug, test failure, crash, wrong output, or performance regression. Use when anything is broken, failing, throwing, hanging, flaky, or slow — before proposing any fix.
---

# Find the bug

## The iron law

```
NO FIX WITHOUT A LOOP THAT GOES RED FIRST
```

A fix you cannot watch turn a red signal green is a guess. Guesses that happen to work are
worse than guesses that fail, because they close the ticket and leave the cause in place.

Use this for every technical failure: test failures, production bugs, wrong output, build
failures, hangs, flakes, and performance regressions. **Especially** use it when you are
under time pressure, when the fix looks obvious, and when you have already tried something
that did not work — those are the conditions that make guessing feel efficient.

## Redact before you show anything

You will paste commands, output, and captured payloads. Replace every secret with
`<REDACTED>` first. Build loops against environment variables so the credential stays in the
environment. Captured traffic carries auth headers — quote only the lines that carry signal.

If the redacted output is not enough to diagnose the bug, say so and ask.

## Phase 1 — Build a loop that goes red

**This phase is the skill.** Everything after it is mechanical. With a tight pass/fail
signal that goes red on *this* bug, you will find the cause; bisection, hypothesis testing,
and instrumentation all just consume that signal. Without one, no amount of reading code
will save you.

Spend disproportionate effort here. Be aggressive. Be inventive. Do not give up early.

### Ways to build one, roughly in order of preference

1. **A failing test** at whatever seam reaches the bug — unit, integration, end to end.
2. **A curl or HTTP script** against a running dev server.
3. **A CLI invocation** with a fixture input, diffed against known-good output.
4. **A headless browser script** that drives the UI and asserts on DOM, console, or network.
5. **A replayed capture.** Save the real request, payload, or event log to disk and replay it
   through the code path in isolation.
6. **A throwaway harness.** Stand up the minimum subset of the system — one service, stubbed
   dependencies — that reaches the bug in a single function call.
7. **A property or fuzz loop.** For "sometimes wrong output", run a thousand random inputs
   and look for the failure mode.
8. **A bisection harness.** When the bug appeared between two known states, automate "set up
   state X, check, repeat" so `git bisect run` can drive it.
9. **A differential loop.** Run the same input through the old and new version, or two
   configs, and diff the output.
10. **A human-in-the-loop script.** Last resort. When a person must click, drive them with a
    script that prompts, captures, and feeds the result back, so the loop stays structured.

### Then tighten it

Treat the loop as a product. Once you have one, make it better:

- **Faster.** Cache setup, skip unrelated initialisation, narrow the scope.
- **Sharper.** Assert on the specific symptom, not "it did not crash".
- **More deterministic.** Pin the clock, seed the RNG, isolate the filesystem, freeze the
  network.

A flaky 30-second loop is barely better than none. A deterministic 2-second loop is a
different tool.

### Non-deterministic bugs

The goal is not a clean repro but a **higher reproduction rate**. Loop the trigger a hundred
times, run it in parallel, add load, narrow the timing window, inject sleeps. A bug that
reproduces half the time is debuggable. One percent is not. Raise the rate until it is.

### When you genuinely cannot build a loop

Stop and say so. List what you tried. Then ask for one of: access to an environment where it
reproduces, a redacted capture (HAR file, log dump, core dump, screen recording with
timestamps), or permission to add temporary instrumentation to a real environment.

**Do not proceed to hypotheses without a loop.** That is the exact failure this skill exists
to prevent.

### Phase 1 is done when

You can name **one command** that you have **already run at least once** — show the
invocation and its output, redacted — and it is:

- [ ] **Red-capable.** It drives the real code path and asserts the user's exact symptom. Not
      "runs without erroring" — it must be able to catch *this* bug and go green when fixed.
- [ ] **Deterministic.** Same verdict every run. For flaky bugs, a pinned high reproduction
      rate.
- [ ] **Fast.** Seconds, not minutes.
- [ ] **Runnable unattended.** No human in the loop except through a driving script.

## Phase 2 — Reproduce, then minimise

Run the loop. Watch it go red.

Confirm three things:

- [ ] The failure is the one **the user** described, not a different one nearby. The wrong bug
      gets the wrong fix.
- [ ] It reproduces across runs, or at a rate high enough to debug against.
- [ ] You have captured the exact symptom — the message, the wrong value, the timing — so a
      later phase can prove the fix addressed it.

Then shrink it. Cut inputs, callers, config, data, and steps **one at a time**, re-running
after each cut. Keep only what is load-bearing.

Why bother: a minimal repro shrinks the hypothesis space in Phase 3, and becomes the clean
regression test in Phase 5.

Done when removing any remaining element makes the loop go green.

## Phase 3 — Hypothesise, ranked

Generate **three to five ranked hypotheses before testing any of them**. Generating one at a
time anchors you on the first plausible idea, and the first plausible idea is wrong often
enough to matter.

Each one must be falsifiable. State the prediction:

> If the connection pool is exhausted, then raising `max` to 50 makes the failure disappear,
> and lowering it to 2 makes it happen on every request.

If you cannot state the prediction, it is a vibe. Sharpen it or drop it.

**Show the ranked list to the user before you start testing.** They often re-rank it
instantly — "we deployed a change to number three yesterday" — or tell you which ones they
have already ruled out. Cheap checkpoint, large saving. Do not block on it; proceed with
your own ranking if they are away.

### Before hypothesising, look at what changed

```bash
git log --oneline -20
git diff HEAD~5 -- <the area>
```

And find working examples in the same codebase. What is similar and works? List every
difference between it and the broken path, however small. "That cannot matter" is where bugs
live.

## Phase 4 — Instrument, one variable at a time

Each probe maps to a specific prediction from Phase 3. Change one thing per run.

Tool preference:

1. **A debugger or REPL** where the environment allows it. One breakpoint beats ten logs.
2. **Targeted logs** at the boundary that distinguishes two hypotheses.
3. Never "log everything and grep".

**Tag every debug log** with a unique marker — `[DEBUG-a4f2]`. Cleanup becomes one grep.
Untagged debug logs reach production.

### Multi-component systems

When the failure crosses a boundary — CI to build to signing, API to service to database —
instrument the boundaries **before** hypothesising about any single component:

```
For each boundary:
  log what enters
  log what exits
  check that config and environment propagated
Run once. The evidence names the failing layer.
Then investigate that layer.
```

### Performance regressions

Logs are usually the wrong tool. Establish a baseline measurement — a timing harness, a
profiler, a query plan — then bisect against it. Measure first, fix second. A guess about
what is slow is wrong most of the time.

## Phase 5 — Fix, with a regression test

Write the regression test **before the fix**, but only where a **correct seam** exists.

A correct seam exercises the real bug pattern as it occurs at the call site. Where the only
available seam is too shallow — a single-caller test when the bug needs two callers, a unit
test that cannot reproduce the chain that triggered it — a test there gives false confidence.

**If no correct seam exists, that is itself a finding.** Say so. The architecture is
preventing the bug from being locked down, and that is worth more than a test that cannot
fail.

Where a seam exists:

1. Turn the minimised repro into a failing test at that seam.
2. Watch it fail, for the right reason.
3. Apply the fix. One change, addressing the cause.
4. Watch it pass.
5. Re-run the Phase 1 loop against the original, un-minimised scenario.

No "while I am here" improvements. No bundled refactor.

## When the fix does not work

Count your attempts.

- **Fewer than three:** return to Phase 3 with what you just learned. Form a new hypothesis.
  Do not stack another fix on top of the last one.
- **Three or more:** stop. Do not attempt a fourth.

Three failed fixes is not three failed hypotheses — it is a signal about the design. The
pattern to look for: each fix reveals a new problem somewhere else, or each fix would need
"a big refactor" to do properly, or fixing here breaks something there.

Raise it with the user before trying again:

> Three fixes have failed, each exposing shared state in a different place. I think the
> problem is that <component> has no single owner for <state>, not any one of these call
> sites. Worth discussing before I try a fourth.

## Phase 6 — Clean up

Required before you say it is done:

- [ ] The original repro no longer reproduces. Re-run the Phase 1 loop and show the output.
- [ ] The regression test passes, or the absence of a correct seam is documented.
- [ ] Every `[DEBUG-...]` line is gone. Grep for the tag.
- [ ] Throwaway harnesses are deleted, or moved somewhere clearly marked.
- [ ] **The confirmed cause is written in the commit message.** The next person to touch this
      code inherits your investigation instead of repeating it.

## Signals you are doing it wrong

If you catch yourself thinking any of these, return to Phase 1:

- "Quick fix now, investigate later."
- "Let me just try changing X and see."
- "It is probably X, let me fix that."
- "I will change several things and run the tests."
- "I do not fully understand it, but this might work."
- "The reference implementation is long, I will adapt the pattern."
- "Here are the main problems:" — followed by fixes, before any evidence.
- "One more fix attempt" — when you have already tried two.

And if the user says any of these, stop and go back to Phase 1: "is that actually
happening?", "stop guessing", "will that show us anything?", "are we stuck?"

## When there really is no root cause

Sometimes the investigation ends at something environmental, timing-dependent, or external.
That is a valid outcome once you have done the work:

1. Say what you investigated and what you ruled out.
2. Implement the appropriate handling — a retry, a timeout, a clearer error.
3. Add the logging that would identify it next time.

But most "no root cause" conclusions are incomplete investigations. Check Phase 1 again
before you settle for it.

## Rationalisations

| Excuse | Reality |
|---|---|
| "This is simple, I do not need the process" | Simple bugs have causes too, and the process is fast for them |
| "It is an emergency, there is no time" | Guess-and-check thrashing is slower than this, every time |
| "Let me try one thing first, then investigate" | The first attempt sets the pattern for the whole session |
| "I will write the test after I confirm the fix" | Then you never watched it fail, so you never proved it can catch the bug |
| "Several changes at once saves time" | You cannot attribute the result, and you may add a new bug |
| "I already manually tested it" | Manual testing has no record and cannot re-run |
| "The reference is too long to read fully" | Partial understanding of a pattern guarantees bugs |
| "I can see the problem" | Seeing a symptom is not understanding a cause |
