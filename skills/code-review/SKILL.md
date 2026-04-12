---
name: code-review
description: 'Proactive code review using a 4-layer heuristic: surface correctness, test coverage gaps, bounded refactors, and architecture attention signals. USE FOR: reviewing PRs, self-review before creating a PR, evaluating changed files. Use when user says "review this", "check this PR", "anything I missed", or "review my changes".'
---

# Code Review — 4-Layer Heuristic

Review code changes using four layers, from mechanical to architectural. Layers 1–3 produce **fixes or suggestions**; layer 4 produces **questions only**.

Finish the mechanical scan before opining on architecture.

## Input

Review operates on a diff — staged/unstaged changes, a PR diff, or changed files the user points to.

## Layer 1 — Surface Correctness

Scan every changed file for mechanical issues. Load `coding-style` first — naming and comment rules come from there.

**Check for:** unused imports/vars, incorrect prop types, `coding-style` naming violations, redundant conditions, dead code branches, hardcoded values that should be config, leftover console logs/debugger statements.

**Output:** File, line, one-line fix. Apply directly when confident. Flag when ambiguous.

## Layer 2 — Test Coverage Gaps

For every changed function/component, check the test file.

**Check for:** missing error state tests, uncovered loading/pending branches, missing edge cases, snapshot tests without behavioral assertions, new code branches with no test, mocks that are never asserted on.

**Output:** `[file] missing test for: <scenario>`. Describe what's missing — do not write the tests.

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
- Load `coding-style` before running Layer 1 — naming and comment rules come from there.
- When called from `git-workflow`, run before creating the PR. Offer to fix Layer 1 issues inline.
- When called from `address-review`, run after triaging Copilot comments as an additional pass.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The tests pass, so it's fine" | Tests are necessary but not sufficient. They don't catch naming issues, dead code, architecture drift, or security holes. |
| "It's a small change, no review needed" | Small changes can introduce subtle bugs. Every diff benefits from a structured pass. |
| "I wrote it, I know it's correct" | Authors are blind to their own assumptions. The 4-layer heuristic catches what familiarity hides. |
| "Layer 4 is just noise" | Architecture signals are the highest-value findings. Skipping them lets coupling and complexity accumulate silently. |
| "I'll check test coverage later" | Later never comes. Layer 2 takes minutes and prevents shipping untested branches. |
| "Refactor suggestions slow things down" | Layer 3 is scoped to the PR. Small consolidations now prevent large refactors later. |

## Red Flags

- Review that only checks if tests pass (ignoring Layers 1, 3, 4)
- "LGTM" without evidence of actual review
- Layer 4 signals consistently ignored across multiple PRs
- No test coverage gaps ever flagged (suggests Layer 2 is being skipped)
- Review findings not categorized by layer — makes it unclear what's actionable vs. informational
- Reviewing only the files you're familiar with and skipping the rest

## Verification

After completing the review:

- [ ] All 4 layers were executed — none skipped
- [ ] Layer 1 issues are either fixed or flagged with file and line
- [ ] Layer 2 gaps are listed with specific missing scenarios
- [ ] Layer 3 suggestions are scoped to the PR diff
- [ ] Layer 4 signals are framed as questions, not directives
- [ ] Output follows the standard format with layer headings

## See Also

- `coding-style` — naming and comment rules used in Layer 1
- `debugging` — when a review uncovers a bug that needs triage
- `references/security-checklist.md` — for security-focused review passes
- `references/testing-patterns.md` — for evaluating test quality in Layer 2
