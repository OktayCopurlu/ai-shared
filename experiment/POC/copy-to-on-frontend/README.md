# Ready-to-copy gh-aw workflows for `onrunning/on-frontend`

Drop the 11 files in `.github/workflows/` straight into
`onrunning/on-frontend/.github/workflows/`. They are the same per-phase
dispatch-chain as `../workflows/`, but pre-filled for this repo:

- `network.allowed` set to the real hosts: `onrunning.atlassian.net` (Jira),
  `api.figma.com` / `www.figma.com` (Figma), `on.com` + `*.on.com` (the
  `on-shop-<PR#>.on.com` preview).
- Figma MCP server wired on the phases that read Figma (1, 7, 11) with a
  `FIGMA_MCP_TOKEN` bearer.
- Everything else (engine `copilot`, read-only permissions + `actions: read`,
  artifact state, `dispatch-workflow` chain, PR opens at phase 8) unchanged.

> **This is the derived set.** `../workflows/phase-*.md` are the canonical
> templates; the files here are the same workflows with `onrunning/on-frontend`
> hosts and the Figma MCP block filled in. There is no generator yet, so any
> change to a phase workflow must be made in **both** places until one is
> generated from the other.

The phase bodies are **not** copied here — they are imported at compile time from
public `OktayCopurlu/ai-shared@main`, so push the `experiment/github-delivery-pipeline/phases/`
folder to `ai-shared` `main` before compiling (and ideally pin `@main` to a tag/SHA).

## What we are waiting for (human-owned, cannot be scripted)

These are credentials / org decisions, not code. Nothing else blocks adoption.

**Audited against `onrunning/on-frontend` repo secrets (2026-06-05).** The
pipeline reuses what is already there and needs only **two** new secrets.

| # | Secret / item | Status in on-frontend | Action |
|---|---|---|---|
| 1 | `COPILOT_GITHUB_TOKEN` | ✅ Already present (+ org Copilot) | None — confirm it reaches this repo |
| 2 | `JIRA_API_TOKEN` | ✅ Already present | None — but confirm **which account owns it** (see Jira note) |
| 3 | `PREVIEW_BASIC_AUTH` | ✅ Already present | None — used to open the preview in phases 10–11 |
| 4 | `JIRA_USER_EMAIL` | ❌ Missing | **Add it.** Jira Cloud REST needs it (see Jira note) |
| 5 | `FIGMA_MCP_TOKEN` | ❌ Missing | **Add it.** Figma PAT, used by phases 1, 7, 11 |
| 6 | *(optional)* Contentful / Google Drive tokens | ❌ Missing | Add only when a ticket references those sources (phase 1) |
| 7 | Confirm `network.allowed` hosts | n/a | Reviewer: defaults to the org hosts above; add any internal preview/API host you actually hit |

The pipeline does **not** need the repo's deploy/CI secrets (`ENV_SECRETS_KEY`,
`NX_CLOUD_ACCESS_TOKEN`, `GITOPS_TOKEN`, `CLOUDFLARE_API_TOKEN`, AWS roles,
Rollbar/Sonar/New Relic/Slack). Those belong to on-frontend's own build + deploy;
the pipeline only reads code, opens a PR, and validates the preview that
on-frontend's CD already builds.

### Jira: why `JIRA_USER_EMAIL` is mandatory, and which account to use

- Jira **Cloud** (`onrunning.atlassian.net`) REST auth is HTTP basic
  `email:api-token`. **The token alone cannot authenticate** — Atlassian needs
  the owning account's email. (Bearer/PAT auth only exists on Jira Server/Data
  Center, not Cloud.) So `JIRA_USER_EMAIL` is not optional.
- The existing `JIRA_API_TOKEN` is **not referenced by any on-frontend
  workflow** (the only Jira step, `onrunning/jira-pr-action`, just builds links
  and uses `github.token`). So before reusing it, **ask the team/admin which
  account that token belongs to** and set `JIRA_USER_EMAIL` to that account's
  email. If the owner is unknown, mint a fresh token + email pair instead.
- **Use a shared service / bot account, not a personal one.** Repo secrets are a
  single shared identity: every developer's pipeline run authenticates as
  whoever owns the token. A personal token means all comments and the *In
  Review* transition show *your* name and break when you rotate it or leave. A
  neutral service account (e.g. a `git@on-running.com`-style mailbox invited to
  Jira with comment + transition permission) keeps the automation team-owned.
  Avoid the Jira **GitHub Copilot** app account — app identities can't issue a
  personal API token for REST basic auth.

> Secret hygiene: never paste these values into tickets, PRs, or comments. The
> preview basic-auth creds are for the agent's own browser only and
> must be stripped from every user-visible artifact.

## How QA / UI validation actually runs (no localhost secret needed)

The pipeline never starts the app on a dev server in CI, so your local `.env` /
env-decryption key is **not** required. Validation happens in two distinct places:

| Phase | When | What it checks against | Live app? |
|---|---|---|---|
| 6 QA, 7 UI | **before** the PR exists | Static: the accumulated diff, Figma specs, and unit/component tests. Catches obvious defects early; defers measurements that need a running app. | No live surface — no dev server is started |
| 10 PR-QA, 11 PR-UI | **after** phase 8 opens the PR | The real **preview** `on-shop-<PR#>.on.com`, browsed with Playwright + `PREVIEW_BASIC_AUTH`. This is the authoritative live QA/UI. | Yes — preview is live |

Why not run the app live in phases 6–7? The preview is **built + deployed by
on-frontend's own CD** (`yarn on-shop build` decrypted with `ENV_SECRETS_KEY` →
Docker → ECR → GitOps/k8s → `on-shop-<PR#>.on.com`), not by this pipeline. The
build-decrypting `ENV_SECRETS_KEY` lives only in on-frontend. Running a localhost
dev server in phases 6–7 is *technically possible inside on-frontend* (the
`yarn on-shop dev` script + `ENV_SECRETS_KEY` exist) but adds install + server +
browser cost on every run, and the live checks are already covered for free by
the preview at phases 10–11. So phases 6–7 stay static by design.

## Adoption steps

1. Push `experiment/github-delivery-pipeline/phases/` to `ai-shared` `main` (so the
   `{{#runtime-import ...@main}}` directives resolve). Optionally pin `@main` to a tag/SHA.
2. Add the **two missing** secrets in `onrunning/on-frontend`: `FIGMA_MCP_TOKEN`
   and `JIRA_USER_EMAIL` (`COPILOT_GITHUB_TOKEN`, `JIRA_API_TOKEN`, and
   `PREVIEW_BASIC_AUTH` are already present — see the audit table above).
3. Copy these 11 `phase-*.md` files into `on-frontend/.github/workflows/`.
4. `gh aw init` (once) then `gh aw compile` — compile all 11 together so the
   `dispatch-workflow` targets resolve. Commit each `.md` + its generated `.lock.yml`.
5. Run the **`phase-01-context-intake`** workflow with a `ticket` (e.g. `DSC-1234`).
   The chain advances itself. Keep phase 8's `dry_run: true` for the first pass
   (stages the PR, no open); set `dry_run: false` for a real end-to-end run.

## Repo facts these files encode

- Nx monorepo, `yarn`, Node 22.17.0 (`.nvmrc`); commands: `yarn --frozen-lockfile`,
  `yarn build`, `yarn test`, `yarn lint`, `yarn dev`.
- Preview URL: `https://on-shop-<PR#>.on.com`. Built by on-frontend's CD
  (`cd-on-shop-preview.yml`): `yarn on-shop build` (uses `ENV_SECRETS_KEY` +
  `NX_CLOUD_ACCESS_TOKEN`) → Docker image → ECR → GitOps/k8s deploy. The pipeline
  consumes this preview; it does not build it.
- Jira account `onrunning`; ticket prefixes include
  `B2C|INF|CAL|ACQ|XUP|LOY|GDC|CAI|QA|TSP|BAD|COP|DSC|API|CPP`.

## Testing before merge

- **The product-change PR is fully testable without merging.** Phase 8 opens a
  normal PR; its preview (`on-shop-<PR#>.on.com`), CI checks, and human review
  all run on the PR. Phases 9–11 validate that live PR.
- **The 11 workflow files themselves must sit on the default branch (`main`) to
  be runnable** — GitHub only exposes `workflow_dispatch` from the default
  branch. Merging them is harmless: they do nothing until manually triggered and
  deploy nothing on their own. Keep phase 8's `dry_run: true` for the first pass
  to stage the PR without opening it.
