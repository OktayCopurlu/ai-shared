---
name: reviewing-code
description: 'Proactive code review using line-by-line changed-hunk inspection, file-type lenses, and a 4-layer heuristic: surface correctness, test coverage gaps, bounded refactors, and architecture attention signals. USE FOR: reviewing PRs, review this PR for missing tests, self-review before creating a PR, evaluating changed files. Use when user says "review this", "check this PR", "anything I missed", "review my changes", or asks for line-by-line code review.'
---

# Code Review — 4-Layer Heuristic

Review code changes line-by-line inside each changed hunk, then apply four layers from mechanical to architectural. Layers 1–3 produce **fixes or suggestions**; layer 4 produces **questions only**.

Finish the mechanical scan before opining on architecture.

## Input

Review operates on a diff — staged/unstaged changes, a PR diff, or changed files the user points to.

## Non-Negotiable Review Contract

Do not review from the file list, diff summary, or intuition alone. For every changed file:

- read each changed hunk with enough surrounding context to understand intent
- inspect every added or modified line, including template, style, test, and config-only hunks
- decide whether each hunk is `OK`, `finding`, `question`, or `unnecessary`
- ask whether the change is required for the PR goal, or whether a smaller local change would do the same job
- report all findings, questions, and unnecessary changes with exact file/line references

Clean hunks do not need one comment each, but the final response must include brief evidence of coverage, such as `Reviewed changed hunks in: Component.vue template/script/style, useThing.ts, Component.spec.ts`.

Do not claim a complete review if any changed hunk was not inspected. If the diff is too large for full confidence, say exactly which files or hunks received lower-confidence review.

## Changed Hunk Pass

Run this pass before the four layers.

For each changed hunk, ask:

- **Necessity:** Does this changed line need to exist for the PR goal, or is it drive-by cleanup/noise?
- **Simpler expression:** Could this be written with less branching, fewer wrappers, fewer props, fewer mocks, or an existing local helper?
- **Local consistency:** Does it match nearby naming, component patterns, test style, composables, CSS conventions, and data-flow patterns?
- **Behavior:** What user-visible, API-visible, state, error, loading, permission, analytics, or accessibility behavior changed?
- **Removal risk:** Did this delete a guard, state branch, fallback, event, class, attribute, test assertion, or type constraint that mattered?

Use this hunk decision internally:

| Decision | Meaning | Output |
|---|---|---|
| `OK` | Required, readable, locally consistent | Usually no per-line output |
| `finding` | Bug, risk, missing test, or concrete improvement | Report with severity and line |
| `question` | Intent unclear or architecture signal | Ask a direct question |
| `unnecessary` | Change does not support PR goal or adds noise | Ask to revert or justify |

## File-Type Review Lenses

Apply the relevant lens to every changed file type. For Vue single-file components, apply template, script, and style lenses separately.

### Template / Markup

Check for: unnecessary wrappers, duplicated conditions, unclear slot usage, excessive inline expressions, missing keys, unstable `v-if`/`v-for` combinations, broken semantics, missing labels/alt text/ARIA where needed, event handlers doing too much, and layout changes hidden inside markup.

Ask: Could this template be flatter, more semantic, or closer to existing component patterns without changing behavior?

### Script / Component Logic

Check for: derived state stored as mutable state, watchers used where computed state would fit, side effects in setup/render paths, missing null/error/loading handling, unused imports/props/emits, broad types, duplicated transformation logic, lifecycle cleanup gaps, and unclear event/data ownership.

Ask: Is the state/data flow obvious from the changed lines, and can any branch or helper be simplified locally?

### Composables / Hooks / Utilities

Check for: single-consumer abstractions, hidden global state, stale closures, missing cleanup, unstable returned object shapes, weak typing at boundaries, swallowed errors, duplicated API normalization, and tests that miss edge cases.

Ask: Does this composable earn its abstraction, or would the logic be clearer at the call site for now?

### Tests

Check for: assertions that only mirror implementation, snapshots without behavioral checks, over-mocked collaborators, mocks that are never asserted, test names that hide the rule being protected, missing negative/error/loading cases, duplicated fixture literals, and optional chaining that can make `undefined === undefined` pass.

Ask: Would this test fail for the real bug or business rule the PR is meant to protect?

### CSS / SCSS / Styling

Check for: duplicate selectors, specificity creep, magic spacing/colors instead of tokens, responsive breakage, text overflow, layout shift, hidden focus states, style changes that affect unrelated children, dead classes, and class names not tied to the component’s intent.

Ask: Can this styling be scoped smaller, use an existing token/pattern, or avoid changing layout outside the intended element?

### Config / Types / Docs

Check for: broad config changes, weakened type safety, generated or lockfile churn without dependency intent, docs drifting from behavior, and examples that cannot run.

Ask: Is this change necessary for the PR, and is the blast radius clear?

## Auto-Scale Review Depth

Scale review effort based on diff size. Do not apply full-depth review to a 10-line typo fix, and do not single-pass a 300-line feature branch.

| Diff Size | Depth | What to do |
|---|---|---|
| < 50 lines | Single pass | Run all 4 layers once. |
| 50–199 lines | Standard | Run all 4 layers. |
| 200–499 lines | Deep | Run all 4 layers file-by-file instead of scanning the whole diff at once. |
| 500+ lines | Flag for split | Warn the author the PR is too large for effective review. Still review, but note that confidence is lower. |

Determine diff size early (e.g., `git diff --stat` or `gh pr diff <N> --stat | tail -1`) and state the chosen depth before starting.

## Review Mode

Choose the mode before running the 4 layers.

### `review-only`

Use this when the input is a PR URL, PR number, or GitHub review context.

Behavior:

- do not edit code
- do not write tests
- report findings only
- prefer PR comment format when replying on GitHub
- for Codex replies, list findings first by severity with file/line references

### `self-review`

Use this when the input is local staged/unstaged changes, changed files in the working tree, or the user's own branch before PR creation.

Behavior:

- findings still come first
- Layer 1 issues may be fixed inline when they are obvious and low-risk
- Layer 2 may hand off to `test` or `test-driven-development`, or be fixed in the same pass when appropriate
- keep fixes scoped to the current change only

## Mode Selection Rules

Determine mode in this order:

1. if the user explicitly says `review-only` or `self-review`, use that
2. if a PR URL or PR number is provided, use `review-only`
3. if the input is a local diff or changed local files, use `self-review`
4. if the context is ambiguous, default to `review-only` to avoid unexpected edits

## Layer 1 — Surface Correctness

Scan every changed file for mechanical issues. Load `applying-coding-style` first — naming and comment rules come from there.

**Output:** File, line, one-line fix. In `self-review`, apply directly when confident. In `review-only`, report the fix without editing. Flag when ambiguous.

## Layer 2 — Test Coverage Gaps

For every changed function/component, check the test file.

**Check for:** missing tests for domain invariants / business rules (a test that fails if the rule is violated, not just if the happy path breaks), missing error state tests, uncovered loading/pending branches, missing edge cases, snapshot tests without behavioral assertions, new code branches with no test, mocks that are never asserted on, hand-rolled stub components that re-implement production logic, single `it` blocks with many unrelated assertions, hardcoded fixture values duplicated in expectations, optional chaining inside `expect(...).toBe(...)` that can pass as `undefined === undefined`.

**Output:** `[file] missing test for: <scenario>`. In `review-only`, describe what's missing and do not write the tests. In `self-review`, either describe the gap or address it via `test` or `test-driven-development` when in scope.

**When Layer 2 is N/A:** docs-only changes, formatting-only changes, generated files, config/types changes with no behavior impact, or explicitly temporary experiment code that should not drive new permanent coverage. State `N/A — no persistent behavior change to cover.`

## Layer 3 — Bounded Refactor Signals

Patterns that could be simplified **within the scope of this PR** only.

**Check for:** duplicated logic across 2+ changed files, repeated inline logic that should be a hook/utility, trivial pass-through wrappers, copy-pasted test setup.

**Output:** Suggest extraction with brief rationale. Scoped to PR diff only — never suggest refactors in untouched code.

## Layer 4 — Architecture Attention Signals

Questions only — never directives. Direct senior reviewer attention.

**Flag when:**
- Global state with a single consumer
- New abstraction used in only one place
- Cross-domain import (checkout ← account)
- 5+ files with the same pattern change
- Client-side computation of server-derivable data
- Component prop interface beyond 8 props

**Output:** Question per signal with file/line. Never state an architectural decision.

## Output Format

Use the **structured format** for self-review and standalone reviews:

```
## Code Review — [scope description]

### Changed Hunk Coverage
- Reviewed: [file/type areas, e.g. Component.vue template/script/style, useThing.ts, Component.spec.ts]
- Lower confidence: [only if any hunk/file could not be fully inspected]
- Unnecessary changes: ✅ None found
  OR
- ⚠️ [file:line] change appears unrelated to PR goal → revert or justify

### Layer 1 — Surface Correctness
- ✅ No issues found
  OR
- ⚠️ [file:line] issue description → fix description

### Layer 2 — Test Coverage Gaps
- ✅ All changed code has test coverage
  OR
- 🧪 [test-file] missing test for: scenario description

### Layer 3 — Bounded Refactors
- ✅ No duplication detected
  OR
- 🔧 [files involved] suggestion description

### Layer 4 — Architecture Signals
- ✅ No signals detected
  OR
- ❓ [file:line] question for senior reviewer
```

When replying directly to the user:

- start with findings ordered by severity, each with file/line references
- keep summaries brief and place them after the findings
- include the layer grouping only when it adds clarity for the user or the workflow
- include changed-hunk coverage evidence, even when there are no findings
- if there are no findings, say so explicitly and mention any residual risk or testing gap

## PR Comment Format

When writing comments on a pull request (GitHub review comments), use one-line format per finding:

```
L<line>: <severity> <problem>. <fix>.
```

Multi-file diffs use: `<file>:L<line>: <severity> <problem>. <fix>.`

**Severity prefixes:**
- `🔴 bug:` — broken behavior, will cause incident
- `🟡 risk:` — works but fragile (race, missing null check, swallowed error)
- `🔵 nit:` — style, naming, micro-optim. Author can ignore
- `❓ q:` — genuine question, not a suggestion

**Drop from PR comments:**
- "I noticed that...", "It seems like...", "You might want to consider..."
- "This is just a suggestion but..." — use `nit:` instead
- "Great work!", "Looks good overall but..." — say once at top, not per comment
- Restating what the line does — reviewer can read the diff
- Hedging ("perhaps", "maybe", "I think") — if unsure use `❓ q:`

**Keep in PR comments:**
- Exact line numbers
- Exact symbol/function/variable names in backticks
- Concrete fix, not "consider refactoring this"
- The *why* if the fix isn't obvious from the problem statement

**Examples:**

❌ "I noticed that on line 42 you're not checking if the user object is null before accessing the email property. This could potentially cause a crash."

✅ `L42: 🔴 bug: user can be null after .find(). Add guard before .email.`

❌ "It looks like this function is doing a lot of things and might benefit from being broken up into smaller functions."

✅ `L88-140: 🔵 nit: 50-line fn does 4 things. Extract validate/normalize/persist.`

❌ "Have you considered what happens if the API returns a 429?"

✅ `L23: 🟡 risk: no retry on 429. Wrap in withBackoff(3).`

**Auto-Clarity exception:** Drop terse format for security findings (CVE-class bugs need full explanation), architectural disagreements (need rationale), and onboarding contexts (author is new, needs the "why"). Write a normal paragraph, then resume terse.

## Rules

- The Changed Hunk Pass is mandatory before the four layers.
- Every changed hunk needs an internal `OK`, `finding`, `question`, or `unnecessary` decision.
- Always run all 4 layers. Do not skip a layer because an earlier one had findings.
- Layer 1–3 findings are actionable. Layer 4 findings are informational.
- Do not suggest changes to files outside the PR diff.
- Do not treat generated files, lockfiles, snapshots, docs, or styles as automatically safe; inspect their changed hunks too, then mark Layer 2 as N/A when appropriate.
- Do not repeat findings already covered by lint or type-check errors.
- Load `applying-coding-style` before running Layer 1 — naming and comment rules come from there.
- When called from `git-workflow`, run before creating the PR. Offer to fix Layer 1 issues inline.
- When called from the `/address-review` prompt, run after triaging Copilot comments as an additional pass.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The tests pass, so it's fine" | Tests don't catch naming issues, dead code, architecture drift, or security holes. |
| "Layer 4 is just noise" | Architecture signals are the highest-value findings. Skipping them lets coupling accumulate silently. |

## Red Flags

- "LGTM" without evidence of actual review
- Layer 4 signals consistently ignored across multiple PRs
- Reviewing only the files you're familiar with and skipping the rest

## See Also

- `applying-coding-style` — naming and comment rules used in Layer 1
- `debugging` — when a review uncovers a bug that needs triage
- `~/.ai-shared/references/security-checklist.md` — for security-focused review passes
- `~/.ai-shared/references/testing-patterns.md` — for evaluating test quality in Layer 2
- `~/.ai-shared/references/accessibility-checklist.md` — for accessibility checks in Layer 1 and Layer 4
- `~/.ai-shared/references/performance-checklist.md` — for performance checks in Layer 4
- `~/.ai-shared/references/cognitive-debt.md` — when reviewing agent-generated code the author never walked through
