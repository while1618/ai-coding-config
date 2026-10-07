# Contributing

This config works because everything in it follows the same shape. Keeping that true is most of
the work.

The model-facing version of this guidance is the `author-skill` skill. Invoke it when an agent is
making the change; read this when you are.

## Where a change goes

| You want to | Put it in |
|---|---|
| A workflow with steps, for a recurring task | `skills/<name>/SKILL.md` |
| A standing rule about how code is written | `rules/NN-<topic>.md` |
| Something enforced whether or not the model cooperates | `hooks/` plus `hooks/hooks.json` |
| A reusable review or writing persona | `agents/<name>.md` |
| Something needed in every session | `AGENTS.md` — think hard first, it costs every turn |
| How output should read | `style/communication.md` — the output style is generated from it |

A form — a PR body, an ADR, a commit message — lives inside the skill that fills it in. A separate
templates directory was tried and removed: nothing pointed at it, so it was four copies of content
the skills already carried.

Two questions settle most cases:

- **Would the model reach for this on its own, mid-task?** Yes → a skill. No → a rule.
- **Must it happen whether or not the model remembers?** Yes → a hook. Nothing else guarantees
  it, because the model can rationalise past any instruction.

## The rules the config applies to itself

- **One source of truth per meaning.** The same instruction in two files means changing behaviour
  is a two-place edit, and one will be missed. There are no exceptions left: the writing rules were
  the last one, and `style/communication.md` is now the single authored copy that the Claude
  output style is generated from.

- **No no-ops.** An instruction the model already follows by default costs context and changes
  nothing. The test is behavioural: does the sentence change the outcome? Settle a disagreement by
  running it, not by arguing.
- **State the positive target.** A prohibition brings the forbidden behaviour into mind and makes
  it more available. Say "write one-line comments above the code", not "do not write trailing
  comments".
- **The environment is a source of truth.** Do not restate `package.json`, the CI config, or
  `--help` output. Document the unwritten convention, the reason behind a choice, and the gotcha
  no config confesses.
- **Keep bash 3.2 compatible.** macOS ships bash 3.2 as `/bin/bash`, so `declare -A`,
  `mapfile`, and `readarray` are out. A test fails the build if one appears. The same test
  catches GNU-only flags such as `sed -i` and `readlink -f`, which break on the BSD userland.
- **Verify claims about a harness.** Every path, event name, and frontmatter field here was
  checked against the tool's own documentation. Do not add one from memory.
- **Write prose under `style/communication.md`.** Run the `plain-language` skill over anything
  you add.

## Adding a skill

```
skills/<name>/
├── SKILL.md              # required
└── references/           # optional, for material only some paths need
```

Frontmatter:

```yaml
---
name: <kebab-case, matching the directory name>
description: <what it does, then the distinct cases that should trigger it>
---
```

A skill with side effects whose timing is a person's call gets
`disable-model-invocation: true`, and its `description` becomes short menu text rather than a
trigger list. `/commit` and `/pr-create` are the two, and a test fails if a third appears without
that decision being made deliberately. Where a skill's triggers are thin, add `when_to_use` with
the phrases you actually type.

The `description` is the entire invocation mechanism — it is the only part loaded before the skill
fires. Front-load the leading word, give one trigger per genuinely distinct case, and cut anything
the body already says. A skill behind a vague description fires sometimes and not other times,
which is worse than one that never fires.

Then add it to the list in `README.md`. Do not add it to `AGENTS.md`: skill descriptions are
already in context, so a table there is a second copy that drifts. The two exceptions are the
skills a person must start, which `AGENTS.md` names because their descriptions are withheld.

## Adding a rule

```yaml
---
description: <one line saying what the rule covers>
paths:
  - "**/*.py"
  - "**/*.{ts,tsx}"
---
```

- **`paths` is the single source of truth for when the rule loads.** Claude Code reads it
  directly from `.claude/rules/` and `~/.claude/rules/`, and it accepts brace groups such as
  `{ts,tsx}`.
- **A rule with no `paths` loads on every turn.** Only `00-core-engineering.md` has none, and a
  test fails if another rule leaves `paths` out. A second always-loaded rule needs a reason, and
  the test needs updating to name it.
- **Prefer real globs over `**`.** A universal glob makes the split pointless: it loads always
  while looking deferred. `70-git-and-review.md` is the deliberate exception, because review and
  commits touch any file.
- Number the file with gaps. Nothing needs adding to `AGENTS.md`: an unscoped rule loads at launch
  and a scoped one loads when a matching file is read, so a pointer would only duplicate that.

## Adding a hook

A hook is code that runs on every matching event, so the bar is higher than for prose.

- Read hook JSON on stdin. Use `hooks/lib/json.sh`, which selects a backend from jq, python3, or
  node, so there is no hard dependency.
- **Exit 0 and print nothing** on the common path. A hook that speaks every time becomes noise and
  then gets disabled.
- **Fail open.** Where the hook cannot determine an answer, allow the action. A false block
  teaches the team to bypass the hook, and then it protects nothing.
- **Never block on something the model cannot fix.** `verify-gate.sh` releases after three
  attempts on an unchanged tree for exactly this reason.
- Register it in `hooks/hooks.json` with the right event, matcher, and timeout. Use
  `__ACC_ROOT__` for the path — `install.sh` substitutes it.
- Give it a `statusMessage` that starts with `ai-coding-config:`, followed by the script name. The
  settings merge uses that tag to find its own hook groups, so it can replace them on a rerun and
  remove them on uninstall. An untagged hook is copied again on every install, and a test fails.
- Add cases to `tests/run-tests.sh` for both the acting and the passing path.

## Verify before you open a PR

```bash
tests/run-tests.sh                                          # the full suite
install/install.sh --project /tmp/scratch                   # a throwaway repo
install/doctor.sh  --project /tmp/scratch                   # expect no problems
install/uninstall.sh --project /tmp/scratch                 # expect the repo restored
```

The installer never prompts. Every choice is a flag, so the suite and CI can never hang on a
question.

`.agentconfig.json` names `tests/run-tests.sh` as this repo's test command, and that is what makes
this config verify itself. Once you have run `install/install.sh --user`, the `Stop` hook lives in
your `~/.claude/settings.json` and applies to every session — including a session in this repo. So
editing a hook and trying to end the turn runs the whole suite, and a failure blocks it.

This repo deliberately does **not** commit its own `.claude/settings.json`: hook commands need
absolute paths, and a committed settings file would carry one machine's layout. The user-scope
install is what wires it, which is why `.agentconfig.json` has to exist here — without it the
detector finds no manifest in a repo of shell and markdown, and the gate would pass silently.

If you have not installed at user scope, nothing runs the suite for you — use the command block
above before opening a PR.

After a change, rerun the installer where the change does not reach on its own, then confirm
`doctor.sh` reports no drift:

| You changed | Rerun |
|---|---|
| An agent or a skill | Nothing. Both are links in every install. |
| A rule | `install.sh --project` in each project. Project rules are copies. User rules are links. |
| `AGENTS.md` | `install.sh --project` in each project. The project file holds a copied block. The global file is a link. |
| `style/communication.md` | `install.sh` in every install, user scope included. The output style is a generated file. |

## What is deliberately absent

- **No plugin manifest.** Distribution is the install script.
- **No dependency beyond bash, git, and python3.** The hooks need one of jq, python3, or node, and
  fall back across them.
- **No vendored workflow engine, and no persona library.** Wrong scope for a team coding config.
- **No ASD-STE100 dictionary.** Free to obtain, not free to redistribute. See
  `skills/plain-language/references/writing-rules.md`.
