# Destructive Operations Guardrail

Stop-and-confirm reference for operations that are irreversible or have high blast radius. Referenced by any skill or agent performing file system, git, database, or infrastructure operations.

## Ruin-Risk Categories

Pause and require explicit user approval before executing any operation in these categories:

| Category | Examples |
|---|---|
| **Bulk file deletion** | `rm -rf`, deleting 5+ files, removing entire directories |
| **Git history alteration** | `git push --force`, `git reset --hard`, `git rebase` on shared branches, `git filter-branch` |
| **Database mutations** | `DROP`, `TRUNCATE`, `ALTER TABLE ... DROP COLUMN`, irreversible migrations |
| **Production environment** | Deployment configs, infrastructure changes, environment variable modifications |
| **Security policy changes** | Auth flows, encryption settings, access control rules, CORS policy |
| **Credential/PII handling** | Schema changes touching PII columns, migration scripts moving sensitive data |
| **External side effects** | API calls that create/modify/delete external resources, sending emails/notifications |

## Decision Flow

```
Is the operation read-only?
  YES → proceed without pause
  NO → Does it match a ruin-risk category above?
    NO → proceed (normal write operation)
    YES → STOP. Present what will happen and why it's risky.
          Wait for explicit user approval before executing.
```

## What to Present When Pausing

State three things:

1. **What** — the exact operation (command, query, API call)
2. **Impact** — what could go wrong if it proceeds unchecked
3. **Scope** — how many files/rows/resources are affected

Keep it to 2-4 lines. Do not bury the risk in paragraphs.

## Scoping Rules

- Scope every destructive action to the smallest unit possible (one file, one user, one record)
- Never batch destructive operations across unrelated resources in a single command
- Prefer reversible alternatives when available (`git revert` over `git reset --hard`, soft delete over hard delete)
- Use dry-run flags when available (`--dry-run`, `--check`, `-n`) and show output before the real run

## Graduated Response

Not all destructive operations carry equal risk:

| Risk Level | Criteria | Response |
|---|---|---|
| **Low** | Single file, local only, easily recreated | State what you're doing, proceed unless user objects |
| **Medium** | Multiple files, local git history, dev environment | Pause, present impact, wait for approval |
| **High** | Shared branches, production, external systems, PII | Pause, present impact with rollback plan, wait for explicit approval |

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I can undo it with git" | Force pushes, hard resets on shared branches, and rebases that others have pulled from cannot be trivially undone. |
| "It's just the dev environment" | Dev environments often share databases, services, or state with other developers. |
| "The user asked me to do it" | The user may not realize the blast radius. Present the impact before executing. |
| "It's faster to just do it" | The 10 seconds spent confirming saves the hours spent recovering from the wrong deletion. |

## Integration Points

- `git-workflow` — already enforces git-specific rules (no force push to main, no --hard reset without request)
- `security-hardening` — covers code-level security; this reference covers operational safety
- `debugging` — when a debug session involves modifying production data or rolling back deployments
