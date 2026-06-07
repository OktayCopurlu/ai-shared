# Experimental Delivery Pipeline Design

Last updated: 2026-06-07

This is an isolated experiment design. It must not modify or depend on the production `prompts/`, `skills/`, `self-evolution/`, or global instruction files. Any prototype runner, command prompt, schema, or run artifact should live under `experiment/delivery-pipeline/` until the approach proves itself.

## Senior Recommendation

Use OpenCode CLI for the experiment. It already fits the shape we want: a runner can call a command/prompt file, choose a model, pass a concise message, and let each phase run with fresh context.

The important design choice is not the CLI. It is the contract:

- the runner owns phase transitions
- each phase owns exactly one responsibility
- validator phases are instructed to behave as read-only and produce verdicts/fix requests
- implementer/fixer phases are the only phases expected to intentionally change code
- every phase reads immutable artifacts and writes a structured verdict
- failures create fix requests, not opportunistic refactors

## The 11 Phases

| # | Phase | Role Contract | Primary Model | Output |
|---:|---|---|---|---|
| 1 | Context Intake | read external context, write artifacts | Claude Sonnet 4.6  medium | context-packet |
| 2 | Implementation Planning | read artifacts/repo, write plan | Claude Opus 4.8 high | implementation-plan |
| 3 | Implementation | edit code, run focused checks | Claude Opus 4.8 high | implementation-report + diff |
| 4 | Unit Test + Test Review | read/run tests, write verdict | Claude Sonnet 4.6  medium | test-verdict |
| 5 | AC-Aware Code Review | read diff, write findings | Claude Opus 4.8 high | code-review-verdict |
| 6 | AC-Aware QA | run app/browser checks, write verdict | Claude Sonnet 4.6  high | qa-verdict |
| 7 | AC + Figma UI Validation | browser/Figma validation, write verdict | Claude Sonnet 4.6  high | ui-verdict |
| 8 | Create PR | git/GitHub write | Claude Sonnet 4.6 medium | pr-url + PR metadata |
| 9 | PR Code Review | read PR diff, write findings | Claude Opus 4.8 high | pr-code-review-verdict |
| 10 | QA on PR | preview/browser QA, write verdict | Claude Sonnet 4.6  high | pr-qa-verdict |
| 11 | UI Validation on PR | preview/Figma/browser validation | Claude Sonnet 4.6  high | pr-ui-verdict |

Model choice is intentionally phase-specific and should start at the cheapest tier likely to do the job:

- Use **GPT-5.4 mini** with `low` reasoning for mechanical, low-risk work such as PR creation.
- Use **Claude Sonnet 4.6** with `medium` reasoning for synthesis and test review, and `high` reasoning for QA or UI validation where browser/Figma evidence needs careful interpretation.
- Use **Claude Opus 4.8** with `high` reasoning for multi-file planning, complex implementation, unfamiliar domains, and judgment-heavy code review.
- Use **Claude Opus 4.8** with `high` as the stable premium fallback when Claude Opus is unavailable.
- Use **Gemini 3.5 Flash** (`gemini-3.5-flash`) as the stable low-cost fallback when GPT-5.4 mini is unavailable.
- Reference model docs: [Claude models](https://platform.claude.com/docs/en/about-claude/models), [OpenAI models](https://developers.openai.com/api/docs/models), [Gemini models](https://ai.google.dev/gemini-api/docs/models).

## Phase Boundaries

Each phase should do only its own job.

| Phase Type | Allowed | Forbidden |
|---|---|---|
| Context Intake | read ticket, read linked context, extract facts | write code, make implementation decisions beyond obvious blockers |
| Planner | inspect repo, propose plan, choose test/QA strategy | edit code |
| Implementer/Fixer | edit code, write tests, run focused checks | silently ignore fix requests |
| Test Reviewer | run/review tests, identify missing invariant coverage | refactor production code |
| Code Reviewer | review diff against AC and context | patch files directly |
| QA | execute scenarios, write expected vs actual, reproduction, fix request | refactor code |
| UI Validator | inspect browser and Figma specs, write precise visual findings | compare screenshots by eye, skip mobile without recovery |
| PR Creator | commit/push/open PR using artifacts | invent missing validation evidence |

Do not technically restrict validator tools in the first version. The prompt contract should tell validator phases not to edit code and to pass findings back as `fix_requests`. The runner may still detect unexpected source changes after a validator phase and record a protocol warning, but the design should not rely on hard tool restrictions as the main safety mechanism.

If QA, UI validation, test review, or code review finds a failure, the output is a structured `fix-request`. The runner sends that to the implementer/fixer phase. After a fix, the runner replays the minimum safety loop:

```text
Fix -> Unit Test + Test Review -> Code Review -> QA -> UI Validation
```

A code-changing fix must never jump directly to PR creation.

## Immutable Inputs

Every phase reads the same artifact chain instead of relying on chat memory:

```text
context-packet/
implementation-plan/
current-diff/
previous-verdicts/
```

The phase may append a new artifact, but it must not rewrite prior phase artifacts. If something in an earlier artifact is wrong, the phase writes a correction note in its own verdict.

## What Step 1 Passes Forward

Step 1 should not pass a free-form summary only. It should produce a `context-packet` with stable, reusable facts.

```text
runs/<run-id>/context-packet/
  ticket.md
  acceptance-criteria.json
  linked-context.md
  figma-specs.json
  constraints.md
  open-questions.md
  validation-targets.md
```

| Artifact | Purpose |
|---|---|
| `ticket.md` | Human-readable summary, source ticket link/key, ticket description, relevant comments |
| `acceptance-criteria.json` | Normalized AC IDs, text, source, priority, observable behavior |
| `linked-context.md` | Extracted facts from Figma, Contentful, Confluence, linked tickets, and other URLs |
| `figma-specs.json` | Token-level design data for UI implementation and validation |
| `constraints.md` | Repo, platform, flags, dependencies, rollout constraints, non-goals |
| `open-questions.md` | Blockers and human-owned decisions |
| `validation-targets.md` | QA scenarios, UI surfaces, browsers/viewports, tracking/experiment checks |

If `open-questions.md` contains a blocking decision, the runner stops with `pause-for-human` before planning.

## Figma Contract

Passing only the Figma URL is not enough. The context packet must contain extracted specs.

Important distinction: not every Figma detail is a design token. Colors, typography, spacing scales, radius, shadows, and borders may map to tokens. Width, height, x/y position, constraints, layer bounds, and responsive behavior are still required implementation specs even when they are not reusable tokens.

```json
{
  "source": "https://figma.com/...",
  "node": "...",
  "screens": ["desktop", "mobile"],
  "frame_exports": [
    {
      "name": "Desktop frame",
      "path": "artifacts/figma/desktop.png",
      "purpose": "implementation orientation only"
    }
  ],
  "components": [
    {
      "name": "Product card",
      "states": ["default", "hover", "loading", "error"],
      "bounds": {
        "x": 0,
        "y": 0,
        "width": 320,
        "height": 180
      },
      "layout": {
        "mode": "auto-layout | absolute | grid | unknown",
        "direction": "horizontal | vertical | none",
        "padding": {},
        "gap": null,
        "alignment": {},
        "constraints": {},
        "responsive_notes": []
      },
      "tokens": {
        "spacing": {},
        "typography": {},
        "colors": {},
        "borders": {},
        "radius": {},
        "effects": {},
        "opacity": {}
      },
      "content": {},
      "assets": [],
      "interactions": []
    }
  ],
  "notes": ["Prefer design-system variables when they match the extracted values."]
}
```

Recommended Figma spec fields:

| Category | Examples |
|---|---|
| Frame metadata | source URL, node ID, frame name, variant, viewport, breakpoint |
| Bounds and dimensions | x, y, width, height, min/max size, aspect ratio |
| Layout | auto-layout mode, direction, padding, gap, alignment, constraints, wrapping, grid settings |
| Spacing | margins, internal padding, item gaps, section offsets |
| Typography | font family, size, weight, line height, letter spacing, text transform |
| Color | fills, text colors, background colors, semantic variable match |
| Borders and radius | border width, color, style, corner radius per corner |
| Effects | shadows, blur, overlays, opacity |
| Assets | image/icon references, export names, intrinsic dimensions |
| Content | exact copy, truncation rules, empty/loading/error text |
| States | default, hover, active, focus, disabled, loading, empty, error |
| Responsive behavior | desktop/mobile frame mapping, stacking, resize constraints |
| Interactions | click targets, navigation, animation notes, transition timing |

UI validation rules:

- never rely on visual screenshot comparison as the main evidence
- extract Figma specs before implementation
- compare rendered computed styles against Figma specs: spacing, dimensions, typography, color, border, radius
- validate desktop and mobile when the UI is responsive or user-facing
- if mobile is hard to reach, use Playwright viewport/device emulation and document the exact recovery attempts
- do not mark mobile untested after one failed attempt
- if a feature flag or data state hides the UI, use documented override paths or create a fix request/blocker

Screenshots are still useful, but only as secondary context. Include Figma frame exports and browser screenshots beside the structured specs because they help the implementer understand composition, hierarchy, density, and visual intent. They must not be the pass/fail source of truth. Validation should cite computed style, DOM/layout measurements, and extracted Figma specs; screenshots can support the narrative.

## Planner Repository Inspection

Yes, the planner should inspect the repo, but in a constrained way.

The planner may:

- read repo instructions and relevant package scripts
- search for existing patterns and shared components
- inspect nearby tests
- identify likely files and validation commands
- propose vertical slices and risks

The planner must not:

- edit files
- do a broad repo scan without a reason
- guess implementation details when source context is available
- convert unresolved product/design choices into code decisions

Planner output should be concrete enough that the implementer can start without rediscovering everything, but not so detailed that it becomes fake certainty.

## Prompt/Command Design

Each phase command should be detailed because agents sometimes skip optional skills. The prompt should include the critical rules inline and also reference the relevant skill files when running inside this repo.

Recommended command structure:

```text
experiment/delivery-pipeline/commands/
  01-context-intake.md
  02-plan.md
  03-implement.md
  04-test-review.md
  05-code-review.md
  06-qa.md
  07-ui-validation.md
  08-create-pr.md
  09-pr-code-review.md
  10-pr-qa.md
  11-pr-ui-validation.md
```

Every command should include:

- role and permission model
- immutable inputs to read
- exact artifact to write
- required output schema
- stop conditions
- forbidden behavior
- relevant skills or rules copied in short form
- what counts as pass/fail/blocked/not-applicable

## Run Directory Contract

Each pipeline run owns one directory. The run directory is the source of truth for state, artifacts, human input, verdicts, and cleanup status.

```text
runs/<run-id>/
  state.json
  input.json
  run-log.jsonl
  human-request.md
  human-inputs/
  context-packet/
    ticket.md
    acceptance-criteria.json
    linked-context.md
    figma-specs.json
    constraints.md
    open-questions.md
    validation-targets.md
  implementation-plan/
    plan.md
    affected-files.json
    validation-plan.json
  current-diff/
    diff.patch
    changed-files.json
    summary.md
  verdicts/
    04-test-review.json
    05-code-review.json
    06-qa.json
    07-ui-validation.json
    09-pr-code-review.json
    10-pr-qa.json
    11-pr-ui-validation.json
  fix-requests/
    QA-001.json
    UI-001.json
  pr/
    metadata.json
    description.md
  phases/
    01-context-intake/
      output.json
      notes.md
    02-plan/
      output.json
      notes.md
    03-implement/
      output.json
      notes.md
```

Rules:

- each phase writes `phases/<phase>/output.json`
- each phase may write `phases/<phase>/notes.md` for human-readable detail
- shared artifacts go into canonical folders such as `context-packet/`, `implementation-plan/`, `current-diff/`, `verdicts/`, `fix-requests/`, and `pr/`
- prior phase artifacts are immutable; corrections are written as new verdicts or correction notes
- `state.json` is runner-owned; agents may read it but must not edit it directly
- `run-log.jsonl` is append-only

Recommended `state.json` shape:

```json
{
  "run_id": "20260524-153000-DSC-1234",
  "status": "running | paused | failed | finished | archived",
  "current_phase": "qa",
  "ticket": { "key": "DSC-1234", "url": "https://..." },
  "target_repo": { "path": "/path/to/repo", "branch": "DSC-1234-short-title" },
  "pr": { "url": null, "number": null },
  "phase_history": [],
  "fix_loop_count": 0,
  "stale_from_phase": null,
  "notification": { "last_event": null, "last_sent_at": null },
  "retention": { "mode": "active", "archive_path": null }
}
```

## Standard Phase Output

Each phase writes a machine-readable verdict.

```json
{
  "phase": "qa",
  "status": "pass | fail | blocked | not-applicable | protocol-error",
  "summary": "Short human-readable summary.",
  "inputs_read": ["context-packet", "implementation-plan", "current-diff", "previous-verdicts"],
  "artifacts_written": ["verdicts/06-qa.json"],
  "evidence": [],
  "fix_requests": [],
  "blockers": [],
  "stale_artifacts": [],
  "next_recommendation": "continue | fix | pause-for-human | retry-phase | stop"
}
```

Status values:

| Status | Meaning |
|---|---|
| `pass` | Phase completed and the runner may continue. |
| `fail` | The phase found a real issue that needs implementation/fix work. |
| `blocked` | The phase needs human input, credentials, environment access, or an external dependency. |
| `not-applicable` | The phase was intentionally skipped with a reason. |
| `protocol-error` | The agent did not produce required artifacts, broke the role contract, or emitted invalid output. |

Next recommendation values:

| Recommendation | Meaning |
|---|---|
| `continue` | Move to the next phase. |
| `fix` | Return to Implementation/Fix with structured fix requests. |
| `pause-for-human` | Stop and request human input. |
| `retry-phase` | Retry the same phase, usually once, after a protocol or transient tool error. |
| `stop` | End the run as finished or failed. |

The runner treats the phase output as advice plus data, not as the final authority. It still validates required files, parses JSON, checks transition rules, and updates `state.json` itself.

Fix request shape:

```json
{
  "id": "QA-001",
  "source_phase": "qa",
  "severity": "blocker | high | medium | low",
  "acceptance_criteria": ["AC-2"],
  "scenario": "User submits the form without required input.",
  "expected": "Inline validation error appears and submit is blocked.",
  "actual": "Form submits successfully.",
  "reproduction": ["Open checkout", "Clear required field", "Click submit"],
  "suggested_direction": "Implement required-field validation before submit."
}
```

## Transition Table

Default transitions:

| Current Phase | `pass` / `not-applicable` | `fail` | `blocked` | `protocol-error` |
|---|---|---|---|---|
| 1 Context Intake | 2 Plan | pause | pause | retry once, then pause |
| 2 Plan | 3 Implement | pause | pause | retry once, then pause |
| 3 Implement | 4 Test Review | 3 Implement | pause | retry once, then pause |
| 4 Test Review | 5 Code Review | 3 Implement/Fix | pause | retry once, then pause |
| 5 Code Review | 6 QA | 3 Implement/Fix | pause | retry once, then pause |
| 6 QA | 7 UI Validation | 3 Implement/Fix | pause | retry once, then pause |
| 7 UI Validation | 8 Create PR | 3 Implement/Fix | pause | retry once, then pause |
| 8 Create PR | 9 PR Code Review | pause | pause | retry once, then pause |
| 9 PR Code Review | 10 PR QA | 3 Implement/Fix, then 4 | pause | retry once, then pause |
| 10 PR QA | 11 PR UI Validation | 3 Implement/Fix, then 4 | pause | retry once, then pause |
| 11 PR UI Validation | finished | 3 Implement/Fix, then 4 | pause | retry once, then pause |

Important transition rules:

- after any code-changing fix, replay the local safety loop: Implementation/Fix -> Unit Test + Test Review -> Code Review -> QA -> UI Validation
- if a PR already exists, the implementer/fixer updates the branch and the runner continues from PR validation after the local safety loop passes
- if human input changes scope or acceptance criteria, mark downstream artifacts stale and replay from Planning
- if human input only provides access, a URL, a flag override, data setup, or a narrow decision, resume at the blocked phase
- stop after `max_fix_loops` and send a WhatsApp notification with the unresolved fix requests
- a protocol error should be retried once; repeated protocol errors become `pause-for-human`

## Step 0: Runner Preflight and Safe Garbage Collection

Step 0 is runner lifecycle work, not a delivery phase. The delivery pipeline still has 11 phases. Preflight exists to start each run cleanly without deleting useful state from other runs.

Startup order:

```text
runner start
-> acquire runner lock
-> run safe garbage collection
-> create a fresh isolated run directory
-> write input.json and initial state.json
-> start Phase 1 Context Intake
```

Safe garbage collection may remove only clearly disposable data:

| Item | Step 0 Can Remove? | Condition |
|---|---|---|
| expired archives | yes | `delete_after` is older than now |
| old temp folders | yes | folder is not referenced by an active `state.json` |
| stale locks | yes | owning process no longer exists |
| interrupted partial run directory | maybe | only if no `state.json` exists and directory is older than the configured temp TTL |
| active runs | no | never during normal startup |
| paused runs | no | waiting for human input |
| failed runs | no | keep until retention TTL expires |
| handoff-complete runs inside 7-day TTL | no | preserve compact evidence window |
| currently locked runs | no | another runner may be using them |

Do not implement startup cleanup as `rm -rf runs/*`. A clean start means a new run gets its own isolated directory; it does not mean previous state is destroyed.

If safe garbage collection is uncertain, it should log a warning and keep the file. Data loss is worse than an extra stale artifact in an experiment.

## Runner Responsibilities

The runner should be small and boring.

It should:

- acquire a runner lock before starting or resuming
- run Step 0 safe garbage collection before creating a new run
- create a run directory
- call OpenCode CLI with the phase command file
- choose the model for the phase
- pass the run directory and current state
- validate that the required output file exists
- parse the verdict JSON
- enforce transitions and retry limits
- stop on blockers
- create human notification requests for blocked, failed, or finished runs
- resume from existing run state after human input
- archive or prune run artifacts according to retention policy
- append a run log entry

It should not:

- decide implementation details
- let agents jump phases
- trust prose summaries when required files are missing
- silently accept validator phases doing implementer work instead of producing fix requests

## Human Notification and Resume

The runner should treat human interaction as a first-class state transition, not as a reason to restart the pipeline.

Notification events:

| Event | Notify Human? | Message Should Include |
|---|---|---|
| `pause-for-human` | yes | blocking question, choices if available, current phase, relevant artifacts, resume command |
| `blocked` | yes | blocker, what was tried, what input/access is needed |
| `failed` | yes | phase, failure summary, logs/artifacts, suggested next action |
| `finished` | yes | PR URL or final artifact, validation summary, unresolved notes |
| `phase-pass` | no by default | log only; WhatsApp after every phase is too noisy and trains the human to ignore the channel |

Notification channels should be adapters, not hardcoded into the phase prompts:

| Channel | Recommendation |
|---|---|
| Local terminal/log | Always enabled. The run directory and `state.json` are the source of truth. |
| WhatsApp | Default external notification channel for this experiment. Use only for human action needed, failure/blocker, or final completion. Keep messages short and include the run ID plus resume command. |
| No notification | Allowed for local dry runs, but the state file still records the event. |

Do not send WhatsApp messages after every successful phase. Step-by-step progress belongs in `state.json`, `run-log.jsonl`, and local terminal output. WhatsApp should preserve its interrupt value.

Suggested notification config:

```json
{
  "notifications": {
    "enabled": true,
    "events": ["pause-for-human", "blocked", "failed", "finished"],
    "channels": [
      { "type": "whatsapp", "mode": "send", "to": "+00000000000" }
    ]
  }
}
```

When a blocker occurs, the runner writes:

```text
runs/<run-id>/human-request.md
runs/<run-id>/state.json
```

The human can unblock in either of these ways:

1. Add an answer file, then run `runner.sh resume <run-id> --answer-file path/to/answer.md`.
2. Reply through the WhatsApp adapter if implemented; the runner stores the reply under `human-inputs/` and resumes.

Resume should not start from the beginning. The runner should load `state.json`, append the human answer as a new immutable artifact, and rerun the blocked phase or the next phase depending on the blocker type.

Suggested resume behavior:

| Blocker Type | Resume From |
|---|---|
| Missing product/design answer during context intake | Context Intake, then continue |
| Planning ambiguity resolved | Planning |
| Implementation blocker resolved | Implementation/Fix |
| QA data/flag/environment unblocked | QA |
| UI route/viewport/Figma access unblocked | UI Validation |
| PR permission/token fixed | Create PR |

If human input changes the acceptance criteria or scope, the runner should mark downstream artifacts stale and replay from Planning. If the answer only supplies missing credentials, a URL, a flag override, or a narrow decision, the runner resumes at the blocked phase.

## Retention and Cleanup

Do not add cleanup as a 12th delivery phase. Cleanup is a runner lifecycle concern, not part of delivery quality. The 11 delivery phases should stay focused on producing and validating the PR.

The run directory must remain isolated per run so logs do not mix. New runs never append into an old run directory. The runner should use `runs/<run-id>/` while active, then archive or prune it after completion.

Recommended policy:

| Run State | Retention Action |
|---|---|
| `running` | Keep full artifacts. |
| `paused` | Keep full artifacts until human input arrives or the pause expires. |
| `failed` | Keep full artifacts for debugging; notify human. |
| `finished` with PR open | Keep full artifacts until PR merge/close, or for a fixed TTL if merge status cannot be checked. |
| `finished` with no PR | Keep full artifacts for a short TTL, then archive summary and remove bulky files. |
| PR merged or closed | Archive compact summary; remove bulky artifacts. |

Recommended defaults:

```json
{
  "retention": {
    "active_runs_dir": "runs",
    "archive_dir": "archive",
    "keep_finished_days": 14,
    "keep_failed_days": 30,
    "keep_paused_days": 30,
    "delete_bulky_artifacts_after_archive": true,
    "bulky_artifact_patterns": [
      "**/*.png",
      "**/*.jpg",
      "**/*.jpeg",
      "**/*.webp",
      "**/*.mp4",
      "**/trace.zip",
      "**/node_modules/**"
    ]
  }
}
```

Archive shape:

```text
archive/<run-id>/
  summary.md
  final-state.json
  run-log.jsonl
  pr-metadata.json
  final-verdicts/
```

Cleanup should preserve enough evidence to answer later questions:

- ticket key and PR URL
- final status and finish time
- phase history
- final AC coverage summary
- final test, QA, and UI verdicts
- unresolved blockers or known gaps
- path or commit reference for the implementation

Cleanup should remove or compress high-volume artifacts:

- screenshots and video captures
- Playwright traces
- repeated intermediate phase notes
- temporary browser/session data
- old diff snapshots superseded by the final diff

PR merge should be a cleanup trigger when available, but not the only one. Some PRs may stay open for days, close without merge, or lose API access. Use both PR state and TTL-based cleanup.

Suggested cleanup commands:

```text
runner.sh cleanup --dry-run
runner.sh cleanup --run-id <run-id>
runner.sh cleanup --older-than 30d
```

The cleanup command should never delete active, paused, or currently locked runs unless forced by an explicit human command.

## Suggested Prototype Layout

```text
experiment/delivery-pipeline/
  design.md
  runner.sh
  pipeline.json
  package.json
  commands/
    01-context-intake.md
    02-plan.md
    03-implement.md
    04-test-review.md
    05-code-review.md
    06-qa.md
    07-ui-validation.md
    08-create-pr.md
    09-pr-code-review.md
    10-pr-qa.md
    11-pr-ui-validation.md
  schemas/
    pipeline.schema.json
    phase-output.schema.json
    state.schema.json
  examples/
    phase-output/
    invalid/
  tools/
    validate-schema.mjs
  runs/
    .gitignore
```

## Pipeline Config Sketch

```json
{
  "phases": [
    { "id": "context-intake", "command": "commands/01-context-intake.md", "model": "github-copilot/claude-sonnet-4.6", "variant": "medium", "writes_code": false },
    { "id": "plan", "command": "commands/02-plan.md", "model": "github-copilot/claude-opus-4.8", "variant": "high", "writes_code": false },
    { "id": "implement", "command": "commands/03-implement.md", "model": "github-copilot/claude-opus-4.8", "variant": "high", "writes_code": true },
    { "id": "test-review", "command": "commands/04-test-review.md", "model": "github-copilot/claude-sonnet-4.6", "variant": "medium", "writes_code": false },
    { "id": "code-review", "command": "commands/05-code-review.md", "model": "github-copilot/claude-opus-4.8", "variant": "high", "writes_code": false },
    { "id": "qa", "command": "commands/06-qa.md", "model": "github-copilot/claude-sonnet-4.6", "variant": "high", "writes_code": false },
    { "id": "ui-validation", "command": "commands/07-ui-validation.md", "model": "github-copilot/claude-sonnet-4.6", "variant": "high", "writes_code": false },
    { "id": "create-pr", "command": "commands/08-create-pr.md", "model": "github-copilot/gpt-5.4-mini", "variant": "low", "writes_code": true },
    { "id": "pr-code-review", "command": "commands/09-pr-code-review.md", "model": "github-copilot/claude-opus-4.8", "variant": "high", "writes_code": false },
    { "id": "pr-qa", "command": "commands/10-pr-qa.md", "model": "github-copilot/claude-sonnet-4.6", "variant": "high", "writes_code": false },
    { "id": "pr-ui-validation", "command": "commands/11-pr-ui-validation.md", "model": "github-copilot/claude-sonnet-4.6", "variant": "high", "writes_code": false }
  ],
  "max_fix_loops": 3
}
```

Model identifiers may need adjustment to the local OpenCode provider names. The canonical API IDs are `claude-opus-4-8`, `claude-sonnet-4-6`, `gpt-5.4-mini`, `gemini-2.5-pro`, and `gemini-3.5-flash`. The experiment should keep them configurable.

## Full 11-Step Project Scope

This experiment is for the full 11-step delivery pipeline, not a reduced MVP. The first prototype should include command files, config entries, state transitions, and output contracts for all 11 phases from the start.

Implementation can still be developed iteratively, but the project design should not narrow the target pipeline. A partial runner is acceptable only as an implementation milestone if the checked-in design and file layout already represent the full 11-phase system.

Required first project shape:

1. Context Intake
2. Implementation Planning
3. Implementation
4. Unit Test + Test Review
5. AC-Aware Code Review
6. AC-Aware QA
7. AC + Figma UI Validation
8. Create PR
9. PR Code Review
10. QA on PR
11. UI Validation on PR

Every phase must have a prompt/command contract before the runner is considered complete.

## Open Questions

| Question | Initial Recommendation |
|---|---|
| Should validator phases be technically prevented from editing files? | No for the first version. Give them normal tools but make the prompt contract explicit: do not edit, produce fix requests, and let the implementer/fixer handle changes. |
| Should the planner inspect repo/workspace? | Yes, but only targeted reads/searches needed to produce a realistic plan. |
| Should commands duplicate skill rules? | Yes, include the critical rules inline and link/reference skills as supporting context. |
| Should UI validation compare screenshots? | Screenshots help implementation and reporting, but are not the source of truth. Use computed-style and Figma spec comparisons. |
| Should PR QA repeat local QA? | Yes, but scoped to preview/environment risk. Local pass does not prove preview pass. |
