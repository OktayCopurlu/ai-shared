# AGENTS.md Convention — Cross-Tool Reference

AGENTS.md is an emerging standard for providing project-specific instructions to AI coding agents. Multiple tools now support it natively, making it a reliable way to encode project context once and have it respected everywhere.

## Tool Support

| Tool | Support | Discovery |
| --- | --- | --- |
| OpenCode | Native (v1.3+) | Walks up from cwd to git root; reads `AGENTS.md` at each level |
| VS Code Copilot | Native (v1.111+) | Reads `.github/copilot-instructions.md` and `AGENTS.md` in workspace |
| OpenAI Agents SDK | Native (v0.14+) | `AGENTS.md` loaded as custom instructions in sandbox agents |
| OpenAI Codex | Native | Reads `AGENTS.md` from repository root |
| Claude Code | Native | Reads `CLAUDE.md` (same concept, different filename) |

## File Locations

Agents discover instructions from multiple paths. More specific files override general ones.

```
project-root/
  AGENTS.md              # Root-level — applies to entire project
  .github/
    copilot-instructions.md  # VS Code Copilot-specific
  src/
    AGENTS.md            # Scoped to src/ subtree
  packages/api/
    AGENTS.md            # Scoped to packages/api/ subtree
```

Subtree-scoped files let you give different instructions for different parts of a monorepo.

## What to Include

### Always include

- **Tech stack and versions** — language, framework, key dependencies
- **Project structure** — where source, tests, config, and build outputs live
- **Coding conventions** — naming, formatting, import order, file organization
- **Test commands** — how to run tests, what framework is used, coverage expectations
- **Build commands** — how to build, lint, type-check

### Include when relevant

- **Architecture decisions** — patterns in use (e.g., "we use barrel exports", "state lives in Pinia stores")
- **Security constraints** — auth patterns, input validation requirements, secrets handling
- **Dependency rules** — preferred packages, packages to avoid, version constraints
- **PR and commit conventions** — branch naming, commit message format, review process
- **Environment setup** — required env vars, local dev prerequisites

### Avoid

- Secrets, API keys, or credentials (even examples with real-looking values)
- Lengthy tutorials or explanations — keep it directive, not educational
- Aspirational rules that the codebase does not actually follow
- Duplicate information already captured in linter configs, tsconfig, or package.json

## Writing Style

1. **Be directive** — "Use `vitest` for tests" not "We prefer vitest because..."
2. **Be specific** — "Name test files `*.spec.ts`" not "Follow testing conventions"
3. **Be honest** — Only document conventions the codebase actually follows
4. **Be concise** — Agents have context limits; every line should earn its place
5. **Use structure** — Headings, lists, and code blocks parse better than prose

## Example

```markdown
# AGENTS.md

## Stack
- TypeScript 5.8, Vue 3.5, Nuxt 4, Pinia
- Vitest for unit tests, Playwright for e2e
- pnpm workspaces, Nx for task orchestration

## Structure
- `packages/app/` — Nuxt frontend
- `packages/api/` — Express API
- `packages/shared/` — shared types and utilities

## Conventions
- Use `<script setup lang="ts">` in all Vue SFCs
- Composables go in `composables/` and are prefixed with `use`
- No barrel exports — import directly from source files
- All API routes validate input with Zod schemas

## Commands
- `pnpm test` — run all unit tests
- `pnpm lint` — ESLint + Prettier check
- `pnpm typecheck` — tsc --noEmit across all packages
- `pnpm e2e` — Playwright tests (requires `pnpm dev` running)

## Rules
- Never commit `.env` files
- All new API endpoints require Zod validation and unit tests
- Use named exports, not default exports
```

## Compatibility Notes

- **Claude Code** uses `CLAUDE.md` instead of `AGENTS.md`. If supporting both, maintain both files or symlink.
- **VS Code Copilot** additionally reads `.github/copilot-instructions.md`. For Copilot-specific instructions (e.g., model preferences), use that file.
- **OpenCode** also reads `instructions.md` in its config directory (`~/.config/opencode/instructions.md`) for global rules that apply across all projects.
- **OpenAI Agents SDK** reads `AGENTS.md` as part of its harness when running sandbox agents; the file content becomes part of the agent's system instructions.

## Sources

- OpenCode Skills & Rules docs: https://opencode.ai/docs/rules/, https://opencode.ai/docs/skills/
- VS Code Copilot customization: https://code.visualstudio.com/docs/copilot/customization/overview
- OpenAI Agents SDK (Apr 2026): https://openai.com/index/the-next-evolution-of-the-agents-sdk/
- AGENTS.md specification: https://agents.md
- agentskills.io: https://agentskills.io
