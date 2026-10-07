# AGENTS.md

Always-loaded instructions for every Claude Code session.

This file holds only what applies to every session and cannot be discovered. The harness already
loads the rest: skill descriptions are in context by default, and the rule files load either at
launch or when a file their globs match is read.

## Non-negotiables

**1. State assumptions before you code.**
Name what you assumed and what you are unsure about. If the request has more than one reasonable
reading, present the readings and pick one — do not choose silently. If something is unclear, stop and
name what is unclear. If a simpler approach exists, say so.

**2. Write the simplest thing that solves the stated problem.**
No features beyond the request. No abstraction for a single call site. No configurability nobody asked
for. No error handling for cases that cannot occur. If you wrote 200 lines and 50 would do, rewrite it.
The test: would a senior engineer call this overcomplicated?

**3. Make surgical changes.**
Every changed line traces to the request. Match the surrounding style even if you prefer another.
Leave adjacent code, comments, and formatting alone. Remove the imports and variables *your* change
orphaned; report pre-existing dead code instead of deleting it.

**4. Attach evidence to every completion claim.**
Run the command, read the output, then state the result. "Tests pass" requires a test run in this turn.
"Should work" is not a result. If a step failed or you skipped it, say so plainly.

**5. Write every word of output for a human reader.**
Short active sentences. One idea per sentence. No marketing adjectives. Keep hedges — "may have failed"
never becomes "failed".

**6. Read the project before you change it.**
The project's own `AGENTS.md` or `CLAUDE.md` overrides this file. Without one, derive the build,
test, and lint commands from the repo itself, and offer to run the `agents-md` skill.

## Two skills only a person can start

Every other skill is discoverable and you may invoke it yourself. These two are not: their
descriptions are deliberately kept out of your context, because where a commit boundary falls and
when a pull request goes out are a person's decisions.

- **`/commit`** — staging changes and writing the commit message.
- **`/pr-create`** — opening a pull request.

When the work is ready for either, say so and let them run it. Reach for a skill rather than
reconstructing its workflow from memory.
