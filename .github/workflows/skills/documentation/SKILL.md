---
name: documentation
description: "Apply the team's ADR, README, and maintenance-map conventions. Use when writing or updating technical documentation, recording architecture decisions, or documenting cross-file change dependencies. Not for Jira ticket content or code-style comments."
---

# Documentation

Keep only durable information that helps someone decide, operate, or change the system.

## Documentation Contracts

- **ADR:** Preserve history. Mark replaced decisions `Deprecated` or `Superseded`, link the replacement, and record material trade-offs.
- **README:** Lead with purpose and quick start. Add architecture, development, environment, and troubleshooting only when they help the reader act.
- **Drift-prone guides:** Add an owner or last-reviewed date when useful. Update documentation in the same PR as the behavior change.
- **Sources:** Link to the canonical source instead of copying content that will drift.

## Cross-File Maintenance Map

A maintenance matrix maps change dependencies: "when X changes, also update Y." Without one, contributors (human or agent) miss co-dependent files and leave docs, configs, or registrations stale.

Create one only when the repository has recurring cross-file registration patterns such as routes, exports, environment variables, schemas, feature flags, or shared contracts.

Put the table in `AGENTS.md`, repo instructions, or `CONTRIBUTING.md`, using verified paths:

| Change Made | Files to Update |
|---|---|
| New API route | Route registry, route tests, API spec, README API section |
| New environment variable | `.env.example`, deployment config, CI workflow, setup guide |
| Schema change | Migration, model, fixtures/seed data, affected handlers and tests |

Verify every path before recording it. Include tests and documentation when they are real co-dependencies, and update the map when the structure changes.

## See Also

- `applying-coding-style` — inline comment and naming standards
- `jira-ticket` — ticket writing standards (not the same as docs)
- `~/.ai-shared/references/search-first.md` — the "Before Renaming or Removing" section complements the maintenance matrix
