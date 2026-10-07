---
name: refactor
description: Restructure code without changing what it does. Use when the user asks to refactor, clean up, extract, split, rename, or simplify existing code, or to reduce duplication.
---

# Refactor safely

A refactor changes the shape and not the behaviour. That is the whole contract, and the only
way to keep it is to be able to prove behaviour did not change.

## The gate: green before, green after

```
1. Run the full suite now.        Not green? Stop. This is not a refactor yet.
2. Refactor in one small step.
3. Run the full suite.            Not green? Revert the step, do not patch it.
4. Commit.
5. Repeat.
```

**If the suite is not green before you start**, say so and stop. Refactoring on a red suite
means you cannot tell your change from the existing failure. Fix the failure first, as its own
commit, or get agreement to proceed knowing behaviour is unverifiable.

**If there is no test coverage over the code you are about to restructure**, that is the first
finding, not an obstacle to work around. Say so:

> `parseInvoice` has no tests. I can add characterisation tests at the `parseInvoice`
> interface first — they pin the current behaviour, including any bugs — then refactor against
> them. Or refactor without a net and verify by reading. Which?

Characterisation tests are the right answer nearly always. They assert what the code *does
now*, not what it should do, and that is exactly what a refactor must preserve.

## Say what you are changing, and why, before you start

Name the smell you are fixing. The `pr-review` skill's `references/smell-baseline.md` has the
vocabulary. "This is Feature Envy — `Invoice.total()` reads five fields off `Customer`, so the
method belongs on `Customer`" is a reason. "Cleaning this up" is not, and it is how a refactor
turns into an unreviewable diff.

Then state the scope, and hold to it. Every changed line should trace to the stated goal.

## One step at a time

Each step is a single named transformation, verified before the next:

- Rename a symbol
- Extract a function
- Inline a function
- Move a method to the class that owns its data
- Introduce a parameter object for a data clump
- Replace a repeated switch with polymorphism or a shared map
- Split a module by responsibility
- Introduce a seam where two adapters actually exist

Use the tooling's rename and extract where it exists. It is more reliable than editing, and it
finds the call site you would have missed.

Do not combine steps. Two transformations in one commit means a failure you cannot attribute
and a diff nobody can review.

## What a refactor is not

- **Not a behaviour change.** A bug you notice mid-refactor is a separate commit. Fix it
  before or after, with its own test, and say you are doing it.
- **Not an opportunity.** No renaming things you merely dislike, no reformatting neighbouring
  code, no dependency upgrades, no "while I am in here".
- **Not a redesign.** Where the shape needs to change substantially, that is a design task.
  Use `design-module` and `plan-work` and get agreement before touching code.
- **Not an interface change.** Changing a public signature changes behaviour for callers. That
  is a breaking change with its own migration story, not a refactor.

## Do not remove what you did not orphan

Remove the imports, variables, and helpers **your** change made unused. Report pre-existing
dead code rather than deleting it — deleting it is a separate change with its own risk, and
bundling it hides both.

## Finish

- [ ] The full suite is green, run in this turn. Quote the result.
- [ ] The public interface is unchanged, or the change is called out explicitly.
- [ ] Every changed line traces to the stated goal.
- [ ] No behaviour changed. Where any did, it is a separate commit with its own test.
- [ ] Only your own orphans were removed.
- [ ] The commit message names the smell and the transformation.

Report what you changed, what you deliberately left, and anything you found and did not touch.
