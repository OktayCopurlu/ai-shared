# Delivery Pipeline Production Implementation Plan

Last updated: 2026-05-24

This plan turns the experimental 11-phase delivery pipeline from a contract-first skeleton into a production-ready local automation system. It is intentionally A-to-Z: contracts, runner behavior, phase prompts, validation, WhatsApp notification, cleanup, testing, real-ticket rollout, and operational guardrails.

## Target Outcome

A production-ready pipeline should be able to take a ticket key/link and target repository, run the full 11-step delivery workflow with OpenCode, pause/resume safely when human input is needed, notify the human through WhatsApp only for actionable events, create a PR, validate it locally and on PR preview, compact the run after handoff, and clean old artifacts without risking active work.

## Status Snapshot

Current stage: local runner hardening is mostly implemented through schema validation, transition safety, OpenCode fallback, notification controls, cleanup safety, redaction, retention manifest coverage, stubbed integration coverage, command prompt productionization, local WhatsApp outbound configuration, and WhatsApp reply resume. The next implementation step is a low-risk pilot run.

| Status | What This Means | Workstreams |
|---|---|---|
| Done | Usable for the current experiment and validated locally. | Design contract, pipeline skeleton, runtime isolation, pipeline/state/phase-output/fix-request/context schemas, examples, Ajv validator tooling, schema-backed runner validation, transition engine, OpenCode fallback/logging, command prompt productionization, notify toggles, cleanup safety, redaction checks, `runner.sh doctor`, stubbed full-run integration tests. |
| Partially done | Some useful behavior exists, but production acceptance criteria are not fully met. | Integration dry runs. |
| Not started | No real implementation yet beyond design notes. | Real-ticket pilot, production readiness gate. |

## Phase Completion Matrix

Legend: `[x]` done · `[~]` partial · `[ ]` not started.

### Phase 1: Contract Hardening
- [x] 1. `schemas/pipeline.schema.json` for `pipeline.json`.
- [x] 2. `schemas/fix-request.schema.json` (if fix requests stay separate files).
- [x] 3. Context artifact schemas for ACs, Figma specs, constraints, and validation targets.
- [x] 4. `phase-output.schema.json` requires `fix_requests` or `blockers` on `status: fail`.
- [x] 5. `phase-output.schema.json` requires at least one blocker on `status: blocked` (and `protocol-error`).
- [x] 6. Valid phase IDs as enums in schemas.
- [x] 7. `schema_version` field on state/phase outputs/fix requests/context artifacts.
- [x] 8. Pass/fail/blocked/not-applicable/protocol-error examples under `examples/`.
- [x] 9. `design.md`/`README.md` link to schemas and examples.

### Phase 2: Runner Validation Engine
- [x] 1. Local JSON schema validator (Ajv via `tools/validate-schema.mjs`).
- [x] 2. `validate_schema` runner function.
- [x] 3. `pipeline.json` validated on every invocation.
- [x] 4. `state.json` validated after every runner write.
- [x] 5. Every `phases/<phase>/output.json` validated before transition handling.
- [x] 6. Canonical artifact validation when more schemas exist (fix-request/context-packet).
- [x] 7. Distinguish parse / schema / missing / command failures in protocol-error output.
- [x] 8. Validation errors saved under `phases/<phase>/validation-error.log`.
- [x] 9. `runner.sh doctor` checks tools, config, schemas, folders, timeout helper.

### Phase 3: Transition Engine Completion
- [x] 1. Transition function aware of phase, status, PR existence, fix-loop count, stale artifacts.
- [x] 2. Local safety loop replay after every code-changing fix.
- [x] 3. PR + later-phase failure routes through implement → safety loop → PR update → resume PR validations.
- [x] 4. `stale_from_phase` and downstream `stale_artifacts` tracked explicitly.
- [x] 5. `fix_loop_count` resets only after a clean full local safety loop.
- [x] 6. `max_fix_loops` enforced with `pause-for-human` + unresolved fix-request summary + notification dispatch.
- [x] 7. `protocol-error` retried once per phase before pausing.
- [x] 8. Every transition decision logged to `run-log.jsonl` with reasons.
- [x] 9. `runner.sh explain-transition` for debugging.

### Phase 4: OpenCode Execution Hardening
- [x] 1. Per-phase `timeout_seconds` + top-level `default_timeout_seconds` in `pipeline.json`.
- [x] 2. Timeout enforced via `gtimeout`/`timeout`; timeouts become `protocol-error`.
- [x] 3. stdout/stderr captured to `phases/<phase>/opencode.log`.
- [x] 4. Command metadata captured per phase in `command-meta.json` (linked from `phase_history`).
- [x] 5. Model fallback for unavailable models.
- [x] 6. `runner.sh start --model` / `--variant` overrides persisted in state.
- [x] 7. `runner.sh run-phase <run-id> <phase-id>` single-phase rerun.
- [x] 8. `--no-notify` / `--notify` toggles.
- [x] 9. Terminal output concise; command-meta summaries surface in `status`/`explain-transition`.

### Phase 5: Command Prompt Productionization
- [x] 1. Shared command preamble file/block.
- [x] 2. Concrete `output.json` examples in every command.
- [x] 3. Phase-specific checklists in every command.
- [x] 4. Required artifact paths in every command in machine-checkable form.
- [x] 5. Skill references + embedded critical rules per phase.
- [x] 6. Expand context-intake (Jira/Figma/Contentful/Confluence/linked-ticket/experiment/preview extraction).
- [x] 7. Expand planner (targeted repo inspection + anti-overplanning).
- [x] 8. Expand implementation (coding style, tests, UI, Figma specs, a11y, security, branch safety).
- [x] 9. Expand test-review (invariant coverage + repo-defined command rules).
- [x] 10. Expand code-review (4-layer review + AC evidence table requirements).
- [x] 11. Expand QA prompts (recovery protocol, expected vs actual, no-code-edit).
- [x] 12. Expand UI validation prompts (computed style, DOM, viewports, Figma specs, screenshots-as-secondary, flag/data recovery).
- [x] 13. Expand PR creation prompt (PR body contract, evidence rules, no invented evidence, no amend/force-push).

### Phase 6: WhatsApp Notification Adapter
- [x] 1. Identify the actual WhatsApp automation path on this machine.
- [x] 2. Add `notifications/whatsapp.sh` adapter.
- [x] 3. Keep secrets/phone numbers out of git.
- [x] 4. `notifications.example.json` with placeholders.
- [x] 5. `pipeline.json` references local notification config path.
- [x] 6. `notify_event` dispatches to WhatsApp for configured events.
- [x] 7. Short message format (run ID, event, phase, summary, resume command, run path).
- [x] 8. Rate limiting for repeated failures.
- [x] 9. `runner.sh notify-test`.
- [x] 10. Keep `notifications.log` as audit trail even when WhatsApp sends.

### Phase 7: Human Reply and Resume
- [x] 1. File-based resume: `resume <run-id> --answer-file <path>`.
- [x] 2. `human-inputs/<timestamp>-answer.md` is saved with adjacent structured metadata.
- [x] 3. WhatsApp reply ingestion.
- [x] 4. WhatsApp thread/run-ID mapping into `human-inputs/`.
- [x] 5. Classify human input impact (`--impact access|decision|scope-change`).
- [x] 6. Scope/AC change marks downstream artifacts stale and resumes from Planning.
- [x] 7. Access/narrow-decision resumes from blocked phase.
- [x] 8. `human-request.md` is generated with explicit impact choices.
- [x] 9. `runner.sh answer-template <run-id>`.

### Phase 8: Cleanup and Retention
- [x] 1. Immediate compacting on handoff-complete.
- [x] 2. Remove bulky artifacts from active run after compact archive.
- [x] 3. Preserve compact archive for `handoff_complete_days` (default 7).
- [x] 4. `delete_after` enforcement for archives.
- [x] 5. `keep_failed_days` / `keep_paused_days` cleanup for stale failed/paused runs with explicit `--include-stale-runs`.
- [x] 6. Locked-run detection before cleanup.
- [x] 7. `cleanup --dry-run` reports without deleting.
- [~] 8. Fixture tests cover active/expired/dry-run/`--run-id`/no-delete-after/paused/failed/locked; stale-temp/stale-lock still missing.
- [x] 9. `runner.sh cleanup --explain`.

### Phase 9: Security and Secret Handling
- [x] 1. Define redaction patterns for logs/WhatsApp.
- [x] 2. Redaction function for notification text + command metadata/log output.
- [x] 3. Avoid printing env vars wholesale.
- [x] 4. Avoid storing auth tokens in run artifacts.
- [x] 5. `.gitignore` coverage for local notification config + secrets.
- [x] 6. Review ticket/context artifacts for sensitive data + document retention.
- [x] 7. `runner.sh redact-check <run-id>`.
- [x] 8. WhatsApp messages contain summaries + local paths, not full payloads.

### Phase 10: Automated Test Suite
- [x] 1. Test scripts under `experiment/delivery-pipeline/tests/`.
- [x] 2. Fixture run directories + fake phase outputs.
- [x] 3. Test `start --dry-run` behavior explicitly.
- [x] 4. Phase output parse failure (`tests/schema-failures.sh`).
- [x] 5. Missing required artifacts (runner-integration test).
- [x] 6. Pass transition.
- [x] 7. Fail transition to implement.
- [x] 8. Max fix loop pause + summary.
- [~] 9. Blocked transition + `human-request.md` creation (covered implicitly; no dedicated assertion yet).
- [x] 10. Resume with answer file (`--impact access`/`scope-change`).
- [x] 11. Finish compact archive + `delete_after`.
- [x] 12. Cleanup dry-run + actual cleanup on fixture archives.
- [x] 13. No deletion of active/paused/failed/locked runs.
- [x] 14. Tests wired into README + `npm test`.

### Phase 11: Integration Dry Runs
- [ ] 1. Fake target repo fixture with minimal scripts.
- [~] 2. Stub OpenCode executor (used in transition tests; not yet a fixture for full integration).
- [x] 3. Run all 11 phases with stubbed outputs to handoff-complete.
- [x] 4. Verify state, artifacts, archive, notifications log in full run.
- [~] 5. Failure-path dry runs (PR-QA fail recovery covered; QA fail / UI blocked / PR-creation blocked / protocol retry still missing).
- [ ] 6. Document dry-run commands + expected outputs.

### Phase 12: Real-Ticket Pilot
- [ ] 1. Pick a small, low-risk ticket.
- [ ] 2. Confirm target repo + branch safety.
- [ ] 3. Start pipeline with WhatsApp notifications enabled.
- [ ] 4. Watch phases 1–3 closely.
- [ ] 5. Let validators produce fix requests, not patches.
- [ ] 6. Inspect PR description evidence before opening.
- [ ] 7. Collect protocol errors, bad prompts, missing artifacts, transitions.
- [ ] 8. Patch pipeline based on findings.

### Phase 13: Production Readiness Gate
- [ ] All gate rows satisfied before routine use (see gate table below).


## Current Baseline

Already implemented:

| Area | Current State |
|---|---|
| Design contract | `design.md` captures the 11 phases, artifact model, transitions, notification policy, and cleanup policy. |
| Pipeline config | `pipeline.json` defines 11 phases, models, required outputs, and basic next-phase rules. |
| Schemas | `schemas/pipeline.schema.json`, `schemas/state.schema.json`, `schemas/phase-output.schema.json`, `schemas/fix-request.schema.json`, `schemas/context-packet.schema.json`, `schemas/acceptance-criteria.schema.json`, and `schemas/figma-specs.schema.json` exist with `schema_version: "1"` where applicable. |
| Schema examples | Positive and negative phase-output examples exist under `examples/`. |
| Commands | 11 command prompt files exist under `commands/`. |
| Runner skeleton | `runner.sh` supports `start`, `resume`, `status`, `list`, and `cleanup`. |
| Runtime isolation | `runs/`, `archive/`, and `tmp/` are gitignored. |
| Notification | Local `notifications.log` audit trail, `--notify`/`--no-notify`, `notify-test`, rate limiting, and a configurable WhatsApp adapter exist; machine-specific sender config stays local. |
| Validation | JSON parse, shell syntax, Ajv schema checks, `runner.sh doctor`, dry-run start, full stubbed integration, and repo validation pass. |

Not production-ready yet:

| Gap | Why It Matters |
|---|---|
| WhatsApp reply ingestion | Human unblock through WhatsApp is not implemented. |
| Real-ticket testing | No actual ticket has been run through the pipeline. |
| Runner tests | Transition decision, stubbed PR-failure recovery, resume-impact, cleanup, schema-contract, missing-artifact, repeated protocol-error, QA fail recovery, UI blocked, PR creation blocked, and full-run tests exist. |
| Safe cleanup tests | Cleanup policy is proven against fixture archives and active/paused/failed/locked runs; partial-run and stale-lock recovery edge cases remain. |
| Security review | Redaction exists for runner-controlled logs/notifications; compact archives now document retained paths and excluded sensitive categories before real tickets. |

## Implementation Progress

| Workstream | Status | Notes |
|---|---|---|
| Design contract | Done | `design.md` exists and captures current architecture decisions. |
| Pipeline skeleton | Done | `pipeline.json`, 11 commands, schemas, runtime folders, and `runner.sh` skeleton exist. |
| Contract hardening | Done | Pipeline/state/phase-output/fix-request/context schemas, examples, schema versions, and stricter validation are implemented. |
| Runner validation engine | Done | Ajv validation, phase output schema rejection, canonical artifact validation, state validation, `doctor`, and fixture tests are implemented. |
| Transition engine completion | Done | Runner records explicit transition decisions, stale artifacts, protocol retries, safety-loop reset/resume state, max-loop summaries, scope-change replay, supports `explain-transition`, and has fixture/stubbed recovery tests. |
| OpenCode execution hardening | Done | Phase logs captured, per-phase timeouts via `gtimeout`/`timeout`, model fallback, model/variant overrides through `start`, notify toggles, `run-phase`, per-phase `command-meta.json`, and status/explain summaries are implemented. |
| Command prompt productionization | Done | 11 commands now include embedded critical rules, skill references, phase checklists, machine-checkable artifact lists, and concrete `output.json` examples. |
| WhatsApp notification adapter | Done | Adapter, local config contract, audit log, notify-test, rate limiting, and the local `.ai-automation` outbound sender configuration exist; secrets and recipient values remain local-only. |
| Human reply and resume | Done | File-based resume, WhatsApp reply ingestion, thread/run mapping, structured hashed source metadata, answer-template, and explicit impact classification exist. |
| Cleanup and retention | Partially done | Compact archive, bulky artifact pruning, explainable cleanup, explicit stale paused/failed cleanup, lock detection, and tests exist; stale temp/lock recovery can still expand. |
| Security and secret handling | Done | Redaction, local secret gitignore, summary-only notifications, redact-check, and compact archive retention manifests are implemented. |
| Automated tests | Done | Transition fixture tests, stubbed PR-failure recovery proof, resume-impact tests, cleanup tests, schema failure-path tests, missing-artifact tests, repeated protocol-error tests, QA fail recovery, UI blocked, PR creation blocked, WhatsApp reply ingestion, and full 11-phase stubbed integration tests exist. |
| Integration dry runs | Done | Full stubbed 11-phase dry run reaches handoff-complete; QA fail recovers through the local safety loop; UI blocked, PR creation blocked, and repeated protocol errors pause for human input. |
| Real-ticket pilot | Not started | No real ticket has been run. |
| Production readiness gate | Not started | Gate criteria are defined but not satisfied. |

## Implementation Principles

- Keep the system isolated under `experiment/delivery-pipeline/` until it proves itself.
- Treat `runs/<run-id>/state.json` as runner-owned source of truth.
- Treat all phase artifacts as immutable inputs for later phases.
- Let only implementer/fixer phases intentionally edit code.
- Let validator phases produce verdicts and fix requests, not patches.
- Make the runner deterministic: agents advise, runner decides transitions.
- Prefer recoverable pause/resume over guessing.
- Notify through WhatsApp only for `pause-for-human`, `blocked`, `failed`, and `finished`.
- Never delete active, paused, failed, or locked runs during startup cleanup.

## Phase 1: Contract Hardening

Goal: make the artifact and transition contracts precise enough that the runner can enforce them.

Tasks:

1. Add `schemas/pipeline.schema.json` for `pipeline.json`.
2. Add `schemas/fix-request.schema.json` if fix requests stay as separate files.
3. Add context artifact schemas for ACs, Figma specs, constraints, and validation targets.
4. Tighten `phase-output.schema.json` so `status: fail` requires at least one `fix_request` or blocker-like explanation.
5. Tighten `phase-output.schema.json` so `status: blocked` requires at least one blocker.
6. Define valid phase IDs as enums in schemas.
7. Add a `schema_version` field to `state.json`, phase outputs, fix requests, and context artifacts.
8. Add examples under `examples/` for pass, fail, blocked, not-applicable, and protocol-error phase outputs.
9. Update `design.md` and `README.md` to link to the schemas and examples.

Acceptance criteria:

- `pipeline.json` validates against `pipeline.schema.json`.
- Example artifacts validate against their schemas.
- Invalid examples fail validation in a predictable way.

## Phase 2: Runner Validation Engine

Goal: the runner should validate artifacts before trusting them.

Tasks:

1. Choose a JSON schema validator available locally. Prefer `ajv-cli` if Node is acceptable; otherwise document and implement a fallback path.
2. Add a runner function `validate_schema <schema> <file>`.
3. Validate `pipeline.json` on every runner invocation.
4. Validate `state.json` after runner writes it.
5. Validate every `phases/<phase>/output.json` before transition handling.
6. Validate canonical artifacts when schemas exist.
7. Distinguish parse failure, schema failure, missing artifact, and command failure in protocol-error output.
8. Save validation errors under `phases/<phase>/validation-error.log`.
9. Add `runner.sh doctor` to verify tools, config, model names, schemas, folders, and notification config.

Acceptance criteria:

- Missing required phase output produces `protocol-error`.
- Invalid JSON produces `protocol-error`.
- Schema-invalid JSON produces `protocol-error` with a readable validation log.
- `doctor` reports missing tools and config problems without starting a run.

## Phase 3: Transition Engine Completion

Goal: implement the full transition table from `design.md`.

Tasks:

1. Replace simple `next_on_pass` / `next_on_fail` logic with a transition function aware of current phase, status, PR existence, fix loop count, and stale artifacts.
2. Implement local safety loop replay after every code-changing fix: `implement -> test-review -> code-review -> qa -> ui-validation`.
3. When a PR exists and a later phase fails, route to implement/fix, replay local safety loop, then update/push branch and resume PR validations.
4. Track `stale_from_phase` and downstream stale artifacts explicitly.
5. Reset `fix_loop_count` only when a clean full local safety loop passes.
6. Enforce `max_fix_loops` with a WhatsApp notification and `pause-for-human` state.
7. Implement `protocol-error` retry once per phase before pausing.
8. Record every transition decision in `run-log.jsonl` with reason fields.
9. Add `runner.sh graph` or `runner.sh explain-transition <run-id>` for debugging transition decisions.

Acceptance criteria:

- Failures in phases 4-7 return to implement/fix and then replay local safety loop.
- Failures in phases 9-11 return to implement/fix, replay local safety loop, update PR, then resume PR validation.
- Repeated protocol errors pause the run with a human request.
- Max fix loop exhaustion pauses with unresolved fix request summary.

## Phase 4: OpenCode Execution Hardening

Goal: make phase execution reliable and inspectable.

Tasks:

1. Add per-phase timeout config to `pipeline.json`.
2. Enforce timeout in `runner.sh` and write timeout as `protocol-error`.
3. Capture stdout/stderr to `phases/<phase>/opencode.log`.
4. Capture the exact OpenCode command metadata without leaking secrets.
5. Add model fallback config for phases where Opus or GPT 5.5 is unavailable.
6. Add `--model-override <model>` and `--variant-override <variant>` for controlled experiments.
7. Add `--phase <phase-id>` to run one phase against an existing run directory for debugging.
8. Add `--no-notify` and `--notify` toggles.
9. Ensure terminal output remains concise and points to the run directory for details.

Acceptance criteria:

- A timed-out phase writes a protocol-error output and pauses safely.
- Phase logs are preserved under the run directory.
- Model fallback behavior is explicit and logged.
- A single phase can be rerun intentionally without corrupting prior artifacts.

## Phase 5: Command Prompt Productionization

Goal: make each command strong enough that agents do not skip required skills, artifacts, or validation duties.

Tasks:

1. Add a shared command preamble file or repeated block covering immutable inputs, role boundaries, output schema, and forbidden behavior.
2. Add concrete `output.json` examples to every command.
3. Add phase-specific checklists to every command.
4. Add required artifact paths to every command in a machine-checkable way.
5. Add explicit skill references and short embedded critical rules for each phase.
6. Expand context-intake prompt with detailed Jira, Figma, Contentful, Confluence, linked ticket, experiment, and preview extraction rules.
7. Expand planner prompt with targeted repo inspection rules and anti-overplanning guidance.
8. Expand implementation prompt with coding style, test strategy, UI discovery, Figma spec usage, a11y, security, and branch safety rules.
9. Expand test-review prompt with invariant coverage review and repository-defined command rules.
10. Expand code-review prompt with 4-layer review and AC evidence table requirements.
11. Expand QA prompts with recovery protocol, expected vs actual, and no-code-edit rules.
12. Expand UI validation prompts with computed-style, DOM/layout measurement, desktop/mobile viewport, Figma specs, screenshots as secondary evidence, and flag/data recovery rules.
13. Expand PR creation prompt with PR body contract, evidence use, no invented evidence, and no amend/force-push rules.

Acceptance criteria:

- Every command can be read independently and still enforce its role.
- Every command names exactly what it reads and writes.
- Validator commands explicitly forbid code edits and require fix requests.
- UI commands cannot pass with screenshot-only validation when Figma specs exist.

## Phase 6: WhatsApp Notification Adapter

Goal: send actionable WhatsApp notifications for human-needed events.

Tasks:

1. Identify the actual WhatsApp automation path previously used on this machine.
2. Add `notifications/whatsapp.sh` or equivalent adapter under the experiment folder.
3. Keep secrets and phone numbers out of git. Use local config or environment variables.
4. Add `notifications.example.json` with placeholders.
5. Update `pipeline.json` to reference a local notification config path instead of hardcoded phone number.
6. Implement `notify_event` dispatching to WhatsApp for configured events.
7. Keep message format short: run ID, event, phase, blocker/failure summary, resume command, run path.
8. Add rate limiting so repeated failures do not spam WhatsApp.
9. Add `runner.sh notify-test` to send a harmless test message.
10. Keep local `notifications.log` as audit trail even when WhatsApp sends.

Acceptance criteria:

- `notify-test` sends one WhatsApp message through the configured adapter.
- `pause-for-human`, `blocked`, `failed`, and `finished` trigger WhatsApp when enabled.
- `phase-pass` does not send WhatsApp by default.
- Missing WhatsApp config logs a warning and does not crash the run unless notification is marked required.

## Phase 7: Human Reply and Resume

Goal: human unblock should continue from the right place without restarting.

Tasks:

1. Support file-based resume fully: `resume <run-id> --answer-file <path>`.
2. Add structured `human-inputs/<timestamp>-answer.md` metadata with source, phase, and time.
3. Add optional WhatsApp reply ingestion if the adapter can read replies.
4. If WhatsApp replies are available, map reply thread/run ID to `human-inputs/`.
5. Add runner logic to classify human input impact: access-only, narrow decision, scope/AC change.
6. If scope/AC changes, mark downstream artifacts stale and resume from Planning.
7. If access/narrow decision changes, resume from blocked phase.
8. Update `human-request.md` with exact choices whenever possible.
9. Add `runner.sh answer-template <run-id>` to generate a structured answer template.

Acceptance criteria:

- File-based human answer resumes a paused run.
- Scope-changing answer replays from Planning.
- Access-only answer resumes from blocked phase.
- Human input is preserved as immutable artifact.

## Phase 8: Cleanup and Retention Implementation

Goal: logs do not accumulate or mix, and cleanup never deletes useful active state.

Tasks:

1. Implement immediate compacting on handoff-complete.
2. Remove bulky artifacts from active run after compact archive is created, or move them only if needed.
3. Preserve compact archive for 7 days by default.
4. Implement `delete_after` enforcement for archives.
5. Implement `keep_failed_days` and `keep_paused_days` cleanup for stale failed/paused runs only with explicit safe policy.
6. Add locked-run detection before cleanup.
7. Add dry-run output for every cleanup deletion.
8. Add fixture tests for active, paused, failed, handoff-complete, expired archive, stale temp, and stale lock cases.
9. Add `runner.sh cleanup --explain` to show why each candidate is kept or deleted.

Acceptance criteria:

- Startup safe GC never deletes active, paused, failed, or locked runs.
- Handoff-complete runs are compacted immediately.
- Expired archives are deleted by cleanup.
- Cleanup dry-run shows intended deletions without deleting.

## Phase 9: Security and Secret Handling

Goal: avoid leaking credentials, private links, tokens, auth headers, or sensitive user data in logs and notifications.

Tasks:

1. Define secrets and sensitive patterns to redact from logs and WhatsApp messages.
2. Add a redaction function for notification text and command metadata.
3. Do not print env vars wholesale.
4. Avoid storing auth tokens in run artifacts.
5. Add `.gitignore` coverage for local notification config and any secrets.
6. Review whether ticket/context artifacts may contain sensitive customer data and document retention expectations.
7. Add a `runner.sh redact-check <run-id>` command or validation step for obvious token patterns.
8. Ensure WhatsApp messages contain summaries and local paths, not full confidential payloads.

Acceptance criteria:

- Notification text redacts known token-like patterns.
- Local secrets/config files are gitignored.
- Run artifacts avoid credentials and raw auth headers.
- A redaction check can be run before sharing logs.

## Phase 10: Automated Test Suite

Goal: make runner behavior safe to change.

Tasks:

1. Add a test script under `experiment/delivery-pipeline/tests/`.
2. Use fixture run directories and fake phase outputs.
3. Test `start --dry-run` behavior.
4. Test phase output parse failure.
5. Test missing required artifacts.
6. Test pass transition.
7. Test fail transition to implement.
8. Test max fix loop pause.
9. Test blocked transition and `human-request.md` creation.
10. Test resume with answer file.
11. Test finish compact archive and `delete_after`.
12. Test cleanup dry-run and actual cleanup on fixture archives.
13. Test no deletion of active/paused/failed/locked runs.
14. Add these tests to the local validation command documented in README.

Acceptance criteria:

- Tests run without calling OpenCode or external services.
- Tests pass on a clean checkout.
- Tests cover the dangerous paths: cleanup, resume, transition, missing artifacts.

## Phase 11: Integration Dry Runs Without Real Code Changes

Goal: prove the orchestration before letting agents modify a real repository.

Tasks:

1. Add a fake target repo fixture with minimal package scripts.
2. Add fake command mode or stub OpenCode executor for deterministic test runs.
3. Run all 11 phases with stubbed phase outputs.
4. Verify state transitions, artifacts, archive, and notifications log.
5. Run failure-path dry runs for QA fail, UI blocked, PR creation blocked, and protocol-error retry.
6. Document dry-run commands and expected outputs.

Acceptance criteria:

- A full 11-phase stub run reaches `handoff-complete`.
- Failure-path stub runs pause or loop as expected.
- No real codebase or external service is required for integration dry runs.

## Phase 12: Real-Ticket Pilot

Goal: run the pipeline on a low-risk real ticket and observe where it breaks.

Tasks:

1. Pick a small, low-risk ticket with clear ACs.
2. Confirm target repo and branch safety manually.
3. Start the pipeline with WhatsApp notifications enabled.
4. Watch phases 1-3 closely and stop if context or planning quality is poor.
5. Let validator phases produce fix requests, not patches.
6. Inspect PR description evidence before opening or sharing.
7. Collect all protocol errors, bad prompts, missing artifacts, and confusing transitions.
8. Patch the pipeline based on findings before a second pilot.

Acceptance criteria:

- Pipeline can reach PR creation or a valid human pause.
- Every pause contains enough information to resume.
- PR evidence is traceable to artifacts.
- No unrelated repo files are modified by validator phases.

## Phase 13: Production Readiness Gate

Goal: define the bar before using this as a normal workflow.

Production-ready means all of the following are true:

| Area | Gate |
|---|---|
| Runner | Start/resume/status/list/cleanup/doctor/notify-test work reliably. |
| Schema validation | Pipeline config, state, phase outputs, and key artifacts validate. |
| Transitions | Pass/fail/blocked/protocol-error transitions match the design. |
| Fix loops | Local safety loop replays after code-changing fixes. |
| Notifications | WhatsApp sends only actionable events and has local audit logs. |
| Resume | File-based resume works; WhatsApp reply resume works if adapter supports it. |
| Cleanup | Expired archives are removed; active/paused/failed/locked runs are preserved. |
| Security | Secrets are redacted and local configs are gitignored. |
| Tests | Runner unit/integration tests pass without external services. |
| Real pilot | At least two low-risk tickets complete or pause correctly with no data loss. |
| Documentation | README explains setup, commands, failure modes, and troubleshooting. |

## Suggested Implementation Order

| Order | Workstream | Why First/Next |
|---:|---|---|
| 1 | Contract hardening | Prevents weak artifacts from shaping the rest of the system. |
| 2 | Runner validation engine | Makes failures deterministic before real runs. |
| 3 | Transition engine completion | Prevents bad fix/resume paths. |
| 4 | OpenCode execution hardening | Makes phase execution reliable and inspectable. |
| 5 | Command prompt productionization | Improves agent compliance phase by phase. |
| 6 | Cleanup and retention | Avoids artifact buildup while tests are created. |
| 7 | Automated test suite | Locks behavior before external integrations. |
| 8 | WhatsApp notification adapter | Adds human notification after core safety is reliable. |
| 9 | Human reply and resume | Completes the human-in-loop path. |
| 10 | Security and secret handling | Must be complete before real sensitive tickets. |
| 11 | Integration dry runs | Proves end-to-end flow without repo risk. |
| 12 | Real-ticket pilot | Validates the system under realistic conditions. |
| 13 | Production readiness gate | Decide whether to use it routinely. |

## Immediate Next Step

Prepare a low-risk real-ticket pilot.

Start with these concrete tasks:

1. Pick a low-risk ticket and target repository for the first pilot.
2. Run `runner.sh start --ticket <ticket> --repo <repo> --notify` and monitor pauses/WhatsApp notifications.
3. Run `runner.sh redact-check <run-id>` before sharing any run artifacts.

Do not use the pipeline routinely until one pilot completes and the production readiness gate is reviewed.
