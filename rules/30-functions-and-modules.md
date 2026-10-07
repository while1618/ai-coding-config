---
description: When to extract a function, where to split a module, and where a seam belongs.
paths:
  - "**/*.{ts,tsx,js,jsx,mjs,cjs}"
  - "**/*.py"
  - "**/*.go"
  - "**/*.rs"
  - "**/*.{java,kt,kts,scala}"
  - "**/*.{cs,fs}"
  - "**/*.rb"
  - "**/*.php"
  - "**/*.{ex,exs}"
  - "**/*.swift"
  - "**/*.{c,cc,cpp,h,hpp,m,mm}"
  - "**/*.{sh,bash}"
  - "**/*.sql"
  - "**/*.{vue,svelte}"
---

# Functions and modules

## Vocabulary

Use these words exactly. The `design-module` skill holds the full glossary; these four carry the rules
below.

- **Module** — anything with an interface and an implementation: a function, class, package, or slice
  that spans tiers.
- **Interface** — everything a caller must know to use it correctly. Not only the signature: also the
  invariants, ordering constraints, error modes, required config, and performance behaviour.
- **Depth** — how much behaviour sits behind how small an interface. A module is **deep** when a caller
  learns a little and gets a lot. It is **shallow** when the interface is nearly as complex as the body.
- **Seam** — the place where the interface lives, and where behaviour can be swapped without editing
  in that place. Where the seam goes is a separate decision from what sits behind it.

## When to create a function

Extract when one of these is true:

- **The logic repeats.** Two call sites of the same shape earn one function. One does not.
- **The block needs a name to be read.** If a comment above five lines explains what they compute, that
  comment is a function name.
- **The nesting exceeds two levels.** Pull the inner body out and give it a name.
- **A unit of behaviour needs a test.** A seam you want to assert on is a function.
- **Two responsibilities share a body.** Split where the sentence describing it needs "and".

Do **not** extract when:

- It has a single call site and the name adds nothing (`getUserName` wrapping `user.name`).
- It exists to shorten a file. Length is not the problem; mixed responsibility is.
- The parameter list would carry more than the body saves. Six parameters to avoid four lines is a loss.
- It is speculative reuse. A second caller is real; an imagined one is not.

## Function shape

- **One job.** The name says it without "and".
- **Few parameters.** Past three or four, the parameters that travel together want to be one type.
- **No boolean mode flags.** `render(true)` tells the reader nothing. Two functions, or a named option.
- **Return a value rather than mutate an argument.** A function that returns is testable at its
  interface; one that mutates makes the caller the test surface.
- **Accept dependencies, do not construct them.** `processOrder(order, gateway)` can be tested.
  `processOrder(order)` that news up a gateway inside cannot.
- **Same level of abstraction throughout.** A function that both parses bytes and sends email is two
  functions.
- **Pure where you can.** Push input/output to the edges and keep the decisions in the middle.

## Module shape

Aim for depth: a small interface over a lot of behaviour.

When you design an interface, ask:

- Can I remove a method?
- Can I simplify a parameter?
- Can I hide more inside?

Three tests:

- **The deletion test.** Imagine the module gone. If complexity disappears, it was a pass-through and
  should not exist. If complexity reappears in every caller, it earns its keep.
- **The interface is the test surface.** Callers and tests cross the same seam. If a test must reach
  past the interface, the module is the wrong shape.
- **One adapter is a hypothetical seam. Two adapters is a real one.** Introduce a seam when something
  actually varies across it, not before.

## Splitting a file

Split when the file changes for more than one reason, or when you can name two groups that never read
each other's code. Do not split by technical layer for its own sake — that scatters what changes
together across directories.

In an existing codebase, follow the established size. Where the file you are editing has grown
unwieldy, proposing a split is reasonable. Restructuring the codebase because you prefer smaller files
is not.
