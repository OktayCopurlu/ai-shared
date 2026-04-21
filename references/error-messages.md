# Error & Log Message Checklist

Quick-reference for writing user-facing errors and developer-facing logs. Referenced by `reviewing-code`, `debugging`, and `security-hardening`. "Invalid token", "Sync failed", "Something went wrong" are never acceptable — they hide blast radius from the user and root cause from the next maintainer.

## The Three-Component Rule

Every error, warning, or diagnostic message must contain all three:

1. **Consequence** — what the user or system can no longer do. `"Unable to log in"`, `"Draft not saved"`, `"Upload aborted"`.
2. **Source module + process** — stable, greppable module name + the specific process that failed. `"user authentication / token refresh"`, `"remote notes sync / pull"`, `"payments / webhook verification"`.
3. **Cause / triggering condition** — the exact condition that produced the message. `"session token signature mismatch"`, `"server connection timed out after 10s"`, `"schema version 4 expected, got 3"`, `"rate limit exceeded (429)"`.

Shape: `"<consequence>: <module>/<process> — <cause>"`. Wording per surface may differ; all three pieces must be present.

Examples:

- Bad: `"Invalid token"`
- Good: `"Unable to log in: user authentication / token refresh — session token signature mismatch. Please sign in again."`

- Bad: `"Sync failed"`
- Good: `"Note cannot be synchronized: remote notes sync / pull — server connection timed out after 10s. Will retry in the background."`

- Bad: `"Validation error"`
- Good: `"Draft not saved: note data validation / schema check — required field 'title' is empty."`

## User-Facing Messages (UI)

- [ ] Three components present (consequence + module/process + cause); cause may be softened for end users but never dropped
- [ ] Plain language — no raw exception types, stack traces, or error codes as the only content
- [ ] Nonjudgmental tone — avoid `invalid`, `illegal`, `incorrect`; state the condition, not blame
- [ ] Positioned near the source of the error (adjacent field, inline, not only a global toast)
- [ ] Offers next step when one exists — retry, contact support, link to docs, edit field
- [ ] Preserves user input — never wipe the form on error
- [ ] Not shown prematurely (e.g. on blur of an empty required field the user hasn't reached yet)
- [ ] Accessibility: `role="alert"` / `aria-live="assertive"` for critical, `aria-live="polite"` for inline; never indicate error by color alone

## Developer-Facing Messages (Logs, Exceptions, Telemetry)

- [ ] Three components present — log wording may be more technical than UI wording, still all three
- [ ] Includes correlation ID / request ID when available (ties log to user report)
- [ ] Includes relevant identifiers (user ID, resource ID, version) — no secrets, tokens, PII, or full request bodies
- [ ] Distinguishes symptom from cause (Google SRE): "what's broken" at the top, "why" in structured context
- [ ] Logs at the right level: `error` for unexpected + actionable, `warn` for recoverable, `info` for lifecycle, `debug` for diagnostics only
- [ ] Thrown exception messages readable standalone — assume the caller sees only `.message`, not the surrounding context

## Anti-Patterns

- Swallowing errors silently: `catch { /* ignore */ }` without a log or rethrow
- Re-wrapping an error and losing the original cause — always chain (`cause: err` / `{ cause }`)
- Generic `catch (e) { throw new Error('Something went wrong') }` — the original stack is lost
- Different wording for the same failure across call sites — makes grep/alert rules brittle; pick one phrasing per module/process
- Humor or puns in error copy — becomes stale when users hit it repeatedly
- Logging secrets, JWTs, full auth headers, or raw request bodies in error paths

## When Editing an Error Path

- [ ] Audit nearby messages in the same module for the three-component rule — bring them into compliance in the same change when scope allows
- [ ] Check both the UI string and the log line — fixing one without the other is a half-fix
- [ ] Grep for the previous message text across the repo before renaming — alert rules and tests may depend on it

## Sources

- NN/g — _Error-Message Guidelines_ (communication, efficiency, visibility heuristics)
- Google SRE Book, Chapter 6 — _Monitoring Distributed Systems_ ("what's broken" vs "why")
