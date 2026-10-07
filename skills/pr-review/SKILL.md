---
name: pr-review
description: Review a pull request, branch, or diff on two separate axes — does it follow this repo's standards, and does it do what the issue asked. Use when the user asks to review a PR, review a branch, "review since X", or check a diff before merge.
---

# Review a pull request

Review two things, and report them apart:

- **Standards** — does this hold up as code in this repository?
- **Spec** — does it do what the issue or spec asked, no less and no more?

A change can pass one and fail the other. Code that follows every convention while
implementing the wrong thing passes Standards and fails Spec. Code that does exactly what
the issue asked while breaking the project's patterns does the reverse. Merging the two
reports lets one hide the other.

## 1. Pin the range

Whatever the user named is the fixed point: a PR number, a branch, a tag, `main`, `HEAD~5`,
a SHA. When they named nothing, ask.

```bash
gh pr view <n> --json title,body,baseRefName,headRefName    # when reviewing a PR
git rev-parse <fixed-point>                                  # confirm it resolves
git log <fixed-point>..HEAD --oneline
git diff --stat <fixed-point>...HEAD
```

Three dots, so the comparison is against the merge base. Confirm the ref resolves and the
diff is non-empty before you go further — a bad ref should fail here, not inside two
subagents.

## 2. Find the spec

In this order:

1. Issue references in the PR body or the commit messages (`#123`, `Closes #45`).
2. A path the user gave you.
3. A spec or design file under `docs/`, `specs/`, or matching the branch name.
4. Ask. If there is no spec, the Spec axis reports "no spec available" and you say so.

## 3. Find the standards

Anything in the repo that says how code should be written: `AGENTS.md`, `CLAUDE.md`,
`CONTRIBUTING.md`, `CODING_STANDARDS.md`, and the rule files this config installs.

On top of whatever the repo documents, the Standards axis always carries the **smell
baseline** in `references/smell-baseline.md`. It applies even when the repo documents
nothing. Two rules bind it: a documented repo standard always overrides it, and every entry
is a labelled judgement call, never a hard violation.

## 4. Run both axes in parallel

Dispatch two subagents so neither pollutes the other's context:

- **`code-reviewer`** — give it the diff command, the commit list, the standards sources you
  found, and the full text of `references/smell-baseline.md`. It has no other access to the
  baseline.
- **`spec-checker`** — give it the diff command, the commit list, and the spec.

Skip the spec agent when there is no spec, and note that in the report.

## 5. Read the diff yourself as well

The subagents are thorough about their own axis and blind to everything else. Read the diff
yourself for the things neither axis owns:

- Does the test suite actually cover the new paths, or only run over them?
- Is there a `[DEBUG-...]` line, a commented-out block, or a `TODO` with no owner left in?
- Does the PR description match what the diff does?

## 6. Report

```markdown
## Standards
<the code-reviewer's report>

## Spec
<the spec-checker's report, or "No spec available — this axis did not run">

## Also
<what you found reading the diff yourself>

## Summary
Standards: <n> findings, worst: <one line>
Spec: <n> findings, worst: <one line>
```

Do not merge or re-rank across the two axes, and do not pick a single winner. That
re-ranking is what the separation exists to prevent.

## Calibration

Rank by what goes wrong, not by how easy the fix is. A nit marked Critical costs you the
reviewer's trust for the real finding.

Say what was done well, specifically, before the list. Accurate praise is what makes the
rest of the feedback land.

Skip anything a linter or formatter already catches — the project runs those.

Where you are unsure whether something is a real problem, say so in those words rather than
dropping it or overstating it.

## Posting the review

When the user asked you to post it, put line-level findings as inline comments on the diff
and the summary as the review body:

```bash
gh pr review <n> --comment --body-file <file>
```

Otherwise report in the session and let the user decide.
