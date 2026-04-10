---
name: security-hardening
description: "Security review and hardening for frontend applications. OWASP Top 10 prevention, input validation, auth patterns, secrets management, dependency auditing. USE FOR: handling user input, auth flows, data storage, external integrations, or any security-sensitive change."
---

# Security Hardening

Prevent security vulnerabilities during implementation and review. Focused on frontend and full-stack patterns relevant to Vue/Nuxt/TypeScript applications.

## When to Use

- Implementing forms, auth flows, or payment integration
- Handling user input that feeds into rendering, APIs, or storage
- Adding or updating dependencies
- Working with environment variables, tokens, or secrets
- Connecting to external APIs or services
- Reviewing code that touches any of the above

**When NOT to use:** Pure styling changes, static content updates, or internal tooling with no user-facing data handling.

## Three-Tier Boundary System

Security enforcement depends on where you are in the stack:

### Tier 1 — Client Boundary (Browser)

User input enters the system here. Trust nothing.

- Validate all form inputs before submission (type, length, format)
- Sanitize any content rendered with `v-html` — or avoid `v-html` entirely
- Never store auth tokens in `localStorage` — use HttpOnly cookies
- Never embed secrets in client-side code or bundles
- Use CSP headers to restrict script sources

### Tier 2 — API Boundary (Server / BFF)

Data crosses the network. Validate at both sides.

- Re-validate all input server-side — client validation is a UX convenience, not a security control
- Use parameterized queries — no string interpolation in SQL/GraphQL
- Authenticate and authorize every request — not just the first one
- Rate-limit sensitive endpoints (login, registration, password reset)
- Return minimal error details — no stack traces, no internal paths

### Tier 3 — Data Boundary (Storage / External Services)

Data leaves your control. Encrypt and minimize.

- Encrypt sensitive data at rest
- Never log PII, tokens, or credentials
- Minimize data stored — collect only what's needed
- Audit third-party services for data handling practices

## OWASP Top 10 — Frontend Focus

| Risk | Prevention |
|------|-----------|
| **Injection (SQL, XSS, SSRF)** | Parameterized queries, output encoding, v-html only with sanitized trusted content |
| **Broken Authentication** | Secure session management, HttpOnly cookies, proper password handling |
| **Sensitive Data Exposure** | HTTPS everywhere, no secrets in code/logs/URLs, encrypt at rest |
| **Broken Access Control** | Server-side auth on every route, role checks not client-only |
| **Security Misconfiguration** | CSP headers, CORS allowlists, disable verbose errors in production |
| **Vulnerable Components** | Regular `npm audit`, lock files committed, dependency review before adding |
| **Insecure Deserialization** | Validate and sanitize all external data before use |

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
