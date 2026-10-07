---
name: pr-create
description: Open a pull request with a description a reviewer can act on.
disable-model-invocation: true
---

# Create a pull request

This skill runs only when someone types `/pr-create`. Claude cannot start it, because opening
a pull request pushes a branch and asks for a teammate's attention. When the branch is ready,
say so and let them run it.

A PR is a request for someone's attention. It earns that attention by stating what the
reviewer cannot read from the diff.

## 1. Verify before you offer

Run the project's full test suite now, in this session. A green run from earlier in the
session proves only the tree it ran on.

If anything fails, stop and report the failures. There is no PR to open yet.

Then check the branch itself:

```bash
git status --short          # nothing uncommitted that belongs in this PR
git log --oneline <base>..HEAD
git diff --stat <base>...HEAD
```

## 2. Confirm the base branch

The base is whatever this work forked from. It is usually named in the issue, the
conversation, or the branch's upstream. When it is not already settled, ask:

> This branch split from `main` — is that the right base?

Merging into the wrong base costs far more to undo than the question costs to ask.

## 3. Read the diff you are about to describe

Read your own diff end to end before writing a word. You are looking for what a reviewer
will ask about: the change you made and forgot, the debug line, the widened scope.

## 4. Write the description

Use the repo's template when `.github/pull_request_template.md` exists — fill every section
with a real answer, never a placeholder. Otherwise:

```markdown
## Problem

<What was wrong or needed, and why it matters. Link the issue. For a bug, name the
confirmed cause — not the symptom. The reviewer cannot read it from the diff.>

## Change

<The approach, in a few sentences. Name the alternative you rejected when the choice is
not obvious. Point at the one or two files that carry the core of it. Say what you did
_not_ change where a reviewer would expect you to have — after checking the diff.
Where the branch is waiting on another PR, say so, name that
PR.>

## Testing

<What you ran and what it returned. What tests you added or fixed, and which behaviour
each one now covers. If a test passed before your fix, say why it did not catch the bug.>

## How to verify

<The exact commands or steps a reviewer runs, and what they should see. Not "run the
tests" — the command, and the expected result.>

## Risk

<What could break. What is not covered. What to watch after deploy. "None" is an answer,
but only after you looked.>

## Out of scope

<What you deliberately left alone, and why. Name the owner of each — the ticket, PR, or
team it belongs to. Name the adjacent code that may carry the same bug, and the follow-up
it needs. Say whether docs changed. "Nothing" is an answer.>
```

Rules for the prose:

- Write it under `style/communication.md`. Short active sentences. No marketing
  adjectives — nothing is seamless or robust.
- State what you verified and how. Leave out what you did not.
- Keep every hedge. "This may affect the batch path" never becomes "this affects the batch
  path".
- `Testing` is your evidence. `How to verify` is the reviewer's instructions. Do not merge
  them.
- `Change` explains the approach. It does not walk the diff file by file.
- Where the diff is large, say why it could not be split.
- End on the last section. Leave out every tool attribution line, whatever your harness
  suggests by default: no `Generated with Claude Code`, no `Co-authored-by: Claude`, no
  `🤖` line. The PR records the change, not the tool that
  typed it.

## 5. Push and open

```bash
git push -u origin <branch>
gh pr create --base <base> --head <branch> --title "<conventional title>" --body-file <file>
```

Use the forge's CLI when one is available. Where none is, push and use the creation URL the
remote prints.

Never force-push. A rejected push means the remote moved, and the answer is to fetch and
read the divergence.

## 6. Report

Give the URL, the title, and the one thing you most want the reviewer to look at.

## Common mistakes

| Mistake                                        | Instead                                         |
| ---------------------------------------------- | ----------------------------------------------- |
| A description that restates the diff           | State the problem the diff solves               |
| "All tests pass" with no run this session      | Run the suite, quote the result                 |
| Placeholder sections in the repo template      | Fill each one, or say why it does not apply     |
| Opening the PR before asking about the base    | Confirm the base first                          |
| Leaving a known-broken neighbour unmentioned   | Name it under `Out of scope` with the follow-up |
| Out-of-scope items with no owner               | Name the ticket, PR, or team that owns each     |
| A 2000-line PR with no explanation of its size | Split it, or justify it in the description      |
| A tool attribution line at the end of the body | End on the last section                         |
