---
name: author-skill
description: Add or edit a skill, rule, or hook in this config, and keep it consistent. Use when the user wants a new skill or rule, wants to change an existing one, or asks how this config is structured.
when_to_use: >-
  "add a skill", "add a rule", "add a hook", "change this config", "how is this config
  structured", editing anything under skills/ rules/ hooks/
---

# Author a skill, rule, or hook

This config works because everything in it follows the same shape. This skill keeps that true as
the team adds to it.

## What goes where

| You want to | Put it in | Because |
|---|---|---|
| A workflow with steps, for a recurring task | `skills/<name>/SKILL.md` | Loads on demand, when its trigger fits |
| A standing rule about how code is written | `rules/NN-<topic>.md` | Applies to a class of files, not a task |
| Something enforced automatically | `hooks/` and `hooks/hooks.json` | The harness runs it, not the model |
| A reusable review or writing persona | `agents/<name>.md` | Runs in its own context, returns findings |
| Something that must be in every session | `AGENTS.md` | Always loaded, so it costs on every turn |
| How output should read | `style/communication.md` | The Claude output style is generated from it |

A form — a PR body, an ADR, a commit message — lives inside the skill that fills it in, not in a
separate templates directory. A form nothing points at is a copy that drifts.

Two questions settle most cases:

- **Would the model reach for this on its own, mid-task?** Yes → a skill. No → probably a rule.
- **Does it have to happen whether or not the model remembers?** Yes → a hook. Nothing else can
  guarantee it, because the model can rationalise past any instruction.

## Two budgets, and every addition spends one

- **Context load** — the cost of always-loaded material: an `AGENTS.md` line, a skill's
  `description`. It spends tokens and attention on every turn, whether or not it fires.
- **Cognitive load** — the cost on the person: knowing which documents exist and when to reach for
  each. This is not a cost to minimise. It is the price of human agency. Spend it where judgement
  matters; remove it where it does not.

Material behind a pointer escapes context load at the price of the pointer's own line. Material
with no pointer at all rides entirely on cognitive load.

## Writing a skill

```markdown
---
name: <kebab-case, matching the directory name>
description: <what it does, then the triggers that should fire it>
---

# <Title>

<One or two sentences: what this is for, and the principle behind it.>

## <Steps, in order>

## <Reference the steps need>

## <Common mistakes, as a table>
```

### The description is the whole invocation mechanism

It is the only part loaded before the skill fires, so it decides whether the skill is ever
reached. Write it as: what the skill does, then the distinct cases that should trigger it.

```
description: Find and fix the root cause of a bug, test failure, crash, wrong output, or
performance regression. Use when anything is broken, failing, throwing, hanging, flaky, or
slow — before proposing any fix.
```

- **Front-load the leading word.** The first few words do the triggering.
- **One trigger per case.** Synonyms naming the same case are one case written twice. Keep only
  genuinely distinct branches.
- **Cut identity the body already carries.** The description is not a summary.

A must-have skill behind a weakly worded description is a variance bug: sometimes it fires,
sometimes it does not. Sharpen the wording before you consider inlining the content somewhere
always-loaded.

### Put material at the right depth

Three tiers, ranked by how immediately the reader needs them:

1. **In-file steps** — what to do, in order. The primary tier.
2. **In-file reference** — consulted as needed. Often a legitimately flat set of peers, such as
   every rule of a review on one level. That is fine, not a smell.
3. **Disclosed reference** — a separate file under `references/`, reached by a pointer, loaded
   only when the pointer fires.

The test for pushing something down: **inline what every path needs, disclose what only some paths
reach.** Where a skill has steps, in-file reference that should have been disclosed buries them,
and attending to the steps becomes a coin flip.

Keep a concept's definition, rules, and caveats under one heading rather than scattered, so
reading one part brings its neighbours along.

### Write for behaviour, not for the reader's approval

- **State the positive target.** A prohibition brings the forbidden behaviour into mind and makes
  it *more* available: say "write one-line comments above the code", not "do not write trailing
  comments". Keep a prohibition only as a hard guardrail you cannot phrase positively, and pair it
  with the positive target.
- **Make every step's completion criterion checkable.** "Understanding reached" invites stopping
  early. "You can name one command you have already run, and its output" does not.
- **Use a word that already carries weight.** A concept the model already holds — a *tight* loop,
  a loop that goes *red*, a *seam*, *fog of war* — anchors a whole region of behaviour in one
  token. Repeat the word, never the definition. Inventing your own recruits nothing, so you pay in
  definition tokens what an existing word gives free.
- **Delete every no-op.** An instruction the model already follows by default costs load and
  changes nothing. The test is behavioural, not aesthetic: does the sentence change the outcome
  versus leaving it out? Settle a disagreement by running the skill, not by arguing. When a
  sentence fails the test, delete the sentence rather than trimming its words.
- **Keep one source of truth per meaning.** The same instruction in two files means changing
  behaviour is a two-place edit, and one of them will be missed.
- **The environment is a source of truth.** `package.json`, the CI config, `--help` output. A
  document restating them is a cache of a lookup, and it earns its place only when the lookup is
  expensive. Cache what cannot be looked up: the unwritten convention, the reason behind a choice,
  the gotcha no config confesses.

### Length

Sprawl is the failure mode: a document too long even when every line is live. Attention thins
across the excess. Where a skill is growing past what you can hold, split it — by sequence, or by
pushing reference behind a pointer — so each path carries only what it needs.

## Writing a rule

```markdown
---
description: <one line saying what the rule covers>
paths:                     # omit only for a rule that must load on every turn
  - "**/*.{ts,tsx}"
---
```

- **`paths`** decides when Claude Code loads the rule: when a file matching one of the globs is
  read. Use a narrow glob for a language or a file class.
- **A rule with no `paths`** loads at launch and costs context on every turn. Reserve that for
  what genuinely always applies. Only `00-core-engineering.md` does it today.
- Number the file so ordering is explicit. Leave gaps.
- Nothing to add in `AGENTS.md`: the harness loads rule files on its own.

## Writing a hook

A hook is code, and it runs on every matching event, so the bar is higher than for prose.

- Read the hook JSON on stdin. Use `hooks/lib/json.sh` — it picks a backend from jq, python3, or
  node, so there is no hard dependency.
- **Exit 0 and say nothing** on the common path. A hook that prints on every call becomes noise
  and then gets disabled.
- **Fail open.** Where the hook cannot determine an answer, allow the action. A false block is
  worse than a missed one, because it teaches the team to bypass the hook.
- **Never block on something the model cannot fix.** Where that is possible, add a release valve —
  `verify-gate.sh` releases after three attempts on an unchanged tree for exactly this reason.
- **Test it by running it**, with fixture JSON on stdin, asserting on stdout. Never by grepping
  its source.
- Add it to `hooks/hooks.json` with the right event and matcher, and give it a timeout.

## Before you finish

- [ ] The `name` matches the directory name.
- [ ] The `description` carries real triggers, front-loaded.
- [ ] It is listed in `README.md`.
- [ ] It does not duplicate a meaning that already lives in `rules/`.
- [ ] Every claim about the harness is verified against the tool's documentation, not remembered.
- [ ] Prose follows `style/communication.md`. Run the `plain-language` skill over it.
- [ ] For a rule: `paths` is set deliberately.
- [ ] For a hook: exercised with fixture input, both the acting and the passing path.
- [ ] `install/doctor.sh` still reports no problems, and the generated files are regenerated.

## Then regenerate

The output style, the `AGENTS.md` and `CLAUDE.md` blocks in a project, and the copied project rules are generated from these sources. After any
change:

```bash
install/install.sh --project <a-project>   # regenerate the generated files
install/doctor.sh --project <a-project>    # confirm no drift
```
