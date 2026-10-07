---
name: threat-model
description: Find what can go wrong with a design's security before it is built, and turn each real threat into a testable requirement. Use while writing a spec, when a design adds sign-in, user data, payments, uploads, a public endpoint, or a third-party integration, or when the user asks for a threat model.
---

# Threat model

A threat model decides what the design must defend and how. It runs before the code exists,
because a missing authorization layer is a redesign, while a missing input check is a one-line
fix. Code-level rules live in `rules/60-security.md`. An audit of code that already exists is the
`security-review` skill.

The method is STRIDE, applied at trust boundaries.

## 1. Describe the system

Write a short list:

- **Actors.** Each kind of user, each admin role, each external system that calls in.
- **Components.** Client, server, workers, data stores, queues.
- **External services.** Payment, email, identity provider, storage, any API.
- **Trust boundaries.** Each place where data crosses from a less trusted side to a more trusted
  side. Typical boundaries: browser to server, server to database, server to a third party, one
  tenant to another, user to admin.

## 2. List the assets

Name what an attacker wants, or what the business cannot lose: personal data, credentials,
money, other tenants' data, admin rights, availability, the audit trail.

## 3. Walk each boundary with STRIDE

At each boundary, ask each question. Write a threat only when it is plausible for this system.

| Letter | Threat | Question |
|---|---|---|
| S | Spoofing | Can someone act as another user or another system? |
| T | Tampering | Can someone change data in transit, in storage, or in a request? |
| R | Repudiation | Can someone deny an action because nothing recorded it? |
| I | Information disclosure | Can someone read data they must not see? |
| D | Denial of service | Can someone make it unavailable or expensive to run? |
| E | Elevation of privilege | Can someone gain rights they were not given? |

## 4. Rate each threat

Rate likelihood and impact as High, Medium, or Low. Give one line of reasoning for each rating.
"High: the endpoint is public and the IDs are sequential" is a rating. "High" alone is not.

## 5. Turn threats into requirements

Each High or Medium threat becomes a requirement in the spec's **Security** section:

```markdown
- **SEC-001:** A user cannot read another tenant's invoice. A request for one returns 404.
  (Threat: I at server/database, High — invoice IDs are sequential.)
```

Write each requirement so a test can prove it. "Validate input" is not a requirement.
"An upload over 10 MB, or one that is not a PDF, is rejected with 413 or 415" is a requirement.

A threat the person decides not to fix becomes an accepted risk. Record the threat, the reason,
and the name of the person who accepted it.

Where no spec exists, write the same content to `docs/security/threat-model.md`.

## 6. Check the design choices

Where a requirement needs a design decision, flag it for `write-adr`. Common decisions are the
identity provider, the session model, the tenant isolation model, and where secrets are stored.
Prefer an established provider or library to custom code for sign-in, sessions, and cryptography.

## When it is complete

Every High threat has a `SEC-` requirement or a named accepted-risk owner. Every trust boundary
from step 1 appears in at least one threat, or carries a one-line reason that none applies.

Run this skill again when the design gains a new boundary: a new integration, a new role, a
public endpoint, or a new kind of data.

## Common mistakes

| Mistake | What to do instead |
|---|---|
| A generic list of fifty web threats | Only the threats plausible at this system's boundaries |
| "Use best-practice security" | One testable `SEC-` requirement per threat |
| Authorization left to "the framework" | State the rule: who can do what to which object, checked on the server per request |
| Rating with no reason | One line of reasoning per rating |
| Running it once and never again | Run it again when a new boundary appears |
