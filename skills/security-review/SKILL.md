---
name: security-review
description: Audit a change or a component for security risk — secrets, input handling, authorization, injection, dependencies, and what reaches the logs. Use when the user asks for a security review, before shipping anything handling untrusted input or credentials, or when reviewing auth code.
---

# Security review

Security defects differ from other bugs in one way that governs the whole method: **nothing
fails until someone attacks.** The tests stay green. So this review is done by reading, with a
checklist, not by running the suite.

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

## 2. Work the checklist

Rank each finding by **what an attacker gains**, not by how easy the fix is.

### Secrets

- [ ] No credential in code, tests, fixtures, config, comments, or commit messages.
- [ ] Secrets read from the environment or a secret store, never a checked-in file.
- [ ] No secret in a log line, an error message, a test failure, or a response body.
- [ ] Check the history, not only the working tree: `git log -p -S '<pattern>'`. A secret in
      history is compromised, and rotation is the fix — deleting the line is not.

### Input handling

- [ ] Validated at the boundary, against an allow-list of what is acceptable.
- [ ] Type, range, length, and format all checked. Rejected explicitly, not sanitized into
      silence.
- [ ] Every query parameterized. No string concatenation into SQL, a shell command, an LDAP
      filter, or a template.
- [ ] No user input reaching a shell. The array form of process spawning, with no shell
      interpolation.
- [ ] Output encoded for its target context — HTML, attribute, URL, and JSON each need their
      own. A value safe in one is unsafe in another.
- [ ] File paths canonicalized, then confirmed to be inside the intended directory.
- [ ] Everything bounded: request size, upload size, page size, recursion depth, regex input
      length. Check regexes for catastrophic backtracking.
- [ ] Deserialization treated as code execution unless the format cannot express it.

### Authorization

- [ ] Checked on every request, at the server. A hidden control is not a check.
- [ ] Checked per object, not only per route. "Can this user read *this* record" is the most
      commonly missing check in real systems.
- [ ] Deny by default. A new route, field, or flag starts closed.
- [ ] Authentication and authorization kept separate.
- [ ] Identity derived from the session or token server-side, never from a client-supplied id,
      role, or tenant header.
- [ ] Tokens and signatures compared in constant time.
- [ ] Tenant scoping present on every query in a multi-tenant system. One missing `WHERE
      tenant_id` is a cross-tenant leak.

### Dependencies

- [ ] Each new dependency justified against its risk. A ten-line utility is not worth a supply
      chain.
- [ ] Lockfile committed. CI installs with the frozen-lockfile flag.
- [ ] Package names checked character by character. Typosquatting works.
- [ ] No install scripts running unread.
- [ ] Known advisories checked, with the project's own audit command.

### What leaves the process

- [ ] TLS enforced, certificate verification on. No "temporarily" disabled verification.
- [ ] No internals in a response — no stack trace, SQL, internal hostname, or library version.
- [ ] CORS scoped narrowly. A wildcard origin with credentials is a hole.
- [ ] Security headers set through the framework rather than by hand.
- [ ] Redirects validated against an allow-list. An open redirect is a phishing primitive.

### Logs and errors

- [ ] No secret, token, full auth header, card number, or personal data beyond policy.
- [ ] The correlating identifier present, so an incident can be reconstructed.
- [ ] Auth failures, authorization denials, and admin actions logged.

## 3. Report

For each finding:

```
<Severity>: <one-line description>
  file:line
  What an attacker gains: <the concrete outcome>
  Why it is reachable: <the path from untrusted input to this code>
  Fix: <the specific change>
```

Severity from what an attacker gains: **Critical** (data loss, remote execution, authentication
bypass, cross-tenant access), **High** (privilege escalation, credential exposure), **Medium**
(information disclosure, denial of service), **Low** (defence in depth, hardening).

Close with what you reviewed, what you did not, and what you could not determine.

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
