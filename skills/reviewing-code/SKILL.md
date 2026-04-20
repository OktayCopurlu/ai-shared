---
name: reviewing-code
description: 'Proactive code review using a 4-layer heuristic: surface correctness, test coverage gaps, bounded refactors, and architecture attention signals. USE FOR: reviewing PRs, self-review before creating a PR, evaluating changed files. Use when user says "review this", "check this PR", "anything I missed", or "review my changes".'
---

# Code Review — 4-Layer Heuristic

Review code changes using four layers, from mechanical to architectural. Layers 1–3 produce **fixes or suggestions**; layer 4 produces **questions only**.

Finish the mechanical scan before opining on architecture.

## Input

Review operates on a diff — staged/unstaged changes, a PR diff, or changed files the user points to.

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

**Check for:** missing tests for domain invariants / business rules (a test that fails if the rule is violated, not just if the happy path breaks), missing error state tests, uncovered loading/pending branches, missing edge cases, snapshot tests without behavioral assertions, new code branches with no test, mocks that are never asserted on.

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

- Always run all 4 layers. Do not skip a layer because an earlier one had findings.
- Layer 1–3 findings are actionable. Layer 4 findings are informational.
- Do not suggest changes to files outside the PR diff.
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
