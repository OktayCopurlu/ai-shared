---
name: structuring-prs
description: "Decide how to package a unit of work into reviewable pull requests — one PR or a stack — and carry it out. USE FOR: should this be one PR or several, planning a ticket as multiple PRs, stacking PRs, splitting a PR into two, breaking up a large PR, extracting a refactor from a feature PR, making a big diff easier to review. Use when scoping a ticket's delivery, when a change grows too large, or when the user asks to split, stack, or break up a pull request."
---

# Structuring Work into Pull Requests

Package a unit of work into pull requests — one PR or a stack — so each is easy to review. The seam-finding is the same whether you plan it up front or split an oversized PR later.

Packaging only: to slice a fuzzy or cross-layer ticket into the work itself, use `references/work-shaping.md` first, then package those slices here.

## One PR or a stack

Default to one PR; one vertical slice is usually one PR. Stack only when it clearly lowers review cost:

- A behaviour-preserving **refactor** can land under the feature, leaving the feature diff as just new behaviour — the most common, cleanest seam.
- A risky or foundational change is safer merged before the work built on it.
- A slice is too big for one review and has a real internal seam.

Keep one PR when the change is atomic, small, or its boundaries aren't clear yet. Don't split a feature into horizontal `data → api → ui` PRs — like work-shaping's horizontal plans, that delays integrated feedback.

Seam test: each PR must build, pass tests, and review on its own. If a slice can't stand alone, it isn't a seam — keep it together.

## Implement as a stack

Planned up front: branch each PR on the previous, open them stacked noting the merge order, land bottom-up, and rebase the branches above each one as it merges.

## Split an existing PR

1. **Map** — `gh pr diff <n>`, `git log --oneline <base>..<head>`. Mark each hunk refactor vs feature; note files touched by both.
2. **Refactor branch, off the original base.** Cherry-pick the refactor commit if it applies cleanly. If it's entangled with feature lines, **rebuild from content** instead: take each refactor file from the feature tip (`git checkout <tip> -- <file>`) and hand-edit shared files down to the refactor-only part.
3. **Feature branch, on the refactor branch.** Set its tree to the original tip (`git checkout <orig-tip> -- .`) and commit. Then verify it is **byte-identical** to the original: `git diff <orig-tip> --quiet`. A non-empty diff means a bad merge resolution — fix before pushing. This is the one check that proves you only repackaged.
4. **Publish.** Back up the original head (tag it), push the refactor branch, update the feature branch with **`--force-with-lease`**. Open the refactor PR (base = original base), then **re-point the feature PR's base** to the refactor branch — otherwise the feature diff still includes the refactor. Note the stack and merge order in the feature PR body.

## Guardrails

- Each PR builds, passes tests, and reviews on its own — or it isn't a valid split.
- Back up before any force-push; never plain `--force`.
- A split must not change behaviour: the byte-identical check is mandatory, not eyeballed.
- Work in an isolated clone, not a shared one.
- No AI attribution (inherits `git-workflow`); if you squash intermediate commits, say so.

## Watch For

- "It's entangled, I'll cherry-pick anyway" — the refactor commit often depends on earlier feature lines; rebuild from content when it won't apply on the base.
- "The diff looks the same" — only `git diff <orig> --quiet` proves it; a wrong resolution changes behaviour silently.
- Re-pointing the feature PR's base is what removes the refactor from its diff; changing the base label alone doesn't (the merge-base is unchanged). On a repo where `gh pr edit` is broken, use REST `PATCH .../pulls/<n>` with `base`.

## See Also

- `git-workflow` — branch/commit/PR conventions and the no-attribution rule
- `reviewing-code` — run before each PR
- `implementation` prompt — decide the breakdown while scoping a ticket
- `references/work-shaping.md` — slice the work into vertical slices before packaging it into PRs
