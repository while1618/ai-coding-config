---
name: dependency-upgrade
description: Upgrade dependencies without shipping a surprise. Use when the user asks to update dependencies, bump a package, apply a security advisory, or clear an audit warning.
when_to_use: >-
  "update the dependencies", "bump this package", "fix the audit warnings", "apply the
  security advisory", npm audit or dependabot output
---

# Upgrade dependencies

An upgrade is a behaviour change written by someone else. Treat it like one.

## 1. Find out what is actually available and why it matters

```bash
npm outdated                    # or: cargo outdated, pip list --outdated, go list -m -u all
npm audit                       # the project's own advisory check
```

Sort by reason, not by version distance:

- **A security advisory that affects a path you use.** First priority. Check whether your code
  reaches the vulnerable function — an advisory in a dependency you use for one unrelated helper
  may not affect you, and that matters when the fix is a major version.
- **A bug fixed that you have hit.** Worth doing.
- **A version behind with no consequence.** Lowest priority. "Up to date" is not a goal in
  itself; each upgrade costs verification time and carries risk.

## 2. Read before you install

For each package you intend to move, read the changelog or release notes between your version
and the target. You are looking for:

- Breaking changes, and whether they touch how you use it.
- Behaviour changes that are not called breaking — a changed default, a stricter parse, a
  different error type.
- A raised minimum runtime version. This one bites hardest, because it fails in CI or in
  production rather than at install.
- Deprecations you should act on now rather than next time.

Where a changelog does not exist or does not say, treat the upgrade as higher risk and say so.

## 3. Upgrade in small batches

**One commit per meaningful upgrade.** A single commit bumping thirty packages cannot be
reverted usefully — when something breaks a week later, you cannot tell which one did it.

A reasonable grouping:

- One commit per major version bump, alone.
- One commit per minor bump of anything load-bearing — the framework, the ORM, the test runner.
- One commit for the batch of patch bumps that nothing depends on.

```bash
npm install <package>@<version>     # name the version; do not let the range decide
```

## 4. Verify each batch

After each commit, before the next:

- [ ] Install from a clean state, so the lockfile is honest: `rm -rf node_modules && npm ci`
- [ ] Build
- [ ] Type check
- [ ] The full test suite
- [ ] Lint — some upgrades change lint rules
- [ ] Run the app and exercise the path the dependency is on. A green suite is not proof for a
      dependency whose behaviour the tests stub.

Where a test fails, decide which it is before fixing anything: your code relying on old
behaviour, a test asserting old behaviour, or a genuine regression in the new version. The three
have different fixes, and patching the test is only right for the second.

## 5. Commit the lockfile

Always. The lockfile is what makes the upgrade reproducible. A `package.json` change without its
lockfile means every teammate and CI resolve something slightly different.

## 6. When something does not work

Stop at the first upgrade that fails and cannot be fixed quickly. Do not carry a broken upgrade
forward while doing the next one — you lose the ability to attribute anything.

Report it and ask:

> `orm@6` requires Node 20; we are on 18 in CI and production. Options: raise the Node floor as
> its own change first, stay on `orm@5.9` and take the backported fix, or pin and revisit. The
> advisory this was meant to address is in the migration path, which we do not use at runtime.

## Rules

- **Never add a dependency to solve this.** An upgrade problem is not solved by another package.
- **Do not `--force` or `--legacy-peer-deps` to make an install succeed.** That defers a real
  incompatibility to runtime. Report the conflict instead.
- **Check the package name character by character** on anything new. Typosquatting works.
- **Do not upgrade and refactor in the same commit.** Even when the upgrade requires code
  changes, keep those changes minimal and about the upgrade — no "while I am here".
- **Say what you did not upgrade, and why.** That list is the useful output for the next person.
