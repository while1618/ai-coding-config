---
name: onboard-project
description: Get productive in an unfamiliar repository — running, green, mapped, and documented. Use at the first session in a new project, when the user says they are new to a codebase, or when nothing runs locally yet.
---

# Onboard to a project

The goal of the first session is not to change code. It is to reach a state where changing code
is safe: the project runs, its tests are green, you know where things are, and the next session
starts from a written map rather than from nothing.

Work in this order. Each step depends on the one before it.

## 1. Get it running

Read `README.md`, `AGENTS.md`, `CONTRIBUTING.md`, and the CI workflow, then follow the setup
steps exactly as written.

**Keep a record of every place the documentation was wrong.** A missing prerequisite, a command
that failed, an undocumented service, a version that does not work. This list is the most
valuable output of the whole session, because it is knowledge nobody else has written down and
everyone rediscovers.

Where a step fails, fix it forward and note what you did. Where you cannot, say what blocked you
and what you would need.

## 2. Get the tests green

```bash
<the project's test command>
```

Three outcomes, and they are not the same:

- **Green.** Good. You now have a baseline you can trust.
- **Failing for an environment reason** — a missing service, an absent credential, a platform
  difference. Fix it, and add it to the record from step 1.
- **Failing on `main` for a real reason.** Do not fix it silently. Report it: the team may know,
  or may not. Either way you now know that a green suite is not this project's baseline, and
  every later verification claim has to account for that.

Run the lint and type commands too. Note which ones CI enforces — CI is the definition of green
that the team actually applies.

## 3. Map it

Use the `explain-project` skill. It covers the seven questions worth answering and the
file-churn command that shows where the work really happens.

Read the entry points and follow one representative path end to end. One concrete trace is worth
more than a directory survey.

## 4. Make one trivial change and put it through the whole loop

Change a log message, fix a typo in a comment, tighten one docstring. Then run the full loop:
edit, verify, commit, and — if the project's flow includes it — open a PR.

This is the step people skip, and it is the one that finds the problems: the pre-commit hook
that needs a tool you do not have, the required commit format, the CI job that fails on
something local does not check, the review requirement nobody mentioned. Finding those on a typo
costs nothing. Finding them on real work costs a day.

Do not merge it unless the user wants it merged. The point is the loop, not the change.

## 5. Write down what you learned

Two outputs:

**`AGENTS.md`** — use the `agents-md` skill. Everything from step 1 that was wrong or missing
goes in it. This is the step that makes the session pay off for the next person, human or agent.

**A note to the user** covering:

- What you could not get working, and what you would need.
- Where the documentation was wrong.
- Anything that looked risky, unowned, or actively broken.
- The three files you would read first, in order, and why.

## Rules for this session

- **Change nothing beyond the trivial commit** without asking. You do not yet know what depends
  on what.
- **Ask rather than infer** on anything that would be destructive, costly, or hard to undo.
  Running a migration against a shared database is not an onboarding step.
- **Say what you did not do.** A large codebase does not fit one session, and naming the gap is
  more useful than a confident partial summary.
- **Write everything under `style/communication.md`.**
