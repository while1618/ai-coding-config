---
name: write-tests
description: Write tests that can actually fail, test-first. Use when implementing a feature or fixing a bug, when the user mentions TDD or red-green, when adding tests to existing code, or when judging whether a test is worth keeping.
---

# Write tests

Write the test first. Watch it fail. Write the least code that passes it.

The reason is not ritual: **a test you never watched fail has not been shown to catch
anything.** A test written after the code passes on the first run, which tells you nothing
about whether it would notice the bug.

## Agree the seams first

A **seam** is the public boundary you observe behaviour through. Tests live at seams, never
against internals.

You cannot test everything. Naming the seams up front is how the effort lands on the
critical paths instead of on every edge case. Before writing any test, say which seams you
intend to test and confirm them:

> I plan to test at the `UploadQueue.enqueue` interface and the HTTP handler. Not the
> internal retry helper — it has no callers outside the queue. Does that match what you want
> covered?

When the shape of the interface is itself the question — how deep the module should be, where
the seam belongs — use the `design-module` skill for the vocabulary first.

## The loop

### Red — write one failing test

One behaviour. A name that describes that behaviour. Real code rather than mocks.

```typescript
test('retries a failed operation three times', async () => {
  let attempts = 0;
  const operation = () => {
    attempts++;
    if (attempts < 3) throw new Error('fail');
    return 'success';
  };

  const result = await retryOperation(operation);

  expect(result).toBe('success');
  expect(attempts).toBe(3);
});
```

Not this:

```typescript
test('retry works', async () => {
  const mock = jest.fn()
    .mockRejectedValueOnce(new Error())
    .mockRejectedValueOnce(new Error())
    .mockResolvedValueOnce('success');
  await retryOperation(mock);
  expect(mock).toHaveBeenCalledTimes(3);
});
```

The name says nothing, and the assertion is about the mock, not about `retryOperation`.

### Watch it fail

Run it. This step is not optional.

Confirm the test **fails** rather than **errors**, and that it fails because the behaviour is
missing rather than because of a typo or a bad import.

- It passes already? You are testing existing behaviour. The test is wrong.
- It errors? Fix the error and re-run until it fails properly.

### Green — the least code that passes

```typescript
async function retryOperation<T>(fn: () => Promise<T>): Promise<T> {
  for (let i = 0; i < 3; i++) {
    try {
      return await fn();
    } catch (e) {
      if (i === 2) throw e;
    }
  }
  throw new Error('unreachable');
}
```

No options object, no backoff strategy, no `onRetry` callback. Nothing the test did not ask
for.

### Watch it pass

Run it. Confirm the new test passes, the other tests still pass, and the output is clean — no
new warnings, no unhandled rejections.

Fails? Fix the code, not the test.

### Refactor

Only once green. Remove duplication, improve names, extract helpers. Do not add behaviour.
Keep the tests green throughout.

Then write the next failing test.

## Work in vertical slices

One test, one implementation, repeat. Each slice responds to what the last one taught you.

Writing all the tests first and then all the implementation — **horizontal slicing** — tests
imagined behaviour. You end up asserting the shape you expected rather than the behaviour
users need, the tests go insensitive to real change, and you commit to a test structure
before you understand the implementation.

## Before writing the body: name the break

Answer this: **what production change would make this test fail — and is that change a bug or
a decision?**

- Cannot name one → redesign around an observable behaviour.
- "The source text changed" → run the artifact and assert its effect, do not grep its text.
- Only a deliberate decision would fail it → it is a change detector. Not
  `expect(MAX_RETRIES).toBe(5)` but "the sixth attempt never happens".

Then check the expected value comes from somewhere other than the code under test:

```typescript
// Mirror assertion: the same builder computes both sides, so it always passes
const expected = buildQuery({ tag: 'urgent' });
expect(buildQuery({ tag: 'urgent' })).toBe(expected);

// Hand-derived literal
expect(buildQuery({ tag: 'urgent' })).toBe('tag:"urgent"');
```

Table-driven tests with literal expected values are the preferred shape.

## Mocks

- **Never assert on a mock.** A mock assertion passes when the mock is present and fails when
  it is absent. It says nothing about your code. If the mock is what you are checking, unmock
  it or delete the assertion.
- **Mock at the right level.** Learn the real method's side effects first. Mock the slow or
  external layer *below* the behaviour the test depends on. A mock that swallows a write the
  test later reads makes the test pass while integration breaks.
- **Mirror the real structure completely.** Every documented field, not only the ones this
  test reads. A partial mock fails silently when downstream code reads an omitted field.
- **Give each branch its own fixture.** Success, error, and malformed each get their own, so
  the wrong branch cannot satisfy the expectation.
- **When mock setup outgrows the test, stop mocking.** Write an integration test with the real
  components instead.

## Anti-patterns

- **Implementation-coupled** — mocks internal collaborators, tests private methods, or checks
  the result through a side channel such as querying the database instead of using the
  interface. The tell: refactoring breaks it while behaviour is unchanged.
- **Tautological** — the assertion recomputes the expected value the way the code does, so it
  passes by construction.
- **Change detector** — only an intentional decision can fail it. It fires on every redesign
  and sleeps through every bug.
- **Coverage theatre** — written to move a number, asserting no outcome or side effect.
- **Test-only production code** — a `destroy()` on a production class that only tests call.
  That belongs in a test utility.

## The mutation check

Before you finish, mentally mutate the production code. At least one test should fail for
each of these:

- A wrong constant or argument
- The wrong branch taken
- A missing state change or side effect
- An empty or default return
- Missing validation for zero, empty, null, unauthorized, or malformed input

A mutation nothing catches means either the behaviour is unprotected or the test is
tautological.

## What earns no test

Trivial code — a getter that only returns, a constructor that only assigns, a one-line
forward. Test the first consumer-visible result that depends on it instead.

Human prose earns no test at all.

## Bug fixes

Every bug fix starts with a test that reproduces the bug. Then follow the loop. The test
proves the fix and prevents the regression. The `fix-bug` skill covers finding the cause
first.

## When you are stuck

| Problem | What it means |
|---|---|
| You do not know how to test it | Write the API you wish existed, then the assertion |
| The test is complicated | The design is complicated. Simplify the interface |
| You must mock everything | The code is too coupled. Inject the dependencies |
| The setup is enormous | Extract helpers. Still large? Simplify the design |

A test that is hard to write is telling you the code is hard to use. Listen to it.

## Existing code with no tests

Add tests for what you are changing, at the seam you are changing it through. You do not owe
the whole file coverage, and pretending otherwise means you write none.
