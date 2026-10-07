---
name: handoff
description: Write a handoff note so the next session or teammate can continue without re-deriving anything. Use when ending a session with work unfinished, when context is nearly full, or when the user asks for a summary to continue from.
---

# Hand off

The next session starts with none of what you currently hold. A handoff note is the difference
between continuing and starting over.

Write it for someone competent who has never seen this task. That is literally who reads it.

## What to write

Save to `docs/handoffs/YYYY-MM-DD-<topic>.md`, or wherever the project keeps them. Commit it, so
it survives the session.

````markdown
# <Task> — handoff, <date>

## Goal

<What we are trying to achieve, in one or two sentences. Not the steps — the outcome.>

## State

<What works now, and what does not. Be exact.>

- Done: <the parts that are finished and verified, with how they were verified>
- In progress: <what is half-done, and what "half" means>
- Not started: <what remains>

**Branch:** `<name>`, <n> commits ahead of `<base>`
**Uncommitted:** <what is in the working tree, or "nothing">
**Suite:** <green, or the exact failures>

## What I learned

<The highest-value section. Everything the next reader would otherwise rediscover.>

- <e.g. The 504 comes from the signing service, not the upload — confirmed by the boundary
  logging in commit a1b2c3d.>
- <e.g. `queue/retry.ts` looks unused but the batch worker imports it dynamically at
  `worker/batch.ts:210`.>
- <e.g. The integration suite needs `docker compose up db` first, and the failure without it
  does not mention Docker.>

## What I tried that did not work

<Save the next person from repeating it. Say why each one failed.>

- <e.g. Raising the client timeout to 60s — still fails at p99.9 and blocks a worker for a
  minute against a dead service.>

## Next step

<One concrete action, specific enough to start on. Not "continue the work".>

<e.g. Add the retry in `worker/upload.ts:88` using the policy in `queue/retry.ts`. The failing
test is already written at `tests/worker/upload.test.ts:44` and currently red. Run it with
`npm test tests/worker/upload.test.ts`.>

## Open questions

<Decisions that need a person, with the options and your recommendation.>

- <e.g. Should the retry regenerate the signature, or reuse it? Reusing is simpler but the
  signature may have expired by then. I lean toward regenerating.>

## Files

- `<path>` — <what changed and why>
````

## Before you write it

Get the tree into a state the next session can trust:

```bash
git status --short
git log --oneline <base>..HEAD
<the test command>
```

Commit what is committable, with real messages. `/commit` is the workflow for that, and only a
person can start it — so ask them to run it. Uncommitted work that
survives only in a working tree is the most common thing lost between sessions.

Where something must stay uncommitted, say exactly what and why, and never leave it undescribed.

## The two sections that matter

**What I learned** and **What I tried that did not work** are the whole point. Everything else
can be recovered from git. Those two cannot, and they are what makes the next session faster
rather than merely informed.

Be specific enough to act on. "The API is slow" is not a finding. "The signing service returns
504 at p99 under the tenant's batch load, measured over 200 requests" is.

## Rules

- **Verify before you claim.** "Tests pass" needs a run in this turn. A handoff that lies about
  the state is worse than none, because the next session builds on it.
- **Keep every hedge.** "The cause is probably the connection pool" stays probably. The next
  reader needs your actual confidence, not a cleaner sentence.
- **No adjectives claiming quality.** Nothing is nearly done. Say which parts are done and
  verified.
- **Write it under `style/communication.md`.**

## Then tell the user

Where the note is, what state the branch is in, and what the next step is. Three sentences.
