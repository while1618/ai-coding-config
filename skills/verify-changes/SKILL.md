---
name: verify-changes
description: Prove work is done before saying it is done. Use before claiming anything passes, is fixed, or is complete, and before committing, pushing, or opening a PR.
---

# Verify changes

## The rule

```
NO COMPLETION CLAIM WITHOUT FRESH EVIDENCE
```

If you have not run the command in this turn, you cannot say it passes. A run from earlier
in the session proves only the tree it ran on.

## The gate

Before any statement about the state of the work:

1. **Identify.** What command proves this claim?
2. **Run it.** In full. Not a subset, not a single test file when the claim is about the
   suite.
3. **Read it.** The whole output. The exit code. The failure count.
4. **Compare.** Does the output actually support the claim?
   - No → state the real status, with the output.
   - Yes → state the claim, with the evidence.
5. **Then** say it.

Skipping a step is not verifying.

## What proves what

| Claim | Requires | Not sufficient |
|---|---|---|
| Tests pass | The test command, this turn, zero failures | An earlier run, "should pass" |
| Linter clean | Linter output, zero errors | A partial check, one file |
| Build succeeds | The build command, exit 0 | The linter passing |
| Types check | The type checker, this turn | The build succeeding on cached output |
| Bug fixed | The original symptom retested and gone | The code changed as intended |
| Regression test works | Failed before the fix, passes after | It passes once |
| A subagent finished | The diff, read by you | The subagent's report |
| Requirements met | Each requirement checked off by name | The tests passing |
| Nothing else broke | The full suite, not the new tests | The new tests passing |

## The red-green check for a regression test

A regression test that never failed proves nothing. Prove it can fail:

```
1. Write the test, run it            → it should fail
2. Apply the fix, run it             → it should pass
3. Revert the fix, run it            → it MUST fail
4. Restore the fix, run it           → it should pass
```

Step 3 is the one people skip, and it is the only one that proves the test is connected to
the code.

## Requirements are checked by name

Tests passing is not the same as the request being met. Re-read what was asked, list each
requirement, and check them off one at a time. Report the gaps rather than the total.

## Do not trust a subagent's report

A subagent saying "done" is a claim, not evidence. Read the diff:

```bash
git diff --stat
git diff
```

Then verify the work yourself against what you asked for.

## Words that mean you have not run it

"Should work." "Probably." "Seems to." "I am confident." "This ought to." "Looks correct."
"I believe it now."

Each of these is a prediction. Replace it with a command and its output, or say plainly that
you have not verified it yet.

## Rationalisations

| Excuse | Reality |
|---|---|
| "It should work now" | Then run it and find out |
| "I am confident" | Confidence is not evidence |
| "Just this once" | The exception is where the wrong claim gets made |
| "The linter passed" | The linter does not compile or run anything |
| "The subagent said it worked" | Read the diff |
| "A partial check is enough" | A partial check proves the part you checked |
| "I am tired and this is done" | Exhaustion is when unverified claims happen |
| "I phrased it differently, so the rule does not apply" | The rule is about the claim, not the wording |

## What the hook already does

This config installs a hook that runs the project's lint, typecheck, and test commands when
a turn ends with edited files, and blocks the turn on failure. That covers the automatic
case. It does not cover:

- A claim about behaviour no test asserts.
- A requirement check against the original request.
- The red-green proof for a regression test.
- Verifying a subagent's work.
- Anything in a project where no commands were detected — `install/doctor.sh` reports that.

Those are yours.
