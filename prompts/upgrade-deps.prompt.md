---
description: "Audit and upgrade outdated dependencies. Classify by risk, research breaking changes, upgrade incrementally, and validate after each batch."
---

# Upgrade Dependencies

Safely audit and upgrade project dependencies with risk classification, incremental application, and validation.

## Audit

1. Run the package manager's outdated command to list all outdated dependencies:
   ```bash
   npm outdated
   # or
   yarn outdated
   ```
2. Run a security audit to surface known vulnerabilities:
   ```bash
   npm audit
   # or
   yarn audit
   ```
3. Check for deprecated or abandoned packages — flag anything with no commits in 12+ months or an archived repository.

## Classify

Categorize each outdated dependency by risk:

| Risk    | Version jump | Action                                              |
| ------- | ------------ | --------------------------------------------------- |
| Critical | CVE / advisory | Upgrade immediately — security patches first      |
| Low     | Patch (x.y.Z) | Apply directly — bug fixes only                    |
| Medium  | Minor (x.Y.z) | Apply, check changelog for new APIs or deprecations |
| High    | Major (X.y.z) | Read migration guide and changelog before upgrading |

## Research

For every major upgrade:

1. Read the changelog and migration guide from the official docs
2. Search GitHub issues for known breaking changes or migration pitfalls
3. Check peer dependency compatibility — especially for Vue/Nuxt ecosystem packages that declare shared peer deps
4. If the package is a framework dependency (Vue, Nuxt, Vite, TypeScript), check whether related packages need coordinated upgrades

Do not upgrade a major version without reading the migration guide first.

## Sequence

Upgrade in this order to minimize blast radius:

1. **Security patches** — critical CVEs regardless of version jump
2. **Patch versions** — lowest risk, highest confidence
3. **Minor versions** — one logical group at a time (e.g., all Radix UI packages together)
4. **Major versions** — one at a time, validate fully between each

Group related packages into a single upgrade batch (e.g., `@nuxt/test-utils` + `vitest` when they share a major).

## Upgrade

For each batch:

1. Apply the version changes via CLI — do not manually edit `package.json`
2. Regenerate the lock file (`npm install` or `yarn install`)
3. Apply any required code migrations (renamed APIs, changed imports, config format changes)
4. Commit the batch: `deps: upgrade <package-group> from vX to vY`

## Validate

After each batch, run the full validation pipeline:

1. Lint
2. Type checks
3. Build
4. Unit tests
5. Security audit (`npm audit` / `yarn audit`)

If any gate fails because of the upgrade: fix it before moving to the next batch.
If a test fails for an unrelated reason: note it and continue.

## Output

Produce a summary when done:

```markdown
## Upgrade Summary

### Upgraded

| Package | From | To | Risk | Notes |
| ------- | ---- | -- | ---- | ----- |

### Deferred

| Package | From | Available | Reason |
| ------- | ---- | --------- | ------ |

### Validation

- [ ] Lint passing
- [ ] Types passing
- [ ] Build succeeds
- [ ] Tests passing
- [ ] No new vulnerabilities
```

## Guardrails

- Never downgrade unless explicitly requested
- Never install pre-release versions (alpha/beta/RC) unless explicitly requested
- Always commit lock files alongside manifest changes
- One major upgrade per batch — validate fully between each
- If a migration path is unclear or risky, defer the package and explain why
