---
name: explain-project
description: Explain what a codebase is and how it fits together, for a person reading it cold. Use when the user asks what this project is, how it works, to walk them through the codebase, or where to start.
when_to_use: >-
  "what is this project", "how does this work", "walk me through the codebase", "where do I
  start", "give me an overview", first look at an unfamiliar repo
---

# Explain the project

Build the map yourself from the code, then hand over the version a person can hold in their
head. Not a directory listing — the reader can run `ls`.

## 1. Read the ground truth

```bash
cat README.md AGENTS.md CLAUDE.md 2>/dev/null
cat package.json Cargo.toml go.mod pyproject.toml pom.xml 2>/dev/null
ls .github/workflows/ && cat .github/workflows/*.yml 2>/dev/null
ls -a && ls src/ app/ lib/ packages/ cmd/ 2>/dev/null
git log --oneline -40
git log --format='' --name-only -200 | sort | uniq -c | sort -rn | head -25
```

That last command is worth the tokens: the files that change most often are where the work
actually happens, which is rarely where the directory names suggest.

Then find the entry points — `main`, the server bootstrap, the CLI definition, the exported
index — and read outward from them. A codebase read from its entry points makes sense. Read
alphabetically it does not.

## 2. Answer these seven questions

Cover them in the explanation, in roughly this order, and skip any the project genuinely does
not have.

1. **What it is, and for whom.** One or two sentences. The problem it solves, not the
   technologies it uses.
2. **The stack.** Language and version, framework, database, and the two or three libraries
   that shape how the code is written.
3. **The shape.** How the parts relate. A request or a job entering the system — what does it
   pass through, in order? This is the section a reader most needs and most rarely gets.
4. **Where things live.** The four to eight directories that matter, one line each, and what
   takes you there. Not every directory.
5. **What it talks to.** Databases, queues, third-party APIs, other services owned by the
   team. Where the credentials come from.
6. **How it is built and verified.** The run, test, and lint commands, and what CI enforces.
7. **What to be careful about.** The parts under active change, the parts nobody understands,
   the legacy corner, the module every change touches. Say when this is your read rather than
   something documented.

## 3. Trace one path end to end

Pick the most representative operation — the main request, the primary job, the core command —
and follow it through the code, naming each file and function. One concrete trace teaches more
than three paragraphs of description, because it gives the reader a thread to pull.

```
POST /uploads
  → routes/upload.ts:34        validates the body against UploadRequest
  → queue/enqueue.ts:12        writes the job row, returns the id
  → worker/upload.ts:88        picks it up, signs the URL (this is where the 504 lived)
  → storage/s3.ts:45           streams to the bucket
```

## 4. Say where to start

Close with the answer to "where do I start?" — the two or three files to read first, in order,
and why each one.

## Rules

- **Every claim comes from the code.** Point at the file. Where you are inferring rather than
  reading, say so: "this looks like X, though nothing states it".
- **Say what you did not read.** A large codebase does not fit one session. Naming the gap is
  more useful than a confident summary of the part you skipped.
- **Match the reader's level.** Ask if you cannot tell. A new hire and a staff engineer joining
  the team need different explanations.
- **Write it under `style/communication.md`.** Short active sentences, one topic per
  paragraph, the project's own vocabulary rather than yours.
- **No adjectives claiming quality.** The codebase is not elegant or robust. Say what it does.

## Related

- `onboard-project` — same map, plus getting it running and green.
- `agents-md` — turn the map into the file agents load.
- `explain-topic` — go deeper on one part of it.
