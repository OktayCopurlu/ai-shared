---
name: security-hardening
description: 'Security review and hardening for frontend applications. OWASP Top 10 prevention, input validation, auth patterns, secrets management, dependency auditing. Use when handling user input, building auth flows, storing data, integrating with external services, or making security-sensitive changes. NOT FOR: general code style review (reviewing-code) — activate alongside reviewing-code when changes touch auth, input handling, or data boundaries.'
---

# Security Hardening

Prevent security vulnerabilities in Vue/Nuxt/TypeScript applications. Use `~/.ai-shared/references/security-checklist.md` as the detailed checklist; this skill defines when and how to apply it.

## When To Apply

- Handling any user input (forms, URL params, file uploads)
- Adding or changing auth flows
- Rendering dynamic content with `v-html`
- Adding new dependencies
- Integrating with external services
- Any agent-generated code touching a system boundary

## Dependency Audit Workflow

Before adding any dependency:

1. **Does the existing stack solve this?** (Often it does)
2. **How large is it?** Check bundle impact on bundlephobia.com
3. **Is it actively maintained?** Check last commit date, open issues, bus factor
4. **Known vulnerabilities?** Run `npm audit` or `yarn audit`
5. **License compatible?** Must be MIT, Apache 2.0, or ISC — check before adding

After adding:

```bash
npm audit
# or
yarn audit
```

## Security Fix Validation

After fixing a security vulnerability, run these checks before committing. The `debugging` skill handles general bug fixes; this workflow adds the security-specific verification that generic "write a regression test" misses.

### 1. Verify the vulnerability is closed

- Reproduce the original attack vector against the fixed code.
- Confirm the response is the **correct safe failure** (e.g., 403, sanitized error, dropped input) — not just a different error.
- A 500 or stack trace is not "fixed."

### 2. Test bypass variants

- Try the same attack from a different auth context (unauthenticated, different role, different tenant).
- Try encoding variants: URL-encoded, double-encoded, Unicode, null bytes.
- Try boundary values: empty string, max-length input, negative IDs.
- If the fix is an allowlist, try values just outside the allowed set.

### 3. Check information leakage

- Error responses must not expose stack traces, internal paths, query details, or framework versions.
- Verify against `~/.ai-shared/references/security-checklist.md` → Output Encoding section.

### 4. Verify logging hygiene

- New log statements must not include tokens, passwords, session IDs, PII, or full request bodies.
- Security-relevant failures (auth failures, signature mismatches) must be logged — but with redacted sensitive fields.

### 5. Write a security regression test

- The test must fail without the fix and pass with it.
- The test must use the **actual attack payload**, not a sanitized version.
- Include a comment explaining the vulnerability the test guards against.

### 6. Rollout considerations

- Flag the fix for expedited review — security fixes should not sit in a PR queue.
- Note if a feature flag or backwards-compatibility shim is needed.
- Note if tokens, sessions, or caches need to be invalidated as part of the fix.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "It's behind auth, so input validation isn't needed" | Authenticated users can still be attackers. Validate all input at every boundary. |
| "The secret is in an env var, it's safe" | Env vars in client-side builds are embedded in the bundle. They're public. Server-side only. |
| "This is an internal tool, security doesn't matter" | Internal tools have access to internal data. That's exactly when security matters most. |

## See Also

- `~/.ai-shared/references/security-checklist.md` — quick-reference checklist for review passes
- `reviewing-code` — security checks in Layer 4 (architecture signals)
- `debugging` — general reproduce→fix→guard workflow; use Security Fix Validation (above) for the security-specific post-fix steps
