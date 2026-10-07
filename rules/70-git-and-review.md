---
description: Commits, branches, pull requests, and how to give and take review.
paths:
  - "**"
---

# Git and review

## Commits

**One commit, one logical change.** A commit that both fixes a bug and renames a variable cannot be
reverted, reviewed, or bisected cleanly.

Stage deliberately. Read the diff of each file before you add it. `git add .` stages the scratch file
you forgot about.

### Message format

Conventional Commits. A hook enforces the subject line.

```
<type>(<scope>): <subject>

<body>

<footer>
```

- **type** — one of `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`,
  `revert`.
- **scope** — the area touched, in kebab-case. Optional but usually worth it.
- **subject** — imperative mood, lower case, no trailing period, 72 characters or fewer.
  "add retry to the upload path", not "added" or "adds".

### Body

The body explains **why**, because the diff already shows what. Write it when the change is anything
more than obvious. Cover, in a few short paragraphs:

- The problem or the trigger. What was wrong, or what was needed.
- The approach, and the alternative you rejected, when the choice is not obvious.
- The confirmed cause, for a bug fix. The next person to touch this code learns from it.
- Anything a reader would otherwise have to reconstruct: a constraint, a vendor quirk, a benchmark number.

Leave out a restatement of the diff, a file list, and any claim you did not verify.

### Footer

`Closes #123` for a repository issue, or `BREAKING CHANGE: <what breaks and what to do>`.

## Branches

Name for the work: `fix/upload-retry`, `feat/tenant-scoped-search`. Branch from the current base and
keep the branch short-lived. Confirm the base branch before merging — merging into the wrong base costs
more to undo than it costs to ask.

## Force and destruction

Never force-push, hard-reset, force-clean, or force-delete a branch on your own initiative. Each one
destroys work that exists nowhere else. When a push is rejected, the remote moved: investigate. A hook
blocks these commands; that block is the rule working, not an obstacle to route around.

## Pull requests

A PR carries what a reviewer needs and nothing they can read from the diff:

- **Problem** — what was wrong or needed, and why it matters. Link the issue.
  For a bug, name the confirmed cause.
- **Change** — the approach in a few sentences, and the alternative rejected if the choice is
  non-obvious. Where the branch waits on another PR, say so.
- **Testing** — what you ran and what it returned, and what tests you added or fixed.
- **How to verify** — the exact commands or steps a reviewer runs, and what they should see.
- **Risk** — what could break, what is not covered, what to watch after deploy. "None" is an answer,
  but only after you looked.
- **Out of scope** — what you left alone and why, including adjacent code that may carry the same
  bug. Name the owner of each. Say whether docs changed.

Keep it small enough to review in one sitting. Where the change is large, say why it could not be
split. Follow the repo's template when one exists. Write it under `style/communication.md`.

The full workflow, including the pre-flight checks, is `/pr-create`. Only a person can start
it, so when the branch is ready, say so rather than opening the PR yourself.

## Reviewing

Review two things separately, because one masks the other:

- **Standards** — does the code follow this repo's conventions and hold up as code?
- **Spec** — does it do what the issue or spec asked, no less and no more?

Code can pass either and fail the other. Report them apart.

Rank findings by actual severity — **Critical** (bug, security, data loss), **Important** (architecture,
missing requirement, test gap), **Minor** (polish). A nit marked critical costs you the reviewer's trust
for the real finding. Every finding carries `file:line`, what is wrong, why it matters, and the fix when
it is not obvious. Say what was done well, specifically, before the list. Skip anything a linter already
catches.

Full process: the `pr-review` skill.

## Receiving review

- **Read all of it before responding.**
- **Verify against the codebase before implementing.** A suggestion can be right in general and wrong
  here.
- **Clarify every unclear item before starting any of them.** Items relate; partial understanding
  produces the wrong change.
- **Push back with technical reasoning** when a suggestion breaks something, misses context, or adds an
  unused feature. Cite the test or code that shows it.
- **State the fix, not agreement.** "Fixed in `upload.ts:42` — the guard now runs before the retry"
  beats "good catch".
- **Say when you cannot verify.** "I cannot check this without staging access — investigate, or proceed?"

Full process: the `pr-comments` skill.
