---
name: code-review
description: 'Proactive code review using a 4-layer heuristic: surface correctness, test coverage gaps, bounded refactors, and architecture attention signals. USE FOR: reviewing PRs, self-review before creating a PR, evaluating changed files. Use when user says "review this", "check this PR", "anything I missed", or "review my changes".'
---

# Code Review — 4-Layer Heuristic

Review code changes using four layers, from mechanical to architectural. Each layer has a clear boundary: layers 1–3 produce **fixes or suggestions**; layer 4 produces **questions only**.

## When to Use

- Self-review before creating a PR (called from `pr-workflow`)
- Standalone review of a PR or set of changed files
- Supplement to `address-review` when triaging review comments

## Input

Review operates on a diff — either:

- the staged/unstaged changes in the working tree
- the diff of a pull request
- a set of changed files the user points to

## Layer 1 — Surface Correctness

Scan every changed file for mechanical issues that don't require domain knowledge.

**Check for:**

- Missing or incorrect imports (unused imports, missing dependencies)
- Unused variables, parameters, or type declarations
- Incorrect or missing prop types / interface mismatches
- Inconsistent naming that violates `coding-style` conventions
- Redundant conditions (`if (x) return true; else return false;`)
- Dead code branches (unreachable code after early returns, impossible conditions)
- Hardcoded values that should be constants or config
- Console logs, debugger statements, or temporary code left in

**Output:** List each issue with file, line, and a one-line fix. Apply fixes directly when confidence is high. Flag for confirmation when ambiguous.

## Layer 2 — Test Coverage Gaps

For every changed component, function, or module, check the corresponding test file (if one exists).

**Check for:**

- No test for error states (API failure, thrown exceptions, rejected promises)
- No coverage for loading/pending branches
- Missing edge case for empty arrays, null inputs, or boundary values
- Snapshot tests without behavioural assertions (snapshots alone don't verify behaviour)
- New branches or conditions in the code that have no corresponding test case
- Mocked dependencies that are never asserted on (mock exists but no `expect` on it)

**Output:** List each gap as: `[file] missing test for: <scenario>`. Do not write the tests — describe what's missing so the developer can decide.

## Layer 3 — Bounded Refactor Signals

Look across the changed files for patterns that could be simplified **within the scope of this PR**.

**Check for:**

- Duplicated logic across 2+ changed files (same condition, same mapping, same formatting)
- A custom hook or utility that could replace repeated inline logic
- Trivial wrapper functions that add no value (single-line pass-through)
- Repeated ternary patterns that could be a shared helper
- Copy-pasted test setup that should be a test fixture or factory

**Output:** Suggest the extraction or consolidation with a brief rationale. Keep suggestions scoped to what the PR already touches — do not suggest refactors in untouched code.

## Layer 4 — Architecture Attention Signals

Flag patterns that **may** indicate an architectural concern. This layer produces **questions, not answers**. The goal is to direct senior reviewer attention to the right places.

**Flag when:**

- Global state is added but only one component consumes it → _"Global state added with a single consumer — is this intentional?"_
- A new abstraction (hook, utility, component) is used in only one place → _"New abstraction with single usage — is this premature?"_
- A cross-domain import is introduced (e.g. checkout module importing from account module) → _"Cross-domain dependency added — is this coupling acceptable?"_
- A PR touches 5+ files with the same pattern change → _"Same pattern changed in N files — should this be centralized?"_
- Data that could be server-derived is being computed client-side → _"This is derived client-side — should it come from the API?"_
- A component's prop interface grows beyond 8 props → _"Prop count is high — would slots or composition simplify this?"_

**Output:** Frame each signal as a question. Include the specific file/line that triggered it. Never state an architectural decision — only surface the signal.

## Output Format

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

## Rules

- Always run all 4 layers. Do not skip a layer because an earlier one had findings.
- Layer 1–3 findings are actionable. Layer 4 findings are informational.
- Do not suggest changes to files outside the PR diff.
- Do not repeat findings already covered by lint or type-check errors.
- Load `coding-style` before running Layer 1 — naming and comment rules come from there.
- When called from `pr-workflow`, run before creating the PR. Offer to fix Layer 1 issues inline.
- When called from `address-review`, run after triaging Copilot comments as an additional pass.
