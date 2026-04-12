---
name: security-hardening
description: "Security review and hardening for frontend applications. OWASP Top 10 prevention, input validation, auth patterns, secrets management, dependency auditing. USE FOR: handling user input, auth flows, data storage, external integrations, or any security-sensitive change."
---

# Security Hardening

Prevent security vulnerabilities in Vue/Nuxt/TypeScript applications.

## Boundary Rules

### Client (Browser)
- Sanitize any content rendered with `v-html` — or avoid `v-html` entirely
- Never store auth tokens in `localStorage` — use HttpOnly cookies
- Never embed secrets in client-side code or bundles
- Use CSP headers to restrict script sources

### API (Server / BFF)
- Re-validate all input server-side — client validation is UX, not security
- Use parameterized queries — no string interpolation in SQL/GraphQL
- Rate-limit sensitive endpoints (login, registration, password reset)
- Return minimal error details — no stack traces, no internal paths

### Data (Storage / External)
- Encrypt sensitive data at rest
- Never log PII, tokens, or credentials
- Minimize data stored — collect only what's needed

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

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "It's behind auth, so input validation isn't needed" | Authenticated users can still be attackers. Validate all input at every boundary. |
| "We only use v-html for admin content" | Admin accounts get compromised. Sanitize everything rendered via v-html. |
| "The secret is in an env var, it's safe" | Env vars in client-side builds are embedded in the bundle. They're public. Server-side only. |
| "npm audit has too many false positives" | Triaging noise is cheaper than shipping a CVE. Check each finding. Suppress with justification. |
| "CORS is already configured" | Configured doesn't mean configured correctly. Verify the allowlist matches expectations. |
| "This is an internal tool, security doesn't matter" | Internal tools have access to internal data. That's exactly when security matters most. |

## Red Flags

- `v-html` used with any user-provided or external content
- Auth tokens in `localStorage` or client-side JavaScript
- Secrets or API keys in source code, even in "internal" repos
- `npm audit` warnings ignored without review
- CORS set to `*` in production
- Client-side role checks without server-side enforcement
- SQL/GraphQL queries built with string templates
- Error responses showing stack traces or file paths

## Verification

After security hardening:

- [ ] All user input validated at the API boundary (Tier 2)
- [ ] `v-html` usage reviewed — all content sanitized or trusted
- [ ] No secrets in client bundles (check build output if unsure)
- [ ] `npm audit` / `yarn audit` returns no high/critical vulnerabilities
- [ ] Auth checked server-side on all protected routes
- [ ] CORS configured with explicit origin allowlist
- [ ] Security headers present (CSP, X-Content-Type-Options, X-Frame-Options)

## See Also

- `references/security-checklist.md` — quick-reference checklist for review passes
- `code-review` — security checks in Layer 4 (architecture signals)
