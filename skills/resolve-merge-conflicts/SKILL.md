---
name: resolve-merge-conflicts
description: Resolve merge or rebase conflicts by understanding both sides. Use when a merge, rebase, or cherry-pick stopped on conflicts, or when the user asks to resolve conflicts.
---

# Resolve merge conflicts

A conflict is two intentions meeting. Resolving it means understanding both, not picking the
side that compiles.

## 1. See the whole situation before touching a file

```bash
git status
git diff --name-only --diff-filter=U        # the conflicted files
git log --oneline --left-right HEAD...MERGE_HEAD
```

For a rebase, `REBASE_HEAD` names the commit being replayed. Knowing which operation you are in
matters, because "ours" and "theirs" swap between merge and rebase — a merge's "ours" is your
branch, and a rebase's "ours" is the upstream you are replaying onto.

## 2. Understand each side before resolving it

For each conflicted file, read three versions, not two:

```bash
git show :1:<file>    # the common ancestor — what both sides started from
git show :2:<file>    # ours
git show :3:<file>    # theirs
```

The ancestor is the one people skip and the one that answers the question. Without it you cannot
tell which side changed what, so you cannot tell what either side intended.

Then find out **why** each side changed:

```bash
git log --oneline -5 <ours-ref> -- <file>
git log --oneline -5 <theirs-ref> -- <file>
```

A commit message usually states the intent the diff cannot.

## 3. Resolve for intent, not for syntax

The resolution must satisfy **both** intentions where they are compatible. Usually they are:
two people changed nearby lines for unrelated reasons, and the answer keeps both changes.

Where they are genuinely incompatible — both sides changed the same behaviour to two different
things — that is not yours to decide silently. Stop and ask, naming both intentions:

> `retryPolicy.ts` conflicts. `main` raised the retry limit to 5 for the batch path (#4001).
> This branch replaced the fixed limit with a backoff policy (#4127). Both cannot stand. Should
> the backoff policy carry a limit of 5, or does the batch path need its own policy?

Never resolve by taking one side wholesale to make the conflict go away. `--ours` and `--theirs`
discard the other side's work, and the loss is silent — no test fails because nothing tested the
line that vanished.

## 4. Watch for the conflicts git does not mark

A clean merge can still be broken. Git conflicts on overlapping lines, not on meaning.

- One side renames a function, the other adds a caller. Both merge cleanly; the build fails.
- One side changes a function's contract, the other adds a caller depending on the old one. Both
  merge cleanly; the behaviour is wrong.
- Both sides add a migration. Both merge cleanly; the ordering is wrong.
- Both sides add a dependency at different versions. The lockfile resolves; the runtime does not.

After resolving, search for callers of anything either side renamed or re-signed.

**Lockfiles and generated files:** do not hand-merge them. Take one side, then regenerate:
`npm install`, `cargo update -p`, `bundle install`, or the project's generate command.

## 5. Verify before you continue

```bash
git add <resolved files>
# confirm no conflict markers survived anywhere
git diff --cached | grep -nE '^\+(<<<<<<<|=======|>>>>>>>)' && echo "MARKERS LEFT"
```

Then run the full test suite on the resolved tree. Both sides passing separately proves nothing
about the merge — that is exactly the class of failure conflicts introduce.

```bash
git merge --continue     # or: git rebase --continue
```

## 6. Say what you did

For each file: what each side wanted, what you kept, and anything you dropped. If you asked the
user to decide, record their decision in the merge commit body — the next person to hit this
conflict inherits the reasoning.

## When to stop and back out

```bash
git merge --abort        # or: git rebase --abort
```

Abort when the conflicts are extensive enough that you cannot be confident in the result, or
when the two branches have diverged so far that merging is the wrong operation. Say so rather
than producing a resolution nobody can trust:

> 23 files conflict, including the whole auth module. This branch is three weeks behind. I
> suggest rebasing onto `main` in stages, or reapplying the four commits onto a fresh branch.
> Aborting for now — nothing is lost.
