# Delivery Pipeline Step Inventory

Experimental reference for the complete delivery pipeline step list. This captures the current understanding of what `prompts/pipeline.prompt.md` orchestrates, including the detailed sub-steps inside implementation, PR review, and review feedback handling.

## Full Step List

| # | Phase | Step | What Happens | Output |
|---:|---|---|---|---|
| 0.1 | Constitute | Load global rules | Read `instructions.md`. | Session rules are ready. |
| 0.2 | Constitute | Load repo rules | Read repo `AGENTS.md` or `.github/copilot-instructions.md` when present. | Repository-specific behavior is clear. |
| 0.3 | Constitute | Apply pipeline contract | Preserve the phase order and do not advance before required earlier outputs exist. | Fixed delivery order. |
| 1.1 | Clarify | Decide whether Clarify is needed | Check whether the ticket is small and crisp or vague and decision-heavy. | Skip/run decision. |
| 1.2 | Clarify | Restate the problem | Summarize the request in one short paragraph. | Shared problem framing. |
| 1.3 | Clarify | Read repo context when needed | Run read-only exploration or a subagent to extract relevant constraints. | Technical context. |
| 1.4 | Clarify | Ask one question at a time | Walk the decision tree in dependency order. | Incremental decisions. |
| 1.5 | Clarify | Include recommendation and trade-off | For each question, state the decision, recommended answer, and trade-off. | Easier human decision-making. |
| 1.6 | Clarify | Walk the design tree | Cover goal, users, scope, data, UX, failure states, rollout, analytics, testing, and non-goals. | Hidden decisions become visible. |
| 1.7 | Clarify | Separate human-owned decisions | Mark PM, design, domain, or team calls as unresolved. | Open questions. |
| 1.8 | Clarify | Stop at the first useful slice | Stop when remaining questions would not materially change the first vertical implementation slice. | Alignment complete. |
| 1.9 | Clarify | Summarize alignment | List decisions made, open questions, out of scope items, and recommended next step. | Usually `spec`, `project-design`, prototype, or investigation. |
| 2.1 | Specify | Decide whether Spec is needed | Skip when the ticket already has spec-quality AC and no hidden decisions. | Skip/run decision. |
| 2.2 | Specify | Identify input type | Determine whether the input is Jira, rough description, Slack summary, Figma link, or similar. | Requirement source type. |
| 2.3 | Specify | Read Jira when available | Read the full Jira detail. | Ticket context. |
| 2.4 | Specify | Read linked context | Open Figma, Contentful, wiki pages, linked tickets, and other relevant URLs. | Full requirement context. |
| 2.5 | Specify | Separate clear vs ambiguous items | Identify what is settled and what needs decisions. | Ambiguity list. |
| 2.6 | Specify | Ask for problem when no ticket exists | Ask what the user wants to achieve, framed as the problem rather than the solution. | Problem definition. |
| 2.7 | Specify | Identify affected area | Determine repo, page, flow, and users. | Scope context. |
| 2.8 | Specify | Write Problem Statement | Explain what happens today, why it is a problem, and who is affected. | Spec section. |
| 2.9 | Specify | Write Proposed Scope | State required changes, out-of-scope items, and observable acceptance criteria. | Scope and AC. |
| 2.10 | Specify | Write Open Questions | Capture missing assumptions, edge cases, owner decisions, and dependencies. | Open questions. |
| 2.11 | Specify | Write Risks | Identify what could go wrong and what remains unknown. | Risk list. |
| 2.12 | Specify | Write Work Shape | Identify the first user-observable vertical slice and likely follow-up slices. | Implementation shape. |
| 2.13 | Specify | Calibrate depth | Keep small work short, medium work complete, and large initiatives routed to project design. | Appropriate spec depth. |
| 2.14 | Specify | Choose output channel | Output inline, update Jira, or create a Jira ticket. | Published spec. |
| 3.1 | Implement | Start implementation | Begin from a ticket key or link. | Execution starts. |
| 3.2 | Implement | Read full Jira detail | Read summary, description, AC, and links. | Ticket contract. |
| 3.3 | Implement | Read linked implementation context | Review Figma, Contentful, wiki pages, linked tickets, and relevant URLs. | Required context is ready. |
| 3.4 | Implement | Check linked-context access | Stop and report a blocker if required context cannot be accessed. | Continue or blocker. |
| 3.5 | Implement | Determine target repository | Identify where the change belongs. | Target repo. |
| 3.6 | Implement | Enter workspace | Move into the configured workspace. | Correct working area. |
| 3.7 | Implement | Verify repository | Confirm the workspace matches the target repo. | Wrong-repo risk closed. |
| 3.8 | Implement | Check branch state | Reuse an in-progress ticket branch when available. | Branch decision. |
| 3.9 | Implement | Create ticket branch when needed | Create a new branch containing the Jira key for todo work. | Ticket branch. |
| 3.10 | Implement | Apply git workflow | Follow branch naming, base branch, and remote sync rules. | Clean git start. |
| 3.11 | Implement | Load coding style | Load `applying-coding-style` and apply it to code written from this point forward. | Code standard active. |
| 3.12 | Implement | Read test context | Read existing tests first when behavior changes. | Test baseline. |
| 3.13 | Implement | Identify domain invariants | Capture business rules, auth boundaries, state transitions, pricing or rounding rules, and other must-preserve behavior. | Test targets. |
| 3.14 | Implement | Decide test coverage | Add or update tests for permanent/shared behavior; consciously skip only for short-lived experiments when appropriate. | Test strategy. |
| 3.15 | Implement | Run UI discovery | Search shared/design-system components and similar code patterns before building UI. | Reuse opportunities. |
| 3.16 | Implement | Verify component API | Check whether existing component props or slots cover the ticket's needs. | Use, extend, or build decision. |
| 3.17 | Implement | Extract Figma tokens | Capture spacing, padding, margin, gap, font, color, radius, and border values from Figma. | Style source data. |
| 3.18 | Implement | Match design variables | Prefer design-system variables; use raw Figma values only when no variable matches. | Consistent UI. |
| 3.19 | Implement | Evaluate accessibility needs | Load `a11y-audit` for forms, dialogs, menus, navigation, keyboard interaction, focus handling, or error states. | Accessibility lens active. |
| 3.20 | Implement | Evaluate security needs | Apply security review for auth, input handling, secrets, or data-boundary changes. | Security lens active. |
| 3.21 | Implement | Shape large work | Break large, cross-layer, or under-specified work into vertical slices. | Implementable slices. |
| 3.22 | Implement | Read minimum code context | Read the files and existing patterns needed for the change. | Code context. |
| 3.23 | Implement | Change code | Implement the fix close to the real source of truth. | Working diff. |
| 3.24 | Implement | Keep scope focused | Avoid unnecessary refactors while making structural changes when correctness requires them. | Focused correct solution. |
| 3.25 | Implement | Check implementation completeness | Confirm scope is implemented, context is incorporated, and no core work is missing. | Diff ready for gates. |
| 3.26 | Quality Gates | Find repo validation commands | Use repository-defined commands instead of inventing custom gates. | Correct gate list. |
| 3.27 | Quality Gates | Run lint | Execute the repo lint gate. | Pass/fail result. |
| 3.28 | Quality Gates | Run type checks | Execute the repo type gate. | Pass/fail result. |
| 3.29 | Quality Gates | Run unit tests | Execute relevant tests. | Pass/fail result. |
| 3.30 | Quality Gates | Run coding-style review | Review changed files against `applying-coding-style`. | Style fixes. |
| 3.31 | Quality Gates | Widen scope for shared packages | Cover real blast radius when shared packages changed. | Impact covered. |
| 3.32 | Quality Gates | Apply failure policy | Fix and rerun implementation-caused failures; record likely unrelated/flaky failures. | Gate decision. |
| 3.33 | Cross-check | Map AC to diff | Match every AC item to concrete code evidence. | AC coverage. |
| 3.34 | Cross-check | Check full spec behavior | Verify failure states, repeat behavior, edge cases, and invariants beyond AC bullets. | Contract coverage. |
| 3.35 | Cross-check | Return to implementation when missing | Implement any uncovered AC or contract behavior before continuing. | Complete coverage. |
| 3.36 | Cross-check | Record spec gaps | Flag behavior that had to be invented because the spec was silent. | PR-visible spec gap. |
| 3.37 | Manual QA | Choose QA depth | Scale QA by risk, user-facing behavior, diff size, statefulness, and blast radius. | QA plan type. |
| 3.38 | Manual QA | Load manual QA when needed | For medium, large, risky, or user-facing work, create a focused QA plan. | QA plan. |
| 3.39 | Manual QA | Execute QA | Run primary scenarios and diff-driven regression checks. | QA verdict. |
| 3.40 | UI Validation | Decide UI validation need | Require validation for visible UI, layout, styling, component, or Figma changes. | UI validation decision. |
| 3.41 | UI Validation | Load UI validation | Gather browser-level evidence instead of relying on screenshots alone. | UI evidence. |
| 3.42 | UI Validation | Apply recovery protocol | Try preview, local, route, data, flag, and component-surface fallbacks before marking blocked. | Recovery attempts. |
| 3.43 | Manual QA | Fix QA/UI failures | Fix implementation-caused QA or UI validation failures. | New diff. |
| 3.44 | Manual QA | Rerun gates after QA fixes | If QA fixes changed code, rerun quality gates. | Clean result. |
| 3.45 | Blocker | Stop on real blockers | Pause for contradictory requirements, inaccessible context, repo ambiguity, unsafe repo state, or missing credentials. | `pause-for-human`. |
| 3.46 | Implement Output | Report implementation result | Summarize implementation, gates, QA, and any spec gaps. | Implementation result. |
| 3.47 | Implement Output | Add Senior Reflection | Add a short 3-4 bullet senior reflection. | Reflection. |
| 3.48 | Implement Output | Add wins or decision nudges | Add wins-log and decision-journal nudges when appropriate. | Closing note. |
| 4.1 | Open PR | Load git workflow | Apply commit, push, and PR rules. | PR workflow active. |
| 4.2 | Open PR | Commit changes | Commit staged changes with a clear message. | Commit. |
| 4.3 | Open PR | Push branch | Push the ticket branch. | Remote branch. |
| 4.4 | Open PR | Write PR title | Follow git-workflow title rules. | PR title. |
| 4.5 | Open PR | Write PR body | Use the git-workflow PR Description Template exactly. | Reviewer-ready PR body. |
| 4.6 | Open PR | Avoid extra sections | Do not add standalone sections unless the repo documents them as convention. | Template discipline. |
| 4.7 | Open PR | Request Copilot review | Ask Copilot to review the PR. | Automated review starts. |
| 4.8 | Open PR | Add wins-log nudge | Remind the user to add a wins entry when the PR is non-trivial. | Closing note. |
| 5.1 | Self-review | Identify PR input | Use PR URL or number and repo. | Review target. |
| 5.2 | Self-review | Read GitHub context | Read PR description, diff, and linked issues. | PR context. |
| 5.3 | Self-review | Extract Jira ID | Find the ticket ID from title, body, or branch name. | Requirement source. |
| 5.4 | Self-review | Read Jira ticket | Read summary, description, AC, and links. | AC source. |
| 5.5 | Self-review | Fall back when no ticket exists | Use PR description, wiki pages, or other linked requirements. | Alternative requirements. |
| 5.6 | Self-review | Read wiki/spec links | Extract relevant requirements from Confluence or other docs. | Additional requirements. |
| 5.7 | Self-review | Find preview URL | Check deployments, status checks, then PR comments. | Preview target. |
| 5.8 | Self-review | Measure diff size | Use diff size to choose review depth. | Review depth. |
| 5.9 | Self-review | Extract experiment or flag context | Identify A/B test keys, groups, and override mechanisms when relevant. | Variant context. |
| 5.10 | Self-review | Present context summary | State AC list, wiki requirements, preview URL, diff size, and chosen depth. | Review preface. |
| 5.11 | AC Coverage | Map every AC to diff | Find files or changes that address each AC. | Coverage table. |
| 5.12 | AC Coverage | Mark coverage status | Label each AC as covered, partial, or not covered. | Gap list. |
| 5.13 | AC Coverage | Map tracking specs | Compare expected event names, properties, and values to implementation. | Tracking coverage. |
| 5.14 | Code Review | Load reviewing-code | Run the 4-layer code review heuristic. | Findings. |
| 5.15 | Code Review | Check surface correctness | Look for bugs and regression risks. | Correctness findings. |
| 5.16 | Code Review | Check test gaps | Look for missing regression and invariant coverage. | Test findings. |
| 5.17 | Code Review | Check bounded refactors | Identify small improvements that reduce meaningful risk or complexity. | Refactor notes. |
| 5.18 | Code Review | Check architecture signals | Review whether the PR moves the codebase in a healthy direction. | Architecture notes. |
| 5.19 | Functional Validation | Check CI status | Scope validation based on passing checks, failing checks, or missing preview. | Validation plan. |
| 5.20 | Functional Validation | Try fallback surfaces | Use local branch, known local URL, Storybook/component playground, or direct route when preview is missing. | Recovery attempts. |
| 5.21 | Manual QA Review | Load manual QA | Build a QA plan from ticket requirements, diff, and preview. | QA plan. |
| 5.22 | Manual QA Review | Execute QA | Run primary scenarios and diff-driven regression checks. | QA verdict. |
| 5.23 | UI Review | Load UI validation when UI changed | Validate visible UI in browser. | UI verdict. |
| 5.24 | UI Review | Run Figma token check | Compare computed styles against Figma spacing, typography, color, and border values. | Fidelity evidence. |
| 5.25 | A11y Review | Load a11y-audit when interactive UI changed | Check focus, keyboard, labels, and error states. | A11y notes. |
| 5.26 | Tracking Review | Verify events | Use console/network evidence to verify event names, properties, and actions. | Tracking verdict. |
| 5.27 | A/B Review | Verify control and treatment | Check variant rendering and variant tracking properties. | Variant verdict. |
| 5.28 | Self-review Output | Write review report | Include context, AC table, code review, validation, recovery, tracking, and variants. | Full PR review. |
| 5.29 | Self-review Output | Give verdict | Mark Pass, Pass with notes, or Fail. | Review result. |
| 5.30 | Self-review Output | Add Senior Reflection | Add a short reviewer-lens reflection. | Closing note. |
| 6.1 | Address Feedback | Fetch PR comments | Fetch Copilot review comments. | Comment list. |
| 6.2 | Address Feedback | Read each comment | Read comment text and the referenced code context. | Evaluation context. |
| 6.3 | Address Feedback | Evaluate comment validity | Decide whether the comment is valid, invalid, or partially valid. | Triage decision. |
| 6.4 | Address Feedback | Fix valid comments | Make a scoped fix in the correct location. | Review fix. |
| 6.5 | Address Feedback | Split partial comments | Fix the valid part and explain the invalid part. | Clear triage. |
| 6.6 | Address Feedback | Explain invalid comments | Reply briefly and respectfully with context. | Dismissal reply. |
| 6.7 | Address Feedback | Respond to every comment | Ensure no review comment is silently ignored. | Review hygiene. |
| 6.8 | Address Feedback | Review full diff again | Run `reviewing-code` across the full PR diff for findings not covered by comments. | Additional findings. |
| 6.9 | Address Feedback | Run gates when code changed | Run lint, type checks, and relevant unit tests. | Validation. |
| 6.10 | Address Feedback | Fix triage-caused gate failures | Fix and rerun when a failure comes from the triage fix. | Clean gate. |
| 6.11 | Address Feedback | Stage scoped files | Stage only files changed during triage. | Scoped staging. |
| 6.12 | Address Feedback | Create a new commit | Commit review feedback fixes without amending the original commit. | Visible review diff. |
| 6.13 | Address Feedback | Push updates | Push to the existing ticket branch without force-pushing. | Remote updated. |
| 6.14 | Address Feedback | Identify human reviewers | Use default reviewers, code ownership, or team conventions. | Reviewer list. |
| 6.15 | Address Feedback | Request human review | Assign human reviewers after triage is complete. | PR review-ready. |
| 6.16 | Address Feedback | Consider skill evolution | Capture reusable insight when the triage revealed a recurring or non-obvious pattern. | Learning loop. |
| 6.17 | Address Feedback | Set PR ready | Ensure valid comments are fixed and invalid comments are explained. | Final review-ready PR. |

## One-Line Summary

Load rules -> clarify when needed -> specify the work -> implement -> run gates and QA -> open PR -> self-review the PR -> triage feedback -> hand off for human review.
