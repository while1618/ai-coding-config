---
name: execute-plan
description: Carry out a written implementation plan task by task — a fresh subagent per task, a spec and standards review after each, and a ledger that survives lost context. Use when an approved plan exists and the user says to start, execute, implement, or continue it.
source: "Adapted from github.com/obra/superpowers skills/subagent-driven-development and skills/executing-plans (MIT), fetched 2026-10-06."
---

# Execute the plan

The plan already did the thinking. This skill carries it out exactly, proves each task with its
own verification command, and keeps a written record so the work survives a lost context. The
spec has the final say. The plan is how the spec gets built.

## 1. Set up

1. **Read the plan and the spec in full.** The spec is the plan's **Source** line.
2. **Check the plan before you start.** Every `Modify` path exists. Every `Consumes` interface is
   produced by an earlier task. Report each problem and fix the plan with the person before task 1.
3. **Ask the person two questions, once:**
   - **Mode.** Subagent per task, the default. Or inline, which is cheaper and runs in one context.
     Use inline when the harness has no subagent tool.
   - **Commits.** Commit at the end of each task as the plan says, or leave the changes for the
     person to commit with `/commit`.
4. **Use a branch.** Work on a feature branch. Do not work on the main branch unless the person
   says so.
5. **Open the ledger.** The ledger is `<plan-file-name>.ledger.md`, next to the plan. When it
   already exists, resume from it. Never redo a task that the ledger marks done.

```markdown
# Ledger: <plan name>

Plan: <path> | Spec: <path> | Branch: <name> | Base: <commit>
Mode: subagent | inline | Commits: per task | by the person

## Tasks
- [x] Task 1: <name> — <commit, or "uncommitted"> — `<command>`: <result>
- [ ] Task 2: <name>

## Rulings
- Task 3: <what you decided> — <why> — <what it costs if wrong>

## Open findings
- <finding> — <severity> — <why it was left>
```

Context can be compacted. Conversation memory then loses track of finished tasks. The ledger
does not.

## 2. Run each task

### Subagent mode

1. **Write the brief.** The subagent sees only the brief, not this conversation. Include:
   - the task text from the plan, verbatim;
   - the spec requirements the task implements, quoted with their IDs;
   - the interfaces that earlier tasks produced, with exact names and types;
   - the project's test and lint commands;
   - the instructions: follow the task's test-first steps, run every verification command, change
     only the task's files, and report the changed files and each command's output. Stop and ask
     when something in the task is unclear.
2. **Dispatch the implementer** with the harness's subagent tool.
3. **Check the report.** A report is a claim. Run the task's verification command yourself, and
   read the diff.
4. **Review the task.** Dispatch the `spec-checker` agent with the diff and the quoted
   requirements. Dispatch the `code-reviewer` agent with the diff. Both are read-only.
5. **Fix.** Send each Critical or Important finding back to the implementer. After three fix
   rounds with findings still open, stop and ask the person.
6. **Record it.** Add the result to the ledger. Commit when the person chose per-task commits.

### Inline mode

Do steps 3 and 6 yourself for each task, and work the task's steps in order. Run the review in
step 4 once, at the end, over the whole branch.

### Between tasks

Continue to the next task without asking. The person approved the plan, so a "should I continue?"
message only costs them time.

## 3. When the plan is wrong

**A small defect.** Examples are a wrong path, a renamed function, or a missing import. Decide,
write a ruling in the ledger, and continue. A ruling has three parts: what you decided, why, and
what it costs if you are wrong.

**A conflict with the spec.** The task needs behaviour the spec does not ask for, or contradicts a
requirement. Stop and ask. Fix the plan with `plan-work` before you continue.

**Stop and ask the person** before any of these actions:

- a destructive or irreversible operation;
- a security-sensitive action;
- an effect outside the repository: a push, a merge, a deploy, or a publish;
- a step where every option is a guess.

## 4. Finish

1. Run the full test suite and the linter with the `verify-changes` skill.
2. Dispatch `spec-checker` with the whole spec, and `code-reviewer`, over the diff from the
   base commit to now.
3. Fix each Critical and Important finding in one pass. Prove each fix with a test that failed
   before the fix and passes after it. Record the Minor findings in the ledger.
4. Report the result: the tasks completed, the rulings, the open findings, and each final command
   with its output.
5. Say that the branch is ready for `/commit` or `/pr-create`. Only the person starts those.

## Common mistakes

| Mistake | What to do instead |
|---|---|
| The subagent gets "do task 3" | The brief carries the task text, the requirements, and the interfaces |
| Trusting "all tests pass" in a report | Run the command yourself |
| Redoing finished tasks after a compaction | Read the ledger first |
| Quietly changing the plan | Write a ruling for small defects. Stop for spec conflicts |
| Pushing or opening the PR at the end | Say it is ready. The person starts `/pr-create` |
