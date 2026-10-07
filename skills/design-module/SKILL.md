---
name: design-module
description: Shared vocabulary and tests for designing an interface, placing a seam, or deciding how deep a module should be. Use when designing or restructuring a module, deciding what to expose, making code more testable, or when another skill needs this vocabulary.
when_to_use: >-
  "how should I structure this", "what should this expose", "where should the boundary go",
  "make this testable", naming a seam, splitting a class, deciding what to hide
---

# Design a module

Design **deep modules**: a lot of behaviour behind a small interface, at a clean seam,
testable through that interface. The aim is leverage for callers, locality for maintainers,
and testability for everyone.

## Vocabulary

Use these words exactly. Consistent language is most of the value here — substituting
"component", "service", "API", or "boundary" loses the distinctions.

**Module** — anything with an interface and an implementation. Deliberately scale-agnostic: a
function, a class, a package, or a slice spanning tiers. *Avoid:* unit, component, service.

**Interface** — everything a caller must know to use the module correctly. The type signature,
and also the invariants, ordering constraints, error modes, required configuration, and
performance characteristics. *Avoid:* API, signature — both are too narrow, naming only the
type-level surface.

**Implementation** — what is inside. Distinct from adapter: a thing can be a small adapter
with a large implementation (a Postgres repository) or a large adapter with a small one (an
in-memory fake). Say "adapter" when the seam is the subject, "implementation" otherwise.

**Depth** — leverage at the interface: how much behaviour a caller or a test can exercise per
unit of interface they must learn. **Deep** means a lot of behaviour behind a small interface.
**Shallow** means the interface is nearly as complex as the implementation.

**Seam** — a place where you can change behaviour without editing in that place; the location
at which the interface lives. Where to put it is its own decision, separate from what goes
behind it. *Avoid:* boundary — overloaded with bounded context.

**Adapter** — a concrete thing satisfying an interface at a seam. Names a role, not a
substance.

**Leverage** — what callers get from depth: more capability per unit of interface learned. One
implementation pays back across many call sites and many tests.

**Locality** — what maintainers get from depth: change, bugs, knowledge, and verification
concentrate in one place instead of spreading across callers. Fix once, fixed everywhere.

## Deep and shallow

```
Deep — what you want                 Shallow — avoid
┌──────────────────┐                 ┌──────────────────────────────┐
│  small interface │                 │      large interface         │
├──────────────────┤                 ├──────────────────────────────┤
│                  │                 │   thin implementation        │
│   a lot of       │                 └──────────────────────────────┘
│   behaviour      │
│                  │
└──────────────────┘
```

When designing an interface, ask three questions:

- Can I remove a method?
- Can I simplify a parameter?
- Can I hide more inside?

## Four tests

- **The deletion test.** Imagine the module gone. If complexity disappears, it was a
  pass-through and should not exist. If complexity reappears across every caller, it earns
  its keep.
- **The interface is the test surface.** Callers and tests cross the same seam. If a test must
  reach past the interface, the module is the wrong shape.
- **One adapter is a hypothetical seam. Two adapters is a real one.** Do not introduce a seam
  until something actually varies across it.
- **Depth is a property of the interface, not the implementation.** A deep module can be built
  internally from small swappable parts — they simply are not part of the interface. A module
  can have internal seams used by its own tests, as well as the external seam at its
  interface.

## Designing for testability

**Accept dependencies, do not construct them.**

```typescript
// testable
function processOrder(order: Order, gateway: PaymentGateway) {}

// not testable: the gateway is welded in
function processOrder(order: Order) {
  const gateway = new StripeGateway();
}
```

**Return results rather than mutating arguments.**

```typescript
// testable at the interface
function calculateDiscount(cart: Cart): Discount {}

// the caller becomes the test surface
function applyDiscount(cart: Cart): void { cart.total -= discount; }
```

**Keep the surface small.** Fewer methods means fewer tests. Fewer parameters means simpler
setup.

**Push input and output to the edges.** Keep the decisions in the middle, where they need no
fixtures.

## How the terms relate

- A module has exactly one interface: the surface it presents to callers and tests.
- Depth is a property of a module, measured against its interface.
- A seam is where a module's interface lives.
- An adapter sits at a seam and satisfies the interface.
- Depth produces leverage for callers and locality for maintainers.

## Framings deliberately rejected

- **Depth as the ratio of implementation lines to interface lines.** It rewards padding the
  implementation. Depth here is leverage, not line count.
- **"Interface" meaning the language keyword, or a class's public methods.** Too narrow.
  Interface here includes every fact a caller must know.
- **"Boundary" as a synonym for seam.** Overloaded. Say seam, or say interface.

## In an existing codebase

Follow the established shape. Where the codebase uses large modules, do not unilaterally
restructure it. Where the module you are already changing has grown unwieldy, proposing a
split is reasonable — say what you would split and why, and let the user decide.
