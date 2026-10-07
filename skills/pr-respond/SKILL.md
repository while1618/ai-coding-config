---
name: pr-respond
description: Respond to code review feedback — verify each item, push back where it is wrong, implement what is right, and reply in the thread. Use when the user shares review comments, says "address the feedback", or asks you to respond to a reviewer.
---

# Respond to review comments

Review feedback needs technical evaluation, not agreement. A suggestion can be correct in
general and wrong for this codebase, and implementing it anyway makes the code worse while
looking cooperative.

## The order matters

```
1. READ      all of it, without acting
2. UNDERSTAND restate each item in your own words
3. CLARIFY   ask about every unclear item, before starting any of them
4. VERIFY    check each item against the codebase
5. RESPOND   acknowledge, or push back with reasoning
6. IMPLEMENT one item at a time, verify each
```

## 1. Read all of it first

Fetch the whole review before you touch anything:

```bash
gh pr view <n> --comments
gh api "repos/{owner}/{repo}/pulls/<n>/comments"   # inline comments, with their ids
```

## 2. Clarify before you start anything

If any item is unclear, stop and ask about it **before implementing the ones you do
understand**. Items relate to each other. Half an understanding produces the wrong change,
and you will redo the clear items once the unclear ones land.

> I understand items 1, 2, 3, and 6. I need clarification on 4 and 5 before I start.

## 3. Verify each item against the codebase

Before implementing a suggestion, check:

- Is it technically correct **for this codebase**, this stack, this version?
- Does it break something that currently works? Search for the call sites.
- Is there a reason the current code is shaped this way — a comment, an ADR, a git blame
  pointing at a fix?
- Does the reviewer have the full context, or are they reading one hunk?
- Does it ask for a feature nothing uses? Grep before you build it.

Feedback from a teammate who knows the codebase deserves more trust than a bot's suggestion
or a drive-by comment. Verify either way.

## 4. Push back when the evidence supports it

Push back when the suggestion breaks working behaviour, misses context, contradicts a
decision already recorded, is wrong for this stack, or asks for something nothing needs.

Push back with the evidence, not with defensiveness:

> The build targets Node 18, and `Array.fromAsync` needs 22. Keeping the manual loop, or do
> we want to raise the floor?

> Grepped for callers of `/metrics/export` — nothing calls it. Remove it rather than
> implement it properly?

Where you cannot verify a claim, say so and ask for direction:

> I cannot check this without access to the staging logs. Should I investigate, or do you
> already know the answer?

If a suggestion conflicts with a decision the team already made, stop and raise it rather
than quietly reversing that decision.

## 5. Acknowledge by stating the fix

State what changed and where. That is what tells the reviewer you understood.

> Fixed. The guard now runs before the retry, in `upload.ts:42`.

> Good catch — the empty-array case returned `undefined`. Fixed in `parse.ts:88`, with a
> test for it.

Skip the performative agreement. "You're absolutely right" and "great point" carry no
information; the fix does.

## 6. Implement in a sensible order

1. Blocking issues: anything broken, unsafe, or wrong.
2. Simple fixes: typos, imports, names.
3. Complex fixes: refactors, logic changes.

Verify each one before starting the next. Batching several fixes and running the suite once
at the end means a failure you cannot attribute.

## 7. Reply in the thread

An inline comment gets an inline reply, not a new top-level comment. A top-level reply
strands the conversation away from the code it is about.

```bash
gh api --method POST \
  "repos/{owner}/{repo}/pulls/<n>/comments/<comment-id>/replies" \
  -f body="Fixed in upload.ts:42 — the guard now runs before the retry."
```

Then push, and say in the PR what you changed and what you pushed back on.

## When you were wrong to push back

State it plainly and move on.

> You were right — I checked, and the batch path does call it. Implementing now.

No long apology, no defence of the original position.

## Common mistakes

| Mistake | Instead |
|---|---|
| Implementing before verifying | Check against the codebase first |
| Implementing the clear items, asking about the rest later | Clarify everything first |
| Agreeing with a suggestion that breaks something | Push back with the evidence |
| Batching fixes, one test run at the end | One fix, one verification |
| A new top-level comment answering an inline one | Reply in the thread |
| Building a "proper" version of something nothing calls | Grep, then propose deleting it |
