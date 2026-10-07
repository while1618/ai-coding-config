---
name: write-spec
description: Write a product or feature specification — journeys, testable requirements, measurable success criteria, and open questions — and settle its ambiguities with the user. Use after an idea is agreed, when the user asks for a spec, PRD, or requirements document, or when a plan has no written source to implement.
source: "Adapted from github.com/github/spec-kit templates/commands/specify.md and clarify.md (MIT), and the spec self-review in github.com/obra/superpowers skills/brainstorming (MIT), fetched 2026-10-06."
---

# Write the spec

A spec says **what** the product does and **how to tell that it does it**. The plan says how to
build it. Keep the two apart: a spec that names libraries locks in a design nobody reviewed, and
a plan with no spec has nothing to check its work against.

## 1. Collect the input

The input is the approved brief from `shape-idea`, saved at `docs/brief.md`, or the person's own
description. Where the purpose, the users, or the success measure is unknown, run `shape-idea`
first.

Where the project already has a spec location or format, follow it. Otherwise write to
`docs/specs/YYYY-MM-DD-<name>.md`.

## 2. Write it

Describe behaviour and outcomes. Name a technology only where the person mandated it. Put that
mandate under **Constraints**.

````markdown
# <Name> specification

**Status:** draft | approved
**Date:** YYYY-MM-DD
**Source:** <the brief, issue, or conversation>

## Problem
<Who has the problem, what it costs them now, and why this solves it.>

## Users
<Each kind of user and the one thing each needs most.>

## Journeys

### J1: <name> (P1)
<The journey in two or three sentences.>

**Independent test:** <how to show this journey works with nothing else built>

**Acceptance**
1. Given <state>, when <action>, then <observable result>.
2. Given ..., when ..., then ...

### J2: <name> (P2)

## Functional requirements
- **FR-001:** The system must <one testable behaviour>. (J1)
- **FR-002:** ...

## Data
<Each entity, the fields that matter, who owns it, how long it is kept, and how sensitive it is.>

## Non-functional requirements
<Only the ones that apply, each with a number: response time, availability, data volume,
accessibility level, supported browsers or devices, privacy or compliance rules.>

## Security
<Filled by the threat-model skill. Write "not assessed" until it runs.>

## Edge cases and errors
<Empty input, duplicates, limits, partial failure, concurrent edits, what the user sees on error.>

## Success criteria
- **SC-001:** <a measurable outcome, with no technology in it>

## Constraints
<Mandated stack, hosting, integrations, deadline, budget.>

## Non-goals
<What this deliberately does not do.>

## Assumptions
<Every default you chose where the source said nothing.>

## Open questions
- [NEEDS CLARIFICATION: <one specific question>]

## Clarifications
<Filled in step 4, one dated line per answer.>
````

Rank the journeys. **P1 alone must be a usable product.** That ranking is what lets the plan
deliver something runnable early.

## 3. Mark the unknowns

Where the source is silent, choose a reasonable default and list it under **Assumptions**.
Mark `[NEEDS CLARIFICATION]` only when all three hold:

- The choice changes scope, security or privacy, or what the user experiences.
- Two readings are reasonable, and they lead to different products.
- No default is reasonable.

Use three markers at most. Rank them by impact: scope, then security and privacy, then user
experience, then technical detail.

## 4. Settle the questions

Ask the open questions one at a time. Ask five questions at most. Give each question two to four
options and mark the one you recommend. After each answer, do these steps at once:

1. Add a dated line under **Clarifications**: the question and the answer.
2. Change the section the answer affects. Remove the marker.

Stop early when the remaining questions change nothing in the plan. Leave those in **Open
questions** with your default.

## 5. Model the threats

Run the `threat-model` skill when the product does any of these: stores personal or financial
data, signs users in, takes uploaded files, takes payments, or is reachable from the internet.
It fills the **Security** section with `SEC-` requirements.

## 6. Review it yourself

Read the whole file again against this list, and fix what you find in place:

- [ ] Every FR is testable and names its journey.
- [ ] Every journey has an independent test and at least one Given/When/Then.
- [ ] Every SC has a number or a yes/no observation.
- [ ] No library, framework, or API name appears outside **Constraints**.
- [ ] No "TBD", "etc.", "appropriate", "fast", or "user-friendly" without a measure.
- [ ] One term per concept. The same thing is not a "client" in J1 and a "customer" in FR-004.
- [ ] No two sections contradict each other.

## 7. Get approval, then hand over

Ask the person to read the file. When they approve it, set **Status** to `approved`. Then:

1. `write-adr` for each technology choice that is costly to reverse.
2. `scaffold-project` when the repository has no code yet.
3. `plan-work`, with this spec as the plan's **Source**.

When the spec changes after approval, edit it, add a dated line under **Clarifications**, and
re-plan every task that implements a changed requirement.

## Common mistakes

| Mistake | What to do instead |
|---|---|
| "Use PostgreSQL and React" in the requirements | Keep the requirements free of technology. Mandates go under **Constraints**, choices go in an ADR |
| "The system should be fast" | "Search returns the first page within 1 second for 10,000 records" |
| Fifteen clarification markers | Choose defaults. Keep the three that change the product |
| Every journey is P1 | P1 alone must be usable. Rank the others |
| A requirement no journey needs | Remove it, or add the journey that needs it |
