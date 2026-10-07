---
name: shape-idea
description: Discuss and sharpen an idea for an app or feature before anything is built — purpose, users, scope, and approach. Use when the user describes something new to build, wants to talk an idea through, or asks to be challenged on an idea before a spec exists.
source: "Adapted from github.com/obra/superpowers skills/brainstorming (MIT), fetched 2026-10-06."
---

# Shape the idea

The output of this skill is agreement, not code. A wrong idea built well is still wrong, and a
conversation is the cheapest place to find that out.

## The gate

Until the person approves the brief in step 6, take read-only actions only. Read code, read docs,
and ask questions. Write no product code, generate no scaffold, install no dependency, and create
no project. Approval of the brief permits the next stage only: a spec for a product, a build for a
bounded change.

## 1. Classify the size, out loud

Say which path you chose and why, so the person can override it.

- **Spike.** A feasibility question: "can we", "is it possible". The output is an answer. Probe as
  cheaply as correctness allows, and label anything you build as throwaway.
- **Bounded.** A small change to a flow that already exists in this repo and that you can read.
  Write a short design in chat, get a yes, then build. No spec file.
- **Product.** A new app, a new subsystem, or a change to an interface that others depend on.
  Follow steps 2 to 6, then the `write-spec` skill.

When two paths fit, take the heavier one. A new app is always a product: it has no existing flow
to read. Complexity found later moves the work to a heavier path. Nothing moves it to a lighter one.

## 2. Find the intent

Ask one question per message. Offer choices when the likely answers are known. Ask only for what
the person has not already said, in this order:

1. **Outcome.** What problem this solves, for whom, and why now.
2. **Success.** How the person will know it works. Get a number where one exists.
3. **Journeys.** The one to three things a user must be able to do.
4. **Constraints.** Deadline, budget, mandated stack, hosting, data rules, integrations, and who
   maintains it afterwards.
5. **Non-goals.** What this will deliberately not do.

The step is complete when you can fill every line of the brief in step 5 without a guess, or
with a guess you will list as an assumption.

## 3. Challenge it

Push back where the evidence supports it. Each challenge names the risk and a cheaper option.

- **Existing solution.** Does a product, a spreadsheet, or an internal tool already do this?
- **Smaller first version.** Name the smallest version that proves the idea. Most first
  descriptions carry a second release inside them.
- **Fatal assumption.** Which assumption kills the idea if it is wrong? Can a spike test it first?
- **Sensitive data.** Does it hold personal, financial, health, or credential data? If yes, the
  spec stage runs the `threat-model` skill.

The person decides. Record a disagreement in the brief rather than repeating it.

## 4. Propose approaches

Give two or three approaches. For each one, state its shape, what it costs, and what it rules out.
Recommend one and say why. Name a technology only where it changes the shape of the product.
Library choices belong to the plan.

## 5. Write back the brief

```markdown
**Idea:** <one sentence>
**For:** <who uses it>
**Success:** <measurable outcome>
**Must do:** <the one to three journeys>
**Will not do:** <non-goals>
**Constraints:** <deadline, stack, hosting, data, integrations>
**Approach:** <the chosen approach, and why it beat the others>
**You said:** <facts from the person>
**I assumed:** <every guess, so the person can correct it>
**Open questions:** <what the spec must still settle>
```

Keep "You said" and "I assumed" apart. The person can only correct an assumption they can see.

## 6. Get approval, then hand over

Ask the person to confirm or correct the brief. The step is complete when the person says the
brief is right. Then:

- **Product:** use `write-spec`, with the brief as its input.
- **Bounded:** build it with `write-tests`.
- **Spike:** report the finding as a recommendation.

## Common mistakes

| Mistake | What to do instead |
|---|---|
| Five questions in one message | One question. The answer often changes the next question |
| "I know this kind of app, so it is bounded" | Bounded describes this repo, not your familiarity. A new app is a product |
| Choosing the framework during the discussion | Settle the outcome and the journeys. The stack follows from the constraints |
| Treating "sounds good" about the idea as approval of the brief | Show the brief. Approval covers only what the person has seen |
| Scaffolding "to save time" while the person reads | The gate is the approval, not the length of the design |
