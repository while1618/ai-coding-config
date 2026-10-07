---
name: scaffold-project
description: Set up a new repository so verification works before the first feature — stack, generator, formatter, linter, type checker, tests, CI, and the gate's commands. Use when starting a new app or service, when a repository has no code yet, or when the verification gate finds no commands to run.
---

# Scaffold the project

The first commit of a new project sets up the checks, not the features. In an empty repository
the verification gate finds no commands, so it passes without checking anything. Every feature
built before the checks exist is unverified.

## 1. Settle the stack

Take the stack from the spec's **Constraints** and from any ADR. Where it is not chosen yet,
propose one or two options. For each option, give the reason and the cost. The person picks.

Prefer a stack the team already runs in production. Record the choice with `write-adr` when it is
costly to reverse.

## 2. Generate the skeleton

Use the framework's official generator: for example `npm create vite@latest`, `dotnet new`,
Spring Initializr, `cargo new`, or `uv init`. Write boilerplate by hand only where no generator
exists.

- Ask the package manager or the registry for the current stable version. Do not take a version
  number from memory.
- Commit the lockfile.
- Keep the generator's `.gitignore`. Add `.env` to it.

## 3. Add the checks

Add each check as one command that a person and the gate can run:

| Check | Requirement |
|---|---|
| Format | The project's standard formatter, with a check mode |
| Lint | The ecosystem's standard linter, with the recommended rule set |
| Type check | Strict mode, where the language has it |
| Test | A test runner and **one real test**. The test starts the app's entry point and checks one observable result |

Expose the commands where the ecosystem expects them: `package.json` scripts, a `Makefile`,
`pyproject.toml`, or the build tool's tasks.

Run each command and read the output. The step is complete when the test passes, and when a
deliberately broken line makes the lint or the test fail.

## 4. Confirm the gate sees the commands

Run `install/doctor.sh --project .` from this config. Its output lists what the gate will run.
When a command is missing or wrong, name it in `.agentconfig.json` at the project root:

```json
{
  "test": "npm test",
  "lint": "npm run lint",
  "typecheck": "npm run typecheck",
  "format": "npm run format:check"
}
```

A value of `""` means the project has no such command.

## 5. Add CI

Add a pipeline that runs the same commands on every push and every pull request. Use the CI
system and the pipeline template that the organisation already uses. Look for an
existing template before you write one.

## 6. Add the project files

- `.env.example` with every variable name and a placeholder value. No real value goes in the repo.
- A short README with the commands to install, run, and test.
- An `AGENTS.md`, written with the `agents-md` skill. Keep its **Specs and plans** section, with
  the spec's real file name. That section is how the next session finds the spec, the decisions,
  and the ledgers.

## When it is complete

A fresh clone reaches a passing test with the documented commands. Report each command you ran
and its result. The doctor output lists the commands. CI passes, or the person said CI is out of
scope.

Feature code is not part of this skill. It starts with `plan-work`.

## Common mistakes

| Mistake | What to do instead |
|---|---|
| A versions list from memory | Ask the package manager for the current stable version |
| A placeholder test like `expect(true)` | A test that starts the real entry point |
| Lint added "later" | Lint before the first feature. Later code fails it in bulk, and then the rules get disabled |
| A secret in the example env file | Placeholder values only |
| Features in the scaffold commit | Checks only. Features go through the plan |
