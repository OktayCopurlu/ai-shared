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
| MCP protocol     | modelcontextprotocol.io, github.com/modelcontextprotocol/servers/releases                                              |

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
- MCP server repositories: github.com/modelcontextprotocol/servers, punkpeye/awesome-mcp-servers
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

## Stop Conditions

- Stop at **7 top findings**. Do not pad with weak ones.
- Stop after checking **2 official sources per vendor** unless a conflict or gap exists.
- A finding with only community-source evidence may be a Watchlist item but never a Top finding.

---

## Empty-State Rules

If no strong findings exist for a run, say so explicitly:

> "No significant new updates found in the defined time window. [N] watchlist items are pending re-evaluation."

Do not invent or force low-quality items to fill a digest.
