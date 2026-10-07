---
name: plan-work
description: Turn a request too large for one pass into a plan of small verifiable tasks. Use when the user asks for a plan, when a task spans several files or sessions, or before starting anything whose approach is not settled.
---

# Plan the work

A plan exists so someone else — or you in a later session with none of this context — can
execute it without guessing. Write it for a skilled engineer who knows nothing about this
codebase or problem domain.

## 1. Settle the approach before writing the plan

Do not plan an approach nobody has agreed to.

Where an approved spec exists, it is the plan's **Source**. Every requirement ID in it maps to a
task, and this step settles only what the spec leaves open.

- State what you understood the request to be, in your own words.
- Name your assumptions. Where the request has more than one reading, present the readings.
- Where a simpler approach exists, say so before planning the complicated one.
- Ask about the choices that change the plan's shape. Skip the ones that do not.

## 2. Check the scope

If the request covers several independent subsystems, propose one plan per subsystem. Each
plan should produce working, testable software on its own. A plan whose first eight tasks
deliver nothing runnable cannot be checked halfway.

## 3. Map the files before the tasks

Before writing any task, list what will be created and modified, and what each file is
responsible for. This is where the decomposition decisions get made, and doing it after the
tasks means redoing the tasks.

- Give each unit one clear responsibility and a well-defined interface.
- Prefer focused files. Edits are more reliable in a file you can hold at once.
- Files that change together belong together. Split by responsibility, not by technical layer.
- In an existing codebase, follow the established patterns. Where a file you are already
  changing has grown unwieldy, a split is reasonable — say so explicitly.

Use the `design-module` skill where the interfaces are the hard part.

## 4. Size the tasks

A task is the smallest unit that carries its own test cycle and is worth a reviewer's
attention.

- Fold setup, config, and scaffolding into the task whose deliverable needs them.
- Split only where a reviewer could reject one task while accepting its neighbour.
- Every task ends with something independently testable.

Inside a task, each step is one action of two to five minutes: write the failing test, run it
and watch it fail, write the minimal code, run it and watch it pass, commit.

## 5. Write it

Save to `docs/plans/YYYY-MM-DD-<name>.md`, unless the project puts plans elsewhere.

````markdown
# <Feature> implementation plan

**Goal:** <one sentence: what this builds>

**Approach:** <two or three sentences>

**Stack:** <the technologies and libraries this touches>

**Source:** <the issue, spec, or conversation this implements>

## Executing this plan

- One task at a time, in order. Finish a task before you open the next one.
- A task is done when its verification command passes, not when its code is written.
- Commit at the end of each task, so every commit is one working step.
- Where a task turns out to be wrong, stop and say what does not match, then re-plan that
  task. The plan is a shared artifact, and improvising past it makes it a lie.

## Constraints

<Project-wide requirements that every task inherits. Version floors, dependency limits,
naming rules, platform requirements. Exact values, copied from the source.>

## Files

- Create `src/queue/retry.ts` — the retry policy and its single public function
- Modify `src/worker/upload.ts:88-120` — call the policy instead of the inline loop
- Create `tests/queue/retry.test.ts`

---

### Task 1: <component>

**Files**
- Create: `exact/path.ts`
- Modify: `exact/path.ts:34-56`
- Test: `tests/exact/path.test.ts`

**Interfaces**
- Consumes: <exact signatures this task relies on from earlier tasks>
- Produces: <exact names, parameters, and return types later tasks rely on>

- [ ] **Write the failing test**

```typescript
test('retries three times before giving up', async () => {
  // the actual test, not a description of it
});
```

- [ ] **Run it and confirm it fails**

Run: `npm test tests/queue/retry.test.ts`
Expect: fails with "retryOperation is not defined"

- [ ] **Write the minimal implementation**

```typescript
// the actual code
```

- [ ] **Run it and confirm it passes**

Run: `npm test tests/queue/retry.test.ts`
Expect: passes, and the rest of the suite still passes

- [ ] **Commit**

```bash
git add src/queue/retry.ts tests/queue/retry.test.ts
git commit -m "feat(queue): add retry policy"
```
````

The `Interfaces` block matters more than it looks: whoever executes a task may see only that
task, and this is how they learn the names and types their neighbours use.

## 6. No placeholders

These are plan failures, not shortcuts. Never write them:

- "TBD", "TODO", "implement later", "fill in the details"
- "Add appropriate error handling", "add validation", "handle edge cases"
- "Write tests for the above", with no test code
- "Similar to task 3" — repeat the code; tasks get read out of order
- A step that says what to do without showing how
- A reference to a type or function no task defines

## 7. Check it yourself before handing it over

Not a subagent dispatch — read it yourself, against the source, with fresh eyes:

1. **Coverage.** Walk each requirement in the source. Can you point at the task that
   implements it? List any gaps and add the tasks.
2. **Placeholders.** Search for the patterns above. Fix them.
3. **Consistency.** Do the names, signatures, and types in later tasks match what earlier
   tasks defined? A function called `clearLayers()` in task 3 and `clearAllLayers()` in task 7
   is a bug you are shipping to your own executor.

Fix what you find inline. No need to re-review.

## 8. Hand over

Report where the plan is, how many tasks, and what the first one is. Then ask whether to
start executing with the `execute-plan` skill, or whether they want to read it first.

The execution rules travel inside the plan, under **Executing this plan**. Whoever picks the
file up in a later session reads them there, with this skill nowhere in context.
