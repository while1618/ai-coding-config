# ai-coding-config

A shared configuration for Claude Code.
It gives the assistant engineering rules, task workflows (skills), review agents, a writing style,
and hooks that enforce the parts that must not depend on the model's memory.

## What it contains

| Directory | Contents |
|---|---|
| `AGENTS.md` | The instructions loaded into every session. |
| `rules/` | Coding rules. Each rule loads at launch or when a file that matches its `paths` is read. |
| `skills/` | Step-by-step workflows for recurring tasks. |
| `agents/` | Subagents that the skills dispatch for review and documentation work. |
| `style/communication.md` | How output reads. The installer generates the Claude output style from this file. |
| `hooks/` | Claude Code hooks: safety guards and the verification gate. |
| `git-hooks/` | `pre-commit` and `pre-push` hooks that run the same verification gate. |
| `install/` | The install, doctor, and uninstall scripts. |
| `tests/` | The test suite for the hooks and the installer. |

## Requirements

- bash (3.2 or later, so the macOS default works)
- git
- python3
- One of jq, python3, or node for the hooks to read JSON

## Install

Clone the repo and keep it in place. A user install links files back to the clone, so a `git pull`
updates it. A project install copies everything, so you can edit the copies and commit them, and
teammates without this config get the same setup. Generated files are never links. After a
`git pull`, run the installer again to refresh the copies and generated files. `doctor.sh` reports
any that are out of date. A rerun overwrites every copy it installed, including copies you edited,
so commit your edits first and review the diff after.

**For your user account:**

```bash
install/install.sh --user
```

This links the skills, rules, agents, and `AGENTS.md` into `~/.claude/`. It adds an `@AGENTS.md`
import to `~/.claude/CLAUDE.md`, and creates that file when it does not exist. It also merges the hooks
into `~/.claude/settings.json` and turns on the **Plain Technical English** output style. Every
session on the machine uses all of it.

**For one project:**

```bash
install/install.sh --project /path/to/repo
```

This copies the same skills, rules, agents, hooks, and output style into `<repo>/.claude/`. The
hooks in `settings.json` run from `$CLAUDE_PROJECT_DIR/.claude/hooks/`, so nothing points back at
the clone. The config's instructions are copied into `<repo>/AGENTS.md`, appended when the file already exists.
`<repo>/CLAUDE.md` gets an `@AGENTS.md` import the same way, because Claude Code reads only
`CLAUDE.md` when both exist. When `CLAUDE.md` already imports `AGENTS.md`, it is left alone.
It also installs the git hooks.

Install at one scope per machine where you can. With both installed, every rule and the
instructions block load twice in that project. The hooks still run once, because Claude Code runs
an identical hook only once.

Options:

| Flag | Effect |
|---|---|
| `--copy` | Copy files instead of linking them (user scope; a project install always copies). |
| `--dry-run` | Print what would change and change nothing. |
| `--no-git-hooks` | Skip the `pre-commit` and `pre-push` hooks (project scope only). |

The installer never overwrites a file it did not create. It reports the file and skips it. Into an
existing `CLAUDE.md` or `AGENTS.md`, it appends a block between `ai-coding-config:begin` and
`ai-coding-config:end` comments, and it changes only that block on later runs. Before it first
changes `settings.json`, it saves a copy to `settings.json.acc-backup`. It records everything it
installs in `acc-manifest.json`, which the uninstaller uses.

### Check and remove an install

```bash
install/doctor.sh --project /path/to/repo      # or --user
install/uninstall.sh --project /path/to/repo   # or --user; add --dry-run to preview
```

`doctor.sh` reports problems and shows which commands the verification gate will run. It also
reports drift: a generated or copied file that no longer matches its source. To fix drift, run
`install.sh` again.

`uninstall.sh` removes only what the installer placed. It removes the marked blocks and keeps the
rest of each file. It restores the settings backup when that is safe.

## Hooks

| Hook | Event | What it does |
|---|---|---|
| `session-start.sh` | SessionStart | Tells Claude which verification commands the gate will run. |
| `guard-dangerous-commands.sh` | PreToolUse (Bash) | Blocks `git push --force`, `git reset --hard`, `git clean -f`, `git branch -D`, and `rm -rf` outside the project. |
| `validate-commit-msg.sh` | PreToolUse (Bash) | Checks `git commit -m` subjects against `type(scope): subject`. |
| `guard-secrets.sh` | PreToolUse (Write, Edit) | Blocks content that contains a provider key or a literal credential. |
| `mark-dirty.sh` | PostToolUse (Write, Edit) | Records which files the turn changed. |
| `verify-gate.sh` | Stop | Runs the project's lint, type check, and tests when the turn changed files. A failure blocks the end of the turn. |

The hooks fail open: when a hook cannot decide, it allows the action. The verification gate stops
blocking after three failed attempts on an unchanged tree.

### The verification gate

The gate detects the project's lint, type check, format, and test commands from its files. When
the detection is wrong, put a `.agentconfig.json` file in the project root to set the commands:

```json
{
  "test": "bash tests/run-tests.sh",
  "timeoutSeconds": 180
}
```

The other command keys are `lint`, `typecheck`, and `format`. An empty string means the project has
no such command. `timeoutSeconds` limits each command. Two keys change what the gate does:

| Key | Effect |
|---|---|
| `gate` | A list of categories, such as `["test", "lint"]`. Only those categories can block. |
| `skip` | `true` turns the gate off for the project. |

To skip the gate and the git hooks for one command, set `AI_CODING_CONFIG_SKIP_VERIFY=1`. The
`pre-push` hook passes file names to the commands only when the repo has 500 tracked files or
fewer. Above that, the commands run on the whole tree. Set `AI_CODING_CONFIG_PUSH_CAP` to change the
limit.

## Skills

The assistant starts most skills when the task matches. A person must start `/commit` and
`/pr-create`, because the timing of a commit or a pull request is a person's decision.

**Ideas and planning**

- `shape-idea` — talk through an idea for an app or feature before anything is built.
- `write-spec` — write a feature specification with testable requirements.
- `threat-model` — find security threats in a design and turn them into requirements.
- `plan-work` — split a large request into small tasks that can each be verified.
- `execute-plan` — carry out a written plan task by task, with a review after each task.
- `write-adr` — record an architecture decision and the reasons for it.
- `design-module` — design an interface, place a seam, or decide how deep a module should be.

**Writing and changing code**

- `scaffold-project` — set up a new repository with a formatter, linter, tests, and CI.
- `write-tests` — write tests first, and make sure each test can fail.
- `fix-bug` — find and fix the root cause of a bug, crash, or failing test.
- `refactor` — change the structure of code without changing its behaviour.
- `upgrade-dependencies` — upgrade dependencies and check the result.
- `resolve-conflicts` — resolve merge or rebase conflicts by understanding both sides.
- `verify-changes` — prove that work is done before claiming it is done.

**Review and git**

- `pr-review` — review a change against the repo's standards and against its spec.
- `pr-respond` — respond to review feedback item by item.
- `audit-security` — check a change for secrets, injection, and authorization problems.
- `commit` — stage changes and write the commit message. Person-started only.
- `pr-create` — open a pull request. Person-started only.

**Understanding and documentation**

- `onboard-project` — get an unfamiliar repository running and mapped.
- `explain-project` — explain what a codebase is and how it fits together.
- `explain-diff` — explain what a diff, commit, or pull request changed.
- `explain-topic` — explain one topic in more depth.
- `agents-md` — write or refresh a project's `AGENTS.md`.
- `project-docs` — write or refresh a README and other docs, checked against the code.
- `handoff` — write a note so the next session can continue the work.
- `plain-language` — rewrite text so it can only be read one way.
- `author-skill` — add or change a skill, rule, or hook in this config.

## Rules

| File | Topic |
|---|---|
| `00-core-engineering.md` | How to reason about every code change. |
| `10-naming-and-style.md` | Naming, structure, and matching an unfamiliar codebase. |
| `20-comments-and-docs.md` | What to comment and what to leave to the code. |
| `30-functions-and-modules.md` | When to extract a function and where to split a module. |
| `40-testing.md` | What a test must prove and the check before claiming done. |
| `50-errors-and-logging.md` | Failure paths, error messages, and log lines. |
| `60-security.md` | Secrets, input handling, authorization, and dependencies. |
| `70-git-and-review.md` | Commits, branches, pull requests, and review. |

## Agents

- `code-reviewer` — reviews a diff against the repo's standards. Used by `pr-review`.
- `spec-checker` — checks a diff against the issue or spec it implements. Used by `pr-review`.
- `doc-writer` — writes one documentation file from the code. Used by `project-docs` and
  `explain-project`.

## Tests

```bash
tests/run-tests.sh
```

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md). It explains where each kind of change goes and how to
verify it before you open a pull request.
