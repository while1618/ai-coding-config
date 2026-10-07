# Smell baseline

The fixed set of code smells the Standards axis carries, from Fowler's *Refactoring*,
chapter 3. It applies even when a repository documents no standards of its own.

Two rules bind every entry:

- **The repository overrides.** A documented repo standard always wins. Where it endorses
  something this baseline would flag, suppress the smell.
- **Always a judgement call.** Each entry is a labelled heuristic ("possible Feature
  Envy"), never a hard violation. Name it, quote the hunk, and let the author decide.

Skip anything a linter or formatter already enforces.

Each entry reads *what it is* → *how to fix*. Match against the diff, not the whole
codebase — a smell that predates the change is not this review's business.

- **Mysterious Name** — a function, variable, or type whose name does not reveal what it
  does or holds. → Rename it. If no honest name comes, the design is murky.
- **Duplicated Code** — the same logic shape appears in more than one hunk or file in the
  change. → Extract the shared shape, call it from both.
- **Long Function** — a function you cannot hold in your head, doing several things in
  sequence. → Extract each step, named for what it does.
- **Long Parameter List** — enough parameters that call sites are hard to read and easy to
  get wrong. → Bundle what travels together into one type, or pass the object that owns the
  data.
- **Feature Envy** — a method that reaches into another object's data more than its own. →
  Move the method onto the data it envies.
- **Data Clumps** — the same few fields or parameters keep travelling together, a type
  wanting to be born. → Bundle them into one type and pass that.
- **Primitive Obsession** — a string or number standing in for a domain concept that
  deserves its own type. → Give the concept its own small type.
- **Repeated Switches** — the same `switch` or `if`-cascade on the same type recurs across
  the change. → Replace with polymorphism, or one map both sites share.
- **Shotgun Surgery** — one logical change forces scattered edits across many files in the
  diff. → Gather what changes together into one module.
- **Divergent Change** — one file or module is edited for several unrelated reasons. →
  Split so each module changes for one reason.
- **Speculative Generality** — abstraction, parameters, or hooks added for needs the spec
  does not have. → Delete it. Inline it back until a real need shows.
- **Message Chains** — long `a.b().c().d()` navigation the caller should not depend on. →
  Hide the walk behind one method on the first object.
- **Middle Man** — a class or function that mostly just delegates onward. → Cut it, call the
  real target directly.
- **Refused Bequest** — a subclass or implementer that ignores or overrides most of what it
  inherits. → Drop the inheritance, use composition.
- **Comments as Deodorant** — a comment explaining what confusing code does. → Rename or
  extract until the code says it, then keep the comment only for the *why*.
- **Mutable Data** — a value updated in place where several call sites can observe it. →
  Return a new value, or narrow who can write it.
