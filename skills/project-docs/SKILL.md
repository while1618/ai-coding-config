---
name: project-docs
description: Write or refresh a README and the docs set, verified against the code. Use when the user asks for a README, for docs, to document the project, or when existing docs have gone stale.
---

# Write the project docs

Documentation is read by someone who is stuck. Its value is entirely in being **correct** —
a wrong command or a stale signature costs the reader more than the missing section would
have.

So the rule that governs everything here: **every fact comes from the code, confirmed.**

## 1. Decide what is needed

Ask, or infer from the repo, then say what you plan to write before writing it.

| Document | Write it when |
|---|---|
| `README.md` | Always. What this is, how to run it, how to contribute. |
| `docs/architecture.md` | The shape is not obvious from the directory layout. |
| `docs/api.md` | It exposes an API and no generated reference exists. |
| `docs/configuration.md` | There are more than a handful of settings or env vars. |
| `docs/development.md` | Setup is more than install-and-run. |
| `docs/deployment.md` | Deploying involves steps a newcomer cannot guess. |
| `docs/troubleshooting.md` | The same failures recur. Mine the issue tracker for them. |
| `CONTRIBUTING.md` | The project takes outside contributions. |
| `docs/adr/` | Decisions are being made and lost. Use the `write-adr` skill. |

Do not write a document you have nothing real to put in.

## 2. Check what exists first

Read the current docs before replacing anything. Hand-written prose usually contains
knowledge that exists nowhere else — the reason behind a design, a warning from a real
incident. Preserve it. Regenerating over it loses it silently.

Where a section is wrong rather than missing, fix that section rather than rewriting the file.

## 3. Write each document from the code

For a single document, write it yourself. For several, dispatch a **`doc-writer`** subagent
per document, each with its own outline. Each one explores the code it documents, which is
what keeps paths and signatures real, and keeps the exploration out of your context.

Whoever writes it follows the same rule:

- A path → confirm it exists.
- A command → read it from `package.json`, the `Makefile`, or the CI config. Run it where you
  safely can.
- A signature or endpoint → read the definition.
- A config key → find where the code reads it.
- A version or requirement → read it from the manifest or the CI matrix.

Where you cannot confirm something, write `TODO: unverified — <what you could not confirm>`
and carry on. Never write a plausible example.

## 4. The README

Order it by what a reader needs first:

````markdown
# <name>

<One or two sentences: what it does and who it is for. No adjectives claiming quality.>

## Install

```bash
<exact commands, including prerequisites and their versions>
```

## Use

<The smallest complete example that does something real. Runnable, copy-pasteable, with
its output shown.>

## Configuration

<Only the settings a reader will need. Name, what it does, default, and whether it is
required. A table works.>

## Development

```bash
<run, test, lint — the exact commands>
```

## How it works

<Only when the shape is not obvious. A few paragraphs, or a link to
docs/architecture.md.>
````

Lead with a runnable example over a description of one. A reader copies the example and
learns from what happens.

## 5. Verify, then report

Re-read each document against the code. For every claim, point at the source.

Run every command you documented. A README whose install command fails is worse than no
README, because it costs the reader trust in everything else on the page.

Then report: what you wrote, what you preserved from the previous version, what you removed
and why, and every `TODO: unverified` you left with what blocked it.

## Verify-only mode

When the user wants a check rather than a rewrite, read the existing docs and report:

- Commands that no longer run.
- Paths that no longer exist.
- Signatures that have changed.
- Config keys the code no longer reads.
- Sections describing removed features.

Report the list. Change nothing until they choose.

## Writing rules

Write everything under `style/communication.md`. Short active sentences. One topic per
paragraph. No marketing adjectives — nothing is powerful, seamless, or blazing-fast. Where
you want to claim performance, give the measurement instead.
