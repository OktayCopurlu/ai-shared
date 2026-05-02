---
description: "Fetch and summarize Discovery team (DSC) sprint tickets from Jira. Produces an executive summary, epic progress, and a detailed ticket breakdown."
---

# Sprint Review — Discovery Team

Generate a DSC sprint review from Jira.

## Context

- **Project**: DSC
- **Board ID**: 3653

## Known Limitations

1. **Sprint names**: Atlassian MCP may not expose sprint name/dates directly. If no reliable name is available, label the output as `Sprint {id}`.
2. **Assignee shape**: Prefer `assignee.displayName`; fall back to `assignee.emailAddress` (local-part) before raw `accountId`.

---

## Workflow

### Step 1 — Parse intent from the user message

Map the user's phrasing to a JQL strategy. Do not ask follow-up questions unless the request is ambiguous.

| User says… | Strategy |
| ---------- | -------- |
| "current sprint", "active sprint", "this sprint", or just `/sprint-review` | `Sprint in openSprints()` |
| "last sprint", "previous sprint", "closed sprint" | Resolve the most recent closed sprint from sprint metadata (see Step 3) |
| "sprint=12345" or a board URL containing `sprint=12345` | Treat `12345` as an explicit Jira sprint ID and use `Sprint = {id}` |
| "sprint 7", "discovery sprint 8", or a retrospective URL/title without an explicit `sprint=` parameter | Treat it as a human sprint reference. Resolve it to a real Jira sprint first, then use `Sprint = {resolvedSprintId}` |
| "current and last", "transition review" | Run both queries and produce two sections |

Default delivery is email (Step 8). Only switch if the user explicitly asks.

### Step 2 — Load Atlassian MCP

Load the `atlassian-mcp` skill and use the Atlassian tools exposed in the current session. If Jira or Confluence tools are unavailable, tell the user to start the Atlassian MCP server and stop.

### Step 3 — Fetch tickets

Use the Jira JQL search tool exposed in the current session. Prefer sprint-ID based JQL after resolving the user's sprint reference. Avoid date-based queries.

**Resolve a sprint reference before querying**:

1. If the user supplied `sprint=12345`, use `12345` directly as the Jira sprint ID.
2. If the user supplied a human reference such as `sprint 7`, `discovery sprint 8`, or a retrospective title/URL without an explicit sprint ID:
   - Use the Confluence "2026 Discovery Sprint Reviews" page (`4102389814`) to identify the matching sprint heading if possible.
   - Inspect sprint metadata from recent DSC issues in `openSprints()` and `closedSprints()` by reading `customfield_10020[]`.
   - Match on sprint `name` or the trailing sprint number from the name. Do not assume `7` means Jira sprint ID `7`.
   - Only then run sprint-ID based JQL.
3. If the reference cannot be resolved confidently, stop and report that the sprint reference was ambiguous. Do not guess.

**Specific sprint**:
```jql
project = DSC AND Sprint = {sprintId} ORDER BY status DESC, key DESC
```

**Current sprint**:
```jql
project = DSC AND Sprint in openSprints() ORDER BY status ASC, key DESC
```

**Last completed sprint**:

1. Run `project = DSC AND Sprint in closedSprints() ORDER BY key DESC` with a small `limit` and inspect `customfield_10020[]`.
2. Build a unique set of sprint objects where `state = CLOSED`.
3. Pick the sprint with the newest `completeDate`; if that is missing, fall back to the newest `endDate`.
4. If no closed sprint can be resolved from sprint metadata, stop and report the failure instead of guessing.

Then query: `project = DSC AND Sprint = {lastSprintId} ORDER BY status DESC, key DESC`.

**Epic progress data**:

1. Extract unique epic keys from `fields.parent.key` on the sprint ticket results.
2. If there are epic keys, fetch all DSC issues in those epics before calculating progress:

```jql
project = DSC AND parent in ({epicKeysCsv}) ORDER BY parent ASC, key DESC
```

3. If there are no epic keys, omit the Epic Progress table.
4. If the epic-child query cannot be resolved reliably, omit Epic Progress rather than estimate it.

For sprint ticket queries, request: `["summary", "status", "issuetype", "parent", "labels", "assignee", "customfield_10016", "customfield_10020"]`.

For epic-child queries, request: `["summary", "status", "issuetype", "parent"]`.

**If the result set is empty** (sprint not started, wrong ID, or no tickets): stop and report the empty result with the exact JQL used. Do not generate a fake report.

### Step 3b — Fetch sprint goals as context

Use sprint goals only as reasoning context for Step 5. Do not render a "Sprint Goals" section.

**Primary source — Confluence "2026 Discovery Sprint Reviews"**:

- Page ID: `4102389814` · Space: `OT`
- Use the Confluence page fetch tool exposed in the current session with Markdown output when available
- Find the section `## Discovery team sprint review sprint {N}` matching the target sprint
- Extract the **Sprint goals** subsection (goal lines with ✅/❌ markers)

**Fallback — Jira sprint `goal` field**:

- From Step 3's ticket results, inspect `fields.customfield_10020[].goal` on any ticket in that sprint

**If both are empty**: proceed without goals — don't block, don't invent.

### Step 4 — Group and analyze

**By epic / parent**: Group tickets under their parent epic. Use the epic's summary as the group header.

**By theme** (if epic grouping is not useful): derive themes from ticket summaries.

**Epic progress**: For each epic mentioned in the sprint, use the dedicated epic-child query from Step 3 to count total tickets in the epic and completed tickets. Show as `{completed}/{total} ({percent}%)`. If that supporting query was skipped or failed, omit the Epic Progress section.

### Step 5 — Build the executive summary

Write a concise executive summary:

- Group accomplishments by theme, not ticket
- Use sprint goals as context without listing them verbatim
- Call out missed or deprioritized goals only when supported by the data
- Focus on business or user impact
- Include top 3 current/next priorities
- Include risks and blockers only if real

### Step 6 — Build the detailed breakdown

Ticket-level detail in tables. Choose the detail layout based on the requested scope:

- **Current sprint only**: `Already Completed`, `In Progress`, `To Do`
- **Single completed/historical sprint**: `Completed`, `Carried Over`
- **Transition review**: include both `Last Sprint` and `Current Sprint`

Omit empty subsections and do not render placeholder tables.

### Step 7 — Compose the report

Compose the report with these sections:

- `# Sprint Review — Discovery Team`
- `_{scopeLabel} · Generated: {YYYY-MM-DD}_`
- `## Executive Summary`
- `### Accomplishments`
- Optional `### Epic Progress`
- `### Current Sprint Focus`
- Optional `### Risks & Blockers`
- `## Details`

Link every ticket ID and epic name to Jira.

Use these detail buckets by scope:

- Current sprint: `Already Completed`, `In Progress`, `To Do`
- Historical sprint: `Completed`, `Carried Over`
- Transition review: both `Last Sprint` and `Current Sprint`

Use tables for ticket details. Required columns are:

- `Ticket`, `Summary`
- Add `Assignee` when useful
- Add `Status` only for carried-over or mixed-status tables

End each sprint section with `Sprint progress: {completed}/{total} completed ({percent}%)`.

### Step 8 — Deliver (default: email with PDF attachment)

Write the report to a temporary file in `/tmp` only as an intermediate render step, convert it to PDF, and email the PDF as an attachment. Do not write the report source into the workspace.

```bash
SLUG="${scopeSlug}"                 # e.g. sprint-8, current-sprint, transition-review
REPORT_MD="/tmp/sprint-review-${SLUG}-$(date +%Y%m%d).md"
PDF="${REPORT_MD%.md}.pdf"
# ... write the report content to $REPORT_MD ...

python3 <<PY
import subprocess, os
from email.message import EmailMessage

md_path = "$REPORT_MD"
pdf_path = "$PDF"
to = "oktay.copurlu@on-running.com"
subject = "Sprint Review — {scopeLabel}"

css = """
body{font-family:-apple-system,'Segoe UI',Helvetica,sans-serif;color:#24292e;line-height:1.5;max-width:760px;margin:40px auto;padding:0 24px}
h1,h2,h3{border-bottom:1px solid #eaecef;padding-bottom:.3em}
table{border-collapse:collapse;margin:16px 0;width:100%;font-size:11px}
th,td{border:1px solid #dfe2e5;padding:4px 8px;text-align:left}
th{background:#f6f8fa}
tr:nth-child(even){background:#fafbfc}
a{color:#0366d6;text-decoration:none}
@page{size:A4;margin:15mm}
"""
body_html = subprocess.check_output(["pandoc", md_path, "-f", "markdown", "-t", "html"], text=True)
full_html = f"<!DOCTYPE html><html><head><meta charset='UTF-8'><style>{css}</style></head><body>{body_html}</body></html>"
subprocess.run(["weasyprint", "-", pdf_path], input=full_html.encode("utf-8"), check=True)

msg = EmailMessage()
msg["From"] = "oktay.copurlu@on-running.com"
msg["To"] = to
msg["Subject"] = subject
msg.set_content("Sprint review attached as PDF.")
with open(pdf_path, "rb") as f:
    msg.add_attachment(f.read(), maintype="application", subtype="pdf",
                       filename=os.path.basename(pdf_path))

subprocess.run(["msmtp", "-a", "gmail", to], input=msg.as_bytes(), check=True)
print("SENT")
PY
```

Report success with subject + recipient. Do not delete `/tmp` files.

---

## Rules

- **Don't invent tickets or progress numbers** — only report what JQL returns.
- **Don't force sections** — if there are no risks, no carried-over tickets, no specific epic, omit the section entirely.
- **Link every ticket ID and epic name** to its Jira URL.
- **Assignee column is optional** — skip if most tickets have no assignee or if the team prefers anonymized summaries.
