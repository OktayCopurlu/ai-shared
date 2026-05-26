# Shared Delivery Pipeline Command Preamble

Every phase command must enforce these rules even when copied out of this folder.

## Runner Contract

- Treat `RUN_DIR`, `STATE_PATH`, `INPUT_PATH`, `TARGET_REPO`, and `PHASE` from the runner message as the only runtime authority.
- Read previous artifacts as immutable inputs. Only write the artifacts listed for the current phase.
- The runner owns transitions. The phase output may recommend the next action, but must not assume it controls the state machine.
- Do not invent evidence, links, test results, browser observations, PR URLs, screenshots, or human answers.
- If a required input, credential, URL, environment, design decision, or repo state is missing, write `status: "blocked"` with a blocker that says exactly what is needed from the human.
- Do not include secrets, tokens, raw auth headers, cookies, or private payloads in `output.json`, notes, verdicts, PR text, notifications, or fix requests. Summarize sensitive material and point to local paths.

## Output Contract

- Always write `phases/<phase-folder>/output.json` before ending.
- `output.json` must validate against `schemas/phase-output.schema.json`.
- Use `schema_version: "1"` and the exact phase ID.
- `status: "fail"` must include at least one `fix_requests[]` item or blocker.
- `status: "blocked"` and `status: "protocol-error"` must include at least one blocker.
- Separate files under `fix-requests/` must validate against `schemas/fix-request.schema.json` and include `schema_version: "1"`.

## Fix Request Contract

Use fix requests only for work the Implementer/Fixer should do. Each request must include ID, source phase, severity, related AC IDs, scenario, expected behavior, actual behavior, reproduction steps, and suggested direction. Validator phases must not patch code or tests directly.
