---
description: Secrets, input handling, authorization, dependencies, and what leaves the process.
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
  - "**/package.json"
  - "**/package-lock.json"
  - "**/pnpm-lock.yaml"
  - "**/yarn.lock"
  - "**/requirements*.txt"
  - "**/pyproject.toml"
  - "**/Cargo.toml"
  - "**/go.mod"
  - "**/pom.xml"
  - "**/build.gradle*"
  - "**/composer.json"
  - "**/Gemfile*"
  - "**/Dockerfile*"
  - "**/*.{yml,yaml}"
  - "**/*.tf"
  - "**/.env*"
---

# Security

Security defects differ from other bugs in one way: nothing fails until someone attacks. The tests stay
green. So these checks run by reading, not by running.

## Secrets

- **Never commit a secret.** Not in code, tests, fixtures, config, comments, or a commit message. Not
  "temporarily".
- **Read secrets from the environment or the project's secret store.** Never from a checked-in file.
- **Never print a secret** in a log, an error message, a test failure, or terminal output. Redact to
  `<REDACTED>` before showing any command output that could carry one.
- **A secret in the repo history is compromised.** Rotating it is the fix; deleting the line is not.
  Say so plainly when you find one.
- **Build loops against environment variables** when debugging authenticated calls, so the credential
  never lands in a transcript.

## Input from outside

Every value from outside the process is untrusted: request bodies, query strings, headers, cookies,
uploaded files, environment variables in a multi-tenant runtime, third-party API responses, and
database rows written by an earlier version of the code.

- **Validate at the boundary,** against an allow-list of what is acceptable — not a deny-list of what
  is not. Check type, range, length, and format. Reject, do not sanitize into silence.
- **Parameterize every query.** String concatenation into SQL, a shell command, an LDAP filter, or a
  template is an injection. Use the parameterized API, always.
- **Never pass user input to a shell.** Use the array form of process spawning, with no shell
  interpolation. Where a shell is unavoidable, allow-list the value first.
- **Encode on output, for the target context.** HTML, attribute, URL, and JSON contexts each need their
  own encoding. A value safe in one is unsafe in another.
- **Resolve paths before you use them.** Canonicalize, then confirm the result is inside the intended
  directory. `../` in a filename is the oldest trick there is.
- **Bound everything.** Request size, upload size, page size, recursion depth, regex input length.
  Unbounded input is a denial-of-service waiting to be found.
- **Treat deserialization as code execution** unless the format cannot express it. Prefer plain data
  formats with a schema.

## Authorization

- **Check on every request, at the server.** A hidden button is not a permission check.
- **Check the object, not only the route.** "Can this user read *this* record" — the missing per-object
  check is the most common real-world hole.
- **Deny by default.** A new route, field, or flag starts closed.
- **Keep authentication and authorization separate.** Knowing who someone is does not say what they may do.
- **Never trust a client-supplied identity** — a user id in a body, a role in a cookie, a tenant in a
  header. Derive it from the session or token, server side.
- **Compare secrets in constant time.** Token and signature comparison uses the constant-time helper,
  not `==`.

## Dependencies

- **Read what you add.** A new dependency for a ten-line utility is a supply-chain risk for a small win.
- **Pin and lock.** Commit the lockfile. Install with the frozen-lockfile flag in CI.
- **Check the package name character by character** before installing. Typosquatting works.
- **Never add a dependency that runs an install script** without reading it.
- **Upgrade deliberately** — the `dependency-upgrade` skill.

## What leaves the process

- **Enforce TLS,** with certificate verification on. Disabling verification "for now" ships.
- **Set the security headers** the framework offers rather than writing them by hand.
- **Do not leak internals in a response.** Stack traces, SQL, internal hostnames, and library versions
  belong in the log, not the error body.
- **Configure CORS narrowly.** A wildcard origin with credentials is a hole.

## Reporting a finding

When you find something, report: the file and line, the class of issue, what an attacker gains, and the
fix. Rank by what an attacker gains, not by how easy the fix is. Where you are unsure whether a path is
reachable, say that rather than either dropping it or overstating it.

The `security-review` skill runs this as a full pass.
