---
description: "Migrate a codebase, library, or pattern from one version/framework/API to another. Use when upgrading major versions, switching libraries, or converting patterns across a codebase."
---

# Migration

When the user provides the migration target (e.g. "upgrade Vue 2 to Vue 3", "migrate from Vuex to Pinia", "convert Options API to Composition API"):

1. **Identify scope** — determine what is being migrated and the source/target versions or patterns
2. **Read official migration guide** — fetch the vendor's official migration or upgrade guide (e.g. vuejs.org/guide/migration, nuxt.com/docs/getting-started/upgrade, devblogs.microsoft.com/typescript)
3. **Audit current state** — search the codebase for patterns that need migration; build an inventory of affected files and patterns
4. **Check dependencies** — verify that all dependencies are compatible with the target version; flag any that need upgrading or replacing

## Migration Plan

Before making changes, produce a migration plan:

1. list every pattern or API that must change, with file counts
2. group changes by type (breaking changes, deprecations, new APIs, config changes)
3. order groups by dependency — foundational changes first (config, build, types), then leaf changes (components, utilities)
4. identify patterns that can be migrated mechanically vs. those requiring judgment

Present the plan to the user before proceeding. Do not start changing files until the plan is confirmed.

## Execution

Migrate one group at a time:

1. **Config and build** — update tooling config, package versions, build scripts
2. **Types and interfaces** — update type definitions, generics, API signatures
3. **Shared utilities** — migrate helpers, composables, stores that other code depends on
4. **Components and pages** — migrate leaf code that consumes the shared layer
5. **Tests** — update test setup, fixtures, and assertions to match new APIs

After each group:

- run type checks and lint
- run affected tests
- fix failures before moving to the next group

## Migration Checklist Per File

For each file being migrated:

- [ ] old API/pattern replaced with new equivalent
- [ ] no deprecated APIs remain
- [ ] imports updated (package paths, named exports)
- [ ] types are correct (no `any` escape hatches introduced)
- [ ] behavior preserved — same inputs produce same outputs
- [ ] file compiles and passes lint

## Completion

Migration is complete when:

- all items in the migration plan are addressed
- type checks, lint, and tests pass
- no deprecated APIs remain in the migrated scope
- a summary of what changed is available for the PR description

## Guardrails

- do not change behavior during migration — refactoring is a separate step
- do not migrate files outside the agreed scope without confirmation
- if a pattern has no clear equivalent in the target, flag it and pause
- if the official migration guide warns about a specific gotcha, call it out before proceeding
- prefer the codemods or automated migration tools recommended by the vendor when they exist
