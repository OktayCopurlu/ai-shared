# Shared Research Policy

This file applies to **all** research modes. Load it before executing any mode skill.

---

## Source Registry

### Tier 1A — Platform & AI vendors (required for top findings)

| Vendor           | Canonical sources                                                                                                      |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------- |
| GitHub / Copilot | github.blog, github.com/changelog, docs.github.com/copilot                                                             |
| VS Code          | code.visualstudio.com/updates, marketplace.visualstudio.com/search?term=mcp                                            |
| OpenAI           | openai.com/news, platform.openai.com/docs, openai.com/changelog                                                        |
| Anthropic        | anthropic.com/news, docs.anthropic.com/en/release-notes                                                                |
| Google / GCP     | blog.google, cloud.google.com/blog, firebase.google.com/support/release-notes, ai.google.dev/gemini-api/docs/changelog |
| Vercel           | vercel.com/changelog, vercel.com/blog                                                                                  |
| Cloudflare       | blog.cloudflare.com, developers.cloudflare.com/changelog                                                               |
| Contentful       | contentful.com/changelog, contentful.com/blog                                                                          |
| Amplitude        | amplitude.com/blog, help.amplitude.com/hc/en-us/categories/release-notes                                               |
| MCP protocol     | modelcontextprotocol.io, registry.modelcontextprotocol.io, github.com/modelcontextprotocol/registry, github.com/modelcontextprotocol/servers/releases |

### Tier 1B — Frontend & tooling (required for stack-specific findings)

| Vendor           | Canonical sources                                                                   |
| ---------------- | ----------------------------------------------------------------------------------- |
| Vue              | vuejs.org/blog, github.com/vuejs/core/releases, vuejs.org/guide/migration           |
| Nuxt             | nuxt.com/blog, github.com/nuxt/nuxt/releases, nuxt.com/docs/getting-started/upgrade |
| TypeScript       | devblogs.microsoft.com/typescript, github.com/microsoft/TypeScript/releases         |
| Vite             | vitejs.dev/blog, github.com/vitejs/vite/releases                                    |
| Vitest           | vitest.dev, github.com/vitest-dev/vitest/releases                                   |
| ESLint           | eslint.org/blog, github.com/eslint/eslint/releases                                  |
| Pinia            | pinia.vuejs.org, github.com/vuejs/pinia/releases                                    |
| Storybook        | storybook.js.org/blog, github.com/storybookjs/storybook/releases                    |
| Nx               | nx.dev/blog, github.com/nrwl/nx/releases                                            |
| Node.js          | nodejs.org/en/blog, github.com/nodejs/node/blob/main/CHANGELOG.md                   |
| Apollo / GraphQL | apollographql.com/changelog, github.com/apollographql, graphql.org/blog             |
| Sass / CSS       | sass-lang.com/blog, github.com/sass/sass/releases, developer.chrome.com/blog (CSS)  |
| Playwright       | playwright.dev/docs/release-notes, github.com/microsoft/playwright/releases         |
| Yarn             | yarnpkg.com/blog, github.com/yarnpkg/berry/releases                                 |

### Tier 2 — Repositories & secondary official sources

- GitHub Releases pages for any vendor above
- Official migration guides and upgrade docs
- RFC repositories: github.com/vuejs/rfcs, github.com/tc39/proposals
- Actively maintained `awesome-*` lists (check last commit date — must be < 6 months)
- MCP server discovery: registry.modelcontextprotocol.io and github.com/modelcontextprotocol/registry for official server metadata; punkpeye/awesome-mcp-servers for actively maintained community discovery
- MCP reference implementations: github.com/modelcontextprotocol/servers for protocol examples only, not broad server discovery
- W3C / TC39 proposal trackers for CSS and JS language changes
- Can I Use (caniuse.com) for browser compatibility changes
- MDN Web Docs changelog for Web API changes

#### Tier 2 — AI / Agents / MCP articles (article-finder mode)

- simonwillison.net — high-signal AI, LLM, and agent engineering notes
- huggingface.co/blog — AI/ML model releases and applied research
- thenewstack.io — cloud-native, AI tooling, and developer platform news
- eugeneyan.com — applied AI/ML engineering in production
- lilianweng.github.io — deep AI/LLM technical posts
- bair.berkeley.edu/blog — AI research from Berkeley AI Research Lab
- arxiv.org (cs.AI, cs.LG, cs.CL) — preprints for AI/ML/NLP (use only for clearly practice-relevant papers)

### Tier 3 — Community (supporting evidence only)

- Hacker News (hn.algolia.com for keyword search)
- The Changelog podcast / changelog.com
- Trusted engineering blogs: Josh Comeau, Kent C. Dodds, Lee Robinson, Anthony Fu
- High-signal GitHub Discussions or issues
- r/javascript, r/typescript, r/vuejs (use only to discover, always verify with Tier 1/2)
- Twitter/X: official vendor accounts only (not individual commentary)
- dev.to — practitioner articles and tutorials (article-finder mode)
- lobste.rs — curated tech link aggregator (article-finder mode)
- The Pragmatic Engineer (newsletter.pragmaticengineer.com) — in-depth engineering articles (article-finder mode)
- InfoQ (infoq.com) — engineering conference talks and articles (article-finder mode)
- GitHub Trending (github.com/trending?since=weekly, with language filters) — discovery-only surface for novel AI/dev-tooling repos (trending-discovery mode); a trending listing alone is never sufficient evidence — read the actual repo files and validate against Tier 1/2 before PR-ing

> **Rule**: Community-only sourcing is not sufficient for a top finding. Always validate with Tier 1 or Tier 2.
> **Rule**: For Tier 1B sources, only check the vendors relevant to the current mode (e.g. release-watch checks them exhaustively; weekly-digest only checks if something bubbles up from Tier 3).

---

## Scoring Rubric

Score every candidate finding before deciding to include it.

| Dimension        | 0                              | 1                              | 2                                                                                            |
| ---------------- | ------------------------------ | ------------------------------ | -------------------------------------------------------------------------------------------- |
| Stack relevance  | Unrelated to our stack         | Tangentially relevant          | Directly relevant to Vue / Nuxt / TS / Nx / Copilot / MCP / GraphQL / Contentful / Amplitude |
| Actionability    | No action possible             | Possible in future             | Actionable now or this sprint                                                                |
| Maturity         | Rumor or concept only          | Preview / Beta / Announced     | Released / GA                                                                                |
| Novelty          | Already reported (same status) | Moderate update                | New or materially changed since last report                                                  |
| Evidence quality | Community only                 | Repository or secondary source | Official Tier 1 source                                                                       |
| Urgency          | No time pressure               | Notable but not urgent         | Breaking change / security / deadline                                                        |

**Score thresholds:**

- **≥ 8** → Top finding
- **5–7** → Watchlist
- **< 5** → Ignore

**Automatic disqualifiers** (score as 0 regardless of other dimensions):

- Exact duplicate in history with same status
- No implementation detail, only announcement prose
- "Top N tools" article format with no original content
- Vague "AI will change everything" framing without a concrete feature or API change

---

## Time Windows

| Mode               | Look back                            |
| ------------------ | ------------------------------------ |
| weekly-digest      | 7 days                               |
| company-watch      | 14 days                              |
| copilot-and-agents | 30 days (fast-moving area)           |
| release-watch      | since last known version, or 30 days |
| tool-evaluation    | no time limit                        |
| article-finder     | 30 days (or no limit if topic-based) |

---

## Dedupe Policy

Before including a finding, check `self-evolution/jobs/research/run-log.jsonl`.

Skip an item if any of these are true:

- Same title with the same status already in history
- Same canonical URL already in history for a concrete item page (article, release note, docs page)
- Materially identical release (same version, same vendor)

Recurring feeds and index pages may be revisited. Do not treat news hubs, changelog indexes, monthly archives, or landing pages as duplicates on URL alone; dedupe the specific article or release item they surface instead.

Re-surface a previously logged item **only** if:

- Status changed (e.g. Preview → Released, Beta → GA, Deprecated)
- Rollout meaningfully expanded (new region, new plan tier, new platform)
- Breaking change or security note was added after initial release
- User explicitly asks for a recap or comparison

---

## Incremental Repo Watch

High-signal repos that publish many small changes (skills, prompts, agent rules, cookbook recipes). Visit incrementally: only inspect commits and changed files since the last visit, not the whole repo.

| Repo                     | Why it matters                                                                 |
| ------------------------ | ------------------------------------------------------------------------------ |
| anthropics/skills        | Anthropic's own skill packages — direct source of skill/agent patterns         |
| openai/openai-cookbook   | Practical agent / prompt / tool-use recipes from OpenAI                        |
| github/awesome-copilot   | Community-curated Copilot instructions, prompts, and agent configs             |

### How to visit incrementally

1. Find the last visit SHA for the repo from recent `run-log.jsonl` entries (field `repo_state.<owner>/<repo>`).
2. If no prior SHA exists, treat this as the baseline: read the repo's top-level structure and any one obviously relevant file, then record the current `HEAD` SHA. Do not deep-read.
3. If a prior SHA exists, list changes since then:
   - `gh api repos/<owner>/<repo>/compare/<last_sha>...HEAD --jq '.files[].filename'`
   - Filter to files that could improve our repo: `**/SKILL.md`, `**/AGENTS.md`, `**/*.prompt.md`, `**/*.agent.md`, `**/instructions.md`, `**/*cursorrules*`, `cookbook/**`, `examples/**`, top-level `*.md` policy/guideline files.
   - Read only those files (not unrelated code, assets, or generated content).
4. If nothing relevant changed, count the repo as one successful visited source and move on.
5. Record the new `HEAD` SHA in the run-log entry under `repo_state`, so the next run can diff from it.

### Run-log addition

When this pattern is used, the run-log line must include a `repo_state` object alongside existing fields:

```json
{"run_id":"...","date":"...","focus":"...","urls_visited":[...],"findings":[...],"prs_opened":0,"repo_state":{"anthropics/skills":"abc1234","openai/openai-cookbook":"def5678"}}
```

Only include repos actually visited this run. Existing SHAs from prior runs remain valid; the runner does not need every repo every day.

---

## Stop Conditions

- Stop at **7 top findings**. Do not pad with weak ones.
- Stop after checking **2 official sources per vendor** unless a conflict or gap exists.
- A finding with only community-source evidence may be a Watchlist item but never a Top finding.

---

## Empty-State Rules

If no strong findings exist for a run, say so explicitly:

> "No significant new updates found in the defined time window. [N] watchlist items are pending re-evaluation."

Do not invent or force low-quality items to fill a digest.
