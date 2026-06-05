# Test checklist — running the pipeline in `onrunning/on-frontend`

Steps to test the delivery pipeline end-to-end in on-frontend.

## Smoke-test findings (2026-06-05, ai-shared)

What the first CI runs proved, so we don't re-litigate it:

| Konu | Sonuç |
|------|-------|
| **Model** | Agent `claude-sonnet-4.6` ile çalıştı (copilot motorunun varsayılanı; deney workflow'larında bu model açıkça sabitlendi). Model seçimi `engine: { id: copilot, model: ... }` ile yapılır. |
| **Jira okuma** | ✅ Çalışıyor — agent CI'da DSC-2307'yi başlık + statüyle okudu (pre-step → `jira-in/ticket.json`). |
| **Figma okuma** | ⏸️ Şimdilik park. Uzak Figma MCP OAuth-only → PAT'e 401. REST `api.figma.com` token geçerli (`/v1/me` 200) ama dosya içerik uçları 403 `File not exportable` (muhtemelen on-running org politikası veya token `file_content:read` scope eksik). İlk denemeler Figma linki gerektirmeyen ticket'larla yapılacak. |
| **`workflow_dispatch` tuzağı** | Form'a gh-aw bir `aw_context` alanı ekler — **boş bırak**. Oraya düz cümle yazmak "Failed to parse aw_context input as JSON" ile patlar. Sadece gerçek input'ları doldur. |

## 3-step chain experiment (ai-shared)

Self-contained 3-stage dispatch-chain to validate per-stage agent + artifact state + hand-off,
without Figma and without code changes. Files in `ai-shared` root `.github/workflows/`:
`exp-step-1-read-jira.md` (read Jira → AC list) → `exp-step-2-plan.md` (AC list → impl plan) →
`exp-step-3-final.md` (receives plan, no-op). Run **step 1** with a `ticket`; it chains itself.
Inspect the `exp-state.tgz` artifact on the step-3 run to see `ac-list.md` + `impl-plan.md` + `done.md`.

## Step 0 (recommended first): token smoke test in `ai-shared`

Before touching on-frontend, prove the agent can READ Figma + Jira with the tokens,
using the tiny self-contained workflow `.github/workflows/figma-jira-read-smoke.md`
(in the `ai-shared` repo root). It uses the same mechanisms as the pipeline:
Jira via a pre-step → `jira-in/ticket.json`, Figma via the Figma MCP.

| # | Yapılacak | Kim |
|---|-----------|-----|
| 0.1 | `ai-shared` repo'ya 4 secret ekle: `COPILOT_GITHUB_TOKEN`, `FIGMA_MCP_TOKEN`, `JIRA_API_TOKEN`, `JIRA_USER_EMAIL` | Sen |
| 0.2 | `gh aw compile` (zaten derlendi) → `.md` + `.lock.yml` commit, `main`'e push | Sen |
| 0.3 | Actions sekmesinden **figma-jira-read-smoke**'u çalıştır: bir `ticket` + bir `figma_url` ver | Sen |
| 0.4 | `smoke-result.md` artifact'ını indir: iki satır da `READABLE` mı? | Sen |

> `COPILOT_GITHUB_TOKEN` ai-shared'e ayrıca eklenmeli — org token kişisel/public repoya ulaşmaz.

## End-to-end pipeline test in on-frontend

| # | Yapılacak | Kim |
|---|-----------|-----|
| 1 | `phases/` klasörünü ai-shared `main`'e push et (import'lar çözülsün) | Sen |
| 2 | `FIGMA_MCP_TOKEN` secret ekle | Sen |
| 3 | `JIRA_USER_EMAIL` secret ekle (servis hesabının maili) | Sen / ekip |
| 4 | 11 `phase-*.md` dosyasını `on-frontend/.github/workflows/`'a kopyala | Sen |
| 5 | `gh aw compile` (11'ini birlikte) → `.md` + `.lock.yml` commit | Sen |
| 6 | PR'ı `main`'e merge et (workflow_dispatch sadece main'den çalışır) | Sen + reviewer |
| 7 | `phase-01`'i bir `ticket` ile tetikle, `dry_run: true` (ilk prova) | Sen |
| 8 | İyi görünürse `dry_run: false` ile gerçek uçtan uca koş | Sen |

**Zaten hazır (ekleme yok):** `COPILOT_GITHUB_TOKEN`, `JIRA_API_TOKEN`, `PREVIEW_BASIC_AUTH`.

Detaylar için: [README.md](README.md) (secret denetim tablosu, Jira auth notu, QA/UI doğrulama bölümü).
