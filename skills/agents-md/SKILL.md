---
name: agents-md
description: Write or refresh a project's AGENTS.md — how to run, test, and lint it, where things live, and the conventions the code does not state. Use when a project has no AGENTS.md or CLAUDE.md, when its one is stale or wrong, or when the user asks to document the project for AI tools.
---

# Write the project's AGENTS.md

`AGENTS.md` is the project's instructions file for coding agents. Claude Code reads it directly
when the repository has no `CLAUDE.md`, on v2.1.277 or later. When a `CLAUDE.md` exists, Claude
Code reads only that file, so the `CLAUDE.md` must import `AGENTS.md` with `@AGENTS.md`. It is the
highest-leverage document in the repo and the easiest to fill with noise.

## The one principle: cache what cannot be looked up

The **environment is a source of truth**. `package.json` scripts, the `Makefile`, the CI
config, `--help` output, and the directory layout all state facts already. A document that
restates them is a cache of a lookup — and it earns its place only when the lookup is
expensive.

So:

**Write down** the unwritten convention, the reason behind a choice, the gotcha no config
confesses, the command that is not where you would expect it, the step everyone forgets.

**Leave out** anything an agent finds by reading one file. Do not list the dependency tree.
Do not paste the script block. Do not describe the framework's own conventions.

A restated `package.json` goes stale in a week and teaches nothing. A line saying "the
integration tests need `docker compose up db` first, and fail with a connection error that
does not mention Docker" saves an hour, every time.

## Before you write: find out

Do not guess, and do not write what a project of this kind usually looks like.

```bash
ls -a                                    # what config exists
cat package.json Makefile pyproject.toml Cargo.toml go.mod 2>/dev/null
ls .github/workflows/ && cat .github/workflows/*.yml   # CI is the truth about what must pass
cat README.md CONTRIBUTING.md 2>/dev/null
git log --oneline -30                    # what changes, and how commits are written
ls src/ app/ lib/ packages/ 2>/dev/null  # the actual layout
```

Then **run the commands**. A build command you did not run is a guess. Where you cannot run
one, say so in the file rather than asserting it works.

The CI workflow is the most reliable source for what must pass, because it is the definition
of "green" the team actually enforces.

Where the codebase is large or unfamiliar, use the `explain-project` skill first to build the
map, then write from it.

## The structure

Adapt it. Drop any section where you have nothing real to say — an empty section is worse
than a missing one.

````markdown
# AGENTS.md

<One or two sentences: what this project is and who uses it. Not marketing.>

## Setup

<Only the steps that are not obvious. The version manager, the required service, the
env file to copy, the credential to obtain and from where.>

```bash
<exact commands>
```

## Commands

| Task | Command | Notes |
|---|---|---|
| Run | `...` | <the port, the required service> |
| Test | `...` | <how long, what it needs running> |
| One test | `...` | <the pattern syntax, if unusual> |
| Lint | `...` | <whether it fixes or only reports> |
| Types | `...` | |
| Build | `...` | |

<Include a command only when the invocation is not what a reader would guess, or when it
carries a condition. A bare `npm test` with nothing to say about it belongs in
package.json alone.>

## Layout

<Where things are, and why — one line each. Only the parts a reader would not infer.>

- `src/queue/` — everything about upload retries. Start here for upload bugs.
- `src/legacy/` — v1 API, still serving two customers. Do not extend it.
- `packages/shared/` — imported by both apps. A change here needs both test suites.

## Conventions

<Only what the code does not enforce and a linter does not catch.>

- <e.g. Errors cross the API boundary as a `Problem` type, never as a raw exception.>
- <e.g. Every migration needs a matching down migration, even trivially.>
- <e.g. Tests use the real database via testcontainers. Do not add a repository mock.>

## Specs and plans

<Keep this section whenever `docs/specs/` exists. It is how a new session finds the work.
Fill in the real file names.>

- Product spec: `docs/specs/<file>` — the source of truth for every feature. Read it before
  planning or reviewing.
- Decisions: `docs/adr/` — read before proposing a technology or a structural change.
- Plans: `docs/plans/` — one per journey. Before continuing work, read the newest
  `*.ledger.md` there and resume from it.
- Next feature: the first journey in the spec's ranking with no plan under `docs/plans/`.

## Gotchas

<The things that waste an afternoon.>

- <e.g. The integration suite needs `docker compose up db` first. Without it the failure is
  a connection timeout that does not mention Docker.>
- <e.g. `npm run build` writes into `dist/` which is gitignored, but the tests import from
  `dist/`, so a stale build makes tests fail confusingly.>

## Before you finish

<The project's own definition of done, matching CI.>

- <e.g. `make check` passes — CI runs exactly this.>
- <e.g. A schema change needs a migration and a note in `docs/schema.md`.>
````

## Writing rules

- **Short and specific.** A vague line costs context on every turn and changes no behaviour.
- **Say the exact invocation**, not a description of it. `pytest -k upload -x` beats "run the
  upload tests".
- **Front-load each line** with the word that makes it findable.
- **State the positive.** "Use the `Problem` type at the API boundary" works better than
  "never throw raw exceptions" — a prohibition brings the forbidden behaviour into mind.
- **One fact per line.** A paragraph mixing three facts gets half-read.
- **No no-ops.** Delete any line stating something an agent already does by default. "Write
  clean code" and "follow best practices" change nothing.
- **Write it under `style/communication.md`.**

## Length

Aim for what fits on two screens. Past that, push detail into a linked file and leave a
pointer that names the condition for reading it:

> Database migrations: `docs/migrations.md` — read before changing any schema.

The pointer's wording decides whether it gets read, so make the condition explicit.

## Prune what is there

When the file already exists, most of the work is removal:

- Delete lines that restate config the agent can read.
- Delete lines that have gone stale. Check each claim against the repo.
- Delete no-ops.
- Fix commands that no longer work — run them.

Report what you removed and why, so the user can push back.

## Finish

1. Re-read the file against the repository. Point at the source of every claim.
2. Run every command you documented.
3. Tell the user what you could not verify, and what you removed.
