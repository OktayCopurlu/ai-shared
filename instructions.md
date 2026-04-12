# Global Agent Rules

Repo/path-specific instructions override these. AI config lives in `~/.ai-shared/` — always edit source there, not symlinked copies.

## Verification First

- Never hallucinate. Unknown → say so.
- Never guess paths, names, types, signatures, packages, config, or CLI flags.
- Search codebase before asking. Check source, configs, scripts, docs first.
- Ask user only when verification fails, external context needed, or ambiguity would materially change outcome.
- Never assume files exist — search/list first.
- Evidence over assertion. Cite file, search result, or output when useful.
- Never falsely claim APIs, functions, files, env vars, routes, configs, tests, or behavior exist.
- Never claim tested/passing/fixed unless actually verified.

## Decision Making

- Unclear conventions → read instruction files, config, or source before answering.
- Better approach, likely bug, or design smell → say so briefly, suggest alternative, then proceed.
- Multiple viable solutions → state trade-offs, choose best.
- Before changing code → inspect relevant files, surrounding implementation, existing patterns.
- Extend existing patterns over inventing new ones.
- Keep changes focused, consistent with repo style.

## Quality Bar

- Correctness and maintainability over speed.
- Quick second pass after completing work — mention better approach if one becomes apparent.
- New files, functions, env vars, routes, configs, helpers allowed when needed.

## Skill Awareness

Skills in `~/.ai-shared/skills/` activate by task context:

- **Build**: `coding-style` (all code), `tdd` (test-first), `debugging` (breakage)
- **Quality**: `code-review` (4-layer) before PRs, `security-hardening` (input/auth/deps)
- **Deliver**: `git-workflow` (PR pipeline), `jira-ticket` (ticket writing/review), `documentation` (ADRs, READMEs)
- **Learn**: `skill-evolution` after complex tasks — capture, validate, codify
- **Tools**: `atlassian-mcp` (Jira/Confluence), `github-mcp` (PRs/issues), `amplitude-analytics` (tracking), `contentful` (CMS), `google-drive` (Sheets/Docs), `playwright-mcp` (browser automation)
- **Browser**: `ui-validation` + `a11y-audit` (UI changes), `chrome-devtools-mcp` (runtime debug)
- **References**: Checklists in `~/.ai-shared/references/` — load on demand, not upfront
