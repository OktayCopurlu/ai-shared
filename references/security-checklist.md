# Security Checklist

Quick-reference for security review passes. Referenced by `code-review` and `security-hardening`.

## Input Validation

- [ ] All user input validated at system boundaries (API routes, form handlers)
- [ ] Allowlists preferred over denylists for accepted values
- [ ] Input length, type, and range constrained before processing
- [ ] File uploads validated by MIME type and size — never trust client-reported type alone
- [ ] URL parameters and query strings sanitized before use in logic or rendering

## Output Encoding

- [ ] HTML output escaped to prevent XSS (Vue's `{{ }}` handles this — watch for `v-html`)
- [ ] `v-html` only used with trusted, sanitized content — never with user input
- [ ] JSON responses do not leak internal error details, stack traces, or system paths
- [ ] Error messages are user-friendly and do not reveal implementation details

## Authentication & Authorization

- [ ] Auth checks on every protected route — both client-side guards and server-side middleware
- [ ] Session tokens are HttpOnly, Secure, SameSite
- [ ] No auth tokens stored in localStorage (use HttpOnly cookies or secure session management)
- [ ] Role-based access verified server-side — never trust client-side role checks alone
- [ ] Password reset and email change flows properly validated

## Secrets & Configuration

- [ ] No secrets, tokens, or API keys in source code or version control
- [ ] Environment variables used for all secrets
- [ ] `.env` files in `.gitignore`
- [ ] No secrets in client-side bundles — verify with bundle analysis if unsure
- [ ] No secrets logged to console, error tracking, or analytics

## Dependencies

- [ ] No dependencies with known vulnerabilities (`npm audit`, `yarn audit`)
- [ ] Dependencies from trusted sources — check maintainer, last commit, open issues
- [ ] Lock file committed (`package-lock.json` or `yarn.lock`)
- [ ] New dependencies justified — prefer standard library and existing utilities

## API Security

- [ ] SQL/NoSQL queries use parameterized queries — no string concatenation
- [ ] GraphQL queries use variables — no string interpolation in query strings
- [ ] Rate limiting on sensitive endpoints (login, registration, password reset)
- [ ] CORS configured to allow only expected origins
- [ ] API responses include proper security headers (CSP, X-Content-Type-Options, X-Frame-Options)

## Data Handling

- [ ] Sensitive data (PII, payment info) encrypted at rest and in transit
- [ ] No sensitive data in URL parameters (visible in logs, browser history, referrer headers)
- [ ] Form data submitted over HTTPS only
- [ ] Client-side storage (cookies, sessionStorage) contains no sensitive data in plain text
