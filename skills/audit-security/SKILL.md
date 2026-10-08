---
name: audit-security
description: Audit a change or a component for security risk against the OWASP Top 10 — access control, misconfiguration, supply chain, cryptography and secrets, injection, design, authentication, integrity, logging, and error handling. Use when the user asks for a security review or an OWASP check, before shipping anything handling untrusted input or credentials, or when reviewing auth code.
---

# Security review

Security defects differ from other bugs in one way that governs the whole method: **nothing
fails until someone attacks.** The tests stay green. So this review is done by reading, with a
checklist, not by running the suite.

The checklist is the [OWASP Top 10:2025](https://top10.owasp.org/2025), one section per
category, so a finding can be named in a vocabulary the whole industry shares. Where a review
needs more depth than the Top 10 gives — a regulated system, a payment flow, an identity
provider — use the [OWASP ASVS 5.0](https://owasp.org/www-project-application-security-verification-standard/)
requirements for the matching chapter, and say which ASVS level you reviewed against.

## 1. Scope it, then find the trust boundaries

Establish what you are reviewing — a diff, a component, a whole service — and confirm it.

Then find where untrusted data enters:

```bash
# request entry points
grep -rn "req\.\(body\|query\|params\|headers\|cookies\)" --include='*.ts' --include='*.js'
grep -rn "request\.\(json\|form\|args\|files\|headers\)" --include='*.py'
# raw SQL and shell
grep -rniE "(execute|query|raw)\(.*(\+|\$\{|%s|format|f\")" 
grep -rnE "(exec|system|popen|spawn|shell_exec|eval)\(" 
# secret-shaped names
grep -rniE "(password|secret|token|api_?key|private_key|credential)" --include='*' -l
```

Everything from outside the process is untrusted: request bodies, query strings, headers,
cookies, uploads, third-party API responses, environment variables in a shared runtime, and
database rows written by an older version of the code.

## 2. Work the OWASP Top 10

Rank each finding by **what an attacker gains**, not by how easy the fix is. Walk every
category even when the change looks unrelated: the category that was skipped is where the
hole is.

### A01 Broken Access Control

- [ ] Checked on every request, at the server. A hidden control is not a check.
- [ ] Checked per object, not only per route. "Can this user read *this* record" is the most
      commonly missing check in real systems.
- [ ] Deny by default. A new route, field, or flag starts closed.
- [ ] Identity derived from the session or token server-side, never from a client-supplied id,
      role, or tenant header.
- [ ] Tenant scoping present on every query in a multi-tenant system. One missing `WHERE
      tenant_id` is a cross-tenant leak.
- [ ] File paths canonicalized, then confirmed to be inside the intended directory.
- [ ] Server-side requests to a user-supplied URL resolved against an allow-list of hosts, with
      private and link-local ranges refused. SSRF reaches the metadata service and the internal
      network.
- [ ] CORS scoped narrowly. A wildcard origin with credentials is a hole.
- [ ] Redirects validated against an allow-list. An open redirect is a phishing primitive.

### A02 Security Misconfiguration

- [ ] Security headers set through the framework rather than by hand.
- [ ] TLS enforced, certificate verification on. No "temporarily" disabled verification.
- [ ] Debug mode, verbose errors, and sample or admin endpoints off outside development.
- [ ] No default account, default password, or default key left in place.
- [ ] Cloud storage, buckets, queues, and infrastructure-as-code default to private.
- [ ] XML parsers configured with external entities off.
- [ ] Framework and runtime security features left on, not disabled to make a test pass.

### A03 Software Supply Chain Failures

- [ ] Each new dependency justified against its risk. A ten-line utility is not worth a supply
      chain.
- [ ] Lockfile committed. CI installs with the frozen-lockfile flag.
- [ ] Package names checked character by character. Typosquatting works.
- [ ] No install scripts running unread.
- [ ] Known advisories checked, with the project's own audit command.
- [ ] CI actions, base images, and build tools pinned to a digest or an exact version, not a
      floating tag.
- [ ] Build and deploy pipelines protected: no secret readable by a pull request from a fork, no
      step that runs untrusted code with publish rights.

### A04 Cryptographic Failures

- [ ] No credential in code, tests, fixtures, config, comments, or commit messages.
- [ ] Secrets read from the environment or a secret store, never a checked-in file.
- [ ] Check the history, not only the working tree: `git log -p -S '<pattern>'`. A secret in
      history is compromised, and rotation is the fix — deleting the line is not.
- [ ] Sensitive data encrypted in transit and, where it sits, at rest. Classify first: what is
      personal, financial, health, or regulated.
- [ ] Passwords stored with a slow, salted hash — Argon2id, scrypt, or bcrypt. Never a fast hash,
      never reversible.
- [ ] Current algorithms and modes. MD5, SHA-1, RC4, DES, and ECB are findings when used for
      security.
- [ ] Tokens, session ids, and nonces from a cryptographically secure random source.
- [ ] Keys managed — generated by the platform, rotated, never hard-coded.
- [ ] Tokens and signatures compared in constant time.
- [ ] Library primitives used as documented. Home-rolled crypto is a finding on its own.

### A05 Injection

- [ ] Validated at the boundary, against an allow-list of what is acceptable.
- [ ] Type, range, length, and format all checked. Rejected explicitly, not sanitized into
      silence.
- [ ] Every query parameterized. No string concatenation into SQL, NoSQL, a shell command, an
      LDAP filter, or a template.
- [ ] No user input reaching a shell. The array form of process spawning, with no shell
      interpolation.
- [ ] Output encoded for its target context — HTML, attribute, URL, and JSON each need their
      own. A value safe in one is unsafe in another.
- [ ] Untrusted text kept out of an LLM prompt's instruction position, and the model's output
      treated as untrusted input to whatever consumes it.

### A06 Insecure Design

- [ ] Everything bounded: request size, upload size, page size, recursion depth, regex input
      length. Check regexes for catastrophic backtracking.
- [ ] Rate limits on anything expensive or abusable — login, signup, password reset, search,
      sending email or SMS.
- [ ] Business rules enforced server-side. A price, quantity, or discount from the client is a
      suggestion.
- [ ] Trust boundaries explicit in the design, not discovered in the code. Where the design is
      new or the boundaries are unclear, run the `threat-model` skill first.

### A07 Authentication Failures

- [ ] Brute force limited: lockout or exponential backoff on login, reset, and MFA.
- [ ] Passwords checked against length and a breached-password list, not composition rules.
- [ ] MFA available, and required for admin.
- [ ] Session id regenerated on login. Session invalidated on logout and after a timeout.
- [ ] Session tokens in cookies marked `HttpOnly`, `Secure`, and `SameSite`. Not in a URL.
- [ ] JWTs verified with an explicit algorithm allow-list and an issuer and audience check.
      `alg: none` is a finding.
- [ ] Credential recovery does not reveal whether an account exists.
- [ ] Authentication and authorization kept separate.

### A08 Software or Data Integrity Failures

- [ ] Deserialization treated as code execution unless the format cannot express it.
- [ ] Webhooks and callbacks verified by signature before any side effect.
- [ ] Updates, plugins, and auto-fetched artifacts verified against a signature or digest.
- [ ] Scripts and styles from a CDN carry an integrity attribute.
- [ ] Data that drives a decision — a role, a price, a flag — writable only by the code that
      owns it.

### A09 Security Logging and Alerting Failures

- [ ] No secret, token, full auth header, card number, or personal data beyond policy.
- [ ] The correlating identifier present, so an incident can be reconstructed.
- [ ] Auth failures, authorization denials, input rejections, and admin actions logged.
- [ ] Log lines cannot be forged by user input — newlines and control characters encoded.
- [ ] Something alerts on the events that matter. A log nobody reads is not detection.

### A10 Mishandling of Exceptional Conditions

- [ ] Fails closed. A thrown exception, a timeout, or a missing config value denies rather than
      allows.
- [ ] No catch-all that swallows an error and continues as though the check passed.
- [ ] No internals in a response — no stack trace, SQL, internal hostname, or library version.
- [ ] Check-then-act sequences atomic. A balance check and a debit in two statements is a race.
- [ ] Resources released on the error path — files, locks, connections, temp files.
- [ ] Partial failure leaves consistent state: a transaction, or an explicit compensation.

## 3. Report

For each finding:

```
<Severity> [A0N:2025 <category>]: <one-line description>
  file:line
  What an attacker gains: <the concrete outcome>
  Why it is reachable: <the path from untrusted input to this code>
  Fix: <the specific change, or the OWASP Cheat Sheet that gives it>
```

Severity from what an attacker gains: **Critical** (data loss, remote execution, authentication
bypass, cross-tenant access), **High** (privilege escalation, credential exposure), **Medium**
(information disclosure, denial of service), **Low** (defence in depth, hardening).

Where a fix is a known pattern, point at the matching page of the
[OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/) rather than writing it out.

Close with the categories you reviewed, the ones you could not assess from the code alone, and
what you could not determine.

## 4. Say what you are unsure of

Where you cannot tell whether a path is reachable, say exactly that. Do not drop it and do not
inflate it:

> `renderTemplate` interpolates a user-supplied name without escaping (`render.ts:44`). I could
> not find a call site that reaches it with untrusted input — the two callers pass constants.
> Worth confirming there is no third caller before treating this as safe.

An overstated finding costs the team's attention. A dropped one costs more. A hedged one costs
neither.

## What this skill does not do

It does not run an exploit, scan a live system, or test anything against an environment you do
not own. Where a finding needs a live check, say what check would confirm it and let the team
decide who runs it and where.

The full standing rules are `rules/60-security.md`. A hook (`guard-secrets.sh`) blocks the most
obvious credential writes, which covers the accident and not the review.
