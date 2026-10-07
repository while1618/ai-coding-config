---
name: write-adr
description: Record an architecture decision and its reasoning. Use when a significant technical choice has been made, when the user asks for an ADR or a design record, or when a decision from a conversation would otherwise be lost.
---

# Write an ADR

An architecture decision record exists to answer one question, asked six months from now by
someone about to undo your work: **why is it like this?**

The reasoning is the content. The decision itself is usually already visible in the code.

## When a decision earns an ADR

Write one when the decision is **costly to reverse** and **not obvious from the code**:

- A choice between technologies — this database, this queue, this framework.
- A structural choice — this boundary, this deployment shape, this data ownership.
- A constraint accepted deliberately — no shared library, no ORM, single region for now.
- A rejected option someone will propose again. This is the highest-value case: the ADR is
  what stops the team relitigating it every quarter.
- A trade-off taken with eyes open — chosen slower writes for simpler reads.

Do not write one for a choice the code makes obvious, a decision that is trivial to reverse,
or a style preference. A linter config is not an architecture decision.

## Where it goes

`docs/adr/NNNN-short-title.md`, numbered sequentially, never renumbered. Where the project
already has a location or a format, follow that instead.

An ADR is **immutable once accepted**. A decision that changes gets a new ADR that supersedes
the old one, and the old one gets a line pointing forward. Editing history to look consistent
destroys the record's only value.

## The format

```markdown
# NNNN. <The decision, as a short statement>

**Status:** proposed | accepted | superseded by [NNNN](NNNN-....md)
**Date:** YYYY-MM-DD
**Deciders:** <who agreed to this>

## Context

<The forces at play, before any decision. What problem, what constraints, what pressures.
Include the numbers — the load, the team size, the deadline, the budget — because they are
what makes the decision make sense later, and they are what changes.

Written so a reader who was not there understands why this was even a question. Two to four
paragraphs.>

## Decision

<What was decided, in the active voice and one or two sentences. "We will store sessions in
Redis with a 24-hour TTL." Not "it was decided that Redis should perhaps be used".>

## Options considered

### <Option A — the one chosen>
<What it is. Why it wins, against the context above.>

### <Option B>
<What it is. Why it was rejected. Be specific and be fair — a strawman here is what makes
someone reopen the decision.>

### <Option C>
<Same.>

## Consequences

**We accept:**
- <What gets harder. The operational cost, the coupling, the limit this imposes.>

**We gain:**
- <What gets easier. Concretely, not as a benefit claim.>

**We will revisit this if:**
- <The condition that invalidates the decision. This is the most useful line in the
  document — e.g. "if write volume passes 5k/s, the single-writer assumption breaks".>
```

## Rules for writing it

- **Write the context before the decision.** A decision without its forces is an assertion, and
  the forces are what the reader needs to judge whether it still holds.
- **Be fair to the rejected options.** Present each one as its advocate would. A weak account of
  the alternative is why decisions get reopened.
- **Give the numbers.** "3 engineers, 200 requests per second, a six-week deadline" dates
  correctly. "Small team, moderate load, tight deadline" does not.
- **Name the revisit condition.** Every decision has one. Writing it down is what lets a future
  team change course with confidence instead of guessing whether the reasoning still applies.
- **Keep every hedge.** "We believe the write volume will stay under 1k/s" stays a belief. That
  is exactly the sentence a future reader needs to check.
- **No marketing adjectives.** Nothing is a modern, scalable, or elegant solution.
- **Write it under `style/communication.md`.**

## After writing it

Link it from where someone will hit it: the `AGENTS.md` section for that area, the module's
README, or a comment at the code it explains.

An ADR nobody finds has done nothing.
