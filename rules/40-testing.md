---
description: What a test must prove, where tests go, and the gate before claiming done.
paths:
  - "**/*{test,spec,Test,Tests,_test}*"
  - "**/tests/**"
  - "**/test/**"
  - "**/__tests__/**"
  - "**/spec/**"
source: "Test-honesty rules adapted from github.com/obra/superpowers (writing-good-tests). Seam and slicing guidance from github.com/mattpocock/skills (tdd)."
---

# Testing

## The two principles

1. **Every test names the break it catches.**
2. **Every test exercises the real thing.**

A test that satisfies neither costs maintenance forever and protects nothing.

## Before you write the test body

Answer this: **what production change would make this test fail — and is that change a bug or a
decision?**

- Cannot name one → redesign the test around an observable behaviour.
- "The source text changed" → run the artifact and assert its effect, do not grep its text.
- Only a deliberate decision would fail it → it is a change detector. Test the behaviour that depends
  on the decision instead. Not `expect(MAX_RETRIES).toBe(5)`, but "the sixth attempt never happens".

Then confirm the expected value comes from somewhere other than the code under test.

```
// Mirror assertion — the same builder computes both sides, so it always passes
const expected = buildQuery({ tag: 'urgent' });
expect(buildQuery({ tag: 'urgent' })).toBe(expected);

// Hand-derived literal
expect(buildQuery({ tag: 'urgent' })).toBe('tag:"urgent"');
```

## Where tests go

A **seam** is the public boundary you observe behaviour through. Tests live at seams, never against
internals.

**Agree the seams before writing tests.** You cannot test everything; naming the seams up front is how
the effort lands on critical paths and complex logic instead of every edge case. Ask: what is the public
interface, and which seams matter here?

## Test your code, not the framework and not the mock

- **Assert on the real component.** A mock assertion passes when the mock is present and fails when it
  is absent. It says nothing about your code. If the mock is what you are checking, unmock it or delete
  the assertion.
- **Mock at the right level.** Learn the real method's side effects first, then mock the slow or external
  layer below the behaviour the test depends on. A mock that swallows a write the test later reads makes
  the test pass while integration breaks.
- **Mirror real data completely.** Mock every documented field, not only the ones this test reads.
  Partial mocks fail silently when downstream code reads an omitted field.
- **Test your boundary, not their mechanics.** Assert the route you register, the query you emit, the
  payload you produce. That the router calls a registered handler is the framework's test.
- **Prefer real components when mock setup outgrows the test.** That is the signal for an integration test.
- **Production classes carry production methods only.** Cleanup that only tests need lives in test
  utilities, never as `destroy()` on the production class.

## Anti-patterns

- **Implementation-coupled** — mocks internal collaborators, tests private methods, or verifies through
  a side channel such as querying the database instead of using the interface. The tell: refactoring
  breaks it while behaviour is unchanged.
- **Tautological** — the assertion recomputes the expected value the way the code does, so it passes by
  construction and can never disagree with the code.
- **Horizontal slicing** — all the tests first, then all the implementation. Bulk tests verify imagined
  behaviour and go insensitive to real change. Work in vertical slices: one test, one implementation,
  repeat, each slice answering what the last one taught you.
- **Coverage theatre** — a test written to move a number, asserting no outcome or side effect.

## Test-first

Write the failing test, watch it fail for the right reason, then write the least code that passes it.
A test written after the code passes immediately, which proves nothing: you never saw it fail, so you
never proved it can catch the bug. The `write-tests` skill holds the full loop.

Trivial code and human prose earn no test.

## The mutation check

Before you finish, mentally mutate the production code. At least one test should fail for each of these:

- Wrong constant or argument
- Wrong branch taken
- A missing state change or side effect
- An empty or default return
- Missing validation for zero, empty, null, unauthorized, or malformed input

A mutation nothing catches means the behaviour is unprotected, or the test is tautological.

## The completion gate

Before you claim anything passes:

1. Name the command that proves the claim.
2. Run it in full, in this turn.
3. Read the whole output. Check the exit code. Count the failures.
4. State the claim with the evidence, or state the actual status with the evidence.

| Claim | What proves it | What does not |
|---|---|---|
| Tests pass | A test run this turn, 0 failures | An earlier run, "should pass" |
| Linter clean | Linter output, 0 errors | A partial check |
| Build succeeds | Build exit 0 | The linter passing |
| Bug fixed | The original symptom retested | The code changed |
| Regression test works | Failed before the fix, passes after | It passes once |
| Requirements met | A line-by-line check against the request | Tests passing |

"Should work", "probably", and "seems to" mean you have not run it yet.
