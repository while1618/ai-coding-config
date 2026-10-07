---
name: explain-diff
description: Explain what a diff, commit range, or PR changed and why, without reviewing it. Use when the user asks what changed, what a PR does, what a commit did, or to walk them through someone else's change.
when_to_use: >-
  "what changed", "what does this PR do", "what did that commit do", "walk me through this
  diff", reviewing someone else's work without judging it
---

# Explain a diff

The reader wants to understand a change, not have it judged. Reviewing is `pr-review`; this
skill explains.

## 1. Pin the range

```bash
git log --oneline <base>..<head>
git diff --stat <base>...<head>
gh pr view <n> --json title,body,baseRefName    # when it is a PR
```

Read the PR description and the commit messages first. They state the author's intent, which
is what the diff alone cannot tell you. Note where the diff and the description disagree —
that is worth reporting, without turning it into a review finding.

## 2. Read the whole diff

```bash
git diff <base>...<head>
```

Three dots, so the comparison is against the merge base.

Where it is large, group the files by what they are doing rather than by directory. Most large
diffs are one real change plus several mechanical consequences of it, and separating those is
most of the explanation.

## 3. Explain

**Lead with the change in one or two sentences.** What is different afterwards, from the
outside.

**Then the why**, from the description, the issue, or the commit body. Where none of them say,
say that: "no stated reason — the commit message only describes the mechanics".

**Then the shape of it:**

- **The core change.** The one or two files that carry it, and what they now do differently.
- **The consequences.** What had to change because of that — signature updates, call-site
  changes, migrations, generated files.
- **The incidental.** Formatting, renames, dependency bumps. Name it as incidental so the
  reader can skip it.

**Then what a reader should notice:**

- Behaviour that changed for a user or a caller.
- A new dependency, config key, environment variable, or migration.
- Anything needed at deploy time — a migration to run, a flag to set, an order to follow.

**Then the trace, when the change is behavioural.** Follow the new path through the code with
file and line references. This is what makes a change concrete.

## 4. What not to do

- Do not rank findings or give a verdict. That is a review.
- Do not restate the diff hunk by hunk. The reader has the diff.
- Do not assert intent the author did not state. Say "this looks intended to..." and keep the
  hedge.
- Do not skip the part you did not understand. Name it: "I cannot tell why `flush()` moved
  above the guard — worth asking the author."

## Writing rules

`style/communication.md`. Short active sentences. Reference code as `file.ts:42`. One topic
per paragraph. No adjectives claiming quality — the change is not elegant, it is a change.
