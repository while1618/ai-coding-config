---
name: commit
description: Stage changes and write a commit message worth reading.
disable-model-invocation: true
---

# Commit

This skill runs only when someone types `/commit`. Claude cannot start it, because where a
commit boundary falls is a judgement about the work, not a step to automate. When a unit of
work is finished, say so and let them run it.

One commit, one logical change, with a message that explains why. The subject is checked by
a hook; the body is your job, and it is the part that pays off six months later.

## 1. See what you actually have

```bash
git status --short
git diff --stat
```

Read the diff of every file you intend to stage:

```bash
git diff -- <path>
```

You are looking for three things: work that belongs in a different commit, a leftover debug
statement or `[DEBUG-...]` log, and anything that should never be committed — a credential,
a large binary, a local config file, a scratch file.

## 2. Split before you stage

If the diff covers more than one logical change, stage and commit them separately. A commit
that fixes a bug and renames a variable cannot be reverted, reviewed, or bisected cleanly.

Where the changes are tangled inside one file, use `git add -p` and stage the hunks that
belong together.

## 3. Stage deliberately

```bash
git add <path> <path>
```

Name the paths. `git add .` stages the scratch file you forgot about and the `.env` you
meant to delete.

## 4. Write the message

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Subject.** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`,
`chore`, or `revert`. Scope in kebab-case, optional. Imperative mood, lower case, no
trailing period, 72 characters or fewer.

- `fix(upload): retry once when the signing service times out`
- `refactor(auth): move token parsing behind a single seam`
- not `fixed a bug`, not `Updated files`, not `WIP`

**Body.** The diff already shows what changed. The body says why, in a few short
paragraphs. Write one whenever the change is more than obvious:

- The problem or trigger. What was wrong, or what was needed.
- The approach, plus the alternative you rejected when the choice is not obvious.
- **For a bug fix: the confirmed cause.** This is the highest-value line in the commit. The
  next person to touch this code inherits your investigation instead of repeating it.
- Anything a reader would otherwise have to reconstruct: a vendor quirk, a version floor, a
  benchmark number, a constraint that forced an ugly shape.

Leave out a restatement of the diff, a file list, and any claim you have not verified.

**Footer.** `Closes #123` for a repository issue, or `BREAKING CHANGE: <what breaks and what
to do>`.

Nothing else goes in the footer. Leave out every tool attribution line, whatever your
harness suggests by default: no `Generated with Claude Code`, no `Co-authored-by: Claude`,
no `🤖` line. The commit records the change, not the tool that
typed it.

Write the whole message under `style/communication.md`: short active sentences, no
marketing adjectives, hedges kept where you are unsure.

## 5. Commit and check

```bash
git commit -m "<subject>" -m "<body>"
git log -1 --stat
```

Read the result. Confirm the message is the one you meant and the file list is the one you
staged. Check the last line too: if a hook or template appended an attribution trailer,
remove it with `git commit --amend`.

## Do not push

Pushing is a separate decision and a separate skill. Use `pr-create` when the branch is
ready to leave the machine.

## Worked example

```
fix(upload): retry once when the signing service times out

Large uploads failed intermittently for one tenant. The signing service returns 504
after 30s under load, and the client treated that as a permanent failure.

The confirmed cause is a fixed 30s client timeout against a service whose p99 is 34s
under the tenant's batch load. Raising the timeout alone would still fail at p99.9, so
this retries once with a fresh signature instead.

Rejected: raising the timeout to 60s. It hides the latency and blocks the worker for a
minute on a genuinely dead service.
```
