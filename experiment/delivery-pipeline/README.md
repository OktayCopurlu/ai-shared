# Experimental Delivery Pipeline

Full 11-phase OpenCode-driven delivery pipeline experiment. This folder is intentionally isolated from production prompts, skills, and self-evolution automation.

## Shape

```text
experiment/delivery-pipeline/
  design.md
  pipeline.json
  package.json
  runner.sh
  commands/
  examples/
  schemas/
  tools/
  runs/       # local runtime state, gitignored
  archive/    # compact completed run summaries, gitignored
  tmp/        # locks and temporary files, gitignored
```

## Commands

Install the local schema validator dependency once:

```bash
npm install --prefix experiment/delivery-pipeline --ignore-scripts
```

```bash
# Check local tooling, schema validation, command files, and runtime dirs
./experiment/delivery-pipeline/runner.sh doctor

# Start a run
./experiment/delivery-pipeline/runner.sh start --ticket DSC-1234 --repo /path/to/repo

# Start from a specific phase for experimentation
./experiment/delivery-pipeline/runner.sh start --ticket DSC-1234 --repo /path/to/repo --start-phase plan

# Dry-run a phase invocation without calling OpenCode
./experiment/delivery-pipeline/runner.sh start --ticket DSC-1234 --repo /path/to/repo --dry-run

# Disable or force external notifications for a run
./experiment/delivery-pipeline/runner.sh start --ticket DSC-1234 --repo /path/to/repo --no-notify
./experiment/delivery-pipeline/runner.sh resume <run-id> --answer-file answer.md --impact access --notify

# Resume a paused run
./experiment/delivery-pipeline/runner.sh answer-template <run-id> > answer.md
./experiment/delivery-pipeline/runner.sh resume <run-id> --answer-file answer.md --impact access
./experiment/delivery-pipeline/runner.sh resume <run-id> --answer-file answer.md --impact scope-change

# Inspect state
./experiment/delivery-pipeline/runner.sh status <run-id>
./experiment/delivery-pipeline/runner.sh list

# Explain the current or hypothetical transition decision
./experiment/delivery-pipeline/runner.sh explain-transition <run-id>
./experiment/delivery-pipeline/runner.sh explain-transition <run-id> --phase qa --status fail

# Clean expired compact archives
./experiment/delivery-pipeline/runner.sh cleanup --dry-run
./experiment/delivery-pipeline/runner.sh cleanup --dry-run --explain
./experiment/delivery-pipeline/runner.sh cleanup --older-than 7d

# Notification and security checks
./experiment/delivery-pipeline/runner.sh notify-test --no-notify
./experiment/delivery-pipeline/runner.sh notify-test --notify
./experiment/delivery-pipeline/runner.sh redact-check <run-id>
```

WhatsApp outbound notifications use the ignored `notification.local.json` file.
On this machine it points at `~/.ai-automation/scripts/send-whatsapp.sh`, sources
`~/.ai-automation/.env`, and loads the access token from macOS Keychain via the
`ai-automation.whatsapp.access-token` service. The local config can override the
sender mode with `.whatsapp.message_mode`; use `text` when a WhatsApp service
conversation is open so pipeline blocker text is sent instead of the global
Meta sample template. Outbound message IDs are written to
`tmp/whatsapp-thread-map.jsonl` so replies to pipeline notifications can be
mapped back to the correct run.

To unblock a paused run from WhatsApp, reply directly to the pipeline notification:

```text
impact: access
The preview URL is https://example.test/preview
```

Use `impact: decision` for a narrow product/design answer and `impact: scope-change`
when acceptance criteria or scope changed. The local WhatsApp webhook routes mapped
pipeline replies to `runner.sh whatsapp-replies`, stores the answer under
`human-inputs/`, writes hashed source metadata, and resumes the run automatically.

Schema checks can also be run directly:

```bash
cd experiment/delivery-pipeline
npm run validate:pipeline
npm run validate:phase-examples
npm run test:transitions
npm run test:cleanup
npm run test:schema
npm run test:phase-execution
npm run test:runner-integration
```

## Current Status

This is still an experiment, not production-ready. The runner can create run directories, call OpenCode phase commands, validate pipeline/state/phase-output JSON with Ajv, check required output files, make explicit transition decisions, pause for human input, compact completed runs, and clean expired archives.

Implemented now:

- `schemas/pipeline.schema.json`, `schemas/state.schema.json`, and `schemas/phase-output.schema.json`.
- Positive and negative phase-output schema examples under `examples/`.
- `tools/validate-schema.mjs` and `runner.sh doctor`.
- Schema-versioned runner-generated `state.json` and `output.json` files.
- `schemas/fix-request.schema.json`, `schemas/context-packet.schema.json`, `schemas/acceptance-criteria.schema.json`, and `schemas/figma-specs.schema.json`, with runner validation for canonical JSON artifacts.
- Transition decision tracking, stale artifact tracking, protocol-error retry once, safety-loop resume state, and `runner.sh explain-transition` with command metadata summaries.
- OpenCode attempt logs, redacted `opencode.log` output, model fallback to the configured default model, and per-attempt metadata in `command-meta.json`.
- Explicit OpenCode permission mode in `pipeline.json` so noninteractive runs can access both pipeline artifacts and the target repository.
- Local notification audit logs, `--notify`/`--no-notify`, a WhatsApp adapter configured for the local `.ai-automation` Cloud API sender, notification rate limiting, and `runner.sh notify-test`.
- Structured human answer metadata, `runner.sh answer-template`, explicit resume impact choices, and WhatsApp reply ingestion with thread/run mapping.
- `cleanup --explain`, locked-run detection, explicit stale paused/failed cleanup via `--include-stale-runs`, and bulky artifact pruning after compact archive creation.
- `runner.sh redact-check` and redaction of notification/run-log/OpenCode output for common token patterns.
- Fixture tests for transition decisions, archive retention, schema contracts, phase execution, missing required artifacts, repeated protocol errors, QA fail recovery, UI blocked, PR creation blocked, WhatsApp reply ingestion, and a full 11-phase stubbed run — all without real OpenCode or external services.

Still pending:

- Real-ticket pilot runs and production readiness sign-off.

## Retention

Completed runs produce a compact archive under `archive/<run-id>/` with a
machine-readable `retention-manifest.json`. The compact archive keeps final state,
redacted run log, PR metadata, final verdict JSON, and a short summary. It does
not copy raw ticket/context packets, human answers, per-phase execution logs,
notification payload logs, screenshots/media, dependencies, local configs, or
secret files.

Full run directories under `runs/<run-id>/` remain local working artifacts and may
contain private ticket context. Run `runner.sh redact-check <run-id>` before
sharing logs or archives outside the machine.

## Safety

- Runtime artifacts are ignored by git.
- Each run gets an isolated `runs/<run-id>/` directory.
- Startup cleanup is selective and must not delete active, paused, failed, or locked runs.
- Compact archives keep only final summaries/metadata and document excluded sensitive categories in `retention-manifest.json`.
- Validator phases are instructed not to edit code; findings become fix requests for the implementer.
