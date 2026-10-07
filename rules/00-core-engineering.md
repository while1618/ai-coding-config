---
description: The reasoning discipline that governs every code change.
source: "Adapted from github.com/multica-ai/andrej-karpathy-skills CLAUDE.md (MIT),
  after Andrej Karpathy's observations on LLM coding pitfalls.
  Upstream commit 2c606141936f (2026-04-20). Diff against that commit to see whether
  upstream has moved since this was adapted."
---

# Core engineering

These four habits cut the mistakes that AI-written code makes most often. They trade speed for
caution. On a one-line change, use judgment.

## 1. Think before coding

**Do not assume. Do not hide confusion. Surface tradeoffs.**

Before you implement:

- State your assumptions explicitly. If you are uncertain, ask.
- If the request has several readings, present them. Do not pick one silently.
- If a simpler approach exists, say so. Push back when the evidence supports it.
- If something is unclear, stop. Name what confuses you. Ask.

## 2. Simplicity first

**The minimum code that solves the problem. Nothing speculative.**

- No features beyond the request.
- No abstraction for a single call site.
- No flexibility or configurability nobody asked for.
- No error handling for cases that cannot occur.
- If you wrote 200 lines and 50 would do, rewrite it.

Ask: would a senior engineer call this overcomplicated? If yes, simplify.

## 3. Surgical changes

**Touch only what you must. Clean up only your own mess.**

When you edit existing code:

- Leave adjacent code, comments, and formatting alone.
- Do not refactor what is not broken.
- Match the existing style, even where you prefer another.
- Report unrelated dead code. Do not delete it.

When your change orphans something:

- Remove the imports, variables, and functions *your* change made unused.
- Leave pre-existing dead code unless someone asks for it.

The test: every changed line traces directly to the request.

## 4. Goal-driven execution

**Define success. Loop until you verify it.**

Turn the task into a check you can run:

- "Add validation" becomes "write tests for invalid input, then make them pass".
- "Fix the bug" becomes "write a test that reproduces it, then make it pass".
- "Refactor X" becomes "tests pass before and after, and behaviour is unchanged".

For a multi-step task, state the plan first:

```
1. [step] → verify: [check]
2. [step] → verify: [check]
```

A strong success criterion lets you work without stopping to ask. A weak one ("make it work") forces
a clarification round for every step.

## These rules work when

Diffs carry fewer unrelated changes. Fewer rewrites follow from overcomplication. Clarifying questions
arrive before the code, not after the mistake.
