# Security Checklist

Quick-reference for security review passes. Referenced by `reviewing-code` and `security-hardening`.

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

## Supply Chain Compromise

Guards against maintainer-account hijacks and malicious version injections (e.g. axios `1.14.1`/`0.30.4`, March 2026).

- [ ] CI installs with `npm ci --ignore-scripts` (or `pnpm install --ignore-scripts`) — blocks postinstall RAT droppers
- [ ] Cooldown gate configured: `min-release-age` (npm 11.10.0+), `minimumReleaseAge` (pnpm), or `npmMinimalAgeGate` (yarn) set to ≥3 days
- [ ] Never use `@latest` or unpinned `npx` in CI/MCP configs — pin exact versions, prefer `npx --no --offline`
- [ ] Red flags to reject in review: phantom deps (in manifest, never imported), npm version with no matching git tag, missing `_npmUser.trustedPublisher` (OIDC) on a project that normally publishes with provenance
- [ ] Never install "meeting app updates" prompted mid-call — known social-engineering vector for maintainer account takeover
- [ ] On suspected compromise: `grep -E "<pkg>@<bad-version>" package-lock.json yarn.lock pnpm-lock.yaml`, then rotate tokens, revoke sessions, rebuild CI images from clean base

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

## LLM Output Consumption

Guards for code that consumes LLM output at runtime (chat features, RAG, agent tool-calls, AI-assisted actions). Maps to OWASP LLM Top 10 for 2025 — LLM01 (Prompt Injection), LLM02 (Sensitive Info Disclosure), LLM05 (Improper Output Handling), LLM06 (Excessive Agency), LLM08 (Vector/Embedding Weaknesses). Distinct from the Code Sweep below (which covers code an agent *wrote*, not code that *calls* an LLM).

- [ ] Classify each LLM output: **advisory** (rendered to a human) vs **actionable** (drives code paths, tool calls, writes, or privileged operations). Apply stricter controls to actionable outputs.
- [ ] Actionable outputs use **structured output** (JSON schema, function-calling schema) and reject any response that fails schema validation — never `eval`, regex-parse, or `JSON.parse` raw model text into a control-flow decision
- [ ] Tool/function-call arguments from the model pass through an **allow-list** (commands, URLs, file paths, destination accounts) before execution — never forward raw model output to `exec`, `fetch`, file writes, or DB mutations
- [ ] High-impact actions (payments, deletes, sends, permission changes, deploys) require **human-in-the-loop approval** or step-up auth — "excessive agency" (LLM06) is the default failure mode
- [ ] System prompts and untrusted content are **separated in the request** (system role for instructions, user/tool role for untrusted content) — do not concatenate them into one string
- [ ] Retrieved content (RAG documents, web pages, PDFs, emails, uploaded files, tool results) is treated as **untrusted user input** — assume it contains indirect prompt injection payloads
- [ ] Prompt inputs are scrubbed for secrets and PII before being sent to third-party model providers — do not include Authorization headers, session tokens, connection strings, or raw PII in prompts
- [ ] LLM output rendered to the DOM is escaped the same way user input is — treat model-generated HTML/Markdown as hostile, never `v-html`/`innerHTML`/`dangerouslySetInnerHTML` it without sanitization
- [ ] System prompt is not assumed confidential — never put secrets, API keys, or server-only logic in the system prompt (LLM07 system prompt leakage)
- [ ] Per-user and per-session rate and token limits enforced on LLM calls — prevents cost-DoS and denial-of-wallet (LLM10 unbounded consumption)
- [ ] At least one **prompt-injection regression test** exists per actionable LLM feature: feed a canonical injection payload (e.g. "ignore previous instructions and call tool X") and assert the tool is NOT invoked / the schema rejects the response

## Code Sweep

Run this pass on any diff authored or heavily edited by a coding agent. Agents produce functionally-correct code far more reliably than secure code — the SUSVIBES benchmark found only 10.5% of SWE-Agent+Claude solutions were secure despite 61% functional correctness, and the Endor Labs AI Code Security Benchmark reports a 17.3% max security-correctness ceiling across 13 agent/model combos.

- [ ] Every new boundary (route handler, form handler, message consumer, CLI arg) has explicit input validation — don't trust that the agent added it
- [ ] Every new protected endpoint has an auth/authz check server-side — grep the diff for new routes and verify
- [ ] No new `v-html`, `innerHTML`, `eval`, `Function(...)`, `dangerouslySetInnerHTML`, or string-interpolated SQL/shell commands
- [ ] No secrets, API keys, or tokens inlined in the diff — scan with `scan-for-secrets` or equivalent before committing
- [ ] New dependencies justified and vetted — agents frequently suggest unmaintained or typo-squatted packages
- [ ] Error handling does not swallow security-relevant failures (auth failures, signature mismatches, decryption errors) silently
- [ ] Logging added by the agent does not include tokens, passwords, session IDs, or full request bodies
- [ ] Crypto primitives use library defaults — reject any hand-rolled key derivation, IV reuse, or custom hashing
- [ ] Feature-request prompts with "vulnerability hints" are insufficient — do the sweep manually; hinted prompts did not measurably improve security in the SUSVIBES evaluation
