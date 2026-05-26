---
description: "Start the experimental delivery pipeline in the background for a Jira ticket key or link. Use when: /pip <ticket-or-url>."
argument-hint: "<ticket-or-url> [--repo <path>] [--start-phase <phase>] [--notify|--no-notify]"
---

# Pipeline Background Launcher

Launch the experimental delivery pipeline for the ticket provided after `/pip`, then end the chat turn once the background run is confirmed as started. Do not implement the ticket in this Copilot session.

## Input Contract

The user should call this prompt as one of:

```text
/pip DSC-1234
/pip https://on-running.atlassian.net/browse/DSC-1234
/pip https://on-running.atlassian.net/browse/DSC-1234 --repo ~/work/on-frontend
```

Treat the first non-option argument as the ticket key or URL. Preserve it exactly when passing it to the runner.

Supported optional flags:

- `--repo <path>`: target repository path
- `--start-phase <phase-id>`: start from a specific delivery-pipeline phase
- `--notify` or `--no-notify`: notification override
- `--model <model>` and `--variant <variant>`: runner model override
- `--dry-run`: runner dry run

If no ticket key or URL was provided, ask for it and stop.

## Target Repository

Resolve the target repo in this order:

1. Use `--repo <path>` when provided.
2. Otherwise use the current terminal/workspace directory when it is a real project repository.
3. If the current directory is `~/.ai-shared`, or the target repo is ambiguous, ask the user to rerun with `--repo <path>` and stop.

Never start a delivery run with `~/.ai-shared` as the target repo unless the ticket explicitly says the work belongs in `ai-shared`.

## Procedure

1. Verify the runner exists at `$HOME/.ai-shared/experiment/delivery-pipeline/runner.sh`.
2. Run the pipeline doctor from `$HOME/.ai-shared`:

```bash
./experiment/delivery-pipeline/runner.sh doctor
```

If dependencies are missing, run:

```bash
npm install --prefix experiment/delivery-pipeline --ignore-scripts
./experiment/delivery-pipeline/runner.sh doctor
```

3. Start the delivery pipeline from `$HOME/.ai-shared` in a persistent VS Code terminal asynchronously, so it keeps running after this chat turn ends. Use the terminal tool's async/background execution mode when available.

Base command:

```bash
./experiment/delivery-pipeline/runner.sh start --ticket "<ticket-or-url>" --repo "<target-repo>"
```

Append only the supported optional flags the user provided.

4. Do not wait for all phases to finish. After the command is running, report:

- that the pipeline was started in the background
- the ticket/key used
- the target repo path
- how to inspect it later:

```bash
cd ~/.ai-shared
./experiment/delivery-pipeline/runner.sh list
./experiment/delivery-pipeline/runner.sh status <run-id>
```

If the runner prints or reveals a run id immediately, include it. If not, tell the user to use `list`.

## Failure Handling

If the start command exits immediately with an error, do not say it is running. Report the error briefly and include the exact command the user can retry after fixing the blocker.

If the pipeline later pauses for human input, it will write `human-request.md` in the run directory and send configured notifications. The chat should not stay open just to monitor that.
