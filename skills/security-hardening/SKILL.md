---
name: security-hardening
description: "Security review and hardening for frontend applications. OWASP Top 10 prevention, input validation, auth patterns, secrets management, dependency auditing. Use when handling user input, building auth flows, storing data, integrating with external services, or making any security-sensitive change."
---

# Security Hardening

Prevent security vulnerabilities in Vue/Nuxt/TypeScript applications. Use `references/security-checklist.md` as the detailed checklist; this skill defines when and how to apply it.

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

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "It's behind auth, so input validation isn't needed" | Authenticated users can still be attackers. Validate all input at every boundary. |
| "The secret is in an env var, it's safe" | Env vars in client-side builds are embedded in the bundle. They're public. Server-side only. |
| "This is an internal tool, security doesn't matter" | Internal tools have access to internal data. That's exactly when security matters most. |

## See Also

- `references/security-checklist.md` — quick-reference checklist for review passes
- `reviewing-code` — security checks in Layer 4 (architecture signals)
