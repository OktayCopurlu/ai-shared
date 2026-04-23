---
description: "Fetch delivered story points from a Jira sprint report and write FE/BE/App breakdown to the Guidance Stream Google Sheet."
---

# Sprint Delivered Points → Google Sheet

Extract delivered story points from a Jira sprint report, categorize by FE/BE/App, and write to the Guidance Stream tracking sheet.

## Input

The user provides a Jira sprint retrospective URL like:
`https://onrunning.atlassian.net/jira/software/c/projects/DSC/boards/3653/reports/sprint-retrospective?sprint={sprintId}`

Extract `rapidViewId` (boardId) and `sprintId` from the URL query parameters. The board ID is in the path: `/boards/{boardId}/`. The sprint ID is the `sprint` query param.

## Constants

- **Spreadsheet ID**: `12fO5QEtuW8SoCAhnFbBX5Mj3_sF3Zlq_yRl41lR9Fdw`
- **Tab name**: `Guidance Stream`
- **Tab gid**: `1880255434`
- **Google OAuth credentials**: `~/.config/google-oauth/token.json`
- **Jira auth**: `$JIRA_USER_EMAIL` and `$JIRA_API_TOKEN` from environment

## Target Rows

| Row | Index (0-based) | Label |
|-----|-----------------|-------|
| 10  | 9               | Points delivered FE |
| 11  | 10              | Points delivered BE |
| 12  | 11              | Points delivered App |
| 13  | 12              | Total Delivered (formula — do NOT write here) |

Row 13 is a formula that sums rows 10-12. Never overwrite it.

## Workflow

### Step 1 — Fetch sprint report from Jira

```bash
curl -s -u "$JIRA_USER_EMAIL:$JIRA_API_TOKEN" \
  "https://onrunning.atlassian.net/rest/greenhopper/1.0/rapid/charts/sprintreport?rapidViewId={boardId}&sprintId={sprintId}"
```

Parse the JSON response. Extract `contents.completedIssues`.

### Step 2 — Categorize completed issues

For each completed issue, read `summary` and `estimateStatistic.statFieldValue.value` (story points).

Categorize by title prefix:

| Prefix pattern (case-insensitive) | Category |
|------------------------------------|----------|
| `[FE` or `[FRONTEND`              | FE       |
| `[BE]` or `[BACKEND`              | BE       |
| `[APP]` or `[App]`                | APP      |
| anything else                     | OTHER    |

Sum story points per category.

### Step 3 — Report & confirm

Print a summary table:

```
Sprint {sprintId} — Delivered Story Points
──────────────────────────────────
FE:      {fe_total}
BE:      {be_total}
APP:     {app_total}
OTHER:   {other_total}  ← {count} issue(s) without FE/BE/APP prefix
──────────────────────────────────
TOTAL:   {total}
```

If OTHER > 0, list those issues with key + summary and ask the user how to distribute them (add to FE, BE, APP, or skip).

Wait for user confirmation before writing.

### Step 4 — Detect target column

Fetch the sheet as CSV and find the correct column:

1. Read row 6 (Points committed FE, 0-indexed row 5).
2. Starting from the rightmost column, find the first column where committed FE has a value but delivered FE (row 10) is empty.
3. That is the target column.
4. Verify the header row value at that column to show the user which sprint column will be written.

### Step 5 — Write to Google Sheet

Convert the 0-based column index to A1 notation (e.g., col 29 → AD).

Use Google Sheets API v4 to write values:

```python
import json, urllib.request, urllib.parse

# Get OAuth token
with open('$HOME/.config/google-oauth/token.json') as f:
    creds = json.load(f)
data = urllib.parse.urlencode({
    'client_id': creds['client_id'],
    'client_secret': creds['client_secret'],
    'refresh_token': creds['refresh_token'],
    'grant_type': 'refresh_token'
}).encode()
req = urllib.request.Request('https://oauth2.googleapis.com/token', data=data)
token = json.loads(urllib.request.urlopen(req).read())['access_token']

# Column index to A1 letter
def col_letter(idx):
    result = ''
    while idx >= 0:
        result = chr(idx % 26 + ord('A')) + result
        idx = idx // 26 - 1
    return result

col = col_letter(target_col)
sheet_id = '12fO5QEtuW8SoCAhnFbBX5Mj3_sF3Zlq_yRl41lR9Fdw'
tab = 'Guidance Stream'

# Write FE (row 10), BE (row 11), App (row 12)
range_str = f"'{tab}'!{col}10:{col}12"
body = json.dumps({
    'range': range_str,
    'majorDimension': 'COLUMN',
    'values': [[fe_total, be_total, app_total]]
}).encode()

url = f'https://sheets.googleapis.com/v4/spreadsheets/{sheet_id}/values/{urllib.parse.quote(range_str)}?valueInputOption=USER_ENTERED'
req = urllib.request.Request(url, data=body, method='PUT',
    headers={'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'})
resp = json.loads(urllib.request.urlopen(req).read())
print(f"Updated {resp.get('updatedCells', 0)} cells")
```

### Step 6 — Verify

After writing, re-fetch the sheet and print:
- The values in rows 10-12 at the target column
- The value in row 13 (Total Delivered) to confirm the formula computed correctly
- Compare the sheet total with the Jira total

Print:
```
✓ Written to column {col} ({header_name})
  FE:    {fe}
  BE:    {be}
  APP:   {app}
  Total: {row_13_value} (formula)
  Jira:  {jira_total}
  Match: {yes/no}
```
